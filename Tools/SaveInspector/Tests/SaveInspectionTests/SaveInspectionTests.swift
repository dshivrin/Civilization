import Foundation
import Testing
import GameCore
import GamePersistence
import GameApplication
@testable import SaveInspection

private func temporaryRoot() throws -> URL {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent("save inspector " + UUID().uuidString)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    return root
}

@Test func validatesNormalLegacyAndBackupsWithoutChangingAnyBytes() throws {
    let root = try temporaryRoot(); defer { try? FileManager.default.removeItem(at: root) }
    let current = try GameEngine(configuration: .bundled(), now: Date(timeIntervalSince1970: 1000)).state
    let legacy = try GameEngine(configuration: .legacyDevelopment(), now: Date(timeIntervalSince1970: 1000)).state
    let normal = root.appendingPathComponent("settlement-v1.json")
    let backup = root.appendingPathComponent("settlement-v1.json.pre-geography-64x48.bak")
    try SaveStore(url: normal).save(current); try SaveStore(url: backup).save(legacy)
    let before = [try Data(contentsOf: normal), try Data(contentsOf: backup)]
    let report = try SaveInspection.inspect(root: root)
    #expect(report.files.count == 2)
    #expect(Set(report.files.map(\.mapID)) == Set([current.mapID, legacy.mapID]))
    #expect(try Data(contentsOf: normal) == before[0])
    #expect(try Data(contentsOf: backup) == before[1])
}

#if DEBUG
@Test func validatesGroupedDeveloperWithItsOwnGeometry() throws {
    let root = try temporaryRoot(); defer { try? FileManager.default.removeItem(at: root) }
    let c = try GameConfiguration.bundled()
    let state = try DeveloperScenario.grouped.makeEngine(configuration: c, now: Date(timeIntervalSince1970: 1000)).state
    let file = root.appendingPathComponent("settlement-v1.json.developer")
    try SaveStore(url: file).save(state)
    let report = try SaveInspection.inspect(root: root)
    #expect(report.files.first?.buildings == 64)
    #expect(report.files.first?.roads == 566)
}
#endif

@Test func rejectsDamagedSaveAndEmptyDirectories() throws {
    let root = try temporaryRoot(); defer { try? FileManager.default.removeItem(at: root) }
    #expect(throws: Error.self) { try SaveInspection.inspect(root: root) }
    let file = root.appendingPathComponent("settlement-v1.json")
    let damaged = Data("damaged".utf8); try damaged.write(to: file)
    #expect(throws: Error.self) { try SaveInspection.inspect(root: root) }
    #expect(try Data(contentsOf: file) == damaged)
}

@Test func rejectsMissingRegisteredSlotAndPreservesIndex() throws {
    let root = try temporaryRoot(); defer { try? FileManager.default.removeItem(at: root) }
    let c = try GameConfiguration.bundled()
    try SaveStore(url: root.appendingPathComponent("settlement-v1.json")).save(GameEngine(configuration: c, now: Date()).state)
    let legacy = SavedGame(id: "legacy", name: "Original", createdAt: Date(), mapID: c.map.id)
    let missing = SavedGame(id: UUID().uuidString, name: "Missing", createdAt: Date(), mapID: c.map.id)
    let store = GameLibraryStore(rootURL: root)
    try store.save(GameLibraryIndex(activeGameID: missing.id, games: [legacy, missing]))
    let bytes = try Data(contentsOf: store.indexURL)
    #expect(throws: Error.self) { try SaveInspection.inspect(root: root) }
    #expect(try Data(contentsOf: store.indexURL) == bytes)
}

@Test func rejectsSymlinkInsteadOfFollowingPrivatePaths() throws {
    let root = try temporaryRoot(); defer { try? FileManager.default.removeItem(at: root) }
    let outside = try temporaryRoot(); defer { try? FileManager.default.removeItem(at: outside) }
    let file = outside.appendingPathComponent("settlement-v1.json")
    let bytes = Data("private".utf8); try bytes.write(to: file)
    try FileManager.default.createSymbolicLink(at: root.appendingPathComponent("settlement-v1.json"), withDestinationURL: file)
    #expect(throws: Error.self) { try SaveInspection.inspect(root: root) }
    #expect(try Data(contentsOf: file) == bytes)
}

@Test func rejectsUnsupportedIndexMapWhileAcceptingLazyGeographyIdentity() throws {
    let root = try temporaryRoot(); defer { try? FileManager.default.removeItem(at: root) }
    let store = GameLibraryStore(rootURL: root)
    let c = try GameConfiguration.bundled()
    try SaveStore(url: root.appendingPathComponent("settlement-v1.json")).save(GameEngine(configuration: c, now: Date()).state)
    let unsupported = SavedGame(id: "legacy", name: "Original", createdAt: Date(), mapID: "unsupported-map")
    try store.save(GameLibraryIndex(activeGameID: "legacy", games: [unsupported]))
    #expect(throws: Error.self) { try SaveInspection.inspect(root: root) }
    let legacy = try GameConfiguration.legacyDevelopment()
    let oldFile = root.appendingPathComponent("settlement-v1.json")
    // Replace only this newly created test fixture, never a development/player save.
    try SaveStore(url: oldFile).save(GameEngine(configuration: legacy, now: Date()).state)
    let convertedMetadata = SavedGame(id: "legacy", name: "Original", createdAt: Date(), mapID: c.map.id)
    try store.save(GameLibraryIndex(activeGameID: "legacy", games: [convertedMetadata]))
    let before = try Data(contentsOf: oldFile)
    #expect(try SaveInspection.inspect(root: root).registeredGames == 1)
    #expect(try Data(contentsOf: oldFile) == before)
}

