import Foundation
import Testing
@testable import GameCore

private let start = Date(timeIntervalSince1970: 2_000_000)
private let shelter = Tile(x: 10, y: 10)
private let woodcutter = Tile(x: 13, y: 10)
private func foundationGame(_ configuration: GameConfiguration? = nil) throws -> GameEngine {
    try GameEngine(configuration: configuration ?? foundationConfiguration(), now: start)
}

@Test func constructionChargesReservesAndCompletesBeforeBenefits() throws {
    var g = try foundationGame()
    try g.build(.gatheringShelter, at: shelter)
    #expect(g.state.resources[.wood] == 85)
    #expect(g.grossRates[.food] == 2)
    #expect(!g.state.completedGoals.contains(.gatheringShelter))
    let id = g.state.buildings.last!.id
    #expect(g.placementIssue(.hut, at: shelter) != nil)
    g.advance(to: start.addingTimeInterval(19))
    #expect(g.grossRates[.food] == 2)
    g.advance(to: start.addingTimeInterval(20))
    #expect(g.grossRates[.food] == 14)
    #expect(g.state.resources[.wood] == 95)
    #expect(g.state.buildings.last?.id == id)
    #expect(g.state.buildings.last?.isOperational == true)
    #expect(g.state.completedGoals.contains(.gatheringShelter))
    g.advance(to: start.addingTimeInterval(60))
    #expect(abs(g.state.resources[.food] - 67) < 0.000001)
    #expect(g.state.resources[.wood] == 95)
}
@Test func populationConsumptionAndHousingAreEventDriven() throws {
    var g = try foundationGame()
    #expect(g.consumption[.food] == 3 && g.rates[.food] == -1)
    try g.build(.gatheringShelter, at: shelter)
    g.advance(to: start.addingTimeInterval(139))
    #expect(g.state.population == 3)
    g.advance(to: start.addingTimeInterval(140))
    #expect(g.state.population == 4 && g.consumption[.food] == 4)
    g.advance(to: start.addingTimeInterval(300))
    #expect(g.state.population == 5)
    #expect(g.growthStatus == .housingFull)
    #expect(abs(g.state.resources[.food] - (107 + 2.0 / 3)) < 0.000001)
    try g.build(.hut, at: woodcutter)
    #expect(g.housingCapacity == 5)
    g.advance(to: start.addingTimeInterval(315))
    #expect(g.housingCapacity == 10)
}
@Test func foodExhaustionHasNoDeathsOrNegativeBalances() throws {
    var g = try foundationGame()
    g.advance(to: start.addingTimeInterval(100_000), offline: true)
    #expect(g.state.resources[.food] == 0)
    #expect(g.state.population == 3)
    #expect(g.growthStatus == .foodReserve)
}
@Test func thresholdCrossingAndPartitionedSimulationAgree() throws {
    var config = try foundationConfiguration()
    config.initialResources.food = 0
    var one = try foundationGame(config), many = try foundationGame(config)
    try one.build(.gatheringShelter, at: shelter)
    try many.build(.gatheringShelter, at: shelter)
    one.advance(to: start.addingTimeInterval(249), offline: true)
    #expect(one.state.population == 3)
    one.advance(to: start.addingTimeInterval(250), offline: true)
    for index in 1...1000 { many.advance(to: start.addingTimeInterval(Double(index) / 4)) }
    #expect(one.state.population == 4 && many.state.population == 4)
    #expect(abs(one.state.resources.food - many.state.resources.food) < 0.000001)
    #expect(abs((one.state.populationGrowthSeconds ?? 0) - (many.state.populationGrowthSeconds ?? 0)) < 0.000001)
}
@Test func growthProgressPausesAndResumes() throws {
    var g = try foundationGame()
    try g.build(.gatheringShelter, at: shelter)
    g.advance(to: start.addingTimeInterval(80)) // 60 eligible seconds
    var paused = g.state
    paused.resources.food = 0
    g = try GameEngine(state: paused, configuration: g.configuration)
    g.advance(to: start.addingTimeInterval(140)) // only 11 food; no new eligible time
    #expect(g.state.populationGrowthSeconds == 60)
    g.advance(to: start.addingTimeInterval(250))
    #expect(g.state.population == 4)
}
@Test func researchPrerequisitesModifiersAndRepeatedPurchases() throws {
    var c = try foundationConfiguration()
    c.initialResources.knowledge = 100
    c.resourceCaps = ResourceAmounts(food: 500, wood: 750, stone: 500, knowledge: 500)
    var g = try foundationGame(c)
    let before = g.state
    #expect(throws: GameError.self) { try g.research("stoneTools") }
    #expect(g.state == before)
    try g.research("oralTradition")
    try g.build(.woodcutter, at: woodcutter)
    g.advance(to: start.addingTimeInterval(20))
    try g.research("stoneTools")
    #expect(g.grossRates.wood == 12)
    #expect(g.capacities.wood == 750)
    let after = g.state
    #expect(throws: GameError.self) { try g.research("stoneTools") }
    #expect(g.state == after)
    try g.research("socialOrder")
    #expect(g.growthIntervalSeconds == 90)
}
@Test func simultaneousEventsAndOfflineCapDoNotDuplicateTime() throws {
    var c = try foundationConfiguration()
    c.offlineCapSeconds = 10
    var g = try foundationGame(c)
    try g.build(.gatheringShelter, at: shelter)
    g.advance(to: start.addingTimeInterval(100), offline: true)
    #expect(g.state.buildings.last?.constructionRemainingSeconds == 10)
    #expect(g.grossRates.food == 2)
    let after = g.state
    g.advance(to: start.addingTimeInterval(100), offline: true)
    g.advance(to: start.addingTimeInterval(90))
    #expect(g.state == after)
    g.advance(to: start.addingTimeInterval(110))
    #expect(g.grossRates.food == 14)
    #expect(g.state.population == 3)
}
@Test func currentSeedStillCompletesWithoutDeadlock() throws {
    var g = try foundationGame()
    let tiles = [shelter, woodcutter, Tile(x:10,y:13), Tile(x:13,y:14)]
    for (kind, tile) in zip([BuildingKind.gatheringShelter,.woodcutter,.hut,.stoneGatherer], tiles) { try g.build(kind, at: tile) }
    try g.research("oralTradition")
    try g.build(.storytellingCircle, at: Tile(x:16,y:14))
    g.advance(to: start.addingTimeInterval(330))
    #expect(g.currentGoal == nil)
    #expect(g.state.completedGoals.count == 7)
    #expect(g.state.resources.knowledge == 15)
    #expect(g.state.population > 3)
}
@Test func configurationRejectsBrokenResearchAndNumericRules() throws {
    var c = try foundationConfiguration()
    c.technologies![0].prerequisites = ["stoneTools"]
    #expect(throws: GameError.self) { try c.validate() }
    c = try foundationConfiguration()
    c.technologies![1].prerequisites = ["missing"]
    #expect(throws: GameError.self) { try c.validate() }
    c = try foundationConfiguration()
    c.populationRules!.growthIntervalSeconds = 0
    #expect(throws: GameError.self) { try c.validate() }
    c = try foundationConfiguration()
    c.buildings[1].constructionSeconds = -1
    #expect(throws: GameError.self) { try c.validate() }
}

