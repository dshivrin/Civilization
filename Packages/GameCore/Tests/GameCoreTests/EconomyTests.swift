import Foundation
import Testing
@testable import GameCore

private let economyEpoch = Date(timeIntervalSince1970: 3_000_000)
private func economyGame() throws -> GameEngine { try GameEngine(configuration: economyConfiguration(), now: economyEpoch) }
private func operational(_ kinds: [BuildingKind]) throws -> GameEngine {
    var c = try economyConfiguration()
    for index in c.buildings.indices { c.buildings[index].constructionSeconds = 0; c.buildings[index].cost = .init() }
    var g = try GameEngine(configuration:c, now:economyEpoch)
    for (index,kind) in kinds.enumerated() { try g.build(kind, at:Tile(x:8+(index%5)*2,y:8+(index/5)*3)) }
    return g
}
@Test func approvedCatalogAndResourcesArePresent() throws {
    let c = try economyConfiguration()
    #expect(c.buildings.count == 20)
    #expect(Resource.allCases.count == 12)
    #expect(c.naturalDeposits!.contains { $0.kind == "copper" && $0.resource == nil })
}
@Test func manufacturingConsumesInputsAndRecoversFromEmptyStocks() throws {
    var g = try operational([.toolmaker])
    var state = g.state
    state.resources[.flint] = 1
    g = try GameEngine(state:state,configuration:g.configuration)
    let wood = state.resources.wood
    g.advance(to:economyEpoch.addingTimeInterval(60))
    #expect(g.state.resources[.stoneTools] > 0)
    #expect(g.state.resources[.flint] == 0)
    #expect(g.state.resources.wood < wood)
    #expect(g.operatingStatus(g.state.buildings.last!).contains("Shortage"))
    var recovered = g.state; recovered.resources[.flint] = 5
    g = try GameEngine(state:recovered,configuration:g.configuration)
    let tools = g.state.resources[.stoneTools]
    g.advance(to:economyEpoch.addingTimeInterval(120))
    #expect(g.state.resources[.stoneTools] > tools)
}
@Test func consumersShareInputsRegardlessOfBuildingArrayOrder() throws {
    var a = try operational([.toolmaker,.toolmaker])
    var state = a.state; state.resources[.flint] = 1
    a = try GameEngine(state:state,configuration:a.configuration)
    state.buildings.reverse()
    var b = try GameEngine(state:state,configuration:a.configuration)
    a.advance(to:economyEpoch.addingTimeInterval(120))
    b.advance(to:economyEpoch.addingTimeInterval(120))
    #expect(a.state.resources == b.state.resources)
    #expect(a.productivity(a.state.buildings[1]) == a.productivity(a.state.buildings[2]))
    #expect(a.state.resources[.flint] == 0)
}
@Test func manufacturingAndMaintenanceStayPartitionIndependent() throws {
    var a = try operational([.stoneGatherer,.toolmaker,.potteryWorkshop])
    try a.setProductionMode(buildingID:1,recipeID:"flint")
    var b = a
    a.advance(to:economyEpoch.addingTimeInterval(600),offline:true)
    for second in 1...600 { b.advance(to:economyEpoch.addingTimeInterval(Double(second))) }
    for r in Resource.allCases { #expect(abs(a.state.resources[r]-b.state.resources[r]) < 0.000001) }
    #expect(a.state.population == b.state.population)
    #expect(a.state.resources[.stoneTools] > 0)
    #expect(a.state.resources[.pottery] == 0) // No clay source yet.
}
@Test func permanentUpgradeIsAtomicAndKeepsIdentity() throws {
    var g = try operational([.woodcutter])
    let id = g.state.buildings.last!.id
    let before = g.grossRates.wood
    try g.upgrade(buildingID:id)
    #expect(g.state.buildings.last?.level == 2)
    #expect(g.state.buildings.last?.id == id)
    #expect(g.grossRates.wood > before)
    var s = g.state; s.resources = .init()
    g = try GameEngine(state:s,configuration:g.configuration)
    #expect(throws:GameError.self) { try g.upgrade(buildingID:id) }
    #expect(g.state == s)
}
@Test func finiteDepositExhaustionPersistsAndSurvivalIsIndependent() throws {
    var g = try operational([.stoneGatherer,.gatheringShelter])
    try g.setProductionMode(buildingID:1,recipeID:"flint")
    var s = g.state
    for key in s.depositRemaining!.keys { s.depositRemaining![key] = 0 }
    g = try GameEngine(state:s,configuration:g.configuration)
    g.advance(to:economyEpoch.addingTimeInterval(600))
    #expect(g.state.resources[.flint] == 0)
    #expect(g.grossRates.food > 0)
    #expect(g.grossRates.wood == 0)
    let restored = try GameEngine(state:g.state,configuration:g.configuration)
    #expect(restored.state.depositRemaining == g.state.depositRemaining)
}
@Test func freshSettlementReachesEveryProductionChainWithRealCosts() throws {
    var g = try economyGame()
    var time = 0.0
    func wait(_ seconds:Double) { time += seconds; g.advance(to:economyEpoch.addingTimeInterval(time)) }
    func construct(_ kind:BuildingKind) throws {
        var attempts = 0
        while !g.canAfford(g.configuration.definition(kind).cost) && attempts < 600 { wait(30); attempts += 1 }
        #expect(g.canAfford(g.configuration.definition(kind).cost))
        let map = g.configuration.map
        let tile = try #require((0..<map.height).flatMap { y in (0..<map.width).map { Tile(x:$0,y:y) } }.first { g.placementIssue(kind,at:$0) == nil })
        try g.build(kind,at:tile); wait(60)
    }
    try construct(.gatheringShelter); try construct(.woodcutter); try construct(.stoneGatherer)
    try construct(.hut); try construct(.huntingLodge); try construct(.fishingShelter)
    try construct(.stoneGatherer); try g.setProductionMode(buildingID:g.state.buildings.last!.id,recipeID:"flint")
    try construct(.stoneGatherer); try g.setProductionMode(buildingID:g.state.buildings.last!.id,recipeID:"clay")
    try construct(.toolmaker); try construct(.tannery); try construct(.potteryWorkshop)
    for kind in [BuildingKind.farm,.animalPen,.storehouse,.healersHut,.shrine,.burialGround,.scoutCamp,.watchtower,.palisade] { try construct(kind) }
    while g.researchIssue("oralTradition") != nil && time < 30_000 { wait(30) }
    try g.research(); try construct(.storytellingCircle); wait(600)
    for r in [Resource.stoneTools,.leather,.pottery,.knowledge,.culture] { #expect(g.state.resources[r] > 0) }
    #expect(Set(g.state.buildings.map(\.kind)).count == 20)
    #expect(g.currentGoal == nil)
}
@Test func modeChangesAndStorageUpgradesAreAtomic() throws {
    var g = try operational([.stoneGatherer,.storehouse,.hut])
    let before = g.state
    #expect(throws:GameError.self) { try g.setProductionMode(buildingID:1,recipeID:"unknown") }
    #expect(g.state == before)
    #expect(g.capacities[.clay] == 750)
    try g.upgrade(buildingID:2)
    #expect(g.capacities[.clay] == 1000)
    let housing = g.housingCapacity
    try g.upgrade(buildingID:3)
    #expect(g.housingCapacity == housing + 5)
}
