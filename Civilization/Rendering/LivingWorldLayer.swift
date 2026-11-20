#if DEBUG
import SpriteKit
import GameCore
import GameApplication

/// Opt-in visual review only. Procedural figures are provisional, not approved character art.
/// No game commands, authoritative clocks, resource transfers, bridge or gate inference.
@MainActor
final class LivingWorldLayer: SKNode {
    typealias Phase = VisualDayPhase
    enum Weather: String, CaseIterable { case clear, rain, fog }

    private struct Walker {
        let node: VillagerFigure
        var journey: VisualAgentJourney
    }
    private struct Creature {
        let node: SKNode
        let origin: CGPoint
        let destination: CGPoint
        let aquatic: Bool
        var elapsed: TimeInterval
    }
    private var walkers: [Walker] = []
    private var wildlife: [Creature] = []
    private var nightLights: [SKShapeNode] = []
    private var figureBuildCount = 0
    private var daylight = VisualDayCycle()
    private var continuousLighting = false
    private var cycleDuration: Double = 120
    private var selectionRevision = -1
    private let atmosphere = SKNode()
    private let tint = SKSpriteNode(color: .clear, size: .zero)
    private var weatherNodes: [SKShapeNode] = []
    private var atmosphereInitialized = false
    private struct LayoutBuilding: Equatable {
        let id: Int
        let kind: BuildingKind
        let origin: Tile
        let footprint: BuildingFootprint
        let operational: Bool
        let productionActive: Bool
    }
    private var renderedBuildings: [LayoutBuilding] = []
    private var renderedRoads: [RoadTile] = []
    private var renderedDiscovery: Set<Tile>?
    private var renderedMap = ""
    private var budget = VisualWorldBudget(reduceMotion: true, lowPower: false, foreground: false)
    private var enabled = false
    private var phase: Phase = .day
    private var weather: Weather = .clear
    private var lastTime: TimeInterval?
    private var frameDebt: TimeInterval = 0
    private var weatherTime: TimeInterval = 0
    private var viewport: CGRect = .zero
    private(set) var routeCount = 0
    private(set) var routeTileCount = 0
    var reviewSummary: String {
        String(format: "fraction=%.4f tint=%.4f light=%.3f", daylight.fraction, tint.color.cgColor.alpha,
            nightLights.first?.alpha ?? 0) +
        " cycle=\(continuousLighting) period=\(Int(cycleDuration)) moving=\(budget.animates) figureBuilds=\(figureBuildCount) nodes=\(descendantCount(self)) lights=\(nightLights.count) weather=\(weather.rawValue)"
    }
    var reviewCaption: String {
        let index = min(3, Int(daylight.fraction * 4))
        let phases = Phase.allCases
        let light = continuousLighting ? "\(phases[index].rawValue.capitalized) → \(phases[(index + 1) % 4].rawValue.capitalized) · \(Int(cycleDuration)) s" : phases[index].rawValue.capitalized
        return light + (budget.animates ? " · Motion" : " · Static")
    }

    override init() {
        super.init()
        name = "living-world-review-provisional"
        isUserInteractionEnabled = false
        atmosphere.zPosition = 1500
        addChild(atmosphere)
        atmosphere.addChild(tint)
    }
    required init?(coder: NSCoder) { fatalError("Programmatic review layer") }

