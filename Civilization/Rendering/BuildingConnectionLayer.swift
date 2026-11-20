import SpriteKit
import GameCore
import GameApplication

/// Review-only ground detail. No hit areas, occupancy, wall/roof joins, or saved state.
/// At most four batched shapes and 256 actual shared-edge segments.
@MainActor final class BuildingConnectionLayer: SKNode {
    private var lastBuildings: [PlacedBuilding] = []
    private var lastDiscovery: Set<Tile>?
    private var lastExcluded: Set<Int> = []
    private var rendered: [BuildingVisualConnection] = []
    private var hasDisplayed = false

    override init() { super.init(); zPosition = 6 }
    required init?(coder: NSCoder) { fatalError("Programmatic connection layer") }

    /// Call when the snapshot is displayed, excluding the currently relocated building.
    /// Parent owns the explicit review gate; this layer never activates itself.
    func display(buildings: [PlacedBuilding], discovered: Set<Tile>?, configuration: GameConfiguration, excludingIDs: Set<Int> = []) {
        guard !hasDisplayed || buildings != lastBuildings || discovered != lastDiscovery || excludingIDs != lastExcluded else { return }
        let segments = BuildingVisualConnections.segments(buildings: buildings, configuration: configuration, discovered: discovered, excludingIDs: excludingIDs)
        lastBuildings = buildings; lastDiscovery = discovered; lastExcluded = excludingIDs; hasDisplayed = true
        guard segments != rendered else { return }
        rendered = segments
        removeAllChildren()
        for family in [BuildingConnectionFamily.housing, .storage] {
            let path = CGMutablePath(), accents = CGMutablePath()
            for edge in segments where edge.family == family {
                let x = Double(edge.tile.x), y = Double(edge.tile.y)
                let start: (Double, Double), end: (Double, Double)
                switch edge.direction {
                case .east: start = (x + 0.5, y - 0.32); end = (x + 0.5, y + 0.32)
                case .south: start = (x - 0.32, y + 0.5); end = (x + 0.32, y + 0.5)
                }
                path.move(to: project(start)); path.addLine(to: project(end))
                let middle = CGPoint(x: (project(start).x + project(end).x) / 2, y: (project(start).y + project(end).y) / 2)
                // Small light stones / timber ties articulate the shared yard without a ground square.
                accents.move(to: CGPoint(x: middle.x - 1.7, y: middle.y + 0.8))
                accents.addLine(to: CGPoint(x: middle.x + 1.7, y: middle.y - 0.8))
            }
            guard !path.isEmpty else { continue }
            let seam = SKShapeNode(path: path)
            seam.strokeColor = family == .housing ? UIColor(red: 0.68, green: 0.63, blue: 0.43, alpha: 0.48) : UIColor(red: 0.57, green: 0.53, blue: 0.40, alpha: 0.52)
            seam.lineWidth = family == .housing ? 3.2 : 4.2; seam.lineCap = .round; seam.fillColor = .clear
            addChild(seam)
            let detail = SKShapeNode(path: accents)
            detail.strokeColor = UIColor(red: 0.84, green: 0.79, blue: 0.61, alpha: 0.6)
            detail.lineWidth = 1.1; detail.lineCap = .round; detail.fillColor = .clear
            addChild(detail)
        }
    }

    /// Invalidate when changing map/configuration or leaving the review mode.
    func clear() {
        removeAllChildren(); rendered = []; lastBuildings = []; lastDiscovery = nil; lastExcluded = []; hasDisplayed = false
    }
    private func project(_ p: (Double, Double)) -> CGPoint {
        CGPoint(x: (p.0 - p.1) * 32, y: -(p.0 + p.1) * 16)
    }
}
