import Foundation
import Testing
@testable import GameCore
import GameApplication

private func visualFixture(rows: [String]) throws -> (GameConfiguration, GameState) {
    var c = try GameConfiguration.bundled()
    c.explorationRules = nil
    c.map.rows = rows; c.map.height = rows.count; c.map.width = rows[0].count
    c.map.campfire = Tile(x: 0, y: 0)
    var s = try GameEngine(configuration: .bundled(), now: Date(timeIntervalSince1970: 0)).state
    s.buildings = []; s.discoveredTiles = nil; s.roads = nil
    return (c, s)
}

@Test func visualRoutesRejectWaterFootprintsFogAndOutsideEndpoints() throws {
    var (c, s) = try visualFixture(rows: [".......", ".www...", ".......", "......."])
    var hut = PlacedBuilding(id: 1, kind: .hut, origin: Tile(x: 3, y: 2))
    hut.footprint = BuildingFootprint(width: 2, height: 2)
    s.buildings = [hut]
    s.discoveredTiles = Set((0..<4).flatMap { y in (0..<6).map { Tile(x: $0, y: y) } })
    let planner = VisualRoutePlanner(configuration: c, state: s)
    let path = planner.path(from: Tile(x: 0, y: 1), to: Tile(x: 5, y: 2))
    #expect(!path.isEmpty)
    #expect(planner.isValid(path: path))
    #expect(path.allSatisfy { c.map.terrain(at: $0) != .water && !hut.tiles(in: c).contains($0) })
    for bad in [Tile(x: 1, y: 1), Tile(x: 3, y: 2), Tile(x: 6, y: 0), Tile(x: Int.max, y: Int.min)] {
        #expect(planner.path(from: bad, to: Tile(x: 0, y: 0)).isEmpty)
        #expect(planner.path(from: Tile(x: 0, y: 0), to: bad).isEmpty)
    }
    #expect(!planner.isValid(path: [Tile(x: 0, y: 0), Tile(x: 2, y: 0)]))
    #expect(!planner.isValid(path: []))
    c.map.rows = [".w.....", ".w.....", ".w.....", ".w....."]
    #expect(VisualRoutePlanner(configuration: c, state: s).path(from: .init(x: 0, y: 0), to: .init(x: 5, y: 0)).isEmpty)
}

@Test func visualRoutesPreferConnectedRoadsAndRemainDeterministicBounded() throws {
    var (c, s) = try visualFixture(rows: [".......", ".......", "......."])
    let road = [Tile(x: 0, y: 1)] + (0..<7).map { Tile(x: $0, y: 0) } + [Tile(x: 6, y: 1)]
    s.roads = road.map { RoadTile(tile: $0, style: .trodden) }
    let planner = VisualRoutePlanner(configuration: c, state: s)
    let a = Tile(x: 0, y: 1), b = Tile(x: 6, y: 1)
    let route = planner.path(from: a, to: b)
    #expect(route == road)
    #expect(planner.path(from: a, to: b) == route)
    #expect(planner.path(from: a, to: b, maximumTiles: 3).isEmpty)
    c.map.rows = [".......", ".fh....", "......."]
    let limited = VisualRoutePlanner(configuration: c, state: s)
    #expect(!limited.isTraversable(.init(x: 1, y: 1)))
    #expect(!limited.isTraversable(.init(x: 2, y: 1)))
}

@Test func visualDestinationRoutesUseRealBuildingEdgesWithoutMutatingGame() throws {
    var (c, s) = try visualFixture(rows: Array(repeating: String(repeating: ".", count: 16), count: 12))
    let kinds: [BuildingKind] = [.woodcutter, .storehouse, .storytellingCircle, .hut]
    s.buildings = kinds.enumerated().map { i, kind in
        PlacedBuilding(id: i + 1, kind: kind, origin: Tile(x: 2 + i * 3, y: 3))
    }
    let before = s
    let planner = VisualRoutePlanner(configuration: c, state: s)
    let routes = planner.destinationRoutes(maximumAgents: 3)
    #expect(routes.count == 3)
    #expect(routes.contains { $0.purpose == .carryWood })
    #expect(routes.contains { $0.purpose == .visitGathering })
    for route in routes {
        #expect(route.tiles.count <= VisualRoutePlanner.maximumRouteTiles)
        #expect(planner.isValid(path: route.tiles))
        let source = try #require(s.buildings.first { $0.id == route.sourceBuildingID })
        let destination = try #require(s.buildings.first { $0.id == route.destinationBuildingID })
        #expect(planner.accessTiles(for: source).contains(try #require(route.tiles.first)))
        #expect(planner.accessTiles(for: destination).contains(try #require(route.tiles.last)))
    }
    #expect(s == before)
    #expect(planner.destinationRoutes(maximumAgents: 1000).count <= VisualWorldBudget.maximumAgents)
    s.buildings[0].constructionRemainingSeconds = 10
    #expect(!VisualRoutePlanner(configuration: c, state: s).destinationRoutes().contains { $0.purpose == .carryWood })
    c.map.rows = Array(repeating: String(repeating: "w", count: 16), count: 12)
    #expect(VisualRoutePlanner(configuration: c, state: s).destinationRoutes().isEmpty)
}

@Test func visualWorldBudgetsSuspendBackgroundAndReduceMotion() {
    #expect(VisualWorldBudget(reduceMotion: false, lowPower: false, foreground: true).agentCount == 6)
    #expect(VisualWorldBudget(reduceMotion: false, lowPower: true, foreground: true).agentCount == 3)
    #expect(VisualWorldBudget(reduceMotion: true, lowPower: false, foreground: true).animates == false)
    #expect(VisualWorldBudget(reduceMotion: false, lowPower: false, foreground: false).agentCount == 0)
    #expect(VisualWorldBudget(reduceMotion: false, lowPower: false, foreground: false).animates == false)
}

@Test func visualRoutesNeverInferGatesOrBridgesFromDecorativeRoads() throws {
    var (c, s) = try visualFixture(rows: ["....w.....", "....w.....", "....w.....", "....w.....", "....w.....", "....w....."])
    s.buildings = [PlacedBuilding(id: 1, kind: .woodcutter, origin: Tile(x: 0, y: 1)),
                   PlacedBuilding(id: 2, kind: .storehouse, origin: Tile(x: 7, y: 1))]
    s.roads = (0..<10).map { RoadTile(tile: Tile(x: $0, y: 3), style: .dirt) }
    #expect(VisualRoutePlanner(configuration: c, state: s).destinationRoutes().isEmpty)
    c.map.rows = Array(repeating: "..........", count: 6)
    for y in 0..<6 {
        var wall = PlacedBuilding(id: y + 3, kind: .palisade, origin: Tile(x: 4, y: y))
        wall.footprint = BuildingFootprint(width: 1, height: 1)
        s.buildings.append(wall)
    }
    #expect(VisualRoutePlanner(configuration: c, state: s).destinationRoutes().isEmpty)
}