    func display(state: GameState, configuration: GameConfiguration, reduceMotion: Bool,
                 reviewEnabled: Bool, phase: Phase = .day, weather: Weather = .clear,
                 foreground: Bool = true, lowPower: Bool = false, cycles: Bool = false,
                 selectionRevision: Int = 0, activeProductionIDs: Set<Int> = [], cycleDuration: Double = 120) {
        let nextBudget = VisualWorldBudget(reduceMotion: reduceMotion, lowPower: lowPower, foreground: foreground)
        let buildings = state.buildings.map {
            LayoutBuilding(id: $0.id, kind: $0.kind, origin: $0.origin,
                           footprint: $0.occupiedFootprint(in: configuration), operational: $0.isOperational,
                           productionActive: activeProductionIDs.contains($0.id))
        }
        let changed = !enabled || budget.agentCount != nextBudget.agentCount || renderedBuildings != buildings ||
            renderedRoads != (state.roads ?? []) || renderedDiscovery != state.discoveredTiles || renderedMap != configuration.map.id
        let wasEnabled = enabled
        enabled = reviewEnabled
        budget = nextBudget
        isHidden = !reviewEnabled || !foreground
        if !reviewEnabled {
            clearFigures(); suspendClocks()
            atmosphere.isHidden = true
            return
        }
        atmosphere.isHidden = !foreground
        if changed {
            figureBuildCount += 1
            clearFigures()
            renderedBuildings = buildings; renderedRoads = state.roads ?? []
            renderedDiscovery = state.discoveredTiles; renderedMap = configuration.map.id
            let planner = VisualRoutePlanner(configuration: configuration, state: state)
            let routes = planner.destinationRoutes(maximumAgents: budget.agentCount)
            routeCount = routes.count; routeTileCount = routes.reduce(0) { $0 + $1.tiles.count }
            for (index, route) in routes.enumerated() { addWalker(route: route, index: index, state: state, planner: planner, activeProductionIDs: activeProductionIDs) }
            if budget.agentCount > 0 {
                addWildlife(configuration: configuration, state: state, planner: planner)
                addNightLights(state: state, configuration: configuration, activeProductionIDs: activeProductionIDs)
            }
            lastTime = nil; frameDebt = 0
        }
        let duration = cycleDuration.isFinite && cycleDuration >= 1 ? cycleDuration : 120
        if self.cycleDuration != duration {
            self.cycleDuration = duration; daylight = VisualDayCycle(duration: duration); daylight.select(phase)
        }
        if self.phase != phase || self.selectionRevision != selectionRevision || !wasEnabled {
            self.phase = phase; self.selectionRevision = selectionRevision; daylight.select(phase)
        }
        if continuousLighting != cycles { continuousLighting = cycles; daylight.suspend() }
        if self.weather != weather || !atmosphereInitialized {
            self.weather = weather
            rebuildAtmosphere()
        }
        applyLighting()
        if !budget.animates { suspendClocks() }
    }

    /// Call with camera bounds in scene coordinates. Offscreen agents stop advancing.
    /// A clamped, presentation-only clock prevents background catch-up and large jumps.
    func update(currentTime: TimeInterval, viewport: CGRect) {
        guard enabled, budget.agentCount > 0, !isHidden, currentTime.isFinite else { suspendClocks(); return }
        daylight.tick(timestamp: currentTime, animates: continuousLighting && budget.animates)
        self.viewport = viewport
        layoutAtmosphere()
        let delta = min(0.1, max(0, currentTime - (lastTime ?? currentTime)))
        lastTime = currentTime
        frameDebt += delta
        guard frameDebt >= 1.0 / 15.0 || !budget.animates else { return }
        let dt = budget.animates ? frameDebt : 0
        frameDebt = 0
        let visible = viewport.insetBy(dx: -48, dy: -48)
        for index in walkers.indices {
            walkers[index].node.isHidden = !visible.contains(walkers[index].node.position)
            guard !walkers[index].node.isHidden, budget.animates else { continue }
            advanceWalker(index: index, dt: dt)
        }
        for index in wildlife.indices {
            wildlife[index].node.isHidden = !visible.contains(wildlife[index].origin)
            guard !wildlife[index].node.isHidden, budget.animates else { continue }
            wildlife[index].elapsed += dt
            let time = wildlife[index].elapsed
            let amount = CGFloat((1 - cos(time * 0.55)) * 0.5)
            let a = wildlife[index].origin, b = wildlife[index].destination
            wildlife[index].node.position = CGPoint(x: a.x + (b.x - a.x) * amount, y: a.y + (b.y - a.y) * amount)
            wildlife[index].node.zPosition = wildlife[index].aquatic ? 2 - zPosition : 0.1 - wildlife[index].node.position.y / 16
            wildlife[index].node.alpha = wildlife[index].aquatic ? 0.25 + CGFloat(sin(time) + 1) * 0.12 : 1
        }
        if budget.animates { weatherTime += dt }
        applyLighting()
        layoutAtmosphere()
    }

    func suspend() {
        suspendClocks(); isHidden = true
    }

    private func suspendClocks() {
        daylight.suspend(); lastTime = nil; frameDebt = 0
    }

