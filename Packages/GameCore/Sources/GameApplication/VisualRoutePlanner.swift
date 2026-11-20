import GameCore

/// Presentation-only destinations. These routes never allocate workers or transfer resources.
public struct VisualAgentRoute: Equatable, Sendable {
    public enum Purpose: String, Equatable, Sendable { case carryWood, visitGathering, visitStorage }
    public let sourceBuildingID: Int
    public let destinationBuildingID: Int
    public let purpose: Purpose
    public let tiles: [Tile]
}

public struct VisualWorldBudget: Equatable, Sendable {
    public static let maximumAgents = 6
    public static let maximumWildlife = 4
    public let agentCount: Int
    public let animates: Bool
    public init(reduceMotion: Bool, lowPower: Bool, foreground: Bool) {
        agentCount = foreground ? (lowPower ? 3 : Self.maximumAgents) : 0
        animates = foreground && !reduceMotion && !lowPower
    }
}

/// Conservative local path graph over discovered, unoccupied grass/clearing.
/// Roads receive a lower visual travel cost; clear non-road tiles are footpaths.
/// Forest, hills, water and every building (including palisades) remain barriers.
/// No inferred gates, bridges or cross-river shortcuts. Does not activate R2-07.
public struct VisualRoutePlanner: Sendable {
    public static let maximumRouteTiles = 96
    private let configuration: GameConfiguration
    private let buildings: [PlacedBuilding]
    private let traversable: Set<Tile>
    private let roads: Set<Tile>

    public init(configuration: GameConfiguration, state: GameState) {
        self.configuration = configuration
        buildings = state.buildings.sorted { $0.id < $1.id }
        let occupied = Set(state.buildings.flatMap { $0.tiles(in: configuration) })
        var clear = Set<Tile>()
        for y in 0..<configuration.map.height {
            for x in 0..<configuration.map.width {
                let tile = Tile(x: x, y: y)
                let terrain = configuration.map.terrain(at: tile)
                if (terrain == .grass || terrain == .clearing), !occupied.contains(tile),
                   state.discoveredTiles?.contains(tile) ?? true {
                    clear.insert(tile)
                }
            }
        }
        traversable = clear
        roads = Set((state.roads ?? []).map(\.tile)).intersection(clear)
    }

    public func isTraversable(_ tile: Tile) -> Bool { traversable.contains(tile) }

    public func isValid(path: [Tile]) -> Bool {
        guard !path.isEmpty, path.count <= Self.maximumRouteTiles,
              path.allSatisfy(isTraversable) else { return false }
        return zip(path, path.dropFirst()).allSatisfy { a, b in
            abs(a.x - b.x) + abs(a.y - b.y) == 1
        }
    }

    public func path(from: Tile, to: Tile, maximumTiles: Int = Self.maximumRouteTiles) -> [Tile] {
        guard isTraversable(from), isTraversable(to) else { return [] }
        return shortestPath(from: [from], to: [to], maximumTiles: maximumTiles)
    }

    /// Outside contacts only; a building's center is never a walking destination.
    public func accessTiles(for building: PlacedBuilding) -> [Tile] {
        let cells = building.tiles(in: configuration)
        return Set(cells.flatMap { Self.neighbors($0) }).filter(isTraversable).sorted(by: Self.ordered)
    }

    public func destinationRoutes(maximumAgents: Int = VisualWorldBudget.maximumAgents) -> [VisualAgentRoute] {
        let limit = min(VisualWorldBudget.maximumAgents, max(0, maximumAgents))
        guard limit > 0 else { return [] }
        let ready = buildings.filter(\.isOperational)
        let stores = ready.filter { $0.kind == .storehouse }
        let gatherings = ready.filter { [.storytellingCircle, .gatheringShelter, .campfire].contains($0.kind) }
        let homes = ready.filter { $0.kind == .hut }
        let producers = ready.filter { [.woodcutter, .stoneGatherer, .farm, .fishingShelter, .huntingLodge, .toolmaker, .potteryWorkshop].contains($0.kind) }
        var pairs: [(PlacedBuilding, PlacedBuilding, VisualAgentRoute.Purpose)] = []
        for source in producers {
            for destination in stores {
                pairs.append((source, destination, source.kind == .woodcutter ? .carryWood : .visitStorage))
            }
        }
        for source in homes + stores {
            for destination in gatherings where source.id != destination.id {
                pairs.append((source, destination, .visitGathering))
            }
        }
        for source in homes {
            for destination in stores { pairs.append((source, destination, .visitStorage)) }
        }
        var result: [VisualAgentRoute] = []
        for (source, destination, purpose) in pairs {
            let destinationContacts = Set(accessTiles(for: destination))
            // Adjacent buildings may share an exterior lane. Start at another
            // valid source contact so the review depicts a real walk, not a zero-hop trip.
            let sourceContacts = accessTiles(for: source).filter { !destinationContacts.contains($0) }
            let route = shortestPath(from: sourceContacts, to: destinationContacts, maximumTiles: Self.maximumRouteTiles)
            guard route.count > 1 else { continue }
            result.append(.init(sourceBuildingID: source.id, destinationBuildingID: destination.id, purpose: purpose, tiles: route))
            if result.count == limit { break }
        }
        return result
    }

    private static func ordered(_ a: Tile, _ b: Tile) -> Bool { a.y == b.y ? a.x < b.x : a.y < b.y }
    private static func neighbors(_ tile: Tile) -> [Tile] {
        [Tile(x: tile.x, y: tile.y - 1), Tile(x: tile.x + 1, y: tile.y),
         Tile(x: tile.x, y: tile.y + 1), Tile(x: tile.x - 1, y: tile.y)]
    }

    private func shortestPath(from sources: [Tile], to targets: Set<Tile>, maximumTiles: Int) -> [Tile] {
        let limit = min(Self.maximumRouteTiles, maximumTiles)
        guard limit > 0, !sources.isEmpty, !targets.isEmpty else { return [] }
        struct Entry { let tile: Tile; let cost: Int; let count: Int }
        var queue = sources.filter(isTraversable).sorted(by: Self.ordered).map { Entry(tile: $0, cost: 0, count: 1) }
        var costs = Dictionary(uniqueKeysWithValues: queue.map { ($0.tile, 0) })
        var previous: [Tile: Tile] = [:]
        while !queue.isEmpty {
            let entry = queue.removeFirst()
            guard costs[entry.tile] == entry.cost else { continue }
            if targets.contains(entry.tile) {
                var route = [entry.tile]
                while let parent = previous[route.last!] { route.append(parent) }
                return route.reversed()
            }
            guard entry.count < limit else { continue }
            for next in Self.neighbors(entry.tile) where isTraversable(next) {
                let cost = entry.cost + (roads.contains(next) ? 1 : 4)
                guard cost < costs[next, default: Int.max] else { continue }
                costs[next] = cost; previous[next] = entry.tile
                let candidate = Entry(tile: next, cost: cost, count: entry.count + 1)
                // Stable insertion makes repeated layouts produce exactly the same routes.
                var low = 0, high = queue.count
                while low < high {
                    let mid = (low + high) / 2
                    if queue[mid].cost <= cost { low = mid + 1 } else { high = mid }
                }
                queue.insert(candidate, at: low)
            }
        }
        return []
    }
}
