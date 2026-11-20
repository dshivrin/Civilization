import Foundation
import Testing
import GameCore
import GamePersistence
import GameApplication

private let civicEpoch = Date(timeIntervalSince1970: 9_000_000)

@Test func civicCenterPaidResearchGatedLevelsPreserveFoundingProvisions() throws {
    var game = try GameEngine(configuration: .bundled(), now: civicEpoch)
    #expect(game.state.buildings.count == 1)
    let original = game.state
    #expect(game.upgradeCost(for: original.buildings[0]) == ResourceAmounts(food: 10, wood: 20, stone: 10))
    #expect(throws: GameError.self) { try game.upgrade(buildingID: 0) }
    #expect(game.state == original)
    try game.research("oralTradition")
    let stock = game.state.resources
    try game.upgrade(buildingID: 0)
    #expect(game.state.buildings[0].level == 2)
    #expect(game.state.resources.food == stock.food - 10)
    #expect(game.state.resources.wood == stock.wood - 20 + game.configuration.constructionGoalWoodReward)
    #expect(game.state.resources.stone == stock.stone - 10)
    #expect(game.grossRates.knowledge == 3)
    #expect(game.grossRates[.culture] == 2)
    #expect(game.grossRates.food == 2)
    #expect(game.grossRates[.water] == 3)
    #expect(game.housingCapacity == 5)
    let level2 = game.state
    #expect(throws: GameError.self) { try game.upgrade(buildingID: 0) }
    #expect(game.state == level2)
    game.advance(to: civicEpoch.addingTimeInterval(1020))
    try game.research("socialOrder")
    let before = game.state.resources
    try game.upgrade(buildingID: 0)
    #expect(game.state.resources.wood == before.wood - 10)
    #expect(game.state.resources.stone == before.stone - 5)
    #expect(game.state.buildings[0].level == 3)
    #expect(game.grossRates.knowledge == 3.75)
    #expect(game.grossRates[.culture] == 2.5)
    #expect(game.grossRates.food == 2)
    #expect(game.grossRates[.water] == 3)
    #expect(game.housingCapacity == 5)
    let final = game.state
    #expect(throws: GameError.self) { try game.upgrade(buildingID: 0) }
    #expect(game.state == final)
}

@Test func civicCenterRelocationPersistsIdentityWithoutChangingGeographicalOrigin() throws {
    var game = try GameEngine(configuration: .bundled(), now: civicEpoch)
    try game.research("oralTradition")
    try game.upgrade(buildingID: 0)
    let before = game.state
    let tile = try #require(before.discoveredTiles?.first { $0 != game.configuration.map.campfire && game.relocationIssue(buildingID: 0, at: $0) == nil })
    try game.relocate(buildingID: 0, to: tile)
    #expect(game.state.buildings[0].id == before.buildings[0].id)
    #expect(game.state.buildings[0].level == before.buildings[0].level)
    #expect(game.state.resources == before.resources)
    #expect(game.state.discoveredTiles == before.discoveredTiles)
    #expect(game.configuration.map.campfire == before.buildings[0].origin)
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("save.json")
    defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
    let store = SaveStore(url: url)
    try store.save(game.state)
    #expect(try store.load(configuration: game.configuration) == game.state)
    let invalid = game.state
    #expect(throws: GameError.self) { try game.relocate(buildingID: 0, to: Tile(x: -1, y: 0)) }
    #expect(game.state == invalid)
}

@Test func civicCenterChaptersReplaceMandatoryStorytelling() throws {
    var game = try GameEngine(configuration: .bundled(), now: civicEpoch)
    #expect(game.journeyChapters[0].objectives.contains { $0.id == "civic-level-2" && !$0.isComplete })
    #expect(game.journeyChapters[4].objectives.contains { $0.id == "civic-level-3" && !$0.isComplete })
    #expect(!game.journeyChapters[4].objectives.contains { $0.id == "building-storytellingCircle" })
    #expect(game.stoneAgeRequirements.first { $0.id == "buildings" }?.total == 19)
    try game.research("oralTradition")
    try game.upgrade(buildingID: 0)
    #expect(game.journeyChapters[0].objectives.first { $0.id == "civic-level-2" }?.isComplete == true)
    #expect(game.state.completedGoals.contains(.storytellingCircle))
    #expect(!game.state.buildings.contains { $0.kind == .storytellingCircle })
}

