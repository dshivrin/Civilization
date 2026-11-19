import Foundation
import Testing
import GameCore
import GamePersistence

private let libraryEpoch = Date(timeIntervalSince1970: 90_000_000)
private func libraryFolder() -> URL { FileManager.default.temporaryDirectory.appendingPathComponent("library-tests-" + UUID().uuidString) }

@Test func libraryBootstrapKeepsOriginalSaveBytesAndReferencesLegacyPath() throws {
    let root = libraryFolder(); defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let old = root.appendingPathComponent("settlement-v1.json"), developer = old.appendingPathExtension("developer")
    let bytes = Data("existing-normal-even-if-corrupt".utf8), devBytes = Data("existing-developer".utf8)
    try bytes.write(to: old); try devBytes.write(to: developer)
    let store = GameLibraryStore(rootURL: root)
    let index = try store.loadOrCreate(mapID: "river-clearing-v1", now: libraryEpoch)
    #expect(index.activeGameID == "legacy" && index.games.count == 1)
    #expect(try store.saveURL(for: index.games[0]) == old)
    #expect(try Data(contentsOf: old) == bytes && Data(contentsOf: developer) == devBytes)
    #expect(try store.load() == index)
}

@Test func libraryGamesResolveIndependentValidatedUUIDPaths() throws {
    let root = libraryFolder(); defer { try? FileManager.default.removeItem(at: root) }
    let store = GameLibraryStore(rootURL: root)
    var index = try store.loadOrCreate(mapID: "river-clearing-v1", now: libraryEpoch)
    let a = SavedGame(id: UUID().uuidString, name: "First", createdAt: libraryEpoch, mapID: "river-clearing-v1")
    let b = SavedGame(id: UUID().uuidString, name: "Second", createdAt: libraryEpoch, mapID: "river-clearing-v1")
    index.games += [a,b]; index.activeGameID = b.id; try store.save(index)
    let pathA = try store.saveURL(for: a), pathB = try store.saveURL(for: b)
    #expect(pathA != pathB && pathA != root.appendingPathComponent("settlement-v1.json"))
    #expect(pathA.path.hasPrefix(root.path + "/games/"))
    #expect(try store.load() == index)
}

@Test func libraryRejectsBadIdentityVersionSelectionAndDoesNotOverwriteValidIndex() throws {
    let root = libraryFolder(); defer { try? FileManager.default.removeItem(at: root) }
    let store = GameLibraryStore(rootURL: root)
    let valid = try store.loadOrCreate(mapID: "river-clearing-v1", now: libraryEpoch)
    let bytes = try Data(contentsOf: store.indexURL)
    var invalid = valid; invalid.activeGameID = "missing"
    #expect(throws: GameError.self) { try store.save(invalid) }
    invalid = valid; invalid.games.append(valid.games[0])
    #expect(throws: GameError.self) { try store.save(invalid) }
    invalid = valid; invalid.version = 999
    #expect(throws: GameError.self) { try store.save(invalid) }
    for id in ["../settlement-v1.json", "LEGACY", "", "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"] {
        let game = SavedGame(id: id, name: "Bad", createdAt: libraryEpoch, mapID: "river-clearing-v1")
        #expect(throws: GameError.self) { try store.saveURL(for: game) }
    }
    #expect(try Data(contentsOf: store.indexURL) == bytes)
}

@Test func corruptLibraryIndexIsPreservedOnBootstrapAndSave() throws {
    let root = libraryFolder(); defer { try? FileManager.default.removeItem(at: root) }
    let store = GameLibraryStore(rootURL: root)
    let valid = try store.loadOrCreate(mapID: "river-clearing-v1", now: libraryEpoch)
    let corrupt = Data("not-an-index".utf8); try corrupt.write(to: store.indexURL)
    #expect(throws: GameError.self) { try store.loadOrCreate(mapID: "river-clearing-v1", now: libraryEpoch) }
    #expect(throws: GameError.self) { try store.save(valid) }
    #expect(try Data(contentsOf: store.indexURL) == corrupt)
}

@Test func libraryRejectsSymlinkAliasesToOtherGamesAndIndexFiles() throws {
    let root = libraryFolder(); defer { try? FileManager.default.removeItem(at: root) }
    let outside = libraryFolder(); defer { try? FileManager.default.removeItem(at: outside) }
    try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
    let store = GameLibraryStore(rootURL: root)
    _ = try store.loadOrCreate(mapID: "river-clearing-v1", now: libraryEpoch)
    try FileManager.default.createSymbolicLink(at: root.appendingPathComponent("games"), withDestinationURL: outside)
    let game = SavedGame(id: UUID().uuidString, name: "Alias", createdAt: libraryEpoch, mapID: "river-clearing-v1")
    #expect(throws: GameError.self) { try store.saveURL(for: game) }
    try FileManager.default.removeItem(at: store.indexURL)
    let original = outside.appendingPathComponent("protected.json"); let bytes = Data("protected".utf8); try bytes.write(to: original)
    try FileManager.default.createSymbolicLink(at: store.indexURL, withDestinationURL: original)
    #expect(throws: GameError.self) { try store.loadOrCreate(mapID: "river-clearing-v1", now: libraryEpoch) }
    #expect(try Data(contentsOf: original) == bytes)
}
