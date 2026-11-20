import Foundation

public enum RoadStyle: String, Codable, CaseIterable, Sendable {
    case trodden, dirt, stone
    public var title: String { switch self { case .trodden: "Trodden path"; case .dirt: "Dirt road"; case .stone: "Stone road" } }
}
public struct RoadTile: Codable, Equatable, Sendable {
    public var tile: Tile
    public var style: RoadStyle
    public init(tile: Tile, style: RoadStyle) { self.tile = tile; self.style = style }
}
public enum RoadTool: Equatable, Sendable {
    case draw(RoadStyle), replace(RoadStyle), erase
    public var style: RoadStyle? { switch self { case .draw(let s), .replace(let s): s; case .erase: nil } }
}
public enum RoadGeometry {
    /// Logical N(y−1)=1, E(x+1)=2, S(y+1)=4, W(x−1)=8. Masks are derived, never saved.
    public static func neighbors(of tile: Tile) -> [(tile: Tile, bit: UInt8)] {
        [(0,-1,UInt8(1)),(1,0,2),(0,1,4),(-1,0,8)].compactMap { dx,dy,bit in
            let (x,ox) = tile.x.addingReportingOverflow(dx), (y,oy) = tile.y.addingReportingOverflow(dy)
            return ox || oy ? nil : (Tile(x:x,y:y),bit)
        }
    }
    public static func connectionMask(at tile: Tile, occupied: Set<Tile>) -> UInt8 {
        guard occupied.contains(tile) else { return 0 }
        return neighbors(of:tile).reduce(0) { $0 | (occupied.contains($1.tile) ? $1.bit : 0) }
    }
    /// A bounded four-connected staircase between sampled tiles; no diagonal gaps.
    public static func path(from start: Tile, to end: Tile, width: Int, height: Int) -> [Tile] {
        let bounded = (width <= 32 && height <= 24) || (width == 64 && height == 48)
        guard width > 0, height > 0, (0..<width).contains(start.x), (0..<height).contains(start.y),
              (0..<width).contains(end.x), (0..<height).contains(end.y), bounded else { return [] }
        let dx = abs(end.x-start.x), dy = abs(end.y-start.y)
        let sx = end.x >= start.x ? 1 : -1, sy = end.y >= start.y ? 1 : -1
        var p = start, ix = 0, iy = 0, result = [start]
        while ix < dx || iy < dy {
            if ix < dx && (iy == dy || (1+2*ix)*dy < (1+2*iy)*dx) { p.x += sx; ix += 1 }
            else { p.y += sy; iy += 1 }
            result.append(p)
        }
        return result
    }
    public static func affectedTiles(before: [RoadTile], after: [RoadTile]) -> Set<Tile> {
        let a = Dictionary(before.map { ($0.tile,$0.style) },uniquingKeysWith: { _,b in b })
        let b = Dictionary(after.map { ($0.tile,$0.style) },uniquingKeysWith: { _,b in b })
        let changed = Set(a.keys).union(b.keys).filter { a[$0] != b[$0] }
        return changed.reduce(into:Set<Tile>()) { result,tile in
            result.insert(tile);result.formUnion(neighbors(of:tile).map(\.tile))
        }
    }
}
public extension GameEngine {
    func roadIssue(at tile: Tile) -> GameError? {
        guard configuration.map.contains(tile) else { return .placement("Keep roads inside the map.") }
        guard isDiscovered(tile) else { return .placement("Explore this tile before drawing roads.") }
        let terrain = configuration.map.terrain(at:tile)
        guard terrain == .grass || terrain == .clearing else { return .placement("Roads need open grass or clearing; water, hills and forest are protected.") }
        guard building(at:tile) == nil else { return .placement("Roads cannot pass under buildings.") }
        return nil
    }
    func roadMask(at tile: Tile) -> UInt8 {
        RoadGeometry.connectionMask(at:tile,occupied:Set((state.roads ?? []).map(\.tile)))
    }
    func validateRoads() throws {
        let roads = state.roads ?? []
        guard roads.count <= configuration.map.width * configuration.map.height,
              Set(roads.map(\.tile)).count == roads.count else { throw GameError.invalidSave("Invalid or duplicate road tiles") }
        for road in roads { if let issue = roadIssue(at:road.tile) { throw GameError.invalidSave(issue.localizedDescription) } }
    }
}
