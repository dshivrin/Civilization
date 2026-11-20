import Foundation
import Testing
@testable import GameCore

/// Deterministic strategy comparisons use only public commands and unmodified bundled costs.
/// Minute polling intentionally matches the historical serial-route regression.
/// 1: early Natural Knowledge; 2: two circles; 3: three circles; 4: two plus temporary research priority.
@Test(arguments: [1, 2, 3, 4])
func firstEraAlternativeNormalCostStrategies(strategy: Int) throws {
    let epoch = Date(timeIntervalSince1970: 10_000_000)
    var game = try GameEngine(configuration: .bundled(), now: epoch)
    var seconds = 0.0
    var longestWait = 0.0
    var chapterTimes: [Int: Int] = [:]
    var checkpoints: [String] = []
    func tick() {
        seconds += 60
        game.advance(to: epoch.addingTimeInterval(seconds))
        for chapter in game.journeyChapters where chapter.isComplete && chapterTimes[chapter.id] == nil {
            chapterTimes[chapter.id] = Int(seconds)
        }
    }
    func afford(_ cost: ResourceAmounts) throws {
        let began = seconds
        for _ in 0..<500 {
            // Priority is a temporary, reversible player choice; protected survival share stays intact.
            if strategy == 4 {
                let priority = game.state.resources.knowledge < cost.knowledge ? 2 : 1
                for circle in game.state.buildings where circle.kind == .storytellingCircle {
                    try game.setWorkerPriority(buildingID: circle.id, priority: priority)
                }
            }
            if game.canAfford(cost) { break }
            tick()
        }
        longestWait = max(longestWait, seconds - began)
        try #require(game.canAfford(cost), "Strategy \(strategy) stalled at \(Int(seconds))s")
        for circle in game.state.buildings where circle.kind == .storytellingCircle && circle.workerPriority == 2 {
            try game.setWorkerPriority(buildingID: circle.id, priority: 1)
        }
    }
    func build(_ kind: BuildingKind) throws {
        try afford(game.configuration.definition(kind).cost)
        let map = game.configuration.map
        let tile = try #require((0..<map.height).flatMap { y in
            (0..<map.width).map { Tile(x: $0, y: y) }
        }.first { game.placementIssue(kind, at: $0) == nil })
        try game.build(kind, at: tile)
        tick()
    }
    func research(_ id: String) throws {
        let tech = try #require(game.configuration.technologyDefinitions.first { $0.id == id })
        for prerequisite in tech.prerequisites where !game.researchedIDs.contains(prerequisite) { try research(prerequisite) }
        if !game.researchedIDs.contains(id) {
            try afford(tech.cost)
            try game.research(id)
        }
    }
    func checkpoint(_ name: String) {
        checkpoints.append("\(name)=\(Int(seconds))s pop=\(game.state.population) knowledge/min=\(String(format: "%.2f", game.rates.knowledge)) food/min=\(String(format: "%.2f", game.rates.food)) water/min=\(String(format: "%.2f", game.rates[.water])) workers=\(game.workforceAvailable)/\(game.workforceRequired)")
    }
    try build(.gatheringShelter); try build(.woodcutter); try build(.stoneGatherer); try build(.hut)
    try research("oralTradition"); try build(.storytellingCircle)
    try research("fishing"); try build(.fishingShelter); try build(.hut)
    checkpoint("bootstrap")
    let circles = strategy == 3 ? 3 : (strategy == 1 ? 1 : 2)
    for _ in 1..<circles { try build(.storytellingCircle) }
    try research("naturalKnowledge")
    checkpoint("knowledge investment")
    try research("hunting"); try build(.huntingLodge)
    try build(.stoneGatherer); try game.setProductionMode(buildingID: game.state.buildings.last!.id, recipeID: "flint")
    try build(.stoneGatherer); try game.setProductionMode(buildingID: game.state.buildings.last!.id, recipeID: "clay")
    try research("stoneTools"); try build(.toolmaker)
    try research("leatherworking"); try build(.tannery)
    try research("pottery"); try build(.potteryWorkshop); try build(.storehouse)
    checkpoint("craft economy")
    // Fork the earned midgame state: an over-prioritized craft/science sector stalls wood,
    // then ordinary priorities recover it without grants, demolition, or a new save.
    if strategy == 2 {
        var recovery = game
        for building in recovery.state.buildings where [.storytellingCircle, .stoneGatherer, .toolmaker, .tannery, .potteryWorkshop].contains(building.kind) {
            try recovery.setWorkerPriority(buildingID: building.id, priority: 2)
        }
        #expect(recovery.rates.wood <= 0) // Unstaffed extraction cannot cover crafting inputs.
        recovery.advance(to: epoch.addingTimeInterval(seconds + 1200), offline: true)
        #expect(Resource.allCases.allSatisfy { recovery.state.resources[$0] >= 0 })
        #expect(recovery.state.population == game.state.population)
        let woodBeforeRecovery = recovery.state.resources.wood
        for building in recovery.state.buildings { try recovery.setWorkerPriority(buildingID: building.id, priority: 1) }
        let saved = try JSONEncoder().encode(recovery.state)
        recovery = try GameEngine(state: JSONDecoder().decode(GameState.self, from: saved), configuration: recovery.configuration)
        #expect(recovery.rates.wood > 0)
        #expect(recovery.rates.food > 0)
        #expect(recovery.rates[.water] > 0)
        recovery.advance(to: epoch.addingTimeInterval(seconds + 1800), offline: true)
        #expect(recovery.state.resources.wood > woodBeforeRecovery)
        print("PACING recovery: 20min craft/science priority stalled wood; reset priorities + normal-save reload +10min restored wood \(String(format: "%.2f", woodBeforeRecovery))->\(String(format: "%.2f", recovery.state.resources.wood)); population \(recovery.state.population)")
    }
    for technology in game.configuration.technologyDefinitions where !game.researchedIDs.contains(technology.id) { try research(technology.id) }
    try afford(try #require(game.upgradeCost(for: game.state.buildings[0]))); try game.upgrade(buildingID: 0)
    try afford(try #require(game.upgradeCost(for: game.state.buildings[0]))); try game.upgrade(buildingID: 0)
    checkpoint("all research")
    for kind in game.configuration.buildings.map(\.kind) where !game.state.buildings.contains(where: { $0.kind == kind }) { try build(kind) }
    while !game.stoneAgeRequirements.first(where: { $0.id == "discovery" })!.isComplete || game.discoveredTileCount < 600 {
        try afford(game.configuration.explorationRules!.cost)
        try game.startExploration(); tick()
    }
    for _ in 0..<500 {
        if game.state.stoneAgeCompleted == true { break }
        tick()
    }
    #expect(game.fullStoneAgeRequirementsMet)
    #expect(game.state.stoneAgeCompleted == true)
    #expect(game.journeyChapters.allSatisfy { $0.isComplete })
    #expect(game.state.completedPillarGoals?.count == 5)
    #expect(game.constructedKinds == Set(game.configuration.buildings.map(\.kind)))
    #expect(game.researchedIDs == Set(game.configuration.technologyDefinitions.map(\.id)))
    #expect(Resource.allCases.allSatisfy { game.state.resources[$0] >= 0 })
    checkpoint("complete")
    // An unattended interval and encoded normal save preserve progress and further play.
    let ready = game.state
    for _ in 0..<10 { tick() }
    let encoded = try JSONEncoder().encode(game.state)
    let restored = try JSONDecoder().decode(GameState.self, from: encoded)
    game = try GameEngine(state: restored, configuration: game.configuration)
    #expect(game.state.completedPillarGoals == ready.completedPillarGoals)
    #expect(game.state.stoneAgeCompleted == true)
    try build(.hut)
    #expect(game.state.stoneAgeCompleted == true)
    print("PACING strategy=\(strategy) longest cost wait=\(Int(longestWait))s; \(checkpoints.joined(separator: "; ")); chapters=\(chapterTimes.sorted { $0.key < $1.key })")
}
