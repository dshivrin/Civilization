import Foundation
import Testing
@testable import GameCore

let connectivityEpoch = Date(timeIntervalSince1970: 90_000)
func connectivityConfiguration() throws -> GameConfiguration {
    var c = try GameConfiguration.bundled()
    c.map.rows = Array(repeating: String(repeating: "c", count: c.map.width), count: c.map.height)
    c.explorationRules = nil; c.progressionGoals = nil; c.workforceRules = nil
    for i in c.buildings.indices {
        c.buildings[i].requiresResearch = false; c.buildings[i].cost = .init(); c.buildings[i].constructionSeconds = 0
    }
    return c
}
func connectivityTile(_ c: GameConfiguration, _ dx: Int, _ dy: Int = 0) -> Tile {
    Tile(x: c.map.campfire.x + dx, y: c.map.campfire.y + dy)
}
@Test func connectedRoadGraphJoinsAllCivicSidesAndStylesWithoutCornerAccess() throws {
    let c = try connectivityConfiguration()
    var g = try GameEngine(configuration: c, now: connectivityEpoch)
    try g.build(.hut, at: connectivityTile(c, 3))
    try g.build(.hut, at: connectivityTile(c, -4))
    try g.build(.hut, at: connectivityTile(c, 4, 3))
    try g.editRoads(at: [connectivityTile(c, 1)], style: .trodden)
    try g.editRoads(at: [connectivityTile(c, 2)], style: .dirt)
    try g.editRoads(at: [connectivityTile(c, -1), connectivityTile(c, -2)], style: .stone)
    try g.editRoads(at: [connectivityTile(c, 2, 1), connectivityTile(c, 2, 2), connectivityTile(c, 3, 2)], style: .stone)
    #expect(g.connectedBuildingIDs == Set([0, 1, 2]))
    let before = g.state
    var reordered = before; reordered.buildings.reverse(); reordered.roads?.reverse()
    let other = try GameEngine(state: reordered, configuration: c)
    #expect(other.connectedBuildingIDs == g.connectedBuildingIDs)
    #expect(g.state == before)
}
@Test func connectedRoadGraphRefreshesAfterCompletionRemovalAndCivicMove() throws {
    var c = try connectivityConfiguration()
    c.buildings[c.buildings.firstIndex { $0.kind == .hut }!].constructionSeconds = 10
    var g = try GameEngine(configuration: c, now: connectivityEpoch)
    try g.build(.hut, at: connectivityTile(c, 3))
    try g.editRoads(at: [connectivityTile(c, 1), connectivityTile(c, 2)], style: .trodden)
    #expect(g.connectedBuildingIDs == [0])
    g.advance(to: connectivityEpoch.addingTimeInterval(10))
    #expect(g.connectedBuildingIDs == Set([0, 1]))
    try g.editRoads(at: [connectivityTile(c, 1)], style: nil)
    #expect(g.connectedBuildingIDs == [0])
    try g.editRoads(at: [connectivityTile(c, 1)], style: .stone)
    try g.relocate(buildingID: 0, to: connectivityTile(c, -6, -6))
    #expect(g.connectedBuildingIDs == [0])
    try g.relocate(buildingID: 0, to: c.map.campfire)
    #expect(g.connectedBuildingIDs == Set([0, 1]))
    #expect(g.isConnectedToCivicCenter(g.state.buildings[1]))
}
@Test func connectedRoadGraphCannotTraverseWaterOrBuildings() throws {
    let c = try connectivityConfiguration()
    var g = try GameEngine(configuration: c, now: connectivityEpoch)
    try g.build(.hut, at: connectivityTile(c, 1))
    try g.build(.hut, at: connectivityTile(c, 4))
    try g.editRoads(at: [connectivityTile(c, 3)], style: .trodden)
    #expect(g.connectedBuildingIDs == [0])
    #expect(throws: GameError.self) { try g.editRoads(at: [connectivityTile(c, 1)], style: .trodden) }
    var water = c
    let tile = connectivityTile(c, 3)
    var row = Array(water.map.rows[tile.y]); row[tile.x] = "w"; water.map.rows[tile.y] = String(row)
    #expect(throws: GameError.self) { try GameEngine(state: g.state, configuration: water) }
}
@Test func connectedRoadGraphRetainsLegacyEconomyWithoutPaths() throws {
    let c = try connectivityConfiguration()
    var g = try GameEngine(configuration: c, now: connectivityEpoch)
    try g.build(.gatheringShelter, at: connectivityTile(c, 3))
    let rates = g.rates
    #expect(g.connectedBuildingIDs == [0])
    try g.editRoads(at: [connectivityTile(c, 1), connectivityTile(c, 2)], style: .trodden)
    #expect(g.connectedBuildingIDs == Set([0, 1]))
    #expect(g.rates == rates)
}
