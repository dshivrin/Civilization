import Foundation

/// Derived topology, never serialized. Mutable economy/timers do not invalidate the graph.
struct ConnectivityTopology: Equatable, Sendable {
    struct Building: Equatable, Sendable {
        var id: Int
        var kind: BuildingKind
        var origin: Tile
        var footprint: BuildingFootprint
        var complete: Bool
    }
    var buildings: [Building]
    var roads: Set<Tile>
    var discovered: Set<Tile>?
}

public extension GameEngine {
    func isConnectedToCivicCenter(_ building: PlacedBuilding) -> Bool {
        connectedBuildingIDs.contains(building.id)
    }
}

extension GameEngine {
    mutating func refreshConnectivity() {
        let key = ConnectivityTopology(buildings: state.buildings.map {
            .init(id: $0.id, kind: $0.kind, origin: $0.origin,
                  footprint: $0.occupiedFootprint(in: configuration), complete: $0.isOperational)
        }, roads: Set((state.roads ?? []).map(\.tile)), discovered: state.discoveredTiles)
        guard key != connectivityTopology else { return }
        connectivityTopology = key
        guard let civic = key.buildings.first(where: { $0.kind == .campfire }) else {
            connectedBuildingIDs = []; return
        }
        let occupied = Set(key.buildings.flatMap { $0.footprint.tiles(at: $0.origin) })
        let roads = key.roads.filter {
            configuration.map.contains($0) && (key.discovered?.contains($0) ?? true) && !occupied.contains($0) &&
            (configuration.map.terrain(at: $0) == .grass || configuration.map.terrain(at: $0) == .clearing)
        }
        func access(_ building: ConnectivityTopology.Building) -> Set<Tile> {
            Set(building.footprint.tiles(at: building.origin).flatMap { RoadGeometry.neighbors(of: $0).map(\.tile) }).intersection(roads)
        }
        // All branches adjacent to the civic footprint share its virtual root.
        var connected = access(civic)
        var queue = Array(connected), index = 0
        while index < queue.count {
            let tile = queue[index]; index += 1
            for neighbor in RoadGeometry.neighbors(of: tile).map(\.tile) where roads.contains(neighbor) {
                if connected.insert(neighbor).inserted { queue.append(neighbor) }
            }
        }
        connectedBuildingIDs = Set(key.buildings.filter {
            $0.id == civic.id || ($0.complete && !access($0).isDisjoint(with: connected))
        }.map(\.id))
    }
}