@Test func civicCenterWorkerShortageDoesNotScaleFoodWaterOrHousing() throws {
    var config = try GameConfiguration.bundled()
    config.workforceRules!.workingPopulationFraction = 0.01 // No whole worker at population three.
    var game = try GameEngine(configuration: config, now: civicEpoch)
    try game.research("oralTradition"); try game.upgrade(buildingID: 0)
    #expect(game.workersRequired(for: game.state.buildings[0]) == 1)
    #expect(game.workforceAvailable == 0)
    #expect(game.grossRates.knowledge == 0)
    #expect(game.grossRates[.culture] == 0)
    #expect(game.grossRates.food == 2)
    #expect(game.grossRates[.water] == 3)
    #expect(game.housingCapacity == 5)
}

@Test func civicCenterGuidanceOffersUpgradeBeforeDuplicateCircle() throws {
    var game = try GameEngine(configuration: .bundled(), now: civicEpoch)
    #expect(game.guidance(for: "civic-level-2").action == .research("oralTradition"))
    try game.research("oralTradition")
    #expect(game.guidance(for: "civic-level-2").action == .upgrade(0))
    #expect(game.guidance(for: "technology-hunting").action == .upgrade(0))
    #expect(game.guidance(for: "civic-level-3").action == .upgrade(0))
}

@Test func civicCenterLegacyMigrationRetainsCompletedChapterAndObjectiveCreditWithoutRewards() throws {
    let config = try GameConfiguration.bundled()
    var legacy = try GameEngine(configuration: config.beforeCivicEvolution, now: civicEpoch)
    for kind: BuildingKind in [.gatheringShelter, .woodcutter, .hut] {
        let tile = try #require(legacy.state.discoveredTiles?.first { legacy.placementIssue(kind, at: $0) == nil })
        try legacy.build(kind, at: tile)
        legacy.advance(to: legacy.state.lastUpdated.addingTimeInterval(60))
    }
    try legacy.research("oralTradition")
    #expect(legacy.journeyChapters[0].isComplete)
    let circle = try #require(legacy.state.discoveredTiles?.first { legacy.placementIssue(.storytellingCircle, at: $0) == nil })
    try legacy.build(.storytellingCircle, at: circle)
    legacy.advance(to: legacy.state.lastUpdated.addingTimeInterval(30))
    let original = legacy.state
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("save.json")
    defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    struct Envelope: Encodable { var version: Int; var state: GameState }
    let bytes = try JSONEncoder().encode(Envelope(version: 5, state: original))
    try bytes.write(to: url)
    let store = SaveStore(url: url)
    let migrated = try #require(try store.load(configuration: config))
    #expect(try Data(contentsOf: url) == bytes)
    #expect(migrated.buildings == original.buildings)
    #expect(migrated.resources == original.resources)
    #expect(migrated.completedGoals == original.completedGoals)
    #expect(migrated.researchedTechnologies == original.researchedTechnologies)
    #expect(migrated.discoveredTiles == original.discoveredTiles)
    #expect(migrated.depositRemaining == original.depositRemaining)
    #expect(migrated.civicProgress?.completedChapters.contains(1) == true)
    #expect(migrated.civicProgress?.completedObjectives.contains("5:building-storytellingCircle") == true)
    #expect(migrated.buildings[0].level == 1)
    var lostReward = migrated; lostReward.completedGoals.remove(.storytellingCircle)
    #expect(throws: GameError.self) { try GameEngine(state: lostReward, configuration: config) }
    var resumed = try GameEngine(state: migrated, configuration: config)
    #expect(resumed.journeyChapters[0].isComplete)
    #expect(resumed.journeyChapters[4].objectives.first { $0.id == "civic-level-3" }?.isComplete == true) // Retain the completed replaced objective even when chapter 5 was unfinished.
    #expect(resumed.journeyChapters[0].objectives.first { $0.id == "civic-level-2" }?.isComplete == true)
    let stocks = resumed.state.resources
    try resumed.upgrade(buildingID: 0)
    #expect(resumed.state.resources.wood == stocks.wood - 20) // Old circle reward cannot be re-awarded.
    try store.save(migrated)
    #expect(try Data(contentsOf: url.appendingPathExtension("pre-civic-v5.bak")) == bytes)
    #expect(try store.load(configuration: config) == migrated)
    try store.save(migrated)
    #expect(try store.load(configuration: config) == migrated)
    #expect(try Data(contentsOf: url.appendingPathExtension("pre-civic-v5.bak")) == bytes)
    var broken = original; broken.civicProgress = nil
    let invalid = try JSONEncoder().encode(Envelope(version: 6, state: broken))
    try invalid.write(to: url)
    #expect(throws: GameError.self) { try store.load(configuration: config) }
    #expect(try Data(contentsOf: url) == invalid)
}

