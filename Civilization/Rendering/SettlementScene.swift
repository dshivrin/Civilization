import SpriteKit
import GameCore
import GameApplication

@MainActor
final class SettlementScene: SKScene {
    private let configuration: GameConfiguration
    private let worldCamera = SKCameraNode()
    private let terrainLayer = SKNode()
    private let depositLayer = SKNode()
    private let buildingLayer = SKNode()
    private var renderedDiscovery: Set<Tile>?
    private var renderedDepositSignature = ""
    private let ghostLayer = SKNode()
    var onReady: (() -> Void)?
    private var hasDisplayedSnapshot = false
    private var didReportReady = false
    private var renderedMovingID: Int?
    override func didFinishUpdate() {
        guard hasDisplayedSnapshot, !didReportReady else { return }
        didReportReady = true
        onReady?()
    }
    private var renderedBuildings: [PlacedBuilding] = []
    private var renderedVisualSignature = ""
    var reduceMotion = false
    var activeProductionIDs: Set<Int> = []
    private var fireAnimationIDs: Set<Int> = []
    private var renderedActiveIDs: Set<Int> = []
    private var renderedReduceMotion = false
    private var lastCenterRequest = -1
    private var didCenter = false
    init(configuration: GameConfiguration) {
        self.configuration = configuration
        super.init(size: CGSize(width: 1000, height: 700))
        scaleMode = .resizeFill
        backgroundColor = UIColor(red: 0.075, green: 0.15, blue: 0.15, alpha: 1)
        camera = worldCamera
        addChild(worldCamera)
        addChild(terrainLayer)
        drawTerrain(discovered: configuration.explorationRules == nil ? nil : [])
        depositLayer.zPosition = 90
        addChild(depositLayer)
        addChild(buildingLayer)
        ghostLayer.zPosition = 2000
        addChild(ghostLayer)
    }
    required init?(coder: NSCoder) { fatalError("Programmatic scene") }
    override func didChangeSize(_ oldSize: CGSize) {
        if !didCenter && size.width > 100 { recenter(); didCenter = true }
        clampCamera()
    }
    func previewContains(_ point: CGPoint) -> Bool { !ghostLayer.nodes(at: point).isEmpty }
    /// Hit visible silhouettes as well as ground footprints, without selecting the drag ghost.
    func buildingID(at point: CGPoint) -> Int? {
        for hit in nodes(at: point) {
            var node: SKNode? = hit
            while let current = node, current !== self {
                if current.parent === buildingLayer, let id = current.userData?["buildingID"] as? Int {
                    if let building = renderedBuildings.first(where: { $0.id == id }), EraArt.texture(building.kind) != nil,
                       !EraArt.contains(building.kind, point: current.convert(point, from: self)) { break }
                    return id
                }
                node = current.parent
            }
        }
        return nil
    }
    func recenter() {
        let point = IsometricProjection.point(configuration.map.campfire)
        worldCamera.position = CGPoint(x: point.x + 80, y: point.y + 30)
        worldCamera.setScale(size.width > 1000 ? 1.1 : 0.95)
        clampCamera()
    }
    func pan(dx: CGFloat, dy: CGFloat) {
        worldCamera.position.x -= dx * worldCamera.xScale
        worldCamera.position.y += dy * worldCamera.yScale
        clampCamera()
    }
    func zoom(factor: CGFloat) {
        worldCamera.setScale(min(2.1, max(0.5, worldCamera.xScale / factor)))
        clampCamera()
    }
    private func clampCamera() {
        let point = MapGeometry.constrainedCamera(WorldPoint(x: worldCamera.position.x, y: worldCamera.position.y),
                                                  width: configuration.map.width, height: configuration.map.height)
        worldCamera.position = CGPoint(x: point.x, y: point.y)
    }
    func display(state: GameState, kind: BuildingKind?, tile: Tile?, valid: Bool, inspected: PlacedBuilding?, movingBuildingID: Int?, centerRequest: Int, deposits: [NaturalDeposit], identifiedDepositIDs: Set<String>) {
        if centerRequest != lastCenterRequest { recenter(); lastCenterRequest = centerRequest }
        let discoveryChanged = state.discoveredTiles != renderedDiscovery
        if discoveryChanged || reduceMotion != renderedReduceMotion {
            drawTerrain(discovered: state.discoveredTiles)
            renderedDiscovery = state.discoveredTiles
        }
        let depositSignature = deposits.sorted { $0.id < $1.id }.map {
            $0.id + (identifiedDepositIDs.contains($0.id) ? ":known" : ":unknown") + ((state.depositRemaining?[$0.id] ?? $0.capacity) <= 0 ? ":empty" : ":available")
        }.joined(separator: "|")
        if depositSignature != renderedDepositSignature {
            drawDeposits(deposits, identifiedIDs: identifiedDepositIDs, reserves: state.depositRemaining ?? [:])
            renderedDepositSignature = depositSignature
        }
        fireAnimationIDs = Set(state.buildings.filter { $0.isOperational && ($0.kind == .campfire || ($0.kind == .potteryWorkshop && activeProductionIDs.contains($0.id))) }.prefix(VisualActivityPolicy.maximumSmokeParticles / 2).map(\.id))
        let signature = state.buildings.map { "\($0.id):\($0.kind.rawValue):\($0.origin.x),\($0.origin.y):\($0.level):\($0.isOperational)" }.joined(separator: "|")
        if signature != renderedVisualSignature || discoveryChanged || movingBuildingID != renderedMovingID || activeProductionIDs != renderedActiveIDs || reduceMotion != renderedReduceMotion {
            buildingLayer.removeAllChildren()
            for building in state.buildings where state.discoveredTiles == nil || state.discoveredTiles!.contains(building.origin) { drawBuilding(building, faded: building.id == movingBuildingID) }
            renderedMovingID = movingBuildingID
            renderedVisualSignature = signature
            renderedActiveIDs = activeProductionIDs
            renderedReduceMotion = reduceMotion
        }
        renderedBuildings = state.buildings
        for building in state.buildings where !building.isOperational {
            if let root = buildingLayer.children.first(where: { ($0.userData?["buildingID"] as? Int) == building.id }) {
                let fraction = 1 - (building.constructionRemainingSeconds ?? 0) / max(1, building.constructionDurationSeconds ?? 1)
                root.childNode(withName: "constructionProgress")?.xScale = max(0.02, min(1, fraction))
                root.childNode(withName: "artSprite")?.alpha = 0.25 + 0.60 * fraction
            }
        }
        hasDisplayedSnapshot = true
        ghostLayer.removeAllChildren()
        if let kind, let tile {
            let definition = configuration.definition(kind)
            // Clamp visual offsets for taps beyond the map. The core remains authoritative.
            if (-1000..<1000).contains(tile.x) && (-1000..<1000).contains(tile.y) {
                for covered in definition.tiles(at: tile) {
                    let node = SKShapeNode(path: IsometricProjection.diamond(at: IsometricProjection.point(covered)))
                    node.fillColor = (valid ? UIColor.systemMint : UIColor.systemRed).withAlphaComponent(0.42)
                    node.strokeColor = valid ? .systemMint : .systemRed; node.lineWidth = 2
                    ghostLayer.addChild(node)
                }
                if let id = movingBuildingID, var preview = state.buildings.first(where: { $0.id == id }) {
                    preview.origin = tile
                    drawBuilding(preview, into: ghostLayer)
                } else {
                    // Render-only identity; no building is added or paid for until the drop is accepted.
                    drawBuilding(PlacedBuilding(id: -1, kind: kind, origin: tile), into: ghostLayer)
                }
            }
        } else if let inspected {
            for covered in configuration.definition(inspected.kind).tiles(at: inspected.origin) {
                let node = SKShapeNode(path: IsometricProjection.diamond(at: IsometricProjection.point(covered)))
                node.fillColor = .clear; node.strokeColor = .systemYellow; node.lineWidth = 2
                ghostLayer.addChild(node)
            }
        }
    }
    private func shape(_ path: CGPath, fill: UIColor, stroke: UIColor = .clear, width: CGFloat = 1) -> SKShapeNode {
        let node = SKShapeNode(path: path); node.fillColor = fill; node.strokeColor = stroke; node.lineWidth = width
        return node
    }
    private func polygon(_ points: [CGPoint], fill: UIColor) -> SKShapeNode {
        let p = CGMutablePath(); p.addLines(between: points); p.closeSubpath()
        return shape(p, fill: fill)
    }
    private func drawTerrain(discovered: Set<Tile>?) {
        terrainLayer.removeAllChildren()
        let ground = SKNode()
        let scenery = SKNode()
        for y in 0..<configuration.map.height {
            for x in 0..<configuration.map.width {
                let tile = Tile(x: x, y: y)
                let point = IsometricProjection.point(tile)
                if let discovered, !discovered.contains(tile) {
                    ground.addChild(shape(IsometricProjection.diamond(at: point), fill: UIColor(red: 0.105, green: 0.16, blue: 0.145, alpha: 1), stroke: UIColor(red: 0.105, green: 0.16, blue: 0.145, alpha: 0.14), width: 7))
                    continue
                }
                let terrain = configuration.map.terrain(at: tile)!
                let variation = CGFloat((x * 17 + y * 31) % 7) / 400
                let color: UIColor
                switch terrain {
                case .grass: color = UIColor(red: 0.39 + variation, green: 0.49 + variation, blue: 0.30 + variation, alpha: 1)
                case .clearing: color = UIColor(red: 0.58 + variation, green: 0.55 + variation, blue: 0.35 + variation, alpha: 1)
                case .forest: color = UIColor(red: 0.29, green: 0.40 + variation, blue: 0.26, alpha: 1)
                case .water: color = UIColor(red: 0.23, green: 0.48 + variation, blue: 0.57 + variation, alpha: 1)
                case .hill: color = UIColor(red: 0.49 + variation, green: 0.49 + variation, blue: 0.43 + variation, alpha: 1)
                }
                ground.addChild(shape(IsometricProjection.diamond(at: point), fill: color, stroke: .clear, width: 0))
                let seed = x * 157 + y * 83
                if terrain == .grass || terrain == .clearing || terrain == .forest {
                    ground.addChild(WorldDetails.groundTexture(at: point, seed: seed, forest: terrain == .forest, soil: terrain == .clearing))
                }
                if terrain == .forest && (x + y) % 2 == 0 {
                    let tree = WorldDetails.tree(seed: seed);tree.position = point;tree.zPosition = CGFloat(x+y)+1;scenery.addChild(tree)
                }
                if terrain == .hill {
                    let rock = WorldDetails.rocks(seed: seed);rock.position = point;rock.zPosition = CGFloat(x+y);scenery.addChild(rock)
                }
                if terrain == .water {
                    let bank = WorldDetails.waterEdge(at: tile, configuration: configuration, discovered: discovered)
                    bank.position = point;ground.addChild(bank)
                }

            }
        }
        // Cache static terrain; no per-frame tile traversal or economy updates.
        let cached = SKEffectNode(); cached.shouldRasterize = true; cached.addChild(ground); terrainLayer.addChild(cached)
        scenery.zPosition = 1; terrainLayer.addChild(scenery)
        if !reduceMotion {
            var ripples = 0
            for y in 0..<configuration.map.height { for x in 0..<configuration.map.width {
                let tile = Tile(x:x,y:y)
                if ripples < VisualActivityPolicy.maximumWaterRipples && (x+y)%3 == 0 && (discovered?.contains(tile) ?? true) && configuration.map.terrain(at: tile) == .water {
                    let ripple = SKShapeNode(ellipseOf: CGSize(width: 21,height: 3));ripple.position = IsometricProjection.point(tile);ripple.strokeColor = .white.withAlphaComponent(0.22);ripple.lineWidth = 0.7;scenery.addChild(ripple)
                    ripple.run(.repeatForever(.sequence([.group([.moveBy(x: 7,y: -3,duration: 3.8),.fadeOut(withDuration: 3.8)]),.run { [weak ripple] in ripple?.position = IsometricProjection.point(tile);ripple?.alpha = 1 }])))
                    ripples += 1
                }
            } }
        }
        buildingLayer.zPosition = 100
    }
    private func drawDeposits(_ deposits: [NaturalDeposit], identifiedIDs: Set<String>, reserves: [String: Double]) {
        depositLayer.removeAllChildren()
        for deposit in deposits {
            let point = IsometricProjection.point(deposit.origin)
            let marker = SKNode()
            marker.position = CGPoint(x: point.x, y: point.y + 8)
            let identified = identifiedIDs.contains(deposit.id)
            let empty = !deposit.renewable && (reserves[deposit.id] ?? deposit.capacity) <= 0
            let disc = SKShapeNode(circleOfRadius: 12)
            disc.fillColor = UIColor(red: 0.11, green: 0.18, blue: 0.17, alpha: 0.95)
            disc.strokeColor = identified ? (empty ? .systemGray : .systemYellow) : .systemGray
            disc.lineWidth = 2
            marker.addChild(disc)
            if identified, !empty, let resource = deposit.resource, let texture = EraArt.resourceTexture(resource) {
                let icon = SKSpriteNode(texture: texture);icon.size = CGSize(width: 26,height: 26);marker.addChild(icon)
            } else {
                let symbol = SKLabelNode(fontNamed: "AvenirNext-Bold")
                symbol.text = identified ? "–" : "?";symbol.fontSize = 16;symbol.verticalAlignmentMode = .center;symbol.fontColor = .systemGray;marker.addChild(symbol)
            }
            marker.name = "deposit-" + deposit.id
            depositLayer.addChild(marker)
        }
    }
    private func drawBuilding(_ building: PlacedBuilding, into layer: SKNode? = nil, faded: Bool = false) {
        let definition = configuration.definition(building.kind)
        let origin = IsometricProjection.point(building.origin)
        // Footprint center is the replaceable sprite's ground-contact anchor.
        let offset = CGFloat(definition.width - 1)
        let anchor = CGPoint(x: origin.x, y: origin.y - offset * 16)
        let node = SKNode(); node.name = definition.assetKey; node.position = anchor
        node.userData = ["buildingID": building.id]
        node.zPosition = CGFloat(building.origin.x + building.origin.y)
        if let texture = EraArt.texture(building.kind), let visual = EraArt.catalog?.building(building.kind) {
            let sprite = SKSpriteNode(texture: texture)
            sprite.name = "artSprite"
            sprite.size = CGSize(width: visual.worldWidth, height: visual.worldHeight)
            sprite.anchorPoint = CGPoint(x: visual.anchorX, y: visual.anchorY)
            node.addChild(sprite)
            if !building.isOperational {
                sprite.alpha = 0.3
                let frame = polygon([CGPoint(x: -36,y: 0),CGPoint(x: -36,y: 40),CGPoint(x: 0,y: 65),CGPoint(x: 36,y: 40),CGPoint(x:36,y:0)], fill: .clear)
                frame.strokeColor = UIColor(red: 0.78,green: 0.65,blue: 0.43,alpha: 0.85); frame.lineWidth = 3; node.addChild(frame)
                let bar = SKSpriteNode(color: .systemYellow, size: CGSize(width: 60, height: 3))
                bar.anchorPoint = CGPoint(x: 0,y: 0.5); bar.position = CGPoint(x:-30,y: -15);bar.name = "constructionProgress";node.addChild(bar)
            }
            if layer == nil && !reduceMotion && fireAnimationIDs.contains(building.id) {
                let glow = SKShapeNode(ellipseOf: CGSize(width: building.kind == .campfire ? 23 : 12, height: 9))
                glow.fillColor = .systemOrange.withAlphaComponent(0.18); glow.strokeColor = .clear;glow.position.y = 6;node.addChild(glow)
                glow.run(.repeatForever(.sequence([.fadeAlpha(to: 0.7,duration: 0.65),.fadeAlpha(to: 0.25,duration: 0.8)])))
                // Two bounded wisps per active fire, never an unbounded particle emitter.
                for offset in [0.0, 1.8] {
                    let smoke = SKShapeNode(ellipseOf: CGSize(width: 8,height: 6));smoke.fillColor = .white.withAlphaComponent(0.18);smoke.strokeColor = .clear;smoke.alpha = 0
                    smoke.position = CGPoint(x: 3,y: 22);node.addChild(smoke)
                    smoke.run(.repeatForever(.sequence([.wait(forDuration: offset),.group([.moveBy(x: 8,y: 28,duration: 3.6),.sequence([.fadeAlpha(to: 0.3,duration: 0.7),.fadeOut(withDuration: 2.9)])]),.run { [weak smoke] in smoke?.position = CGPoint(x: 3,y: 22) }])))
                }
            }
            if layer == nil && !reduceMotion && building.isOperational && activeProductionIDs.contains(building.id) && building.kind != .campfire {
                let active = SKShapeNode(circleOfRadius: 2.5);active.fillColor = .systemMint.withAlphaComponent(0.8);active.strokeColor = .clear;active.position = CGPoint(x: 0,y: -8);node.addChild(active)
                active.run(.repeatForever(.sequence([.fadeAlpha(to: 0.35,duration: 1.6),.fadeAlpha(to: 0.8,duration: 1.6)])))
            }
            if faded { node.alpha = 0.2 }
            (layer ?? buildingLayer).addChild(node)
            return
        }
        let shadow = SKShapeNode(ellipseOf: CGSize(width: definition.width == 1 ? 40 : 94, height: 30)); shadow.fillColor = UIColor.black.withAlphaComponent(0.20); shadow.strokeColor = .clear; shadow.position = CGPoint(x: 7,y: -5); node.addChild(shadow)
        if building.kind == .campfire || building.kind == .storytellingCircle {
            let ring = SKShapeNode(ellipseOf: CGSize(width: building.kind == .campfire ? 35 : 85, height: building.kind == .campfire ? 19 : 43)); ring.strokeColor = UIColor(red: 0.76,green: 0.73,blue: 0.60,alpha: 1); ring.lineWidth = 7; node.addChild(ring)
            let log = SKShapeNode(rectOf: CGSize(width: 29,height: 7), cornerRadius: 3); log.fillColor = .brown; log.strokeColor = .clear; log.zRotation = 0.3; node.addChild(log)
            node.addChild(polygon([CGPoint(x: -11,y: 3), CGPoint(x: -6,y: 21), CGPoint(x: 1,y: 32), CGPoint(x: 11,y: 12), CGPoint(x: 7,y: 2)], fill: .systemOrange))
            node.addChild(polygon([CGPoint(x: -4,y: 4), CGPoint(x: 1,y: 19), CGPoint(x: 6,y: 4)], fill: .systemYellow))
            if building.kind == .storytellingCircle {
                for x in [-31, 31] { let seat = SKShapeNode(ellipseOf: CGSize(width: 14,height: 10)); seat.fillColor = .brown; seat.strokeColor = .clear; seat.position = CGPoint(x:x,y:0); node.addChild(seat) }
            }
        } else {
            let wall = UIColor(red: 0.66,green: 0.49,blue: 0.30,alpha: 1)
            node.addChild(polygon([CGPoint(x:-35,y:4),CGPoint(x:0,y:-14),CGPoint(x:35,y:4),CGPoint(x:35,y:33),CGPoint(x:0,y:16),CGPoint(x:-35,y:33)],fill:wall))
            node.addChild(polygon([CGPoint(x:-35,y:33),CGPoint(x:0,y:16),CGPoint(x:35,y:33),CGPoint(x:0,y:64)],fill:UIColor(red:0.77,green:0.61,blue:0.34,alpha:1)))
            node.addChild(polygon([CGPoint(x:0,y:64),CGPoint(x:0,y:16),CGPoint(x:35,y:33)],fill:UIColor(red:0.62,green:0.43,blue:0.25,alpha:1)))
            let door = SKShapeNode(rectOf: CGSize(width: 12,height: 19)); door.position = CGPoint(x:-14,y:9); door.fillColor = UIColor(red:0.22,green:0.20,blue:0.15,alpha:1); door.strokeColor = .clear; node.addChild(door)
            let marker = SKLabelNode(fontNamed:"AvenirNext-Bold"); marker.text = building.kind == .hut ? "" : (building.kind == .gatheringShelter ? "✦" : building.kind == .woodcutter ? "≋" : "◆"); marker.fontSize = 20; marker.fontColor = .white; marker.position = CGPoint(x:0,y:31); node.addChild(marker)
        }
        if !building.isOperational {
            node.alpha = 0.65
            let badge = SKLabelNode(fontNamed: "AvenirNext-Bold")
            badge.text = "Building \(Int(ceil(building.constructionRemainingSeconds ?? 0)))s"
            badge.fontSize = 12; badge.fontColor = .systemYellow
            badge.position = CGPoint(x: 0, y: 70); badge.zPosition = 100
            node.addChild(badge)
        }
        if faded { node.alpha = 0.2 }
        (layer ?? buildingLayer).addChild(node)
    }
}
