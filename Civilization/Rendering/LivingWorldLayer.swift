#if DEBUG
import SpriteKit
import GameCore
import GameApplication

/// Opt-in visual review only. Procedural figures are provisional, not approved character art.
/// No game commands, authoritative clocks, resource transfers, bridge or gate inference.
@MainActor
final class LivingWorldLayer: SKNode {
    enum Phase: String, CaseIterable { case day, dusk, night }
    enum Weather: String, CaseIterable { case clear, rain, fog }

    private struct Walker {
        let node: SKNode
        let body: SKNode
        let head: SKShapeNode
        let legs: [SKShapeNode]
        let route: [CGPoint]
        var segment = 0
        var fraction: CGFloat = 0
        var forward = true
        var elapsed: TimeInterval = 0
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
        "provisional villagers=\(walkers.count) routes=\(routeCount) routeTiles=\(routeTileCount) wildlife=\(wildlife.count) nodes=\(descendantCount(self)) phase=\(phase.rawValue) weather=\(weather.rawValue) moving=\(budget.animates)"
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
                 foreground: Bool = true, lowPower: Bool = false) {
        let nextBudget = VisualWorldBudget(reduceMotion: reduceMotion, lowPower: lowPower, foreground: foreground)
        let buildings = state.buildings.map {
            LayoutBuilding(id: $0.id, kind: $0.kind, origin: $0.origin,
                           footprint: $0.occupiedFootprint(in: configuration), operational: $0.isOperational)
        }
        let changed = !enabled || budget != nextBudget || renderedBuildings != buildings ||
            renderedRoads != (state.roads ?? []) || renderedDiscovery != state.discoveredTiles || renderedMap != configuration.map.id
        enabled = reviewEnabled
        budget = nextBudget
        isHidden = !reviewEnabled || !foreground
        if !reviewEnabled {
            clearFigures(); lastTime = nil
            atmosphere.isHidden = true
            return
        }
        atmosphere.isHidden = !foreground
        if changed {
            clearFigures()
            renderedBuildings = buildings; renderedRoads = state.roads ?? []
            renderedDiscovery = state.discoveredTiles; renderedMap = configuration.map.id
            let planner = VisualRoutePlanner(configuration: configuration, state: state)
            let routes = planner.destinationRoutes(maximumAgents: budget.agentCount)
            routeCount = routes.count; routeTileCount = routes.reduce(0) { $0 + $1.tiles.count }
            for (index, route) in routes.enumerated() { addWalker(route: route, index: index) }
            if budget.agentCount > 0 { addWildlife(configuration: configuration, state: state, planner: planner) }
            lastTime = nil; frameDebt = 0
        }
        if self.phase != phase || self.weather != weather || !atmosphereInitialized {
            self.phase = phase; self.weather = weather
            rebuildAtmosphere()
        }
        if !budget.animates { lastTime = nil }
    }

    /// Call with camera bounds in scene coordinates. Offscreen agents stop advancing.
    /// A clamped, presentation-only clock prevents background catch-up and large jumps.
    func update(currentTime: TimeInterval, viewport: CGRect) {
        guard enabled, budget.agentCount > 0, !isHidden else { lastTime = nil; return }
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
        layoutAtmosphere()
    }

    func suspend() {
        lastTime = nil; frameDebt = 0; isHidden = true
    }

    private func clearFigures() {
        for walker in walkers { walker.node.removeFromParent() }
        for animal in wildlife { animal.node.removeFromParent() }
        walkers.removeAll(); wildlife.removeAll(); routeCount = 0; routeTileCount = 0
    }