@Test func civicCenterModifiersAndProducerCountsIncludeCultureWithoutScalingProvisions() throws {
    var config = try GameConfiguration.bundled()
    config.initialResources.knowledge = 100
    var game = try GameEngine(configuration: config, now: civicEpoch)
    try game.research("oralTradition"); try game.upgrade(buildingID: 0)
    try game.research("naturalKnowledge"); try game.research("rituals")
    #expect(abs(game.grossRates.knowledge - 3.6) < 1e-9)
    #expect(abs(game.grossRates[.culture] - 2.2) < 1e-9)
    #expect(game.producingBuildingCount(for: .knowledge) == 1)
    #expect(game.producingBuildingCount(for: .culture) == 1)
    #expect(game.grossRates.food == 2)
    #expect(game.grossRates[.water] == 3)
    #expect(game.housingCapacity == 5)
    let before = game.state
    let site = try #require(game.state.discoveredTiles?.first { game.placementIssue(.storytellingCircle, at: $0) == nil })
    try game.build(.storytellingCircle, at: site)
    game.advance(to: civicEpoch.addingTimeInterval(30))
    #expect(game.state.resources.wood == before.resources.wood - config.definition(.storytellingCircle).cost.wood)
    #expect(game.state.completedGoals == before.completedGoals)
    #expect(game.producingBuildingCount(for: .knowledge) == 2)
}

@Test func civicCenterMigrationRefusesConflictingBackupWithoutChangingSource() throws {
    let config = try GameConfiguration.bundled()
    let old = try GameEngine(configuration: config.beforeCivicEvolution, now: civicEpoch)
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let url = folder.appendingPathComponent("save.json")
    let store = SaveStore(url: url)
    try store.save(old.state)
    let bytes = try Data(contentsOf: url)
    let retained = Data("older backup must not be overwritten".utf8)
    try retained.write(to: url.appendingPathExtension("pre-civic-v5.bak"))
    let migrated = try #require(try store.load(configuration: config))
    #expect(throws: GameError.self) { try store.save(migrated) }
    #expect(try Data(contentsOf: url) == bytes)
    #expect(try Data(contentsOf: url.appendingPathExtension("pre-civic-v5.bak")) == retained)
}

#if DEBUG
import GameApplication
@Test func civicCenterMigrationProtectsAllSevenLegacyChaptersAndReadiness() throws {
    let config = try GameConfiguration.bundled()
    var old = try DeveloperScenario.late.makeEngine(configuration: config.beforeCivicEvolution, now: civicEpoch)
    try old.developerUnlockTechnology("fortification"); old.developerAddResources(1000)
    let site = try #require(old.state.discoveredTiles?.first { old.placementIssue(.palisade, at: $0) == nil })
    try old.build(.palisade, at: site)
    old.advance(to: old.state.lastUpdated.addingTimeInterval(60))
    #expect(old.journeyChapters.allSatisfy { $0.isComplete })
    let state = GameEngine.retainingLegacyCivicProgress(old)
    let migrated = try GameEngine(state: state, configuration: config)
    #expect(migrated.civicLevel == 1)
    #expect(migrated.journeyChapters.allSatisfy { $0.isComplete })
    #expect(migrated.state.stoneAgeCompleted == true)
    #expect(migrated.settlementGuidance.action == .complete)
    #expect(migrated.state.completedPillarGoals == old.state.completedPillarGoals)
    #expect(migrated.state.completedGoals == old.state.completedGoals)
    #expect(migrated.state.buildings == old.state.buildings)
    #expect(migrated.state.resources == old.state.resources)
    #expect(migrated.state.civicProgress?.completedChapters == Set(1...7))
}
#endif

@Test func civicCenterSaveCannotDowngradeAndDiscardEarnedHistory() throws {
    var game = try GameEngine(configuration: .bundled(), now: civicEpoch)
    try game.research("oralTradition"); try game.upgrade(buildingID: 0)
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let store = SaveStore(url: folder.appendingPathComponent("save.json"))
    try store.save(game.state)
    let bytes = try Data(contentsOf: store.url)
    var stripped = game.state; stripped.civicProgress = nil
    #expect(throws: GameError.self) { try store.save(stripped) }
    #expect(try Data(contentsOf: store.url) == bytes)
}

