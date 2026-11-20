#if DEBUG
import Foundation
import Testing
import GameCore
import GamePersistence
import GameApplication

@Test @MainActor func connectivityReviewActivationIsExplicitAndKeepsCompanionsIndependent() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = folder.appendingPathComponent("save.json")
    var now = connectivityEpoch
    let session = try GameSession(clock: { now }, saveURL: url)
    session.loadDeveloperScenario(.early); session.returnToNormalGame()
    let normal = try Data(contentsOf: url)
    let developer = try Data(contentsOf: url.appendingPathExtension("developer"))
    session.activateReviewConnectivity()
    #expect(session.state.operatingRules == nil)
    #expect(try Data(contentsOf: url) == normal)
    session.startGameplayReview()
    #expect(session.state.operatingRules == nil)
    let original = session.state
    let reviewURL = url.appendingPathExtension("review")
    let bytes = try Data(contentsOf: reviewURL)
    session.activateReviewConnectivity()
    #expect(session.state.operatingRules == .connectedPathsV1)
    #expect(session.state.buildings == original.buildings && session.state.resources == original.resources)
    #expect(session.state.civicProgress == original.civicProgress && session.state.completedGoals == original.completedGoals)
    #expect(try Data(contentsOf: reviewURL.appendingPathExtension("pre-connectivity-v6.bak")) == bytes)
    #expect(try Data(contentsOf: url) == normal)
    #expect(try Data(contentsOf: url.appendingPathExtension("developer")) == developer)
    let strict = try Data(contentsOf: reviewURL)
    session.activateReviewConnectivity(); #expect(try Data(contentsOf: reviewURL) == strict)
    now.addTimeInterval(3600)
    let reopened = try GameSession(clock: { now }, saveURL: url)
    #expect(reopened.state.operatingRules == nil)
    reopened.resumeGameplayReview()
    #expect(reopened.state.operatingRules == .connectedPathsV1)
    #expect(reopened.state.resources == original.resources)
    #expect(try Data(contentsOf: url.appendingPathExtension("developer")) == developer)
}
@Test @MainActor func connectivityReviewBackupFailurePreservesSourceThenCanRetry() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = folder.appendingPathComponent("save.json")
    var now = connectivityEpoch
    let session = try GameSession(clock: { now }, saveURL: url)
    session.startGameplayReview()
    let file = url.appendingPathExtension("review"), backup = file.appendingPathExtension("pre-connectivity-v6.bak")
    let bytes = try Data(contentsOf: file)
    let food = session.state.resources.food
    now.addTimeInterval(60)
    let conflict = Data("preserve conflicting source".utf8); try conflict.write(to: backup)
    session.activateReviewConnectivity()
    #expect(session.state.operatingRules == nil && session.persistenceWarning != nil)
    #expect(session.state.lastUpdated == now && abs(session.state.resources.food - food + 1) < 1e-8)
    #expect(try Data(contentsOf: file) == bytes && Data(contentsOf: backup) == conflict)
    try FileManager.default.removeItem(at: backup) // Only this test's new temporary conflict.
    let advanced = session.state
    session.activateReviewConnectivity()
    #expect(session.state.resources == advanced.resources && session.state.lastUpdated == advanced.lastUpdated)
    #expect(session.state.operatingRules == .connectedPathsV1 && session.persistenceWarning == nil)
    #expect(try Data(contentsOf: backup) == bytes)
}
@Test @MainActor func connectivityReviewRejectsDamagedSourceWithoutReplacingIt() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = folder.appendingPathComponent("save.json")
    let session = try GameSession(clock: { connectivityEpoch }, saveURL: url)
    session.startGameplayReview()
    let file = url.appendingPathExtension("review")
    let bytes = Data("damaged review source".utf8); try bytes.write(to: file)
    session.activateReviewConnectivity()
    #expect(session.state.operatingRules == nil && session.persistenceWarning != nil)
    #expect(try Data(contentsOf: file) == bytes)
}
@Test @MainActor func connectivityReviewTopologyCommitsSettlePriorTimeAndIgnorePreviews() throws {
    var c = try connectivityConfiguration(); c.populationRules?.foodPerPersonPerMinute = 0
    var now = connectivityEpoch
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let session = try GameSession(clock: { now }, saveURL: folder.appendingPathComponent("save.json"), configuration: c)
    session.choose(.gatheringShelter); session.tap(connectivityTile(c, 3)); session.confirm()
    session.startGameplayReview(); session.activateReviewConnectivity()
    let before = session.state
    session.chooseRoadTool(.draw(.trodden)); session.extendRoadStroke(to: connectivityTile(c, 1)); session.extendRoadStroke(to: connectivityTile(c, 2))
    #expect(session.state == before && session.grossRates.food == 2)
    now.addTimeInterval(60); session.confirmRoadStroke()
    #expect(abs(session.state.resources.food - before.resources.food - 2) < 1e-8)
    #expect(session.grossRates.food > 2)
    let rate = session.grossRates.food, connectedStock = session.state.resources.food
    session.beginRelocation(buildingID: 1); session.tap(connectivityTile(c, 6, 3))
    #expect(session.grossRates.food == rate)
    now.addTimeInterval(60); session.confirm()
    #expect(abs(session.state.resources.food - connectedStock - rate) < 1e-8)
    #expect(session.grossRates.food == 2)
}
#endif