    private func addWalker(route: VisualAgentRoute, index: Int) {
        let root = SKNode(), body = SKNode()
        root.name = "provisional-villager-\(route.purpose.rawValue)"
        root.position = IsometricProjection.point(route.tiles[0])
        root.zPosition = 0.1 - root.position.y / 16
        let shadow = ellipse(size: CGSize(width: 9, height: 4), color: UIColor.black.withAlphaComponent(0.18))
        shadow.position.y = -1; root.addChild(shadow)
        let palette: [UIColor] = [UIColor(red: 0.61, green: 0.32, blue: 0.17, alpha: 1), UIColor(red: 0.37, green: 0.47, blue: 0.30, alpha: 1), UIColor(red: 0.71, green: 0.57, blue: 0.35, alpha: 1)]
        let skin = UIColor(red: 0.70 - Double(index % 3) * 0.08, green: 0.48 - Double(index % 3) * 0.05, blue: 0.30, alpha: 1)
        var legs: [SKShapeNode] = []
        for x in [-1.7, 1.7] as [CGFloat] {
            let leg = SKShapeNode(rectOf: CGSize(width: 2, height: 5), cornerRadius: 0.7)
            leg.fillColor = skin; leg.strokeColor = .clear
            leg.position = CGPoint(x: x, y: 2.4); legs.append(leg); root.addChild(leg)
        }
        root.addChild(body)
        let tunic = SKShapeNode(rectOf: CGSize(width: 6.5, height: 8), cornerRadius: 2)
        tunic.fillColor = palette[index % palette.count]; tunic.strokeColor = .clear
        tunic.position.y = 8; body.addChild(tunic)
        let head = ellipse(size: CGSize(width: 5, height: 5.5), color: skin)
        head.position.y = 14; body.addChild(head)
        let hair = ellipse(size: CGSize(width: 5.2, height: 2.4), color: UIColor(red: 0.23, green: 0.16, blue: 0.10, alpha: 1))
        hair.position.y = 16; body.addChild(hair)
        let nose = ellipse(size: CGSize(width: 1.8, height: 1.3), color: skin)
        nose.name = "nose"; nose.position = CGPoint(x: 2.6, y: 13.6); body.addChild(nose)
        if route.purpose == .carryWood {
            for y in [7, 9] as [CGFloat] {
                let log = SKShapeNode(rectOf: CGSize(width: 10, height: 2), cornerRadius: 1)
                log.fillColor = UIColor(red: 0.37, green: 0.23, blue: 0.12, alpha: 1); log.strokeColor = .clear
                log.name = "carried-log"; log.position = CGPoint(x: 2, y: y); body.addChild(log)
            }
        }
        addChild(root)
        walkers.append(Walker(node: root, body: body, head: head, legs: legs, route: route.tiles.map(IsometricProjection.point)))
    }

    private func advanceWalker(index: Int, dt: TimeInterval) {
        var walker = walkers[index]
        walker.elapsed += dt
        // Pause briefly at a truthful exterior contact, then walk the same valid route home.
        if walker.segment == walker.route.count - 1 {
            walker.fraction += CGFloat(dt)
            if walker.fraction < 1.5 { walkers[index] = walker; return }
            walker.forward.toggle(); walker.segment = 0; walker.fraction = 0
            for log in walker.body.children where log.name == "carried-log" { log.isHidden = !walker.forward }
        }
        let points = walker.forward ? walker.route : Array(walker.route.reversed())
        let a = points[walker.segment], b = points[walker.segment + 1]
        let length = hypot(b.x - a.x, b.y - a.y)
        walker.fraction += CGFloat(dt) * 17 / max(1, length)
        if walker.fraction >= 1 {
            walker.segment += 1; walker.fraction = 0
            walker.node.position = b
        } else {
            walker.node.position = CGPoint(x: a.x + (b.x - a.x) * walker.fraction, y: a.y + (b.y - a.y) * walker.fraction)
        }
        let facingRight = b.x > a.x
        walker.body.xScale = facingRight ? 1 : -1
        // Head/nose changes distinguish near-facing and away-facing diagonal walks.
        walker.head.fillColor = b.y < a.y ? UIColor(red: 0.69, green: 0.46, blue: 0.30, alpha: 1) : UIColor(red: 0.40, green: 0.28, blue: 0.17, alpha: 1)
        walker.body.childNode(withName: "nose")?.isHidden = b.y > a.y
        walker.body.position.y = CGFloat(sin(walker.elapsed * 9)) * 0.5
        for (legIndex, leg) in walker.legs.enumerated() {
            leg.position.y = 2.4 + CGFloat(sin(walker.elapsed * 9 + Double(legIndex) * .pi)) * 1.4
        }
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
        switch phase {
        case .day: tint.color = .clear
        case .dusk: tint.color = UIColor(red: 0.84, green: 0.42, blue: 0.15, alpha: 0.10)
        case .night: tint.color = UIColor(red: 0.10, green: 0.20, blue: 0.40, alpha: 0.20)
        }
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

    private func layoutAtmosphere() {
        guard !viewport.isEmpty else { return }
        tint.size = viewport.size; tint.position = CGPoint(x: viewport.midX, y: viewport.midY)
        for (index, node) in weatherNodes.enumerated() {
            let fraction = CGFloat(index + 1) / CGFloat(weatherNodes.count + 1)
            let drift = budget.animates ? CGFloat(weatherTime) * (weather == .rain ? 42 : 2) : 0
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
