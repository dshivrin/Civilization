import Foundation
import Testing
@testable import GameCore
import GamePersistence

private func pilotConfiguration() throws -> GameConfiguration {
    var c = try connectivityConfiguration(); c.populationRules?.foodPerPersonPerMinute = 0
    return c
}
private func pilot(_ engine: GameEngine) throws -> GameEngine {
    var state = engine.state; state.operatingRules = .connectedPathsV1
    return try GameEngine(state: state, configuration: engine.configuration)
}
@Test func connectivityPilotStopsAndRestartsOutputsInputsAndDepositUse() throws {
    var c = try pilotConfiguration()
    for i in c.naturalDeposits!.indices where c.naturalDeposits![i].resource == .stone {
        c.naturalDeposits![i].origin = connectivityTile(c, 3); c.naturalDeposits![i].radius = 8
        c.naturalDeposits![i].accessSites = nil
    }
    var g = try GameEngine(configuration: c, now: connectivityEpoch)
    try g.build(.stoneGatherer, at: connectivityTile(c, 3))
    g = try pilot(g)
    let before = g.state
    #expect(g.productivity(g.state.buildings[1]) == 0)
    #expect(g.operatingStatus(g.state.buildings[1]).contains("Not connected"))
    #expect(g.producingBuildingCount(for: .stone) == 0)
    g.advance(to: connectivityEpoch.addingTimeInterval(60))
    #expect(g.state.resources.stone == before.resources.stone)
    #expect(g.state.depositRemaining == before.depositRemaining)
    #expect(g.grossRates.food == 2 && g.grossRates[.water] == 3)
    try g.editRoads(at: [connectivityTile(c, 1), connectivityTile(c, 2)], style: .trodden)
    #expect(g.producingBuildingCount(for: .stone) == 1)
    g.advance(to: connectivityEpoch.addingTimeInterval(120))
    #expect(g.state.resources.stone > before.resources.stone)
    #expect(g.state.depositRemaining != before.depositRemaining)
}
@Test func connectivityPilotDisconnectedWorkshopConsumesNoInputsOrMaintenance() throws {
    let c = try pilotConfiguration()
    var g = try GameEngine(configuration: c, now: connectivityEpoch)
    try g.build(.toolmaker, at: connectivityTile(c, 3))
    var state = g.state; state.resources[.flint] = 50
    g = try pilot(GameEngine(state: state, configuration: c))
    let before = g.state.resources
    g.advance(to: connectivityEpoch.addingTimeInterval(60))
    #expect(g.state.resources.wood == before.wood && g.state.resources[.flint] == before[.flint])
    #expect(g.state.resources[.stoneTools] == 0)
    try g.editRoads(at: [connectivityTile(c, 1), connectivityTile(c, 2)], style: .dirt)
    g.advance(to: connectivityEpoch.addingTimeInterval(120))
    #expect(g.state.resources[.stoneTools] > 0)
    #expect(g.state.resources.wood < before.wood)
}
@Test func connectivityPilotRedistributesWorkersAndKeepsIntrinsicCivicOutput() throws {
    var c = try pilotConfiguration(); c.workforceRules = try GameConfiguration.bundled().workforceRules
    var g = try GameEngine(configuration: c, now: connectivityEpoch)
    try g.build(.gatheringShelter, at: connectivityTile(c, 3))
    try g.build(.woodcutter, at: connectivityTile(c, 3, 3))
    try g.editRoads(at: [connectivityTile(c, 1), connectivityTile(c, 2)], style: .trodden)
    g = try pilot(g)
    #expect(g.workersAllocated(to: g.state.buildings[1]) == 1)
    #expect(g.workersAllocated(to: g.state.buildings[2]) == 0)
    #expect(g.workforceProductivity(g.state.buildings[2]) == 0)
    var civic = try GameEngine(configuration: c, now: connectivityEpoch)
    try civic.research("oralTradition"); try civic.upgrade(buildingID: 0)
    civic = try pilot(civic)
    #expect(civic.grossRates.knowledge > 0 && civic.grossRates[.culture] > 0)
    #expect(civic.grossRates.food == 2 && civic.grossRates[.water] == 3 && civic.housingCapacity == 5)
}
@Test func connectivityPilotRetainsOverCapStocksAcrossTickCreditsSpendingAndReload() throws {
    var c = try pilotConfiguration()
    c.buildings[c.buildings.firstIndex { $0.kind == .hut }!].cost.wood = 20
    var g = try GameEngine(configuration: c, now: connectivityEpoch)
    try g.build(.storehouse, at: connectivityTile(c, 3))
    let retained = c.baseCapacities.wood + (c.definition(.storehouse).storageBonus?.wood ?? 0) / 2
    var state = g.state; state.resources.wood = retained
    g = try pilot(GameEngine(state: state, configuration: c))
    #expect(g.capacities.wood == 500)
    #expect((c.baseCapacities.wood + (c.definition(.storehouse).storageBonus?.wood ?? 0)) >= retained)
    g.advance(to: connectivityEpoch.addingTimeInterval(60))
    #expect(g.state.resources.wood == retained)
    try g.build(.hut, at: connectivityTile(c, 6)) // One-time reward must not destroy or increase overflow.
    #expect(g.state.resources.wood == retained - 20)
    #if DEBUG
    g.developerAddResources(250); #expect(g.state.resources.wood == retained - 20)
    #endif
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let store = SaveStore(url: folder.appendingPathComponent("save.json")); try store.save(g.state)
    #expect(try store.load(configuration: c) == g.state)
    var bad = g.state; bad.resources.wood = (c.baseCapacities.wood + (c.definition(.storehouse).storageBonus?.wood ?? 0)) + 1
    #expect(throws: GameError.self) { try GameEngine(state: bad, configuration: c) }
    try g.editRoads(at: [connectivityTile(c, 1), connectivityTile(c, 2)], style: .stone)
    #expect(g.capacities.wood == (c.baseCapacities.wood + (c.definition(.storehouse).storageBonus?.wood ?? 0)) && g.state.resources.wood == retained - 20)
}
@Test func connectivityPilotCompletesDisconnectedConstructionWithoutEviction() throws {
    var c = try pilotConfiguration(); c.populationRules = try GameConfiguration.bundled().populationRules
    c.buildings[c.buildings.firstIndex { $0.kind == .hut }!].constructionSeconds = 10
    var g = try GameEngine(configuration: c, now: connectivityEpoch)
    try g.build(.hut, at: connectivityTile(c, 3)); g = try pilot(g)
    g.advance(to: connectivityEpoch.addingTimeInterval(10))
    #expect(g.state.buildings[1].isOperational && g.housingCapacity == 5)
    try g.editRoads(at: [connectivityTile(c, 1), connectivityTile(c, 2)], style: .trodden)
    #expect(g.housingCapacity == 10)
    var state = g.state; state.population = 8
    g = try GameEngine(state: state, configuration: c)
    try g.editRoads(at: [connectivityTile(c, 1)], style: nil)
    #expect(g.housingCapacity == 5 && g.growthStatus == .housingFull)
    g.advance(to: connectivityEpoch.addingTimeInterval(600))
    #expect(g.state.population == 8)
}
@Test func connectivityPilotScoutDispatchNeedsPathButPaidExpeditionSurvivesDisconnection() throws {
    var c = try pilotConfiguration(); c.explorationRules = try GameConfiguration.bundled().explorationRules
    let rules = try #require(c.explorationRules)
    var g = try GameEngine(configuration: c, now: connectivityEpoch)
    try g.build(.scoutCamp, at: connectivityTile(c, 3))
    var state = g.state; state.explorationRadius = rules.requiresScoutAfterRadius
    state.discoveredTiles?.formUnion(c.tiles(within: rules.requiresScoutAfterRadius))
    g = try pilot(GameEngine(state: state, configuration: c))
    let before = g.state
    #expect(throws: GameError.self) { try g.startExploration() }
    #expect(g.state == before)
    try g.editRoads(at: [connectivityTile(c, 1), connectivityTile(c, 2)], style: .trodden)
    try g.startExploration(); let dispatched = g.state
    try g.editRoads(at: [connectivityTile(c, 1)], style: nil)
    g.advance(to: connectivityEpoch.addingTimeInterval(rules.durationSeconds))
    #expect(g.state.explorationRemainingSeconds == nil)
    #expect(g.discoveredTileCount > (dispatched.discoveredTiles?.count ?? 0))
    #expect(abs(g.state.resources.food - (dispatched.resources.food + 2 * rules.durationSeconds / 60)) < 1e-8)
}
@Test func connectivityPilotTickAndOfflineAgreeAndHistorySurvivesDisconnection() throws {
    let c = try pilotConfiguration()
    var g = try GameEngine(configuration: c, now: connectivityEpoch)
    try g.build(.gatheringShelter, at: connectivityTile(c, 3))
    try g.editRoads(at: [connectivityTile(c, 1), connectivityTile(c, 2)], style: .trodden)
    g = try pilot(g)
    let earned = g.state.completedGoals
    try g.editRoads(at: [connectivityTile(c, 1)], style: nil)
    var small = g, offline = g
    for second in 1...60 { small.advance(to: connectivityEpoch.addingTimeInterval(Double(second))) }
    offline.advance(to: connectivityEpoch.addingTimeInterval(60), offline: true)
    for resource in Resource.allCases { #expect(abs(small.state.resources[resource] - offline.state.resources[resource]) < 1e-8) }
    #expect(offline.state.completedGoals == earned)
}

@Test func connectivityPilotReserveAndGuidanceDoNotCountDisconnectedSuppliers() throws {
    var c = try GameConfiguration.bundled()
    c.map.rows = Array(repeating: String(repeating: "c", count: c.map.width), count: c.map.height)
    c.explorationRules = nil; c.progressionGoals = nil
    var g = try GameEngine(configuration: c, now: connectivityEpoch)
    try g.build(.woodcutter, at: connectivityTile(c, 3))
    g.advance(to: connectivityEpoch.addingTimeInterval(60))
    var state = g.state; state.resources.wood = 20
    let legacy = try GameEngine(state: state, configuration: c)
    #expect(legacy.bootstrapRequirement(for: c.definition(.hut).cost, constructing: .hut) == nil)
    g = try pilot(legacy)
    #expect(g.bootstrapRequirement(for: c.definition(.hut).cost, constructing: .hut) == .woodcutter)
    #expect(g.guidance(for: "building-woodcutter").action == .inspect(1))
    #expect(g.guidance(for: "building-woodcutter").title == "Connect Woodcutter")
    try g.editRoads(at: [connectivityTile(c, 1), connectivityTile(c, 2)], style: .trodden)
    #expect(g.bootstrapRequirement(for: c.definition(.hut).cost, constructing: .hut) == nil)
}

@Test func connectivityPilotRoadCommitCapturesNewPillarBeforeDisconnectAndReload() throws {
    var c = try connectivityConfiguration()
    let base = try GameConfiguration.bundled()
    c.progressionGoals = base.progressionGoals; c.explorationRules = base.explorationRules
    var g = try GameEngine(configuration: c, now: connectivityEpoch)
    try g.build(.gatheringShelter, at: connectivityTile(c, 3))
    try g.build(.hut, at: connectivityTile(c, 3, 3))
    var state = g.state; state.population = 10
    g = try pilot(GameEngine(state: state, configuration: c))
    #expect(!g.isPillarGoalComplete(id: "populationFoundation"))
    try g.editRoads(at: [connectivityTile(c, 1), connectivityTile(c, 2)], style: .trodden)
    #expect(g.isPillarGoalComplete(id: "populationFoundation"))
    try g.editRoads(at: [connectivityTile(c, 1)], style: nil)
    #expect(g.isPillarGoalComplete(id: "populationFoundation"))
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let store = SaveStore(url: folder.appendingPathComponent("save.json")); try store.save(g.state)
    let loaded = try GameEngine(state: #require(try store.load(configuration: c)), configuration: c)
    #expect(loaded.isPillarGoalComplete(id: "populationFoundation"))
}