#if DEBUG
@Test @MainActor func connectivityReviewActivationRetainsFastConstructionControl() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let session = try GameSession(clock: { connectivityEpoch }, saveURL: folder.appendingPathComponent("save.json"))
    session.startGameplayReview(); session.setDeveloperFastConstruction(true)
    #expect(session.constructionDuration(for: .hut) == 3)
    session.activateReviewConnectivity()
    #expect(session.developerFastConstruction && session.constructionDuration(for: .hut) == 3)
}
@Test func connectivityPilotRetainsAllLegacyChaptersPillarsReadinessAndStockThroughV7() throws {
    let c = try GameConfiguration.bundled()
    var old = try DeveloperScenario.late.makeEngine(configuration: c.beforeCivicEvolution, now: connectivityEpoch)
    try old.developerUnlockTechnology("fortification"); old.developerAddResources(1000)
    let tile = try #require(old.state.discoveredTiles?.first { old.placementIssue(.palisade, at: $0) == nil })
    try old.build(.palisade, at: tile); old.advance(to: old.state.lastUpdated.addingTimeInterval(60))
    #expect(old.journeyChapters.allSatisfy { $0.isComplete })
    let legacy = GameEngine.retainingLegacyCivicProgress(old)
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let store = SaveStore(url: folder.appendingPathComponent("save.json")); try store.save(legacy)
    let bytes = try Data(contentsOf: store.url)
    var strict = legacy; strict.operatingRules = .connectedPathsV1; strict.roads = nil
    try store.save(strict)
    let loaded = try #require(try store.load(configuration: c))
    var game = try GameEngine(state: loaded, configuration: c)
    #expect(game.journeyChapters.allSatisfy { $0.isComplete } && game.state.stoneAgeCompleted == true)
    #expect(game.state.completedGoals == legacy.completedGoals && game.state.completedPillarGoals == legacy.completedPillarGoals)
    #expect(game.state.civicProgress == legacy.civicProgress && game.state.resources == legacy.resources)
    #expect(game.operatingProductionBuildingIDs.isSubset(of: [0]))
    game.advance(to: game.state.lastUpdated.addingTimeInterval(1))
    #expect(game.state.completedGoals == legacy.completedGoals && game.state.completedPillarGoals == legacy.completedPillarGoals)
    #expect(game.state.civicProgress?.completedChapters == legacy.civicProgress?.completedChapters && game.state.stoneAgeCompleted == true)
    #expect(legacy.civicProgress!.completedObjectives.isSubset(of: game.state.civicProgress!.completedObjectives))
    #expect(game.state.civicProgress?.reachedLevels == legacy.civicProgress?.reachedLevels)
    #expect(game.state.resources.wood == legacy.resources.wood)
    #expect(try Data(contentsOf: store.url.appendingPathExtension("pre-connectivity-v6.bak")) == bytes)
}
#endif
