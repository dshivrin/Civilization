import Foundation
import Testing
import GameCore
import GamePersistence
import GameApplication

private func gameLibraryRoot() -> URL { FileManager.default.temporaryDirectory.appendingPathComponent("session-library-" + UUID().uuidString) }
private let gamesEpoch = Date(timeIntervalSince1970: 80_000_000)

@Test @MainActor func independentGamesResumeTheirOwnProgressAndSelection() async throws {
    let root = gameLibraryRoot(); defer { try? FileManager.default.removeItem(at: root) }
    var now = gamesEpoch
    let library = try await GameLibrary.load(rootURL: root, clock: { now })
    library.setActive(true)
    let original = library.session.state
    library.session.choose(.hut)
    let second = try await library.createGame(name: "Second village")
    #expect(library.activeGameID == second.id && library.games.count == 2)
    #expect(library.session.selectedKind == nil)
    now = now.addingTimeInterval(60)
    library.session.tick()
    let secondState = library.session.state
    try await library.openGame(id: "legacy")
    #expect(library.session.state.buildings == original.buildings)
    #expect(library.session.selectedKind == nil)
    let index = try #require(try GameLibraryStore(rootURL: root).load())
    #expect(index.activeGameID == "legacy")
    try await library.openGame(id: second.id)
    #expect(library.session.state == secondState)
    let restored = try await GameLibrary.load(rootURL: root, clock: { now })
    #expect(restored.activeGameID == second.id && restored.session.state == secondState)
}

@Test @MainActor func missingOrCorruptRegisteredGamesNeverResetOrReplaceCurrentGame() async throws {
    let root = gameLibraryRoot(); defer { try? FileManager.default.removeItem(at: root) }
    let library = try await GameLibrary.load(rootURL: root, clock: { gamesEpoch })
    let second = try await library.createGame(name: "Other")
    try await library.openGame(id: "legacy")
    let session = library.session
    let store = GameLibraryStore(rootURL: root), url = try store.saveURL(for: second)
    try FileManager.default.removeItem(at: url)
    await #expect(throws: Error.self) { try await library.openGame(id: second.id) }
    #expect(library.session === session && library.activeGameID == "legacy")
    #expect(!FileManager.default.fileExists(atPath: url.path))
    let corrupt = Data("corrupt-target".utf8); try corrupt.write(to: url)
    await #expect(throws: Error.self) { try await library.openGame(id: second.id) }
    #expect(try Data(contentsOf: url) == corrupt)
    #expect(library.session === session && !library.isBusy)
}

@Test @MainActor func failedCurrentSaveBlocksSwitchAndKeepsLibrarySelection() async throws {
    let root = gameLibraryRoot(); defer { try? FileManager.default.removeItem(at: root) }
    let library = try await GameLibrary.load(rootURL: root, clock: { gamesEpoch })
    let second = try await library.createGame(name: "Other")
    try await library.openGame(id: "legacy")
    let url = root.appendingPathComponent("settlement-v1.json")
    try FileManager.default.removeItem(at: url)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
    await #expect(throws: Error.self) { try await library.openGame(id: second.id) }
    #expect(library.activeGameID == "legacy" && library.session.persistenceWarning != nil)
    #expect(try GameLibraryStore(rootURL: root).load()?.activeGameID == "legacy")
}

@Test @MainActor func corruptLegacyCanBeLeftWithoutOverwritingItsBytes() async throws {
    let root = gameLibraryRoot(); defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let url = root.appendingPathComponent("settlement-v1.json"), bytes = Data("protected-original".utf8)
    try bytes.write(to: url)
    let library = try await GameLibrary.load(rootURL: root, clock: { gamesEpoch })
    #expect(library.session.persistenceWarning != nil)
    _ = try await library.createGame(name: "")
    #expect(library.session.persistenceWarning == nil)
    #expect(try Data(contentsOf: url) == bytes)
}

@Test @MainActor func backgroundDuringAsyncSwitchDoesNotActivateTargetOrDoubleCountCatchup() async throws {
    let root = gameLibraryRoot(); defer { try? FileManager.default.removeItem(at: root) }
    var now = gamesEpoch
    let library = try await GameLibrary.load(rootURL: root, clock: { now })
    library.setActive(true)
    _ = try await library.createGame(name: nil)
    let switching = Task { try await library.openGame(id: "legacy") }
    await Task.yield()
    library.setActive(false)
    try await switching.value
    #expect(library.session.shouldPauseRendering)
    now = now.addingTimeInterval(100_000)
    library.setActive(true)
    let restored = library.session.state
    library.setActive(true)
    #expect(library.session.state == restored)
    #expect(restored.lastUpdated == now)
}

#if DEBUG
@Test @MainActor func developerScenarioCannotBeSwitchedIntoRegularGameLibrary() async throws {
    let root = gameLibraryRoot(); defer { try? FileManager.default.removeItem(at: root) }
    let library = try await GameLibrary.load(rootURL: root, clock: { gamesEpoch })
    library.session.loadDeveloperScenario(.early)
    await #expect(throws: Error.self) { try await library.createGame(name: "Not a scenario") }
    #expect(library.games.count == 1 && library.session.isDeveloperMode)
}
#endif

@Test @MainActor func failedIndexCommitKeepsOldSessionAndPreservesOriginalSave() async throws {
    let root = gameLibraryRoot(); defer { try? FileManager.default.removeItem(at: root) }
    let library = try await GameLibrary.load(rootURL: root, clock: { gamesEpoch })
    library.setActive(true)
    let session = library.session, store = GameLibraryStore(rootURL: root)
    let oldState = session.state
    let corrupt = Data("externally-corrupt-index".utf8); try corrupt.write(to: store.indexURL)
    await #expect(throws: Error.self) { try await library.createGame(name: "Unselected candidate") }
    #expect(library.session === session && library.games.count == 1 && library.activeGameID == "legacy")
    #expect(!session.shouldPauseRendering && !library.isBusy)
    #expect(try Data(contentsOf: store.indexURL) == corrupt)
    #expect(try SaveStore(url: root.appendingPathComponent("settlement-v1.json")).load(configuration: session.configuration) == oldState)
}

@Test @MainActor func simultaneousCreationIsRejectedAndOnlyOneGameIsPublished() async throws {
    let root = gameLibraryRoot(); defer { try? FileManager.default.removeItem(at: root) }
    let library = try await GameLibrary.load(rootURL: root, clock: { gamesEpoch })
    // MainActor task runs synchronously up to the first off-thread restoration suspension.
    let first = Task { try await library.createGame(name: "First") }
    for _ in 0..<100 where !library.isBusy { await Task.yield() }
    try #require(library.isBusy)
    await #expect(throws: Error.self) { try await library.createGame(name: "Duplicate") }
    let created = try await first.value
    #expect(library.games.count == 2 && library.activeGameID == created.id)
    #expect(try GameLibraryStore(rootURL: root).load()?.games.count == 2)
}
