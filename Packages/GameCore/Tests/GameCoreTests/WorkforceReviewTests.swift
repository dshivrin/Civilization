import Foundation
import Testing
@testable import GameCore
import GamePersistence

private let workerReviewEpoch = Date(timeIntervalSince1970: 9_000_000)
private func reviewBootstrap() throws -> GameEngine {
    var g = try GameEngine(configuration:workforceConfiguration(),now:workerReviewEpoch)
    try g.build(.gatheringShelter,at:Tile(x:8,y:8))
    try g.build(.woodcutter,at:Tile(x:10,y:8))
    try g.build(.hut,at:Tile(x:12,y:8))
    try g.build(.stoneGatherer,at:Tile(x:14,y:8))
    try g.setWorkerPriority(buildingID:1,priority:0)
    try g.setWorkerPriority(buildingID:2,priority:2)
    return g
}
@Test func reviewActualCostBootstrapSurvivesHighNonFoodPriorityAndConstruction() throws {
    var g = try reviewBootstrap()
    #expect(g.workforceRequired == 0) // No benefits or workers during construction.
    #expect(g.state.resources.wood == 40)
    g.advance(to:workerReviewEpoch.addingTimeInterval(20))
    #expect(g.workforceRequired == 3)
    #expect(g.workersAllocated(to:g.state.buildings[1]) == 0.5)
    #expect(g.workersAllocated(to:g.state.buildings[2]) == 0.5)
    #expect(g.rates.food > 0)
    let wood = g.state.resources.wood
    g.advance(to:workerReviewEpoch.addingTimeInterval(2400),offline:true)
    #expect(g.state.population > 3)
    #expect(g.state.resources.wood > wood)
    #expect(g.state.resources.food > 0)
    #expect(Resource.allCases.allSatisfy { g.state.resources[$0] >= 0 })
}
@Test func reviewPriorityAndPendingConstructionSurviveSaveWithEquivalentCatchup() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("save.json")
    defer { try? FileManager.default.removeItem(at:url.deletingLastPathComponent()) }
    var a = try reviewBootstrap()
    a.advance(to:workerReviewEpoch.addingTimeInterval(7))
    let store = SaveStore(url:url)
    try store.save(a.state)
    let loaded = try #require(try store.load(configuration:a.configuration))
    #expect(loaded.buildings[1].workerPriority == 0)
    #expect(loaded.buildings[2].workerPriority == 2)
    #expect(loaded.buildings[2].constructionRemainingSeconds == 13)
    var b = try GameEngine(state:loaded,configuration:a.configuration)
    a.advance(to:workerReviewEpoch.addingTimeInterval(2000),offline:true)
    for second in [8.1,21.5,100,400.3,520,800.6,1120,2000] { b.advance(to:workerReviewEpoch.addingTimeInterval(second)) }
    #expect(a.state.population == b.state.population)
    #expect(abs((a.state.populationGrowthSeconds ?? 0) - (b.state.populationGrowthSeconds ?? 0)) < 1e-6)
    for r in Resource.allCases { #expect(abs(a.state.resources[r] - b.state.resources[r]) < 1e-6) }
}
@Test func reviewWaterReserveBoundaryPreservesEarnedGrowthExactly() throws {
    var g = try reviewBootstrap()
    g.advance(to:workerReviewEpoch.addingTimeInterval(20))
    var state = g.state
    state.resources[.water] = 9
    state.populationGrowthSeconds = 30
    g = try GameEngine(state:state,configuration:g.configuration)
    #expect(g.growthStatus == .waterReserve)
    g.advance(to:workerReviewEpoch.addingTimeInterval(60)) // 40 seconds at +1.5 water/min.
    #expect(abs(g.state.resources[.water] - 10) < 1e-8)
    #expect(g.state.populationGrowthSeconds == 30)
    #expect(g.growthStatus == .growing)
    g.advance(to:workerReviewEpoch.addingTimeInterval(150))
    #expect(g.state.population == 4)
    #expect(abs(g.state.populationGrowthSeconds ?? -1) < 1e-8)
}
@Test func reviewInvalidPrioritySaveIsRejectedWithoutChangingDisk() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("save.json")
    defer { try? FileManager.default.removeItem(at:url.deletingLastPathComponent()) }
    let g = try reviewBootstrap()
    var state = g.state; state.buildings[1].workerPriority = -1
    let store = SaveStore(url:url)
    try store.save(state)
    let original = try Data(contentsOf:url)
    #expect(throws:GameError.self) { try store.load(configuration:g.configuration) }
    #expect(try Data(contentsOf:url) == original)
}
