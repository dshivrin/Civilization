import GameCore

public enum BuildingConnectionFamily: String, Equatable, Sendable { case housing, storage }
public enum BuildingConnectionDirection: String, Equatable, Sendable { case east, south }

/// One actual shared tile edge, independent of art, level and simulation connectivity.
public struct BuildingVisualConnection: Equatable, Sendable {
    public let tile: Tile
    public let direction: BuildingConnectionDirection
    public let family: BuildingConnectionFamily
    public let firstBuildingID: Int
    public let secondBuildingID: Int
}

public enum BuildingVisualConnections {
    public static let maximumSegments = 256
    public static func segments(buildings: [PlacedBuilding], configuration: GameConfiguration, discovered: Set<Tile>?, excludingIDs: Set<Int> = [], maximumSegments: Int = maximumSegments) -> [BuildingVisualConnection] {
        let budget = min(Self.maximumSegments, max(0, maximumSegments))
        guard budget > 0 else { return [] }
        let idCounts = buildings.reduce(into: [Int: Int]()) { $0[$1.id, default: 0] += 1 }
        var owner: [Tile: Int] = [:]
        var ambiguous: Set<Tile> = []
        var families: [Int: BuildingConnectionFamily] = [:]
        for building in buildings {
            let footprint = building.occupiedFootprint(in: configuration)
            // Validate bounded dimensions before enumerating a possibly damaged render snapshot.
            guard footprint.width > 0, footprint.height > 0,
                  footprint.width <= configuration.map.width, footprint.height <= configuration.map.height,
                  building.origin.x >= 0, building.origin.y >= 0,
                  building.origin.x <= configuration.map.width - footprint.width,
                  building.origin.y <= configuration.map.height - footprint.height else { continue }
            let tiles = footprint.tiles(at: building.origin)
            for tile in tiles {
                if owner[tile] != nil { ambiguous.insert(tile) }
                else { owner[tile] = building.id }
            }
            guard idCounts[building.id] == 1, building.isOperational,
                  !excludingIDs.contains(building.id),
                  tiles.allSatisfy({ discovered?.contains($0) ?? true }) else { continue }
            switch building.kind {
            case .hut: families[building.id] = .housing
            case .storehouse: families[building.id] = .storage
            default: break
            }
        }
        let tiles = owner.keys.sorted { $0.y == $1.y ? $0.x < $1.x : $0.y < $1.y }
        var result: [BuildingVisualConnection] = []
        for tile in tiles {
            guard !ambiguous.contains(tile), let first = owner[tile], let family = families[first] else { continue }
            // Canonical east/south only: the opposite building cannot emit a duplicate.
            for direction in [BuildingConnectionDirection.east, .south] {
                let neighbor = Tile(x: tile.x + (direction == .east ? 1 : 0), y: tile.y + (direction == .south ? 1 : 0))
                guard !ambiguous.contains(neighbor), let second = owner[neighbor], first != second,
                      families[second] == family else { continue }
                result.append(BuildingVisualConnection(tile: tile, direction: direction, family: family,
                                                       firstBuildingID: min(first, second), secondBuildingID: max(first, second)))
                if result.count == budget { return result }
            }
        }
        return result
    }
}
