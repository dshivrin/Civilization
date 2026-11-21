#if DEBUG
import Foundation

public extension GameConfiguration {
    static let riverbendFoothillID = "riverbend-ui2-foothill-v1"
    var isRiverbendFoothillReview: Bool { map.id == Self.riverbendFoothillID }
    /// One authored review map. The bundled map and every existing identity stay intact.
    static func riverbendFoothillReview() throws -> Self {
        var c = try riverbendFoundingReview()
        c.map.id = riverbendFoothillID
        var rows = Array(repeating: Array(repeating: Character("."), count: 64), count: 48)
        for y in 0..<48 { for x in 0..<64 {
            if x == 30 || x == 31 { rows[y][x] = "w" }
            else if x < 6 || x > 48 { rows[y][x] = "f" }
            else if (8...25).contains(x) && (8...21).contains(y) { rows[y][x] = "c" }
        } }
        for tile in FoothillBoundary.cliffs { rows[tile.y][tile.x] = "h" }
        // Low grassy slopes are deliberately outside the cliff collision set.
        for y in 22...25 { for x in 22...26 { rows[y][x] = "h" } }
        for y in 13...17 { for x in 7...8 { rows[y][x] = "f" } }
        rows[16][21] = "h" // reachable Stone source, never a natural defensive wall
        c.map.rows = rows.map { String($0) }
        c.explorationRules?.initialRadius = 16
        c.explorationRules?.requiresScoutAfterRadius = 16
        c.explorationRules?.initialKnownDepositIDs = ["western-forest", "valley-stone"]
        for i in (c.naturalDeposits ?? []).indices {
            switch c.naturalDeposits![i].id {
            case "western-forest": c.naturalDeposits![i].origin = Tile(x: 8, y: 15); c.naturalDeposits![i].accessSites = [Tile(x: 9, y: 15)]
            case "valley-stone": c.naturalDeposits![i].origin = Tile(x: 21, y: 16); c.naturalDeposits![i].accessSites = [Tile(x: 20, y: 16)]
            case "valley-flint": c.naturalDeposits![i].origin = Tile(x: 22, y: 24); c.naturalDeposits![i].accessSites = nil
            case "river-water": c.naturalDeposits![i].origin = Tile(x: 30, y: 12); c.naturalDeposits![i].accessSites = [Tile(x: 29, y: 12)]
            case "river-clay": c.naturalDeposits![i].origin = Tile(x: 29, y: 12); c.naturalDeposits![i].accessSites = nil
            default: break
            }
        }
        try c.validate()
        return c
    }
}

/// Review collision, independent of the cosmetic NPC planner. All map cells are searched.
/// Forest and ordinary slopes are pedestrian ground; only water, explicit cliffs,
/// occupied footprints and purchased solid walls block movement. Cardinal only.
public struct FoothillBoundary {
    public static let gate = Tile(x: 23, y: 14)
    public static let outside = Tile(x: 26, y: 14)
    public static let inside = Tile(x: 20, y: 14)
    public static let slope = Tile(x: 24, y: 23)
    public static let expansion = Tile(x: 25, y: 27)
    public static let earlyResources = [Tile(x: 12, y: 16), Tile(x: 9, y: 15), Tile(x: 20, y: 16)]
    public static let cliffs: Set<Tile> = Set((3...7).flatMap { y in (10...23).map { Tile(x: $0, y: y) } })
    public static let interior: Set<Tile> = Set((8...18).flatMap { y in (11...22).map { Tile(x: $0, y: y) } })
    public static let wall: Set<Tile> = Set((8...19).flatMap { y in [Tile(x: 10, y: y), Tile(x: 23, y: y)] } + (11...22).map { Tile(x: $0, y: 19) })
    public static let freestandingWall = wall.union((10...23).map { Tile(x: $0, y: 7) })
    public static let gateRoad: Set<Tile> = Set(RoadGeometry.path(from: Tile(x: 18, y: 12), to: Tile(x: 22, y: 14), width: 64, height: 48) + [gate, Tile(x: 24,y: 14), Tile(x: 25,y: 14), outside])
    public static let reserved = wall.union(gateRoad).union([inside])
    public static let cliffCost = Double(wall.count)
    public static let freestandingCost = Double(freestandingWall.count)
    public let configuration: GameConfiguration
    private let blocked: Set<Tile>
    public init(configuration: GameConfiguration, buildings: [PlacedBuilding], enclosed: Bool, gateOpen: Bool, freestanding: Bool = false, omittedWall: Set<Tile> = []) {
        self.configuration = configuration
        var cells = freestanding ? Set<Tile>() : Self.cliffs
        cells.formUnion(buildings.flatMap { $0.tiles(in: configuration) })
        if enclosed {
            var wall = (freestanding ? Self.freestandingWall : Self.wall).subtracting(omittedWall)
            if gateOpen { wall.remove(Self.gate) }
            cells.formUnion(wall)
        }
        blocked = cells
    }
    public func walkable(_ tile: Tile) -> Bool {
        configuration.isRiverbendFoothillReview && configuration.map.contains(tile) &&
            configuration.map.terrain(at: tile) != .water && !blocked.contains(tile)
    }
    public func reachable(from start: Tile) -> Set<Tile> { search(from: start).seen }
    private func search(from start: Tile) -> (seen: Set<Tile>, parents: [Tile: Tile]) {
        guard walkable(start) else { return ([], [:]) }
        var seen: Set<Tile> = [start], parents: [Tile: Tile] = [:], queue = [start], index = 0
        while index < queue.count {
            let current = queue[index]; index += 1
            for neighbor in RoadGeometry.neighbors(of: current).map(\.tile) where walkable(neighbor) && seen.insert(neighbor).inserted {
                parents[neighbor] = current; queue.append(neighbor)
            }
        }
        return (seen, parents)
    }
    public func path(from start: Tile, to end: Tile) -> [Tile] {
        let result = search(from: start)
        guard result.seen.contains(end) else { return [] }
        var path = [end], current = end
        while current != start {
            guard let parent = result.parents[current] else { return [] }
            path.append(parent); current = parent
        }
        return path.reversed()
    }
}
#endif
