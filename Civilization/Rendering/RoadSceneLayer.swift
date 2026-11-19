import SpriteKit
import GameCore

/// Replaceable procedural candidate surfaces. One shape per tile; at most16 cached paths.
@MainActor final class RoadSceneLayer: SKNode {
    let preview = SKNode()
    private var rendered: [RoadTile] = []
    private var nodesByTile: [Tile:SKShapeNode] = [:]
    private var paths: [UInt8:CGPath] = [:]
    private var lastDiscovery: Set<Tile>?
    private var lastDraft: [Tile] = []
    private var lastTool: RoadTool?
    private var lastIssue: Bool = false
    override init() { super.init();zPosition = 5;preview.zPosition = 1999 }
    required init?(coder:NSCoder) { fatalError("Programmatic road layer") }
    func display(roads:[RoadTile],discovered:Set<Tile>?,configuration:GameConfiguration,tool:RoadTool?,draft:[Tile],invalid:Bool) {
        let visible = roads.filter { discovered?.contains($0.tile) ?? true }
        let discoveryChanged = discovered != lastDiscovery
        let dirty = discoveryChanged ? Set(rendered.map(\.tile)).union(visible.map(\.tile)) : RoadGeometry.affectedTiles(before:rendered,after:visible)
        let byTile = Dictionary(visible.map { ($0.tile,$0) },uniquingKeysWith:{ _,b in b }),occupied = Set(byTile.keys)
        for tile in dirty {
            nodesByTile.removeValue(forKey:tile)?.removeFromParent()
            guard let road = byTile[tile] else { continue }
            let node = surface(at:tile,mask:RoadGeometry.connectionMask(at:tile,occupied:occupied),color:color(road.style))
            addChild(node);nodesByTile[tile] = node
        }
        if draft != lastDraft || tool != lastTool || invalid != lastIssue || !dirty.isEmpty || discoveryChanged {
            preview.removeAllChildren()
            let shown = draft.filter { configuration.map.contains($0) && (discovered?.contains($0) ?? true) }
            let previewOccupied = occupied.union(shown)
            for tile in shown {
                let tint:UIColor = invalid ? .systemRed : tool == .erase ? .systemOrange : .systemMint
                let node = surface(at:tile,mask:RoadGeometry.connectionMask(at:tile,occupied:previewOccupied),color:tint.withAlphaComponent(0.65))
                preview.addChild(node)
            }
        }
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
        let node = SKShapeNode(path:path(mask));node.fillColor = color;node.strokeColor = .clear
        let p = MapGeometry.point(for:tile);node.position = CGPoint(x:p.x,y:p.y);return node
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
