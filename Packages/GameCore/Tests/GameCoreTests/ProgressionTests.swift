import Foundation
import Testing
import GamePersistence
@testable import GameCore
private let progressionEpoch = Date(timeIntervalSince1970:10_000_000)
@Test func researchGatesAreAtomicAndFivePillarsAreConfigured() throws {
    var c = try GameConfiguration.bundled(); c.initialResources.knowledge = 100
    var g = try GameEngine(configuration:c,now:progressionEpoch)
    #expect(Set(g.pillarGoals.map(\.pillar)) == Set(DevelopmentPillar.allCases))
    #expect(!g.isUnlocked(.huntingLodge))
    let before = g.state
    #expect(throws:GameError.self) { try g.build(.huntingLodge,at:Tile(x:12,y:12)) }
    #expect(g.state == before)
    try g.research("oralTradition"); try g.research("hunting")
    #expect(g.isUnlocked(.huntingLodge))
    let researched = g.state
    #expect(throws:GameError.self) { try g.research("hunting") }
    #expect(g.state == researched)
}
@Test func pillarCompletionIsStickyAndDoesNotGrantRepeatRewards() throws {
    var c = try GameConfiguration.bundled()
    c.requiresCompleteStoneAgeCatalog = false // Historical five-pillar contract, retained as a regression.
    for i in c.progressionGoals!.indices {
        c.progressionGoals![i].requiredBuildings = []; c.progressionGoals![i].requiredTechnologies = []
        c.progressionGoals![i].minimumPopulation = 0; c.progressionGoals![i].minimumResources = .init()
        c.progressionGoals![i].minimumNetRates = .init(); c.progressionGoals![i].minimumDiscoveredTiles = 0
    }
    var g = try GameEngine(configuration:c,now:progressionEpoch)
    g.advance(to:progressionEpoch.addingTimeInterval(1))
    #expect(g.state.stoneAgeCompleted == true)
    #expect(g.state.completedPillarGoals?.count == 5)
    let wood = g.state.resources.wood
    g.advance(to:progressionEpoch.addingTimeInterval(20))
    #expect(g.state.resources.wood == wood)
    try g.build(.hut,at:Tile(x:12,y:12))
    #expect(g.state.stoneAgeCompleted == true) // Sandbox stays playable.
}
@Test func freshStoneAgeCompletesThroughRealResearchAndProduction() throws {
    var g = try GameEngine(configuration:.bundled(),now:progressionEpoch)
    var time = 0.0
    func wait(_ seconds:Double = 60) { time += seconds; g.advance(to:progressionEpoch.addingTimeInterval(time)) }
    func afford(_ cost:ResourceAmounts) throws {
        var attempts = 0
        while !g.canAfford(cost) && attempts < 3000 { wait(); attempts += 1 }
        #expect(g.canAfford(cost))
    }
    func construct(_ kind:BuildingKind) throws {
        try afford(g.configuration.definition(kind).cost)
        let map = g.configuration.map
        let tile = try #require((0..<map.height).flatMap { y in (0..<map.width).map { Tile(x:$0,y:y) } }.first { g.placementIssue(kind,at:$0) == nil })
        try g.build(kind,at:tile); wait(60)
        print("PLAYTHROUGH build \(kind.rawValue) at \(Int(time))s")
    }
    func research(_ id:String) throws {
        let tech = try #require(g.configuration.technologyDefinitions.first { $0.id == id })
        for prerequisite in tech.prerequisites where !g.researchedIDs.contains(prerequisite) { try research(prerequisite) }
        if !g.researchedIDs.contains(id) { try afford(tech.cost); try g.research(id); print("PLAYTHROUGH research \(id) at \(Int(time))s") }
    }
    try construct(.gatheringShelter); try construct(.woodcutter); try construct(.stoneGatherer); try construct(.hut)
    try research("oralTradition"); try construct(.storytellingCircle)
    try research("fishing"); try construct(.fishingShelter); try construct(.hut)
    try research("hunting"); try construct(.huntingLodge)
    try construct(.stoneGatherer); try g.setProductionMode(buildingID:g.state.buildings.last!.id,recipeID:"flint")
    try construct(.stoneGatherer); try g.setProductionMode(buildingID:g.state.buildings.last!.id,recipeID:"clay")
    try research("stoneTools"); try construct(.toolmaker)
    try research("leatherworking"); try construct(.tannery)
    try research("pottery"); try construct(.potteryWorkshop); try construct(.storehouse)
    // Complete every catalog entry; all are required in Seed 0.2.7.
    for tech in g.configuration.technologyDefinitions where !g.researchedIDs.contains(tech.id) { try research(tech.id) }
    for kind in g.configuration.buildings.map(\.kind) where !g.state.buildings.contains(where: { $0.kind == kind }) { try construct(kind) }
    while !g.stoneAgeRequirements.first(where: { $0.id == "discovery" })!.isComplete || g.discoveredTileCount < 600 { try afford(g.configuration.explorationRules!.cost); try g.startExploration(); wait(60) }
    var attempts = 0
    while g.state.stoneAgeCompleted != true && attempts < 3000 { wait(); attempts += 1 }
    #expect(g.state.stoneAgeCompleted == true)
    #expect(g.state.completedPillarGoals?.count == 5)
    #expect(g.fullStoneAgeRequirementsMet)
    #expect(g.journeyChapters.allSatisfy { $0.isComplete })
    #expect(g.constructedKinds == Set(g.configuration.buildings.map(\.kind)))
    #expect(g.researchedIDs == Set(g.configuration.technologyDefinitions.map(\.id)))
    #expect(g.discoveredTileCount < g.configuration.map.width * g.configuration.map.height)
    #expect(g.state.population >= 10)
    #expect(Resource.allCases.allSatisfy { g.state.resources[$0] >= 0 })
    print("PLAYTHROUGH complete at \(Int(time))s; population \(g.state.population); buildings \(g.state.buildings.count); technologies \(g.researchedIDs.count); discovered \(g.discoveredTileCount)")
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at:folder) }
    let store = SaveStore(url:folder.appendingPathComponent("save.json"))
    try store.save(g.state)
    if let artifact = ProcessInfo.processInfo.environment["CIVILIZATION_PLAYTHROUGH_SAVE"] {
        try SaveStore(url:URL(fileURLWithPath:artifact)).save(g.state)
    }
    let restored = try #require(try store.load(configuration:g.configuration))
    #expect(restored == g.state)
    g = try GameEngine(state:restored,configuration:g.configuration)
    try construct(.hut)
    #expect(g.state.stoneAgeCompleted == true)
    #expect(g.state.completedPillarGoals == restored.completedPillarGoals)
}
