import SpriteKit
import GameCore

/// Replaceable procedural road surfaces. Refined paths are an explicit visual review opt-in.
/// At most 32 cached base paths plus three batched detail nodes (384 road stamps).
@MainActor final class RoadSceneLayer: SKNode {
    let preview = SKNode()
    var visualRefinementsEnabled = false
    private var renderedRefinements = false
    private let materialDetails = SKNode()
    private var refinedPaths: [UInt8:CGPath] = [:]
    private var rendered: [RoadTile] = []
    private var nodesByTile: [Tile:SKShapeNode] = [:]
    private var paths: [UInt8:CGPath] = [:]
    private var lastDiscovery: Set<Tile>?
    private var lastDraft: [Tile] = []
    private var lastTool: RoadTool?
    private var lastIssue: Bool = false
    override init() { super.init();zPosition = 5;preview.zPosition = 1999;materialDetails.zPosition = 0.1;addChild(materialDetails) }
    required init?(coder:NSCoder) { fatalError("Programmatic road layer") }
    func display(roads:[RoadTile],discovered:Set<Tile>?,configuration:GameConfiguration,tool:RoadTool?,draft:[Tile],invalid:Bool) {
        let visible = roads.filter { discovered?.contains($0.tile) ?? true }
        let discoveryChanged = discovered != lastDiscovery
        let refinementsChanged = visualRefinementsEnabled != renderedRefinements
        let dirty = discoveryChanged || refinementsChanged ? Set(rendered.map(\.tile)).union(visible.map(\.tile)) : RoadGeometry.affectedTiles(before:rendered,after:visible)
        let byTile = Dictionary(visible.map { ($0.tile,$0) },uniquingKeysWith:{ _,b in b }),occupied = Set(byTile.keys)
        for tile in dirty {
            nodesByTile.removeValue(forKey:tile)?.removeFromParent()
            guard let road = byTile[tile] else { continue }
            let node = surface(at:tile,mask:RoadGeometry.connectionMask(at:tile,occupied:occupied),color:color(road.style))
            addChild(node);nodesByTile[tile] = node
        }
        if !dirty.isEmpty || discoveryChanged || refinementsChanged { rebuildMaterialDetails(visible) }
        if draft != lastDraft || tool != lastTool || invalid != lastIssue || !dirty.isEmpty || discoveryChanged || refinementsChanged {
            preview.removeAllChildren()
            let shown = draft.filter { configuration.map.contains($0) && (discovered?.contains($0) ?? true) }
            let previewOccupied = occupied.union(shown)
            for tile in shown {
                let tint:UIColor = invalid ? .systemRed : tool == .erase ? .systemOrange : .systemMint
                let node = surface(at:tile,mask:RoadGeometry.connectionMask(at:tile,occupied:previewOccupied),color:tint.withAlphaComponent(0.65))
                preview.addChild(node)
            }
        }
        renderedRefinements = visualRefinementsEnabled
        rendered = visible;lastDiscovery = discovered;lastDraft = draft;lastTool = tool;lastIssue = invalid
    }
    private func color(_ style:RoadStyle) -> UIColor {
        switch style {
        case .trodden: UIColor(red:0.53,green:0.48,blue:0.24,alpha:0.85)
        case .dirt: UIColor(red:0.48,green:0.30,blue:0.15,alpha:1)
        case .stone: UIColor(red:0.64,green:0.64,blue:0.57,alpha:1)
        }
    }
    private func surface(at tile:Tile,mask:UInt8,color:UIColor) -> SKShapeNode {
        let node = SKShapeNode(path:visualRefinementsEnabled ? refinedPath(mask) : path(mask));node.fillColor = color;node.strokeColor = .clear
        let p = MapGeometry.point(for:tile);node.position = CGPoint(x:p.x,y:p.y);return node
    }
    /// Narrow joins leave grass at the corners instead of making a tiled brown platform.
    private func refinedPath(_ mask: UInt8) -> CGPath {
        if let cached = refinedPaths[mask] { return cached }
        let path = CGMutablePath()
        func polygon(_ corners: [(Double, Double)]) {
            path.addLines(between: corners.map { CGPoint(x: ($0.0 - $0.1) * 32, y: -($0.0 + $0.1) * 16) }); path.closeSubpath()
        }
        polygon([(-0.15,-0.28),(0.15,-0.28),(0.28,-0.15),(0.28,0.15),(0.15,0.28),(-0.15,0.28),(-0.28,0.15),(-0.28,-0.15)])
        if mask & 1 != 0 { polygon([(-0.24,-0.15),(-0.24,-0.5),(0.24,-0.5),(0.24,-0.15)]) }
        if mask & 2 != 0 { polygon([(0.15,-0.24),(0.5,-0.24),(0.5,0.24),(0.15,0.24)]) }
        if mask & 4 != 0 { polygon([(-0.24,0.15),(0.24,0.15),(0.24,0.5),(-0.24,0.5)]) }
        if mask & 8 != 0 { polygon([(-0.5,-0.24),(-0.15,-0.24),(-0.15,0.24),(-0.5,0.24)]) }
        refinedPaths[mask] = path; return path
    }
    private func rebuildMaterialDetails(_ roads: [RoadTile]) {
        materialDetails.removeAllChildren()
        guard visualRefinementsEnabled else { return }
        // Static deterministic stamps, batched by material; never a node or action per pebble.
        let bounded = roads.sorted { $0.tile.y == $1.tile.y ? $0.tile.x < $1.tile.x : $0.tile.y < $1.tile.y }.prefix(384)
        for style in RoadStyle.allCases {
            let path = CGMutablePath()
            for road in bounded where road.style == style {
                let center = MapGeometry.point(for: road.tile)
                let flip = (road.tile.x + road.tile.y).isMultiple(of: 2) ? 1.0 : -1.0
                func mark(_ x: Double, _ y: Double, _ dx: Double, _ dy: Double) {
                    path.move(to: CGPoint(x: center.x + x, y: center.y + y))
                    path.addLine(to: CGPoint(x: center.x + x + dx, y: center.y + y + dy))
                }
                switch style {
                case .trodden: mark(-3, flip * 1.5, 3, -1.5); mark(2, -flip, 2, 1)
                case .dirt: mark(-4, 0, 5, -2.5); mark(0, 2, 4, -2)
                case .stone: mark(-4, 0, 3, -1.5); mark(0, 2, 3, -1.5); mark(2, -2, 2, 1)
                }
            }
            guard !path.isEmpty else { continue }
            let detail = SKShapeNode(path: path)
            detail.fillColor = .clear; detail.lineCap = .round
            detail.strokeColor = style == .stone ? UIColor(red: 0.83, green: 0.83, blue: 0.75, alpha: 0.56) : UIColor(red: 0.76, green: 0.68, blue: 0.44, alpha: 0.36)
            detail.lineWidth = style == .stone ? 2 : 1
            materialDetails.addChild(detail)
        }
    }
    private func path(_ mask:UInt8) -> CGPath {
        if let cached = paths[mask] { return cached }
        let path = CGMutablePath()
        func quad(_ corners:[(Double,Double)]) {
            path.addLines(between:corners.map { CGPoint(x:($0.0-$0.1)*32,y:-($0.0+$0.1)*16) });path.closeSubpath()
        }
        // Broad central surface plus full shared-edge joins makes parallel tiles form wider ground.
        quad([(-0.4,-0.4),(0.4,-0.4),(0.4,0.4),(-0.4,0.4)])
        if mask & 1 != 0 { quad([(-0.4,-0.4),(-0.5,-0.5),(0.5,-0.5),(0.4,-0.4)]) }
        if mask & 2 != 0 { quad([(0.4,-0.4),(0.5,-0.5),(0.5,0.5),(0.4,0.4)]) }
        if mask & 4 != 0 { quad([(0.4,0.4),(0.5,0.5),(-0.5,0.5),(-0.4,0.4)]) }
        if mask & 8 != 0 { quad([(-0.4,0.4),(-0.5,0.5),(-0.5,-0.5),(-0.4,-0.4)]) }
        paths[mask] = path;return path
    }
}