    private func clearFigures() {
        for walker in walkers { walker.node.removeFromParent() }
        for animal in wildlife { animal.node.removeFromParent() }
        for light in nightLights { light.removeFromParent() }
        nightLights.removeAll()
        walkers.removeAll(); wildlife.removeAll(); routeCount = 0; routeTileCount = 0
    }

    private func addWalker(route: VisualAgentRoute, index: Int, state: GameState,
                           planner: VisualRoutePlanner, activeProductionIDs: Set<Int>) {
        guard let source = state.buildings.first(where: { $0.id == route.sourceBuildingID }),
              let destination = state.buildings.first(where: { $0.id == route.destinationBuildingID }),
              let journey = VisualAgentJourney(tiles: route.tiles, planner: planner, source: source.kind,
                destination: destination.kind, sourceActive: activeProductionIDs.contains(source.id), purpose: route.purpose) else { return }
        let figure = VillagerFigure(profile: index)
        figure.name = "provisional-villager-" + route.purpose.rawValue
        figure.position = CGPoint(x: journey.position.x, y: journey.position.y)
        figure.zPosition = 0.1 - figure.position.y / 16
        figure.display(.sample(activity: journey.activity, elapsed: journey.poseElapsed), activity: journey.activity, facing: journey.facing)
        addChild(figure); walkers.append(Walker(node: figure, journey: journey))
    }

    private func advanceWalker(index: Int, dt: TimeInterval) {
        var walker = walkers[index]
        walker.journey.advance(by: dt, animates: true)
        walker.node.position = CGPoint(x: walker.journey.position.x, y: walker.journey.position.y)
        walker.node.display(.sample(activity: walker.journey.activity, elapsed: walker.journey.poseElapsed),
            activity: walker.journey.activity, facing: walker.journey.facing)
        walker.node.zPosition = 0.1 - walker.node.position.y / 16
        walkers[index] = walker
    }

    private func addWildlife(configuration: GameConfiguration, state: GameState, planner: VisualRoutePlanner) {
        let map = configuration.map
        let occupied = Set(state.buildings.flatMap { $0.tiles(in: configuration) })
        var forestSites: [(Tile, Tile)] = [], riverSites: [Tile] = []
        for y in 1..<max(1, map.height - 1) {
            for x in 1..<max(1, map.width - 1) {
                let tile = Tile(x: x, y: y)
                guard state.discoveredTiles?.contains(tile) ?? true else { continue }
                let adjacent = [Tile(x: x + 1, y: y), Tile(x: x, y: y + 1), Tile(x: x - 1, y: y), Tile(x: x, y: y - 1)]
                if planner.isTraversable(tile), adjacent.contains(where: { map.terrain(at: $0) == .forest }),
                   let next = adjacent.first(where: { planner.isTraversable($0) }), forestSites.count < 2 {
                    if forestSites.allSatisfy({ abs($0.0.x - x) + abs($0.0.y - y) > 5 }) { forestSites.append((tile, next)) }
                }
                if map.terrain(at: tile) == .water, !occupied.contains(tile), adjacent.contains(where: { planner.isTraversable($0) }), riverSites.count < 2 {
                    if riverSites.allSatisfy({ abs($0.x - x) + abs($0.y - y) > 6 }) { riverSites.append(tile) }
                }
            }
        }
        for (index, site) in forestSites.enumerated() {
            let root = SKNode(); root.name = "provisional-temperate-rabbit"
            let body = ellipse(size: CGSize(width: 7, height: 4.5), color: UIColor(red: 0.58, green: 0.51, blue: 0.40, alpha: 1))
            body.position.y = 2; root.addChild(body)
            let head = ellipse(size: CGSize(width: 3.4, height: 3.4), color: body.fillColor)
            head.position = CGPoint(x: 3, y: 4); root.addChild(head)
            for x in [2.3, 3.8] as [CGFloat] {
                let ear = ellipse(size: CGSize(width: 1.2, height: 4), color: body.fillColor)
                ear.position = CGPoint(x: x, y: 6.8); root.addChild(ear)
            }
            let origin = IsometricProjection.point(site.0), destination = IsometricProjection.point(site.1)
            root.position = origin; root.zPosition = 0.1 - origin.y / 16; addChild(root)
            wildlife.append(Creature(node: root, origin: origin, destination: destination, aquatic: false, elapsed: Double(index) * 2))
        }
        for (index, site) in riverSites.enumerated() {
            let ripple = SKShapeNode(ellipseOf: CGSize(width: 11, height: 4))
            ripple.name = "provisional-river-ripple"
            ripple.strokeColor = UIColor.white.withAlphaComponent(0.55); ripple.lineWidth = 0.7; ripple.fillColor = .clear
            let point = IsometricProjection.point(site)
            ripple.position = point; ripple.zPosition = 2 - zPosition; addChild(ripple)
            wildlife.append(Creature(node: ripple, origin: point, destination: point, aquatic: true, elapsed: Double(index) * 2))
        }
        assert(wildlife.count <= VisualWorldBudget.maximumWildlife)
    }

