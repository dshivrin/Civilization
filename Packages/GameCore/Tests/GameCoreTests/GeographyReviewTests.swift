import Foundation
import Testing
@testable import GameCore
import GamePersistence
private let geoReviewEpoch = Date(timeIntervalSince1970:10_000_000)
private func geoReviewBootstrap() throws -> GameEngine {
    var g = try GameEngine(configuration:geographyConfiguration(),now:geoReviewEpoch)
    try g.build(.gatheringShelter,at:Tile(x:10,y:8))
    try g.build(.woodcutter,at:Tile(x:12,y:8))
    try g.setWorkerPriority(buildingID:2,priority:2)
    return g
}
@Test func reviewFreshSettlementCanFundScoutAndRevealWholeValleyWithoutRepeatCharge() throws {
    var g = try geoReviewBootstrap()
    for expedition in 1...2 {
        try g.startExploration()
        g.advance(to:geoReviewEpoch.addingTimeInterval(Double(expedition)*45))
    }
    #expect(g.state.explorationRadius == 11)
    let before = g.state
    #expect(throws:GameError.self) { try g.startExploration() }
    #expect(g.state == before)
    try g.build(.scoutCamp,at:Tile(x:14,y:8))
    #expect(g.explorationIssue != nil) // Camp is still under construction.
    g.advance(to:geoReviewEpoch.addingTimeInterval(150))
    var time = 150.0
    while g.discoveredTileCount < 768 {
        try g.startExploration(); time += 45
        g.advance(to:geoReviewEpoch.addingTimeInterval(time))
    }
    #expect(g.state.explorationRadius == 17)
    #expect(g.state.resources.food >= 0)
    #expect(g.configuration.map.id == before.mapID)
    let complete = g.state
    #expect(throws:GameError.self) { try g.startExploration() }
    #expect(g.state == complete)
    g.advance(to:complete.lastUpdated)
    #expect(g.state == complete)
}
@Test func reviewUnseenForestBonusActivatesExactlyAtExpeditionCompletion() throws {
    var a = try geoReviewBootstrap()
    #expect(a.geographicMultiplier(a.state.buildings[2]) == 1)
    try a.startExploration()
    var b = a
    a.advance(to:geoReviewEpoch.addingTimeInterval(100))
    for second in [19.9,20,44.9,45,45.1,60,100] { b.advance(to:geoReviewEpoch.addingTimeInterval(second)) }
    #expect(a.geographicMultiplier(a.state.buildings[2]) == 1.2)
    #expect(a.state.discoveredTiles == b.state.discoveredTiles)
    #expect(a.state.completedGoals == b.state.completedGoals)
    for r in Resource.allCases { #expect(abs(a.state.resources[r] - b.state.resources[r]) < 1e-6) }
}
@Test func reviewExpeditionTimerSavesAndUsesOfflineCapWithoutClockReplay() throws {
    var c = try geographyConfiguration(); c.offlineCapSeconds = 10
    var a = try GameEngine(configuration:c,now:geoReviewEpoch)
    try a.startExploration()
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("save.json")
    defer { try? FileManager.default.removeItem(at:url.deletingLastPathComponent()) }
    let store = SaveStore(url:url); try store.save(a.state)
    var b = try GameEngine(state:try #require(try store.load(configuration:c)),configuration:c)
    b.advance(to:geoReviewEpoch.addingTimeInterval(10000),offline:true)
    #expect(b.state.explorationRemainingSeconds == 35)
    let applied = b.state
    b.advance(to:geoReviewEpoch.addingTimeInterval(10000),offline:true)
    #expect(b.state == applied)
    b.advance(to:geoReviewEpoch.addingTimeInterval(9999),offline:true)
    #expect(b.state == applied)
}
@Test func reviewSaveRejectsRadiusThatClaimsUnrevealedCompletedRings() throws {
    let c = try geographyConfiguration()
    var state = try GameEngine(configuration:c,now:geoReviewEpoch).state
    state.explorationRadius = 32
    #expect(throws:GameError.self) { try GameEngine(state:state,configuration:c) }
}
