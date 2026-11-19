import Foundation

/// Logical quarter turns, not a rotation of the finished isometric sprite.
public enum BuildingOrientation: String, Codable, CaseIterable, Sendable {
    case north, east, south, west
}

/// Base dimensions are stored independently of orientation. Origin is always the
/// minimum logical x/y corner. Engine validation bounds dimensions before enumeration.
public struct BuildingFootprint: Codable, Equatable, Sendable {
    public var width: Int
    public var height: Int
    public init(width: Int, height: Int) { self.width = width; self.height = height }
    public func oriented(_ orientation: BuildingOrientation) -> BuildingFootprint {
        switch orientation {
        case .north, .south: self
        case .east, .west: BuildingFootprint(width: height, height: width)
        }
    }
    public func tiles(at origin: Tile) -> [Tile] {
        guard width > 0, height > 0 else { return [] }
        return (0..<height).flatMap { dy in (0..<width).map { dx in Tile(x: origin.x + dx, y: origin.y + dy) } }
    }
    public func center(at origin: Tile) -> WorldPoint {
        let p = MapGeometry.point(for: origin)
        return WorldPoint(x: p.x + Double(width - height) * 16, y: p.y - Double(width + height - 2) * 8)
    }
}

public extension BuildingDefinition {
    var footprint: BuildingFootprint { BuildingFootprint(width: width, height: height) }
    var resolvedOrientations: [BuildingOrientation] { allowedOrientations ?? [.north] }
}
public extension PlacedBuilding {
    var resolvedOrientation: BuildingOrientation { orientation ?? .north }
    func resolvedFootprint(in configuration: GameConfiguration) -> BuildingFootprint {
        footprint ?? configuration.definition(kind).footprint
    }
    func occupiedFootprint(in configuration: GameConfiguration) -> BuildingFootprint {
        resolvedFootprint(in: configuration).oriented(resolvedOrientation)
    }
    func tiles(in configuration: GameConfiguration) -> [Tile] {
        occupiedFootprint(in: configuration).tiles(at: origin)
    }
}