    private func rebuildAtmosphere() {
        atmosphereInitialized = true
        for node in weatherNodes { node.removeFromParent() }
        weatherNodes.removeAll()
        let count = weather == .rain ? 12 : weather == .fog ? 3 : 0
        for _ in 0..<count {
            let node: SKShapeNode
            if weather == .rain {
                let path = CGMutablePath(); path.move(to: .zero); path.addLine(to: CGPoint(x: -4, y: -12))
                node = SKShapeNode(path: path); node.strokeColor = UIColor(red: 0.72, green: 0.83, blue: 0.90, alpha: 0.35)
                node.lineWidth = 0.8
            } else {
                node = SKShapeNode(ellipseOf: CGSize(width: 220, height: 75))
                node.fillColor = UIColor(white: 0.92, alpha: 0.045); node.strokeColor = .clear
            }
            atmosphere.addChild(node); weatherNodes.append(node)
        }
        layoutAtmosphere()
    }

    private func addNightLights(state: GameState, configuration: GameConfiguration, activeProductionIDs: Set<Int>) {
        func priority(_ kind: BuildingKind) -> Int { kind == .campfire ? 0 : kind == .potteryWorkshop ? 1 : 2 }
        let sources = state.buildings.filter {
            $0.isOperational && DiscoveryVisibility.isVisible($0, in: configuration, discovered: state.discoveredTiles) &&
            ($0.kind == .campfire || $0.kind == .hut || ($0.kind == .potteryWorkshop && activeProductionIDs.contains($0.id)))
        }.sorted {
            priority($0.kind) == priority($1.kind) ? $0.id < $1.id : priority($0.kind) < priority($1.kind)
        }.prefix(8)
        for building in sources {
            // Proposed hearth light pools, not accepted window/contact art or a fuel mechanic.
            let center = building.occupiedFootprint(in: configuration).center(at: building.origin)
            let light = ellipse(size: CGSize(width: 48, height: 24), color: UIColor(red: 1, green: 0.68, blue: 0.25, alpha: 0.18))
            light.name = "review-warm-ground-pool"; light.position = CGPoint(x: center.x, y: center.y)
            light.zPosition = -0.2 - light.position.y / 16
            addChild(light); nightLights.append(light)
        }
    }

    private func applyLighting() {
        let sample = VisualLighting.sample(cycleFraction: daylight.fraction)
        tint.color = UIColor(red: sample.red, green: sample.green, blue: sample.blue, alpha: sample.opacity)
        for light in nightLights { light.alpha = CGFloat(sample.opacity / 0.20) }
    }

    private func layoutAtmosphere() {
        guard !viewport.isEmpty else { return }
        tint.size = viewport.size; tint.position = CGPoint(x: viewport.midX, y: viewport.midY)
        for (index, node) in weatherNodes.enumerated() {
            let fraction = CGFloat(index + 1) / CGFloat(weatherNodes.count + 1)
            let drift = CGFloat(weatherTime) * (weather == .rain ? 42 : 2)
            node.position = CGPoint(x: viewport.minX + viewport.width * fraction,
                                    y: viewport.minY + (viewport.height * CGFloat((index * 7 + 3) % 13) / 13 - drift).truncatingRemainder(dividingBy: max(1, viewport.height)))
            if node.position.y < viewport.minY { node.position.y += viewport.height }
        }
    }

    private func ellipse(size: CGSize, color: UIColor) -> SKShapeNode {
        let shape = SKShapeNode(ellipseOf: size); shape.fillColor = color; shape.strokeColor = .clear; return shape
    }
    private func descendantCount(_ node: SKNode) -> Int { node.children.reduce(node.children.count) { $0 + descendantCount($1) } }
}
#endif
