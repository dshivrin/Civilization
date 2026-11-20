import SpriteKit
import GameCore
import GameApplication

@MainActor
final class SettlementScene: SKScene {
    #if DEBUG
    private static var constructedSceneCount = 0
    #endif
    private let configuration: GameConfiguration
    private let worldCamera = SKCameraNode()
    private let terrainLayer = SKNode()
    private let depositLayer = SKNode()
    private let buildingLayer = SKNode()
    private let roadLayer = RoadSceneLayer()
    #if DEBUG
    private let connectionLayer = BuildingConnectionLayer()
    private let livingLayer = LivingWorldLayer()
    var reviewReservedRightWidth: CGFloat = 0
    var reviewFocusTiles: Set<Tile>? {
        didSet { if let tiles = reviewFocusTiles { fitReview(tiles) } }
    }
    private func fitReview(_ tiles: Set<Tile>) {
        let points = tiles.map(IsometricProjection.point)
        guard let minX = points.map(\.x).min(), let maxX = points.map(\.x).max(),
              let minY = points.map(\.y).min(), let maxY = points.map(\.y).max() else { return }
        let scale = max((maxX - minX + 160) / max(1, size.width - reviewReservedRightWidth), (maxY - minY + 100) / max(1, size.height * 0.60))
        worldCamera.setScale(max(0.8, scale))
        worldCamera.position = CGPoint(x: (minX + maxX) / 2 + reviewReservedRightWidth * scale / 2,
            y: (minY + maxY) / 2 + size.height * scale * 0.15)
    }
    var onReviewRevealComplete: (() -> Void)?
    var reviewContinuousFog = false
    private var renderedContinuousFog = false
    var reviewVisualsEnabled = false
    var reviewPhase = LivingWorldLayer.Phase.day
    var reviewWeather = LivingWorldLayer.Weather.clear
    var reviewCyclesLighting = false
    var reviewLightingCycleDuration: Double = 120
    var reviewLightingSelectionRevision = 0
    var reviewLowPowerPreview = false
    var reviewAtmosphereSummary: String {
        func actions(_ node: SKNode) -> Int { (node.hasActions() ? 1 : 0) + node.children.reduce(0) { $0 + actions($1) } }
        return livingLayer.reviewSummary + " buildingActions=\(actions(buildingLayer))"
    }
    var reviewAtmosphereCaption: String { livingLayer.reviewCaption }
    override func update(_ currentTime: TimeInterval) {
        let width = size.width * worldCamera.xScale, height = size.height * worldCamera.yScale
        livingLayer.update(currentTime: currentTime, viewport: CGRect(x: worldCamera.position.x - width / 2,
            y: worldCamera.position.y - height / 2, width: width, height: height))
    }
    #endif
    private var renderedDiscovery: Set<Tile>?
    private var renderedDepositSignature = ""
    private let ghostLayer = SKNode()
    private let relocationGridLayer = SKNode()
    private var renderedRelocationGrid: [Tile: Bool]?
    #if DEBUG
    private let diagnostics = RenderDiagnostics()
    #endif
    var onReady: (() -> Void)?
    private var hasDisplayedSnapshot = false
    private var didReportReady = false
    private var renderedMovingID: Int?
    var onCandidateLayout: (() -> Void)?
    private var candidateTile: Tile?
    private var candidateFootprint: BuildingFootprint?
    func candidateControlPoint() -> CGPoint? {
        guard let tile = candidateTile, let footprint = candidateFootprint else { return nil }
        let bottom = footprint.tiles(at: tile).map(IsometricProjection.point).map(\.y).min() ?? 0
        let center = footprint.center(at: tile)
        return convertPoint(toView: CGPoint(x: center.x, y: bottom - 16))
    }
    override func didFinishUpdate() {
        onCandidateLayout?()
        #if DEBUG
        diagnostics.observe(self)
        #endif
        guard hasDisplayedSnapshot, !didReportReady else { return }
        didReportReady = true
        onReady?()
    }
    private var renderedBuildings: [PlacedBuilding] = []
    private var civicCenterTile: Tile?
    private var newlyPlacedIDs: Set<Int> = []
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
        #if DEBUG
        Self.constructedSceneCount += 1
        #endif
        scaleMode = .resizeFill
        backgroundColor = UIColor(red: 0.075, green: 0.15, blue: 0.15, alpha: 1)
        camera = worldCamera
        addChild(worldCamera)
        addChild(terrainLayer)
        drawTerrain(discovered: configuration.explorationRules == nil ? nil : [])
        depositLayer.zPosition = 90
        addChild(depositLayer)
        addChild(buildingLayer)
        addChild(roadLayer);addChild(roadLayer.preview)
        #if DEBUG
        addChild(connectionLayer); addChild(livingLayer)
        livingLayer.zPosition = buildingLayer.zPosition
        #endif
        relocationGridLayer.zPosition = 95
        addChild(relocationGridLayer)
        ghostLayer.zPosition = 2000
        addChild(ghostLayer)
    }
    required init?(coder: NSCoder) { fatalError("Programmatic scene") }
    override func didChangeSize(_ oldSize: CGSize) {
        if !didCenter && size.width > 100 {
            #if DEBUG
            if configuration.map.id == "river-clearing-review-64x48-v1" { showMapOverview() } else { recenter() }
            #else
            recenter()
            #endif
            didCenter = true
        }
        clampCamera()
        #if DEBUG
        if let tiles = reviewFocusTiles { fitReview(tiles) }
        #endif
    }
    /// The candidate's opaque sprite is a drag handle as well as its ground footprint.
    func previewContains(_ point: CGPoint) -> Bool {
        guard let root = ghostLayer.children.first(where: { ($0.userData?["buildingID"] as? Int) == -1 }),
              let kindName = root.name,
              let kind = configuration.buildings.first(where: { $0.assetKey == kindName })?.kind else { return false }
        return root.calculateAccumulatedFrame().contains(point) && EraArt.contains(kind, point: root.convert(point, from: self))
    }
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
        let point = IsometricProjection.point(civicCenterTile ?? configuration.map.campfire)
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
        #if DEBUG
        let maximumScale: CGFloat = configuration.map.width == 64 ? 6 : 2.1
        #else
        let maximumScale: CGFloat = 2.1
        #endif
        worldCamera.setScale(min(maximumScale, max(0.5, worldCamera.xScale / factor)))
        clampCamera()
    }
    #if DEBUG
    var cameraAccessibilityValue: String {
        String(format: "camera=%.2f,%.2f zoom=%.4f sceneBuilds=%d", worldCamera.position.x, worldCamera.position.y, worldCamera.xScale, Self.constructedSceneCount)
    }
    func showMapOverview() {
        let map = configuration.map
        let point = IsometricProjection.point(Tile(x: map.width / 2,y: map.height / 2))
        worldCamera.position = point
        let span = CGFloat(map.width + map.height)
        worldCamera.setScale(min(6, max(span * 32 / max(1,size.width), span * 16 / max(1,size.height - 120)) * 1.08))
        clampCamera()
    }
    #endif
    private func clampCamera() {
        let point = MapGeometry.constrainedCamera(WorldPoint(x: worldCamera.position.x, y: worldCamera.position.y),
                                                  width: configuration.map.width, height: configuration.map.height)
        worldCamera.position = CGPoint(x: point.x, y: point.y)
    }
    func display(state: GameState, kind: BuildingKind?, tile: Tile?, valid: Bool, inspected: PlacedBuilding?, movingBuildingID: Int?, previewFootprint: BuildingFootprint? = nil, relocationGrid: [Tile: Bool]? = nil, unavailablePreviewTiles: Set<Tile>? = nil, roadTool: RoadTool? = nil, roadDraft: [Tile] = [], roadInvalid: Bool = false, centerRequest: Int, deposits: [NaturalDeposit], identifiedDepositIDs: Set<String>) {
        candidateTile = kind == nil ? nil : tile
        candidateFootprint = kind.map { previewFootprint ?? configuration.definition($0).footprint }
        civicCenterTile = state.buildings.first { $0.kind == .campfire }?.origin
        if centerRequest != lastCenterRequest {
            #if DEBUG
            if lastCenterRequest == -1 && configuration.map.id == "river-clearing-review-64x48-v1" { showMapOverview() } else { recenter() }
            #else
            recenter()
            #endif
            lastCenterRequest = centerRequest
        }
        #if DEBUG
        roadLayer.visualRefinementsEnabled = reviewVisualsEnabled
        if reviewVisualsEnabled {
            connectionLayer.display(buildings: state.buildings, discovered: state.discoveredTiles, configuration: configuration,
                excludingIDs: movingBuildingID.map { Set([$0]) } ?? [])
        } else { connectionLayer.clear() }
        livingLayer.display(state: state, configuration: configuration, reduceMotion: reduceMotion,
            reviewEnabled: reviewVisualsEnabled, phase: reviewPhase, weather: reviewWeather,
            foreground: !isPaused, lowPower: ProcessInfo.processInfo.isLowPowerModeEnabled || reviewLowPowerPreview,
            cycles: reviewCyclesLighting, selectionRevision: reviewLightingSelectionRevision,
            activeProductionIDs: activeProductionIDs, cycleDuration: reviewLightingCycleDuration)
        #endif
        #if DEBUG
        if reviewContinuousFog != renderedContinuousFog { drawTerrain(discovered: state.discoveredTiles); renderedContinuousFog = reviewContinuousFog }
        #endif
        let discoveryChanged = state.discoveredTiles != renderedDiscovery
        roadLayer.display(roads: state.roads ?? [], discovered: state.discoveredTiles, configuration: configuration, tool: roadTool, draft: roadDraft, invalid: roadInvalid)
        if discoveryChanged || reduceMotion != renderedReduceMotion {
            drawTerrain(discovered: state.discoveredTiles)
            renderedDiscovery = state.discoveredTiles
        }
        let depositSignature = deposits.sorted { $0.id < $1.id }.map {
            $0.id + (identifiedDepositIDs.contains($0.id) ? ":known" : ":unknown") + ((state.depositRemaining?[$0.id] ?? $0.capacity) <= 0 ? ":empty" : ":available")
        }.joined(separator: "|")
        if depositSignature != renderedDepositSignature || discoveryChanged {
            drawDeposits(deposits, identifiedIDs: identifiedDepositIDs, reserves: state.depositRemaining ?? [:], discovered: state.discoveredTiles)
            renderedDepositSignature = depositSignature
        }
        newlyPlacedIDs = hasDisplayedSnapshot ? Set(state.buildings.map(\.id)).subtracting(renderedBuildings.map(\.id)) : []
        fireAnimationIDs = Set(state.buildings.filter { $0.isOperational && ($0.kind == .campfire || ($0.kind == .potteryWorkshop && activeProductionIDs.contains($0.id))) }.prefix(VisualActivityPolicy.maximumSmokeParticles / 2).map(\.id))
        let signature = state.buildings.map { building in
            let footprint = building.occupiedFootprint(in: configuration)
            return "\(building.id):\(building.kind.rawValue):\(building.origin.x),\(building.origin.y):\(building.level):\(building.isOperational):\(footprint.width)x\(footprint.height):\(building.resolvedOrientation.rawValue)"
        }.joined(separator: "|")
        if signature != renderedVisualSignature || discoveryChanged || movingBuildingID != renderedMovingID || activeProductionIDs != renderedActiveIDs || reduceMotion != renderedReduceMotion {
            buildingLayer.removeAllChildren()
            for building in state.buildings where DiscoveryVisibility.isVisible(building, in: configuration, discovered: state.discoveredTiles) { drawBuilding(building, faded: building.id == movingBuildingID) }
            renderedMovingID = movingBuildingID
            renderedVisualSignature = signature
            renderedActiveIDs = activeProductionIDs
            renderedReduceMotion = reduceMotion
        }
        renderedBuildings = state.buildings.filter { DiscoveryVisibility.isVisible($0, in: configuration, discovered: state.discoveredTiles) }
        for building in state.buildings where !building.isOperational {
            if let root = buildingLayer.children.first(where: { ($0.userData?["buildingID"] as? Int) == building.id }) {
                let construction = ConstructionPresentation(remaining: building.constructionRemainingSeconds ?? 0, duration: building.constructionDurationSeconds ?? 0)
                let fraction = construction.fraction
                root.childNode(withName: "constructionProgress")?.xScale = max(0.02, min(1, fraction))
                root.childNode(withName: "artSprite")?.alpha = fraction < 0.25 ? 0.12 : 0.25 + 0.60 * fraction
                root.childNode(withName: "constructionScaffold")?.isHidden = construction.stage != .frame
                root.childNode(withName: "constructionRoof")?.isHidden = construction.stage != .roof
            }
        }
        if relocationGrid != renderedRelocationGrid {
            relocationGridLayer.removeAllChildren()
            for (tile, available) in relocationGrid ?? [:] {
                let node = SKShapeNode(path: IsometricProjection.diamond(at: IsometricProjection.point(tile)))
                node.strokeColor = (available ? UIColor.white : UIColor.lightGray).withAlphaComponent(0.7)
                node.fillColor = available ? .clear : UIColor.lightGray.withAlphaComponent(0.12)
                node.lineWidth = 1
                relocationGridLayer.addChild(node)
            }
            renderedRelocationGrid = relocationGrid
        }
        hasDisplayedSnapshot = true
        ghostLayer.removeAllChildren()
        if let kind, let tile {
            let footprint = previewFootprint ?? configuration.definition(kind).footprint
            // Clamp visual offsets for taps beyond the map. The core remains authoritative.
            if (-1000..<1000).contains(tile.x) && (-1000..<1000).contains(tile.y) {
                for covered in footprint.tiles(at: tile) {
                    let node = SKShapeNode(path: IsometricProjection.diamond(at: IsometricProjection.point(covered)))
                    let available = unavailablePreviewTiles.map { !$0.contains(covered) } ?? valid
                    let tint: UIColor = movingBuildingID == nil ? (available ? .systemMint : .systemRed) : (available ? .white : .lightGray)
                    node.fillColor = tint.withAlphaComponent(0.30)
                    node.strokeColor = tint; node.lineWidth = 2
                    node.zPosition = 10_000
                    ghostLayer.addChild(node)
                    if !available {
                        let center = IsometricProjection.point(covered)
                        let cross = CGMutablePath()
                        cross.move(to: CGPoint(x: center.x - 5, y: center.y - 5))
                        cross.addLine(to: CGPoint(x: center.x + 5, y: center.y + 5))
                        cross.move(to: CGPoint(x: center.x - 5, y: center.y + 5))
                        cross.addLine(to: CGPoint(x: center.x + 5, y: center.y - 5))
                        let marker = SKShapeNode(path: cross)
                        marker.strokeColor = .white; marker.lineWidth = 2; marker.zPosition = 10_001
                        ghostLayer.addChild(marker)
                    }
                }
                if movingBuildingID == nil {
                    // Only new construction has a moving sprite; relocation keeps its source faded in place.
                    drawBuilding(PlacedBuilding(id: -1, kind: kind, origin: tile), into: ghostLayer)
                }
            }
        } else if let inspected {
            for covered in inspected.tiles(in: configuration) {
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
        // Bounded caches are required in both Debug and Release at device raster scales.
        let chunked = configuration.map.width > 32
        var chunks: [Tile: (ground: SKNode, scenery: SKNode)] = [:]
        struct ScenicKey: Hashable { let chunk: Tile; let depth: Int }
        var scenicChunks: [ScenicKey: SKNode] = [:]
        func sceneryLayer(for tile: Tile) -> SKNode {
            guard chunked else { return scenery }
            let key = ScenicKey(chunk: Tile(x:tile.x / 16,y:tile.y / 16), depth:tile.x + tile.y)
            if scenicChunks[key] == nil { scenicChunks[key] = SKNode() }
            return scenicChunks[key]!
        }
        let continuousFogPath = CGMutablePath()
        #if DEBUG
        let continuousFog = reviewContinuousFog
        #else
        let continuousFog = false
        #endif
        for y in 0..<configuration.map.height {
            for x in 0..<configuration.map.width {
                let tile = Tile(x: x, y: y)
                let key = Tile(x: x / 16,y: y / 16)
                if chunked && chunks[key] == nil { chunks[key] = (SKNode(), SKNode()) }
                let ground = chunked ? chunks[key]!.ground : ground
                let point = IsometricProjection.point(tile)
                if let discovered, !discovered.contains(tile) {
                    if continuousFog { continuousFogPath.addPath(IsometricProjection.diamond(at: point)); continue }
                    // Opaque ground-independent clouds: no hidden terrain is rendered beneath them.
                    let shade = CGFloat((x * 17 + y * 31) % 7) / 150
                    ground.addChild(shape(IsometricProjection.diamond(at: point), fill: UIColor(white: 0.73 + shade, alpha: 1), stroke: UIColor(white: 0.77, alpha: 1), width: 1))
                    for offset in [-14.0, 5.0] {
                        let cloud = SKShapeNode(ellipseOf: CGSize(width: 33, height: 14))
                        cloud.position = CGPoint(x: point.x + offset, y: point.y + (offset < 0 ? 1 : -2))
                        cloud.fillColor = UIColor(white: 0.83 + shade, alpha: 1)
                        cloud.strokeColor = .clear
                        ground.addChild(cloud)
                    }
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
                    let tree = WorldDetails.tree(seed: seed);tree.position = point;tree.zPosition = CGFloat(x+y)+1;sceneryLayer(for: tile).addChild(tree)
                }
                if terrain == .hill {
                    let rock = WorldDetails.rocks(seed: seed);rock.position = point;rock.zPosition = CGFloat(x+y);sceneryLayer(for: tile).addChild(rock)
                }
                if terrain == .water {
                    let bank = WorldDetails.waterEdge(at: tile, configuration: configuration, discovered: discovered)
                    bank.position = point;ground.addChild(bank)
                }

            }
        }
        // Flatten immutable ground/scenery to one texture and release thousands of source shape nodes.
        // Rebuild only when discovery or motion preferences change, never per simulation/render frame.
        var cachedLayers: [(node: SKNode, depth: CGFloat)] = []
        if chunked {
            // All ground composites below all scenery. Bounded scenery strips keep
            // global depth order even where trees/rocks overhang chunk boundaries.
            for key in chunks.keys.sorted(by: { a,b in a.y == b.y ? a.x < b.x : a.y < b.y }) {
                cachedLayers.append((chunks[key]!.ground, 0))
            }
            for (key,node) in scenicChunks {
                cachedLayers.append((node, 1 + CGFloat(key.depth) / CGFloat(configuration.map.width + configuration.map.height)))
            }
        } else {
            let staticWorld = SKNode(); staticWorld.addChild(ground)
            scenery.zPosition = 1; staticWorld.addChild(scenery)
            cachedLayers.append((staticWorld, 0))
        }
        for layer in cachedLayers {
            let staticWorld = layer.node
            if let view, let texture = view.texture(from: staticWorld) {
                let bounds = staticWorld.calculateAccumulatedFrame()
                let sprite = SKSpriteNode(texture: texture); sprite.position = CGPoint(x:bounds.midX,y:bounds.midY); sprite.size = bounds.size
                sprite.zPosition = layer.depth; terrainLayer.addChild(sprite)
            } else if chunked {
                staticWorld.zPosition = layer.depth; terrainLayer.addChild(staticWorld)
            } else {
                let cached = SKEffectNode();cached.shouldRasterize = true;cached.addChild(staticWorld);terrainLayer.addChild(cached)
            }
        }
        if continuousFog, !continuousFogPath.isEmpty {
            let field = SKShapeNode(path: continuousFogPath)
            field.fillColor = UIColor(red: 0.60, green: 0.65, blue: 0.67, alpha: 1)
            field.strokeColor = field.fillColor; field.lineWidth = 1.5; field.glowWidth = 3
            field.zPosition = 80; terrainLayer.addChild(field)
            if !reduceMotion, let previous = renderedDiscovery, let discovered {
                let newlyKnown = discovered.subtracting(previous)
                if !newlyKnown.isEmpty {
                    let revealPath = CGMutablePath()
                    for tile in newlyKnown { revealPath.addPath(IsometricProjection.diamond(at: IsometricProjection.point(tile))) }
                    let receding = SKShapeNode(path: revealPath)
                    receding.fillColor = field.fillColor; receding.strokeColor = field.fillColor
                    receding.lineWidth = 1.5; receding.zPosition = 81
                    terrainLayer.addChild(receding)
                    #if DEBUG
                    receding.run(.sequence([.fadeOut(withDuration: 1.2), .removeFromParent(), .run { [weak self] in self?.onReviewRevealComplete?() }]))
                    #else
                    receding.run(.sequence([.fadeOut(withDuration: 1.2), .removeFromParent()]))
                    #endif
                }
            }
        }
        let waterEffects = SKNode();waterEffects.zPosition = 2;terrainLayer.addChild(waterEffects)
        if !reduceMotion {
            var ripples = 0
            for y in 0..<configuration.map.height { for x in 0..<configuration.map.width {
                let tile = Tile(x:x,y:y)
                if ripples < VisualActivityPolicy.maximumWaterRipples && (x+y)%3 == 0 && (discovered?.contains(tile) ?? true) && configuration.map.terrain(at: tile) == .water {
                    let ripple = SKShapeNode(ellipseOf: CGSize(width: 21,height: 3));ripple.position = IsometricProjection.point(tile);ripple.strokeColor = .white.withAlphaComponent(0.22);ripple.lineWidth = 0.7;waterEffects.addChild(ripple)
                    ripple.run(.repeatForever(.sequence([.group([.moveBy(x: 7,y: -3,duration: 3.8),.fadeOut(withDuration: 3.8)]),.run { [weak ripple] in ripple?.position = IsometricProjection.point(tile);ripple?.alpha = 1 }])))
                    ripples += 1
                }
            } }
        }
        buildingLayer.zPosition = 100
    }
    private func drawDeposits(_ deposits: [NaturalDeposit], identifiedIDs: Set<String>, reserves: [String: Double], discovered: Set<Tile>?) {
        depositLayer.removeAllChildren()
        for deposit in deposits {
            for site in [deposit.origin] + (deposit.accessSites ?? []) where discovered?.contains(site) ?? true {
            let point = IsometricProjection.point(site)
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
            if site != deposit.origin {
                let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
                label.text = "Quarry"; label.fontSize = 10; label.fontColor = .white
                label.position = CGPoint(x: 0, y: -24); marker.addChild(label)
            }
            depositLayer.addChild(marker)
            }
        }
    }
    private func drawBuilding(_ building: PlacedBuilding, into layer: SKNode? = nil, faded: Bool = false) {
        let definition = configuration.definition(building.kind)
        let footprint = building.occupiedFootprint(in: configuration)
        // Both logical axes contribute to the ground-contact anchor.
        let center = footprint.center(at: building.origin)
        let anchor = CGPoint(x: center.x, y: center.y)
        let node = SKNode(); node.name = definition.assetKey; node.position = anchor
        node.userData = ["buildingID": building.id]
        node.zPosition = CGFloat(building.origin.x + building.origin.y + footprint.width + footprint.height - 2)
        if let texture = EraArt.texture(building.kind), let visual = EraArt.catalog?.building(building.kind) {
            let sprite = SKSpriteNode(texture: texture)
            sprite.name = "artSprite"
            sprite.size = CGSize(width: visual.worldWidth, height: visual.worldHeight)
            sprite.anchorPoint = CGPoint(x: visual.anchorX, y: visual.anchorY)
            node.addChild(sprite)
            if !building.isOperational {
                sprite.alpha = 0.3
                let frame = polygon([CGPoint(x: -36,y: 0),CGPoint(x: -36,y: 40),CGPoint(x: 0,y: 65),CGPoint(x: 36,y: 40),CGPoint(x:36,y:0)], fill: .clear)
                frame.name = "constructionScaffold"
                frame.strokeColor = UIColor(red: 0.78,green: 0.65,blue: 0.43,alpha: 0.85); frame.lineWidth = 3; node.addChild(frame)
                let roof = polygon([CGPoint(x: -38, y: 40), CGPoint(x: 0, y: 66), CGPoint(x: 38, y: 40)], fill: .brown.withAlphaComponent(0.45))
                roof.name = "constructionRoof"; roof.isHidden = true; node.addChild(roof)
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
            if layer == nil && newlyPlacedIDs.contains(building.id) && !reduceMotion {
                let ring = SKShapeNode(ellipseOf: CGSize(width: 96,height: 42));ring.strokeColor = .systemMint.withAlphaComponent(0.7);ring.lineWidth = 2;ring.fillColor = .clear;node.addChild(ring)
                ring.run(.sequence([.group([.scale(to:1.2,duration:0.65),.fadeOut(withDuration:0.65)]),.removeFromParent()]))
            }
            if faded { node.alpha = 0.2 }
            (layer ?? buildingLayer).addChild(node)
            return
        }
        let shadow = SKShapeNode(ellipseOf: CGSize(width: footprint.width == 1 && footprint.height == 1 ? 40 : 94, height: 30)); shadow.fillColor = UIColor.black.withAlphaComponent(0.20); shadow.strokeColor = .clear; shadow.position = CGPoint(x: 7,y: -5); node.addChild(shadow)
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