@Test func researchCapacityAndConstructionModifiersApplyOnce() throws {
    var c = try foundationConfiguration()
    c.initialResources.knowledge = 100
    c.technologies![1].effects.storageBonus.wood = 250
    c.technologies![1].effects.constructionDurationMultiplier = 0.8
    var g = try foundationGame(c)
    try g.research()
    try g.research("stoneTools")
    #expect(g.capacities.wood == 750)
    try g.build(.hut, at: shelter)
    #expect(g.state.buildings.last?.constructionRemainingSeconds == 12)
    g.advance(to: start.addingTimeInterval(12))
    #expect(g.housingCapacity == 10)
}
@Test func growthAndConstructionAtSameInstantMatchPartitionedUpdates() throws {
    var c = try foundationConfiguration()
    c.buildings[1].constructionSeconds = 140
    var one = try foundationGame(c), many = try foundationGame(c)
    for kind in [BuildingKind.gatheringShelter, .hut] {
        let tile = kind == .hut ? woodcutter : shelter
        try one.build(kind, at: tile); try many.build(kind, at: tile)
    }
    one.advance(to: start.addingTimeInterval(600), offline: true)
    for second in 1...600 { many.advance(to: start.addingTimeInterval(Double(second))) }
    #expect(one.state.population == many.state.population)
    #expect(one.housingCapacity == 10)
    #expect(one.state.buildings == many.state.buildings)
    #expect(one.state.completedGoals == many.state.completedGoals)
    for r in Resource.allCases { #expect(abs(one.state.resources[r] - many.state.resources[r]) < 0.000001) }
}
@Test func pausedGrowthCanBeSavedAfterResearchShortensInterval() throws {
    var c = try foundationConfiguration()
    c.initialResources.knowledge = 100
    var g = try foundationGame(c)
    try g.research()
    var s = g.state
    s.populationGrowthSeconds = 110
    g = try GameEngine(state: s, configuration: c)
    try g.research("socialOrder") // Net food is negative; preserve earned progress while paused.
    let restored = try GameEngine(state: g.state, configuration: c)
    #expect(restored.state.populationGrowthSeconds == 110)
}

@Test func effectiveCapacitiesValidateProgressionAndStartingBalances() throws {
    var c = try foundationConfiguration()
    c.resourceCaps = ResourceAmounts(food:500,wood:750,stone:500,knowledge:10)
    #expect(throws: GameError.self) { try c.validate() }
    c.resourceCaps!.knowledge = 500
    c.initialResources.wood = 600
    try c.validate()
    let g = try foundationGame(c)
    #expect(g.state.resources.wood == 600 && g.capacities.wood == 750)
}

@Test func oppositeTechnologyMultipliersCannotHideOverflow() throws {
    var c = try foundationConfiguration()
    c.technologies![1].effects.constructionDurationMultiplier = 1e308
    c.technologies![2].effects.constructionDurationMultiplier = 1e-308
    #expect(throws: GameError.self) { try c.validate() }
    c = try foundationConfiguration()
    c.technologies![1].effects.growthIntervalMultiplier = 1e308
    c.technologies![2].effects.growthIntervalMultiplier = 1e-308
    #expect(throws: GameError.self) { try c.validate() }
}
@Test func pausedGrowthFromEarlierLongerIntervalSurvivesResearchAndReload() throws {
    var c = try foundationConfiguration()
    c.initialResources.knowledge = 100
    c.technologies![1].effects.growthIntervalMultiplier = 2
    var g = try foundationGame(c)
    try g.research(); try g.research("stoneTools")
    var state = g.state
    state.populationGrowthSeconds = 200
    state.resources.food = 0
    g = try GameEngine(state: state, configuration: c)
    try g.research("socialOrder")
    #expect(g.growthIntervalSeconds == 180)
    let restored = try GameEngine(state: g.state, configuration: c)
    #expect(restored.state.populationGrowthSeconds == 200)
}
