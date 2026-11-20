import Foundation
import Testing
import GameCore
import GamePersistence

private struct ProgressionMigrationEnvelope: Codable { var version:Int; var state:GameState }

@Test func geographySaveMigratesWithoutFreeResearchOrLostConstructionKnowledge() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at:folder) }
    try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
    let url = folder.appendingPathComponent("settlement-v1.json")
    let epoch = Date(timeIntervalSince1970:6_000_000)
    var old = try GameEngine(configuration:geographyConfiguration(),now:epoch)
    try old.build(.scoutCamp,at:Tile(x:12,y:10))
    old.advance(to:epoch.addingTimeInterval(30))
    try old.startExploration()
    old.advance(to:epoch.addingTimeInterval(37))
    let original = try JSONEncoder().encode(ProgressionMigrationEnvelope(version:4,state:old.state))
    try original.write(to:url)
    let store = SaveStore(url:url)
    let config = try GameConfiguration.bundled()
    let migrated = try #require(try store.load(configuration:config))
    #expect(migrated.buildings == old.state.buildings)
    #expect(migrated.resources == old.state.resources)
    #expect(migrated.completedGoals == old.state.completedGoals)
    #expect(migrated.researchedTechnologies == old.state.researchedTechnologies)
    #expect(migrated.researchedOralTradition == old.state.researchedOralTradition)
    #expect(migrated.depositRemaining == old.state.depositRemaining)
    #expect(migrated.discoveredTiles == old.state.discoveredTiles)
    #expect(migrated.explorationRadius == old.state.explorationRadius)
    #expect(migrated.explorationRemainingSeconds == old.state.explorationRemainingSeconds)
    #expect(migrated.completedPillarGoals == [])
    #expect(migrated.stoneAgeCompleted == false)
    #expect(migrated.grandfatheredBuildingKinds == [.campfire,.scoutCamp])
    let resumed = try GameEngine(state:migrated,configuration:config)
    #expect(resumed.isUnlocked(.scoutCamp))
    #expect(!resumed.researchedIDs.contains("exploration"))
    #expect(try Data(contentsOf:url) == original)
    try store.save(migrated)
    let backup = url.appendingPathExtension("seed-0.2.4.bak")
    #expect(try Data(contentsOf:backup) == original)
    #expect(try JSONDecoder().decode(ProgressionMigrationEnvelope.self,from:Data(contentsOf:url)).version == 6)
    try store.save(migrated)
    #expect(try Data(contentsOf:backup) == original)
    #expect(try store.load(configuration:config) == migrated)
}

@Test func progressionSaveRoundTripsStickyAchievementHistory() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("save.json")
    defer { try? FileManager.default.removeItem(at:url.deletingLastPathComponent()) }
    var config = try GameConfiguration.bundled()
    config.requiresCompleteStoneAgeCatalog = false // Preserve the historical completion contract under test.
    // Keep genuine permanent witnesses, while isolating sticky resource thresholds.
    for i in config.progressionGoals!.indices {
        config.progressionGoals![i].requiredCivicLevel = nil
        config.progressionGoals![i].requiredBuildings = [.campfire]
        config.progressionGoals![i].requiredTechnologies = ["oralTradition"]
        config.progressionGoals![i].minimumPopulation = 3
        config.progressionGoals![i].minimumDiscoveredTiles = 1
        config.progressionGoals![i].minimumResources = .init(food:30)
        config.progressionGoals![i].minimumNetRates = .init()
    }
    var game = try GameEngine(configuration:config,now:Date(timeIntervalSince1970:6_000_000))
    try game.research("oralTradition")
    #expect(game.state.stoneAgeCompleted == true)
    var state = game.state
    state.resources.food = 0 // Consumed since completion; permanent witnesses still exist.
    let store = SaveStore(url:url)
    try store.save(state)
    #expect(try store.load(configuration:config) == state)
}

@Test func currentProgressionSaveCannotSilentlyRepairMissingHistory() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at:folder) }
    try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
    let url = folder.appendingPathComponent("save.json")
    let config = try GameConfiguration.bundled()
    let game = try GameEngine(configuration:config,now:Date(timeIntervalSince1970:6_000_000))
    let store = SaveStore(url:url)
    var cases:[GameState] = []
    var state = game.state; state.completedPillarGoals = nil; cases.append(state)
    state = game.state; state.stoneAgeCompleted = nil; cases.append(state)
    state = game.state; state.grandfatheredBuildingKinds = nil; cases.append(state)
    for invalid in cases {
        let original = try JSONEncoder().encode(ProgressionMigrationEnvelope(version:5,state:invalid))
        try original.write(to:url)
        #expect(throws:GameError.self) { try store.load(configuration:config) }
        #expect(try Data(contentsOf:url) == original)
    }
}