#if DEBUG
@Test @MainActor func civicCenterDeveloperMigrationBacksUpCompanionAndLeavesNormalBytesUntouched() throws {
    let config = try GameConfiguration.bundled()
    let now = Date(timeIntervalSince1970: 1000)
    let old = try DeveloperScenario.developed.makeEngine(configuration: config.beforeCivicEvolution, now: now)
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let normalURL = folder.appendingPathComponent("save.json")
    let session = try GameSession(clock: { now }, saveURL: normalURL)
    let normal = try Data(contentsOf: normalURL)
    struct Envelope: Encodable { let version = 5; let state: GameState; let developerScenario = DeveloperScenario.developed }
    let bytes = try JSONEncoder().encode(Envelope(state: old.state))
    let developer = normalURL.appendingPathExtension("developer")
    try bytes.write(to: developer)
    session.resumeDeveloperSettlement()
    #expect(session.isDeveloperMode)
    #expect(session.state.buildings == old.state.buildings)
    #expect(session.state.resources == old.state.resources)
    #expect(session.state.civicProgress?.completedChapters.isEmpty == false)
    session.save()
    #expect(session.persistenceWarning == nil)
    #expect(try Data(contentsOf: normalURL) == normal)
    #expect(try Data(contentsOf: developer.appendingPathExtension("pre-civic-v5.bak")) == bytes)
    let first = session.state
    session.save(); session.returnToNormalGame(); session.resumeDeveloperSettlement()
    #expect(session.state == first)
    #expect(try Data(contentsOf: developer.appendingPathExtension("pre-civic-v5.bak")) == bytes)
}
#endif

@Test(arguments: [1, 2, 3, 4])
func civicCenterMigrationProtectsEveryOlderBackup(version: Int) throws {
    let config = try GameConfiguration.bundled()
    let old = try GameEngine(configuration: config.beforeCivicEvolution, now: civicEpoch)
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let url = folder.appendingPathComponent("save.json")
    struct Envelope: Encodable { let version: Int; let state: GameState }
    let bytes = try JSONEncoder().encode(Envelope(version: version, state: old.state))
    try bytes.write(to: url)
    let suffix = [1: "seed-0.1.bak", 2: "seed-0.2.1.bak", 3: "seed-0.2.3.bak", 4: "seed-0.2.4.bak"][version]!
    let backup = url.appendingPathExtension(suffix)
    let retained = Data("Different prior source; preserve both".utf8)
    try retained.write(to: backup)
    let store = SaveStore(url: url)
    let migrated = try #require(try store.load(configuration: config))
    #expect(throws: GameError.self) { try store.save(migrated) }
    #expect(try Data(contentsOf: url) == bytes)
    #expect(try Data(contentsOf: backup) == retained)
}

@Test func civicCenterRejectsContradictoryChapterAndObjectiveWitnesses() throws {
    let config = try GameConfiguration.bundled()
    let game = try GameEngine(configuration: config, now: civicEpoch)
    var chapter = game.state; chapter.civicProgress!.completedChapters = Set(1...7)
    #expect(throws: GameError.self) { try GameEngine(state: chapter, configuration: config) }
    var objective = game.state; objective.civicProgress!.completedObjectives = ["1:building-hut"]
    #expect(throws: GameError.self) { try GameEngine(state: objective, configuration: config) }
    var circle = game.state; circle.civicProgress!.completedObjectives = ["5:building-storytellingCircle"]
    #expect(throws: GameError.self) { try GameEngine(state: circle, configuration: config) }
}

@Test func civicCenterOldEnvelopeCannotSupplyNewHistory() throws {
    let config = try GameConfiguration.bundled()
    let game = try GameEngine(configuration: config, now: civicEpoch)
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let store = SaveStore(url: folder.appendingPathComponent("save.json"))
    struct Envelope: Encodable { let version = 5; let state: GameState }
    let bytes = try JSONEncoder().encode(Envelope(state: game.state))
    try bytes.write(to: store.url)
    #expect(throws: GameError.self) { try store.load(configuration: config) }
    #expect(try Data(contentsOf: store.url) == bytes)
}

@Test @MainActor func civicCenterConstructionPreviewFollowsMovedCenterAndResourceHelpNamesIt() throws {
    var config = try GameConfiguration.bundled(); config.explorationRules = nil; config.progressionGoals = nil
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let session = try GameSession(clock: { civicEpoch }, saveURL: folder.appendingPathComponent("save.json"), configuration: config)
    let target = Tile(x: 40, y: 30)
    session.beginRelocation(buildingID: 0); session.tap(target); session.finishRelocation()
    #expect(session.state.buildings[0].origin == target)
    let before = session.state
    session.choose(.hut)
    let site = try #require(session.selectedTile)
    #expect(abs(site.x - target.x) + abs(site.y - target.y) <= 4)
    #expect(session.state == before)
    #expect(session.productionSources(for: .knowledge).contains { $0.kind == .campfire })
    #expect(session.productionSources(for: .culture).contains { $0.kind == .campfire })
}
