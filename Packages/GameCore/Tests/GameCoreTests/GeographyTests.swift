import Foundation
import Testing
@testable import GameCore
private let geographyEpoch = Date(timeIntervalSince1970:9_000_000)
@Test func unknownFootprintsCannotChargeAndExplorationRevealsExistingMap() throws {
    var g = try GameEngine(configuration:geographyConfiguration(),now:geographyEpoch)
    let unknown = Tile(x:0,y:23)
    #expect(!g.isDiscovered(unknown))
    let before = g.state
    #expect(throws:GameError.self) { try g.build(.hut,at:unknown) }
    #expect(g.state == before)
    let count = g.discoveredTileCount
    try g.startExploration()
    #expect(g.state.explorationRemainingSeconds == 45)
    let pending = g.state
    #expect(throws:GameError.self) { try g.startExploration() }
    #expect(g.state == pending)
    var b = g
    g.advance(to:geographyEpoch.addingTimeInterval(90),offline:true)
    for i in 1...90 { b.advance(to:geographyEpoch.addingTimeInterval(Double(i))) }
    #expect(g.discoveredTileCount > count)
    #expect(g.state.discoveredTiles == b.state.discoveredTiles)
    #expect(g.configuration.map.rows == b.configuration.map.rows)
    for r in Resource.allCases { #expect(abs(g.state.resources[r]-b.state.resources[r]) < 1e-6) }
}
@Test func unidentifiedAndUndiscoveredDepositsDoNotProduce() throws {
    var c = try geographyConfiguration()
    for i in c.buildings.indices { c.buildings[i].cost = .init(); c.buildings[i].constructionSeconds = 0 }
    c.workforceRules = nil
    var g = try GameEngine(configuration:c,now:geographyEpoch)
    try g.build(.stoneGatherer,at:Tile(x:12,y:12))
    try g.setProductionMode(buildingID:1,recipeID:"flint")
    #expect(g.grossRates[.flint] > 0)
    let deposit = try #require(c.naturalDeposits?.first { $0.resource == .flint })
    var s = g.state; s.discoveredTiles?.remove(deposit.origin)
    g = try GameEngine(state:s,configuration:c)
    #expect(g.grossRates[.flint] == 0)
    c.naturalDeposits![c.naturalDeposits!.firstIndex { $0.id == deposit.id }!].requiredTechnology = "futureMetalworking"
    g = try GameEngine(state:s,configuration:c)
    #expect(!g.isIdentified(depositWithFutureTechnology(c)))
    #expect(g.grossRates[.flint] == 0)
}
private func depositWithFutureTechnology(_ c:GameConfiguration)->NaturalDeposit { c.naturalDeposits!.first { $0.resource == .flint }! }
@Test func fishingNeedsDiscoveredRiverAndCopperRemainsFutureOnly() throws {
    let g = try GameEngine(configuration:geographyConfiguration(),now:geographyEpoch)
    #expect(g.placementIssue(.fishingShelter,at:Tile(x:12,y:12)) != nil)
    #expect(g.placementIssue(.fishingShelter,at:Tile(x:18,y:12)) == nil)
    let copper = try #require(g.configuration.naturalDeposits?.first { $0.kind == "copper" })
    #expect(copper.resource == nil && !g.isIdentified(copper))
}
