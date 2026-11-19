import Foundation
import Testing
import GameCore
import GamePersistence

private struct EconomyMigrationEnvelope: Codable {
    var version: Int
    var state: GameState
}

@Test func actualFoundationSaveMigratesWithoutResettingProgressAndBacksUpExactly() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let url = folder.appendingPathComponent("settlement-v1.json")
    let epoch = Date(timeIntervalSince1970: 4_000_000)
    var foundation = try GameEngine(configuration: foundationConfiguration(), now: epoch)
    try foundation.build(.hut, at: Tile(x:8,y:8))
    foundation.advance(to: epoch.addingTimeInterval(7))
    // Reproduce v2's four-resource shape, rather than allowing the current encoder
    // to populate newly introduced resources before testing their decode defaults.
    let encoded = try JSONEncoder().encode(EconomyMigrationEnvelope(version:2,state:foundation.state))
    var object = try #require(JSONSerialization.jsonObject(with:encoded) as? [String:Any])
    var stateObject = try #require(object["state"] as? [String:Any])
    let resources = try #require(stateObject["resources"] as? [String:Double])
    stateObject["resources"] = resources.filter { ["food","wood","stone","knowledge"].contains($0.key) }
    object["state"] = stateObject
    let original = try JSONSerialization.data(withJSONObject:object,options:.sortedKeys)
    try original.write(to:url)
    let store = SaveStore(url:url)
    let configuration = try GameConfiguration.bundled()
    let migrated = try #require(try store.load(configuration:configuration))
    #expect(migrated.buildings == foundation.state.buildings)
    #expect(migrated.buildings.last?.constructionRemainingSeconds == 8)
    #expect(migrated.resources == foundation.state.resources)
    #expect(migrated.resources[.water] == 0) // New stocks are not gifted during migration.
    #expect(migrated.population == foundation.state.population)
    #expect(migrated.populationGrowthSeconds == foundation.state.populationGrowthSeconds)
    #expect(migrated.completedGoals == foundation.state.completedGoals)
    #expect(migrated.researchedTechnologies == foundation.state.researchedTechnologies)
    #expect(migrated.nextBuildingID == foundation.state.nextBuildingID)
    #expect(migrated.lastUpdated == foundation.state.lastUpdated)
    let expectedDeposits = Dictionary(uniqueKeysWithValues: configuration.naturalDeposits!.filter { !$0.renewable }.map { ($0.id,$0.capacity) })
    #expect(migrated.depositRemaining == expectedDeposits)
    #expect(try Data(contentsOf:url) == original)
    try store.save(migrated)
    let backup = url.appendingPathExtension("seed-0.2.1.bak")
    #expect(try Data(contentsOf:backup) == original)
    #expect(try JSONDecoder().decode(EconomyMigrationEnvelope.self,from:Data(contentsOf:url)).version == 5)
    try store.save(migrated)
    #expect(try Data(contentsOf:backup) == original)
    #expect(try store.load(configuration:configuration) == migrated)
}

@Test func economySaveRoundTripsModeUpgradeAndDepletedDeposit() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("save.json")
    defer { try? FileManager.default.removeItem(at:url.deletingLastPathComponent()) }
    var configuration = try economyConfiguration() // Frozen economy semantics, independent of later fog rules.
    for index in configuration.buildings.indices { configuration.buildings[index].constructionSeconds = 0 }
    var game = try GameEngine(configuration:configuration,now:Date(timeIntervalSince1970:4_000_000))
    try game.build(.stoneGatherer,at:Tile(x:8,y:8))
    try game.setProductionMode(buildingID:1,recipeID:"flint")
    try game.upgrade(buildingID:1)
    var state = game.state
    let depositID = try #require(configuration.naturalDeposits?.first { $0.resource == .flint }?.id)
    state.depositRemaining?[depositID] = 0
    let store = SaveStore(url:url)
    try store.save(state)
    let restored = try #require(try store.load(configuration:configuration))
    #expect(restored == state)
    #expect(restored.buildings.last?.productionModeID == "flint")
    #expect(restored.buildings.last?.level == 2)
    #expect(restored.depositRemaining?[depositID] == 0)
    let resumed = try GameEngine(state:restored,configuration:configuration)
    #expect(resumed.grossRates[.flint] == 0)
}

@Test func currentSaveMissingOrCorruptDepositAccountingIsRejectedWithoutRepair() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at:folder) }
    try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
    let url = folder.appendingPathComponent("save.json")
    let configuration = try economyConfiguration() // v3 deposit strictness remains covered under its ruleset.
    let game = try GameEngine(configuration:configuration,now:Date(timeIntervalSince1970:4_000_000))
    var state = game.state
    let store = SaveStore(url:url)
    for deposits: [String:Double]? in [nil, [:], ["unknown":1]] {
        state.depositRemaining = deposits
        let original = try JSONEncoder().encode(EconomyMigrationEnvelope(version:3,state:state))
        try original.write(to:url)
        #expect(throws:GameError.self) { try store.load(configuration:configuration) }
        #expect(try Data(contentsOf:url) == original)
    }
}
