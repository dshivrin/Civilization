import Foundation
import Testing
import GameCore
import GamePersistence

private struct GeographyMigrationEnvelope: Codable { var version: Int; var state: GameState }

@Test func workforceSaveMigrationPreservesValleyIdentityAndEarlierVisibility() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at:folder) }
    try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
    let url = folder.appendingPathComponent("settlement-v1.json")
    let epoch = Date(timeIntervalSince1970:5_000_000)
    var old = try GameEngine(configuration:workforceConfiguration(),now:epoch)
    try old.build(.stoneGatherer,at:Tile(x:8,y:8))
    old.advance(to:epoch.addingTimeInterval(20))
    try old.setProductionMode(buildingID:1,recipeID:"flint")
    try old.setWorkerPriority(buildingID:1,priority:2)
    let original = try JSONEncoder().encode(GeographyMigrationEnvelope(version:3,state:old.state))
    try original.write(to:url)
    let store = SaveStore(url:url)
    let config = try geographyConfiguration() // Freeze v4 geography semantics beneath later progression.
    let migrated = try #require(try store.load(configuration:config))
    #expect(migrated.mapID == old.state.mapID)
    #expect(migrated.buildings == old.state.buildings)
    #expect(migrated.resources == old.state.resources)
    #expect(migrated.population == old.state.population)
    #expect(migrated.populationGrowthSeconds == old.state.populationGrowthSeconds)
    #expect(migrated.completedGoals == old.state.completedGoals)
    #expect(migrated.researchedTechnologies == old.state.researchedTechnologies)
    #expect(migrated.depositRemaining == old.state.depositRemaining)
    #expect(migrated.nextBuildingID == old.state.nextBuildingID)
    #expect(migrated.lastUpdated == old.state.lastUpdated)
    #expect(migrated.discoveredTiles?.count == 32*24)
    #expect(migrated.explorationRadius == 32)
    #expect(migrated.explorationRemainingSeconds == nil)
    #expect(try Data(contentsOf:url) == original)
    try store.save(migrated)
    let backup = url.appendingPathExtension("seed-0.2.3.bak")
    #expect(try Data(contentsOf:backup) == original)
    #expect(try JSONDecoder().decode(GeographyMigrationEnvelope.self,from:Data(contentsOf:url)).version == 5)
    try store.save(migrated)
    #expect(try Data(contentsOf:backup) == original)
    #expect(try store.load(configuration:config) == migrated)
}

@Test func explorationSaveRoundTripsPendingExpeditionAndDiscoveryExactly() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("save.json")
    defer { try? FileManager.default.removeItem(at:url.deletingLastPathComponent()) }
    let config = try geographyConfiguration() // Freeze v4 geography semantics beneath later progression.
    let epoch = Date(timeIntervalSince1970:5_000_000)
    var game = try GameEngine(configuration:config,now:epoch)
    try game.startExploration()
    game.advance(to:epoch.addingTimeInterval(7))
    #expect(game.state.explorationRemainingSeconds == 38)
    let store = SaveStore(url:url)
    try store.save(game.state)
    let restored = try #require(try store.load(configuration:config))
    #expect(restored == game.state)
    var resumed = try GameEngine(state:restored,configuration:config)
    resumed.advance(to:epoch.addingTimeInterval(45),offline:true)
    #expect(resumed.state.explorationRemainingSeconds == nil)
    #expect(resumed.state.explorationRadius == 9)
    #expect(resumed.discoveredTileCount > game.discoveredTileCount)
}

@Test func currentExplorationSaveCannotSilentlyRepairMissingOrInvalidProgress() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at:folder) }
    try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
    let url = folder.appendingPathComponent("save.json")
    let config = try geographyConfiguration() // Freeze v4 geography semantics beneath later progression.
    let game = try GameEngine(configuration:config,now:Date(timeIntervalSince1970:5_000_000))
    let store = SaveStore(url:url)
    var cases: [GameState] = []
    var state = game.state; state.discoveredTiles = nil; cases.append(state)
    state = game.state; state.explorationRadius = nil; cases.append(state)
    state = game.state; state.discoveredTiles?.insert(Tile(x:-1,y:0)); cases.append(state)
    state = game.state; state.explorationRadius = 33; cases.append(state)
    state = game.state; state.explorationRemainingSeconds = -1; cases.append(state)
    for invalid in cases {
        let original = try JSONEncoder().encode(GeographyMigrationEnvelope(version:4,state:invalid))
        try original.write(to:url)
        #expect(throws:GameError.self) { try store.load(configuration:config) }
        #expect(try Data(contentsOf:url) == original)
    }
}
