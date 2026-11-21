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

public typealias FoothillBoundary = RiverbendBoundary
#endif
