import Foundation
import Testing
@testable import GameCore

private let epoch = Date(timeIntervalSince1970: 1_000_000)
private func game() throws -> GameEngine { try GameEngine(configuration: baselineConfiguration(), now: epoch) }
private let openTiles = [Tile(x: 10, y: 10), Tile(x: 13, y: 10), Tile(x: 10, y: 13), Tile(x: 13, y: 14), Tile(x: 16, y: 14)]

@Test func initialSettlement() throws {
    let g = try game()
    #expect(g.state.resources[.food] == 60)
    #expect(g.state.resources[.wood] == 100)
    #expect(g.state.resources[.stone] == 50)
    #expect(g.state.resources[.knowledge] == 0)
    #expect(g.state.population == 3 && g.housingCapacity == 5)
    #expect(g.state.buildings.count == 1)
    #expect(g.rates[.food] == 2)
}
@Test func fractionsAndFrameIndependence() throws {
    var a = try game(), b = try game()
    for second in 1...60 { a.advance(to: epoch.addingTimeInterval(Double(second))) }
    b.advance(to: epoch.addingTimeInterval(60))
    #expect(abs(a.state.resources[.food] - b.state.resources[.food]) < 0.000001)
    #expect(b.state.resources[.food] == 62)
}
@Test func atomicPlacementValidation() throws {
    var g = try game()
    let original = g.state
    for tile in [Tile(x: -1,y: 2), Tile(x: 31,y: 23), g.state.buildings[0].origin, Tile(x: 0,y: 0), Tile(x: 21,y: 12), Tile(x: 29,y: 2)] {
        #expect(throws: GameError.self) { try g.build(.hut, at: tile) }
        #expect(g.state == original)
    }
    #expect(throws: GameError.self) { try g.build(.storytellingCircle, at: openTiles[0]) }
    #expect(throws: GameError.self) { try g.build(.campfire, at: openTiles[0]) }
    #expect(g.state == original)
}
@Test func costsRatesHousingAndRewards() throws {
    var g = try game()
    try g.build(.gatheringShelter, at: openTiles[0])
    #expect(g.state.resources[.wood] == 95) // 100 - 15 + one-time 10
    #expect(g.rates[.food] == 14)
    try g.build(.gatheringShelter, at: openTiles[1])
    #expect(g.state.resources[.wood] == 80)
    try g.build(.hut, at: openTiles[2])
    #expect(g.housingCapacity == 10)
    #expect(g.state.population == 3)
}
@Test func insufficientFundsDoesNotCharge() throws {
    var g = try game()
    var state = g.state
    state.resources = ResourceAmounts(food: 0, wood: 0, stone: 0, knowledge: 0)
    g = try GameEngine(state: state, configuration: g.configuration)
    #expect(throws: GameError.self) { try g.build(.woodcutter, at: openTiles[0]) }
    #expect(g.state == state)
    #expect(throws: GameError.self) { try g.research() }
    #expect(g.state == state)
}
@Test func researchIsAtomicAndUnique() throws {
    var g = try game()
    try g.research()
    #expect(g.state.resources[.food] == 40 && g.state.resources[.wood] == 90)
    let after = g.state
    #expect(throws: GameError.self) { try g.research() }
    #expect(g.state == after)
    try g.build(.storytellingCircle, at: openTiles[0])
    #expect(g.rates[.knowledge] == 3)
}
@Test func offlineCapAndClockRollback() throws {
    var g = try game()
    g.advance(to: epoch.addingTimeInterval(100_000), offline: true)
    #expect(g.state.resources[.food] == 500)
    let after = g.state
    g.advance(to: epoch.addingTimeInterval(100_000), offline: true)
    #expect(g.state == after)
    g.advance(to: epoch.addingTimeInterval(90_000))
    #expect(g.state == after)
    var s = try game().state
    s.resources[.food] = 0
    var capped = try GameEngine(state: s, configuration: baselineConfiguration())
    capped.advance(to: epoch.addingTimeInterval(100_000), offline: true)
    #expect(capped.state.resources[.food] == 500)
    #expect(capped.state.lastUpdated == epoch.addingTimeInterval(100_000))
    var c = try baselineConfiguration()
    c.offlineCapSeconds = 60
    var limited = try GameEngine(configuration: c, now: epoch)
    limited.advance(to: epoch.addingTimeInterval(600), offline: true)
    #expect(limited.state.resources[.food] == 62)
    limited.advance(to: epoch.addingTimeInterval(601))
    #expect(abs(limited.state.resources[.food] - (62 + 2.0 / 60)) < 0.000001)
}
@Test func seedCanCompleteAndRewardsSurviveReload() throws {
    var g = try game()
    let kinds: [BuildingKind] = [.gatheringShelter, .woodcutter, .hut, .stoneGatherer]
    for (kind, tile) in zip(kinds, openTiles) { try g.build(kind, at: tile) }
    try g.research()
    try g.build(.storytellingCircle, at: openTiles[4])
    g.advance(to: epoch.addingTimeInterval(300))
    #expect(g.state.completedGoals.count == 7)
    #expect(g.currentGoal == nil)
    #expect(g.state.resources[.knowledge] == 15)
    let reloaded = try GameEngine(state: g.state, configuration: g.configuration)
    #expect(reloaded.state == g.state)
}
@Test func configurationRejectsInvalidData() throws {
    var c = try baselineConfiguration()
    c.resourceCap = -1
    #expect(throws: GameError.self) { try c.validate() }
    c = try baselineConfiguration()
    c.buildings[0].width = 0
    #expect(throws: GameError.self) { try c.validate() }
}

@Test func allProductionUsesPerResourceCapacity() throws {
    var g = try game()
    for (kind, tile) in zip([BuildingKind.gatheringShelter, .woodcutter, .hut, .stoneGatherer], openTiles) { try g.build(kind, at: tile) }
    try g.research()
    try g.build(.storytellingCircle, at: openTiles[4])
    g.advance(to: epoch.addingTimeInterval(1_000_000))
    for resource in [Resource.food, .wood, .stone, .knowledge] { #expect(g.state.resources[resource] == 500) }
}
@Test func fullFootprintChecksTerrainAndOccupancy() throws {
    var g = try game()
    let before = g.state
    // Origin is grass but the far column touches the river.
    #expect(throws: GameError.self) { try g.build(.hut, at: Tile(x: 20, y: 12)) }
    // Origin is clear but the far corner covers the campfire.
    #expect(throws: GameError.self) { try g.build(.hut, at: Tile(x: 16, y: 11)) }
    #expect(g.state == before)
}
