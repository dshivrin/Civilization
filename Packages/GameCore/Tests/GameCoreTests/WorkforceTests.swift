import Foundation
import Testing
@testable import GameCore
private let workforceEpoch = Date(timeIntervalSince1970:8_000_000)
private func workforceGame() throws -> GameEngine {
    var c = try workforceConfiguration()
    for i in c.buildings.indices { c.buildings[i].cost = .init(); c.buildings[i].constructionSeconds = 0 }
    var g = try GameEngine(configuration:c,now:workforceEpoch)
    try g.build(.gatheringShelter,at:Tile(x:8,y:8)); try g.build(.woodcutter,at:Tile(x:10,y:8)); try g.build(.stoneGatherer,at:Tile(x:12,y:8))
    return g
}
@Test func automaticWorkersShareShortageAndPrioritiesPreserveSurvival() throws {
    var g = try workforceGame()
    #expect(g.workforceAvailable == 1)
    #expect(g.workforceRequired == 3)
    #expect(g.workersAllocated(to:g.state.buildings[1]) >= 0.5)
    let normal = g.workersAllocated(to:g.state.buildings[2])
    try g.setWorkerPriority(buildingID:2,priority:2)
    #expect(g.workersAllocated(to:g.state.buildings[2]) > normal)
    #expect(g.grossRates.food > g.consumption.food)
    #expect(g.state.resources.food >= 0)
    let before = g.state
    #expect(throws:GameError.self) { try g.setWorkerPriority(buildingID:2,priority:99) }
    #expect(g.state == before)
    var reversed = g.state; reversed.buildings.reverse()
    let b = try GameEngine(state:reversed,configuration:g.configuration)
    #expect(g.grossRates == b.grossRates)
}
@Test func workforceWaterGrowthAndElapsedPartitionsAgree() throws {
    var a = try workforceGame()
    try a.build(.hut,at:Tile(x:14,y:8)); try a.build(.fishingShelter,at:Tile(x:16,y:8))
    var b = a
    a.advance(to:workforceEpoch.addingTimeInterval(2400),offline:true)
    for i in 1...240 { b.advance(to:workforceEpoch.addingTimeInterval(Double(i)*10)) }
    #expect(a.state.population > 3)
    #expect(a.state.population == b.state.population)
    for r in Resource.allCases { #expect(abs(a.state.resources[r]-b.state.resources[r]) < 1e-6) }
}
@Test func noWaterPausesGrowthAndPassiveCollectionRecovers() throws {
    var g = try workforceGame()
    var s = g.state; s.resources[.water] = 0
    g = try GameEngine(state:s,configuration:g.configuration)
    #expect(g.growthStatus == .waterReserve)
    g.advance(to:workforceEpoch.addingTimeInterval(240))
    #expect(g.state.population == 3)
    g.advance(to:workforceEpoch.addingTimeInterval(600))
    #expect(g.state.population > 3)
}
