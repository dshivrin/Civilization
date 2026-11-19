import SpriteKit
import GameCore

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
                if current.parent === buildingLayer, let id = current.userData?["buildingID"] as? Int { return id }
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
        if discoveryChanged {
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
        if state.buildings != renderedBuildings || discoveryChanged || movingBuildingID != renderedMovingID {
            buildingLayer.removeAllChildren()
            for building in state.buildings where state.discoveredTiles == nil || state.discoveredTiles!.contains(building.origin) { drawBuilding(building, faded: building.id == movingBuildingID) }
            renderedMovingID = movingBuildingID
            renderedBuildings = state.buildings
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
                    ground.addChild(shape(IsometricProjection.diamond(at: point), fill: UIColor(red: 0.12, green: 0.20, blue: 0.20, alpha: 1), stroke: UIColor.black.withAlphaComponent(0.10), width: 0.5))
                    continue
                }
                let terrain = configuration.map.terrain(at: tile)!
                let variation = CGFloat((x * 17 + y * 31) % 7) / 100
                let color: UIColor
                switch terrain {
                case .grass: color = UIColor(red: 0.39 + variation, green: 0.49 + variation, blue: 0.30 + variation, alpha: 1)
                case .clearing: color = UIColor(red: 0.58 + variation, green: 0.55 + variation, blue: 0.35 + variation, alpha: 1)
                case .forest: color = UIColor(red: 0.29, green: 0.40 + variation, blue: 0.26, alpha: 1)
                case .water: color = UIColor(red: 0.23, green: 0.48 + variation, blue: 0.57 + variation, alpha: 1)
                case .hill: color = UIColor(red: 0.49 + variation, green: 0.49 + variation, blue: 0.43 + variation, alpha: 1)
                }
                ground.addChild(shape(IsometricProjection.diamond(at: point), fill: color, stroke: UIColor.black.withAlphaComponent(0.07), width: 0.5))
                if terrain == .forest && (x + y) % 2 == 0 {
                    let tree = SKNode(); tree.position = point; tree.zPosition = CGFloat(x + y) + 1
                    let trunk = SKShapeNode(rectOf: CGSize(width: 5, height: 19)); trunk.position.y = 10; trunk.fillColor = .brown; trunk.strokeColor = .clear; tree.addChild(trunk)
                    tree.addChild(polygon([CGPoint(x: -18,y: 12), CGPoint(x: 0,y: 57), CGPoint(x: 18,y: 12)], fill: UIColor(red: 0.19,green: 0.33,blue: 0.23,alpha: 1)))
                    tree.addChild(polygon([CGPoint(x: 0,y: 57), CGPoint(x: 3,y: 12), CGPoint(x: 18,y: 12)], fill: UIColor(red: 0.24,green: 0.39,blue: 0.27,alpha: 1)))
                    scenery.addChild(tree)
                }
                if terrain == .hill {
                    let rock = polygon([CGPoint(x: point.x - 27,y: point.y), CGPoint(x: point.x - 8,y: point.y + 38), CGPoint(x: point.x + 10,y: point.y + 45), CGPoint(x: point.x + 28,y: point.y + 2), CGPoint(x: point.x,y: point.y - 12)], fill: UIColor(red: 0.59,green: 0.58,blue: 0.50,alpha: 1))
                    rock.zPosition = CGFloat(x + y); scenery.addChild(rock)
                }
                if terrain == .water && (x + y) % 3 == 0 {
                    let ripple = SKShapeNode(ellipseOf: CGSize(width: 24,height: 5)); ripple.position = point; ripple.strokeColor = UIColor.white.withAlphaComponent(0.22); ground.addChild(ripple)
                }
            }
        }
        // Cache static terrain; no per-frame tile traversal or economy updates.
        let cached = SKEffectNode(); cached.shouldRasterize = true; cached.addChild(ground); terrainLayer.addChild(cached)
        scenery.zPosition = 1; terrainLayer.addChild(scenery)
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
            let symbol = SKLabelNode(fontNamed: "AvenirNext-Bold")
            symbol.text = identified ? (empty ? "–" : "◆") : "?"
            symbol.fontSize = 16
            symbol.verticalAlignmentMode = .center
            symbol.fontColor = identified && !empty ? .systemYellow : .systemGray
            marker.addChild(symbol)
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
