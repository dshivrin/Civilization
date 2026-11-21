#if DEBUG
import Foundation
import Testing
import GameCore
import GameApplication
import GamePersistence

@Test @MainActor func gameplayReviewClonesNormalAndKeepsDeveloperCompanionIndependent() throws {
    var now = Date(timeIntervalSince1970: 1000)
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = folder.appendingPathComponent("normal.json")
    let session = try GameSession(clock: { now }, saveURL: url)
    session.loadDeveloperScenario(.early); session.returnToNormalGame()
    let original = session.state
    let normal = try Data(contentsOf: url)
    let developer = try Data(contentsOf: url.appendingPathExtension("developer"))
    session.startGameplayReview()
    #expect(session.isGameplayReview)
    #expect(session.isDeveloperMode)
    #expect(session.state == original)
    #expect(session.state.buildings.count == 1)
    #expect(!session.isSelectedDeveloperScenario(.early))
    session.setDeveloperSpeed(10)
    now.addTimeInterval(6); session.tick()
    #expect(abs(session.state.resources.food - (original.resources.food - 1)) < 1e-9) // 60 simulated seconds at net -1 food/min.
    let beforeGrant = session.state.resources.wood
    session.addDeveloperResources()
    #expect(session.state.resources.wood == min(session.capacities.wood, beforeGrant + 250))
    #expect(try Data(contentsOf: url) == normal)
    #expect(try Data(contentsOf: url.appendingPathExtension("developer")) == developer)
    #expect(FileManager.default.fileExists(atPath: url.appendingPathExtension("review").path))
    let reviewed = session.state
    session.loadDeveloperScenario(.late) // A scenario command cannot replace an active review copy.
    #expect(session.isGameplayReview && session.state == reviewed)
    session.returnToNormalGame()
    #expect(!session.isGameplayReview && !session.isDeveloperMode)
    #expect(session.state.resources.wood == original.resources.wood)
    #expect(abs(session.state.resources.food - (original.resources.food - 0.1)) < 1e-9) // Only six ordinary seconds, not 60 or a grant.
    #expect(try Data(contentsOf: url.appendingPathExtension("developer")) == developer)
}

@Test @MainActor func gameplayReviewResumesWithoutOfflineGrantsOrPersistedDebugSettings() throws {
    var now = Date(timeIntervalSince1970: 1000)
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = folder.appendingPathComponent("normal.json")
    let session = try GameSession(clock: { now }, saveURL: url)
    session.startGameplayReview(); session.addDeveloperResources()
    session.setDeveloperSpeed(10); session.setDeveloperPaused(true); session.setDeveloperFastConstruction(true)
    let earned = session.state
    session.save()
    now.addTimeInterval(3600)
    let reloaded = try GameSession(clock: { now }, saveURL: url)
    let normalBytes = try Data(contentsOf: url)
    reloaded.resumeGameplayReview()
    #expect(reloaded.isGameplayReview)
    #expect(reloaded.state.resources == earned.resources)
    #expect(reloaded.state.buildings == earned.buildings)
    #expect(reloaded.developerSpeed == 1 && !reloaded.developerPaused && !reloaded.developerFastConstruction)
    #expect(try Data(contentsOf: url) == normalBytes)
    let retained = reloaded.state
    reloaded.startGameplayReview() // An existing copy is never reset from the new normal state.
    #expect(reloaded.state == retained)
}

@Test @MainActor func gameplayReviewDamagedCopyIsPreservedAndNeverEntersDeveloperMode() throws {
    let now = Date(timeIntervalSince1970: 1000)
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = folder.appendingPathComponent("normal.json")
    let session = try GameSession(clock: { now }, saveURL: url)
    let normal = try Data(contentsOf: url)
    let broken = Data("damaged review data".utf8)
    try broken.write(to: url.appendingPathExtension("review"))
    session.startGameplayReview()
    #expect(!session.isGameplayReview && !session.isDeveloperMode)
    #expect(try Data(contentsOf: url.appendingPathExtension("review")) == broken)
    #expect(try Data(contentsOf: url) == normal)
}
#endif

#if DEBUG
@Test(arguments: [false, true]) @MainActor
func gameplayReviewCannotRacePendingScenarioPreparation(resume: Bool) async throws {
    let now = Date(timeIntervalSince1970: 1000)
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = folder.appendingPathComponent("normal.json")
    let session = try GameSession(clock: { now }, saveURL: url)
    session.startGameplayReview(); session.addDeveloperResources(); session.returnToNormalGame()
    let retained = try Data(contentsOf: url.appendingPathExtension("review"))
    let preparation = Task { await session.prepareDeveloperScenario(.grouped) }
    // Yield-count polling can exhaust before the child task receives MainActor time.
    // Wait for the same observable precondition with a bounded scheduling interval.
    let deadline = ContinuousClock.now.advanced(by: .seconds(5))
    while !session.isPreparingDeveloperScenario && ContinuousClock.now < deadline {
        try await Task.sleep(for: .milliseconds(1))
    }
    guard session.isPreparingDeveloperScenario else { preparation.cancel(); await preparation.value; Issue.record("Preparation did not start"); return }
    if resume { session.resumeGameplayReview() } else { session.startGameplayReview() }
    #expect(!session.isGameplayReview && !session.isDeveloperMode)
    await preparation.value
    #expect(!session.isGameplayReview && session.isSelectedDeveloperScenario(.grouped))
    #expect(try Data(contentsOf: url.appendingPathExtension("review")) == retained)
}

@Test @MainActor func gameplayReviewFailedWritesKeepModeAndUnsavedProgress() throws {
    let now = Date(timeIntervalSince1970: 1000)
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer {
        try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: folder.path)
        try? FileManager.default.removeItem(at: folder)
    }
    let url = folder.appendingPathComponent("normal.json")
    let session = try GameSession(clock: { now }, saveURL: url)
    let original = session.state
    try FileManager.default.setAttributes([.posixPermissions: 0o500], ofItemAtPath: folder.path)
    session.startGameplayReview()
    #expect(!session.isGameplayReview && !session.isDeveloperMode)
    #expect(session.state == original)
    try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: folder.path)
    session.save(); session.startGameplayReview()
    #expect(session.isGameplayReview)
    let saved = try Data(contentsOf: url.appendingPathExtension("review"))
    try FileManager.default.setAttributes([.posixPermissions: 0o500], ofItemAtPath: folder.path)
    session.advanceDeveloperTime(seconds: 60)
    let unsaved = session.state
    session.returnToNormalGame()
    #expect(session.isGameplayReview && session.isDeveloperMode)
    #expect(session.state == unsaved && session.persistenceWarning != nil)
    #expect(try Data(contentsOf: url.appendingPathExtension("review")) == saved)
    try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: folder.path)
    session.returnToNormalGame()
    #expect(!session.isGameplayReview && !session.isDeveloperMode)
}

@Test @MainActor func gameplayReviewCannotCloneProtectedFallbackFromDamagedNormalSave() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let url = folder.appendingPathComponent("normal.json"), bytes = Data("damaged normal".utf8)
    try bytes.write(to: url)
    let session = try GameSession(clock: { Date(timeIntervalSince1970: 1000) }, saveURL: url)
    #expect(session.persistenceWarning != nil)
    session.startGameplayReview()
    #expect(!session.isGameplayReview && !session.isDeveloperMode)
    #expect(!FileManager.default.fileExists(atPath: url.appendingPathExtension("review").path))
    #expect(try Data(contentsOf: url) == bytes)
}
#endif