@Test func validatesIndependentIndexedUUIDSlots() throws {
    let root = try temporaryRoot(); defer { try? FileManager.default.removeItem(at: root) }
    let store = GameLibraryStore(rootURL: root), c = try GameConfiguration.bundled()
    let original = SavedGame(id: "legacy", name: "Original", createdAt: Date(), mapID: c.map.id)
    let second = SavedGame(id: UUID().uuidString, name: "Second", createdAt: Date(), mapID: c.map.id)
    for game in [original, second] {
        try SaveStore(url: store.saveURL(for: game)).save(GameEngine(configuration: c, now: Date()).state)
    }
    try store.save(GameLibraryIndex(activeGameID: second.id, games: [original, second]))
    let report = try SaveInspection.inspect(root: root)
    #expect(report.registeredGames == 2 && report.files.count == 2 && report.sourceByteIdentical)
}

@Test func rejectsRootAliasEvenWhenItsTargetIsHealthy() throws {
    let root = try temporaryRoot(); defer { try? FileManager.default.removeItem(at: root) }
    let folder = try temporaryRoot(); defer { try? FileManager.default.removeItem(at: folder) }
    let c = try GameConfiguration.bundled()
    try SaveStore(url: root.appendingPathComponent("settlement-v1.json")).save(GameEngine(configuration: c, now: Date()).state)
    let alias = folder.appendingPathComponent("alias")
    try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: root)
    #expect(throws: Error.self) { try SaveInspection.inspect(root: alias) }
    #expect(try SaveInspection.inspect(root: root).files.count == 1)
}

@Test func validatesReviewCompanionAndRetainsEverySourceByte() throws {
    let root = try temporaryRoot(); defer { try? FileManager.default.removeItem(at: root) }
    let config = try GameConfiguration.bundled()
    let now = Date(timeIntervalSince1970: 1000)
    let normal = try GameEngine(configuration: config, now: now)
    var review = normal
    try review.research("oralTradition"); try review.upgrade(buildingID: 0)
    let normalURL = root.appendingPathComponent("settlement-v1.json")
    let reviewURL = root.appendingPathComponent("settlement-v1.json.review")
    try SaveStore(url: normalURL).save(normal.state)
    struct ReviewEnvelope: Encodable { let version = 6; let state: GameState; let isGameplayReview = true }
    let reviewBytes = try JSONEncoder().encode(ReviewEnvelope(state: review.state))
    try reviewBytes.write(to: reviewURL)
    try reviewBytes.write(to: reviewURL.appendingPathExtension("snapshot.bak"))
    let originalNormal = try Data(contentsOf: normalURL), originalReview = try Data(contentsOf: reviewURL)
    let report = try SaveInspection.inspect(root: root)
    #expect(report.files.count == 3)
    #expect(report.files.contains { $0.relativePath == "settlement-v1.json.review" })
    #expect(report.files.contains { $0.relativePath == "settlement-v1.json.review.snapshot.bak" })
    #expect(try Data(contentsOf: normalURL) == originalNormal)
    #expect(try Data(contentsOf: reviewURL) == originalReview)
}

@Test(arguments: [false, true], ["review", "review.snapshot.bak"])
func rejectsReviewWithoutTrueMarker(present: Bool, suffix: String) throws {
    let root = try temporaryRoot(); defer { try? FileManager.default.removeItem(at: root) }
    let state = try GameEngine(configuration: .bundled(), now: Date(timeIntervalSince1970: 1000)).state
    try SaveStore(url: root.appendingPathComponent("settlement-v1.json")).save(state)
    struct Envelope: Encodable { let version = 6; let state: GameState; let isGameplayReview: Bool? }
    let bytes = try JSONEncoder().encode(Envelope(state: state, isGameplayReview: present ? false : nil))
    let file = root.appendingPathComponent("settlement-v1.json." + suffix)
    try bytes.write(to: file)
    #expect(throws: Error.self) { try SaveInspection.inspect(root: root) }
    #expect(try Data(contentsOf: file) == bytes)
}

@Test func validatesExplicitConnectivityAndLegacyBackupWithoutWrites() throws {
    let root = try temporaryRoot(); defer { try? FileManager.default.removeItem(at: root) }
    let file = root.appendingPathComponent("settlement-v1.json")
    let c = try GameConfiguration.bundled()
    var state = try GameEngine(configuration: c, now: Date(timeIntervalSince1970: 1000)).state
    try SaveStore(url: file).save(state)
    state.operatingRules = .connectedPathsV1; try SaveStore(url: file).save(state)
    let bytes = try Data(contentsOf: file)
    let report = try SaveInspection.inspect(root: root)
    #expect(Set(report.files.map(\.operatingRules)) == Set(["legacy", "connectedPathsV1"]))
    #expect(report.sourceByteIdentical && report.files.count == 2)
    #expect(try Data(contentsOf: file) == bytes)
}
