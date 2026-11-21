import Foundation
import Testing
import GameCore
import GamePersistence

private func retirementRoot() -> URL { FileManager.default.temporaryDirectory.appendingPathComponent("small-map-fixture-" + UUID().uuidString) }
private let retirementEpoch = Date(timeIntervalSince1970: 90_000_000)

@Test func smallMapRetirementUsesDecodedValidatedHistoricalIdentity() throws {
    let root = retirementRoot(); defer { try? FileManager.default.removeItem(at: root) }
    let old = try GameConfiguration.legacyDevelopment()
    #expect(old.map.id == "river-clearing-v1" && old.map.width == 32 && old.map.height == 24)
    let store = GameLibraryStore(rootURL: root)
    // Intentionally misleading metadata cannot decide retirement.
    let game = SavedGame(id: "legacy", name: "Large village", createdAt: retirementEpoch, mapID: "river-clearing-64x48-v1")
    let index = GameLibraryIndex(activeGameID: game.id, games: [game]); try store.save(index)
    let url = try store.saveURL(for: game)
    try SaveStore(url: url).save(GameEngine(configuration: old, now: retirementEpoch).state)
    let original = try Data(contentsOf: url)
    let backup = url.appendingPathExtension("pre-civic-v5.bak"), backupBytes = Data("preserve-even-an-unknown-backup".utf8)
    try backupBytes.write(to: backup)
    let result = try store.retiringObsoleteSmallMaps(index)
    #expect(result.games.first?.retiredSmallMap == true)
    #expect(try Data(contentsOf: url) == original)
    #expect(try Data(contentsOf: backup) == backupBytes)
    let archive = root.appendingPathComponent("retired-small-maps/legacy")
    #expect(try Data(contentsOf: archive.appendingPathComponent(url.lastPathComponent)) == original)
    #expect(try Data(contentsOf: archive.appendingPathComponent(backup.lastPathComponent)) == backupBytes)
    #expect(try store.retiringObsoleteSmallMaps(result) == result)
    #expect(try store.load() == result)
}

@Test(arguments: ["large", "unknown", "corrupt", "review"])
func smallMapRetirementPreservesAnythingNotPositivelyObsolete(kind: String) throws {
    let root = retirementRoot(); defer { try? FileManager.default.removeItem(at: root) }
    let store = GameLibraryStore(rootURL: root)
    let game = SavedGame(id: "legacy", name: "32x24 old filename", createdAt: retirementEpoch, mapID: "river-clearing-v1")
    let index = GameLibraryIndex(activeGameID: game.id, games: [game]); try store.save(index)
    let url = try store.saveURL(for: game)
    if kind == "large" { try SaveStore(url: url).save(GameEngine(configuration: .bundled(), now: retirementEpoch).state) }
    else if kind == "corrupt" { try Data("broken".utf8).write(to: url) }
    else {
        try SaveStore(url: url).save(GameEngine(configuration: .legacyDevelopment(), now: retirementEpoch).state)
        var json = try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        if kind == "review" { json["isGameplayReview"] = true }
        else { var state = json["state"] as! [String: Any]; state["mapID"] = "unrecognized-small-map"; json["state"] = state }
        try JSONSerialization.data(withJSONObject: json).write(to: url)
    }
    let original = try Data(contentsOf: url)
    #expect(try store.retiringObsoleteSmallMaps(index) == index)
    #expect(try Data(contentsOf: url) == original)
    #expect(!FileManager.default.fileExists(atPath: root.appendingPathComponent("retired-small-maps").path))
}

@Test func smallMapRetirementFailureKeepsSelectionAndCanRecover() throws {
    let root = retirementRoot(); defer { try? FileManager.default.removeItem(at: root) }
    let store = GameLibraryStore(rootURL: root)
    let game = SavedGame(id: "legacy", name: "Old", createdAt: retirementEpoch, mapID: "river-clearing-v1")
    let index = GameLibraryIndex(activeGameID: game.id, games: [game]); try store.save(index)
    let url = try store.saveURL(for: game)
    try SaveStore(url: url).save(GameEngine(configuration: .legacyDevelopment(), now: retirementEpoch).state)
    let original = try Data(contentsOf: url), indexBytes = try Data(contentsOf: store.indexURL)
    let conflict = root.appendingPathComponent("retired-small-maps")
    try Data("blocked archive destination".utf8).write(to: conflict)
    #expect(throws: Error.self) { try store.retiringObsoleteSmallMaps(index) }
    #expect(try Data(contentsOf: url) == original)
    #expect(try Data(contentsOf: store.indexURL) == indexBytes)
    try FileManager.default.removeItem(at: conflict) // Fixture only.
    let restored = try store.retiringObsoleteSmallMaps(index)
    #expect(restored.games.first?.retiredSmallMap == true)
    #expect(try Data(contentsOf: url) == original)
}

@Test func smallMapRetirementPreservesMigratedLargePrimaryAndOldBackup() throws {
    let root = retirementRoot(); defer { try? FileManager.default.removeItem(at: root) }
    let store = GameLibraryStore(rootURL: root)
    let game = SavedGame(id: "legacy", name: "Old label", createdAt: retirementEpoch, mapID: "river-clearing-v1")
    let index = GameLibraryIndex(activeGameID: game.id, games: [game]); try store.save(index)
    let url = try store.saveURL(for: game)
    try SaveStore(url: url).save(GameEngine(configuration: .bundled(), now: retirementEpoch).state)
    let backup = url.appendingPathExtension("pre-geography-64x48.bak")
    try SaveStore(url: backup).save(GameEngine(configuration: .legacyDevelopment(), now: retirementEpoch).state)
    let primaryBytes = try Data(contentsOf: url), backupBytes = try Data(contentsOf: backup)
    #expect(try store.retiringObsoleteSmallMaps(index) == index)
    #expect(try Data(contentsOf: url) == primaryBytes)
    #expect(try Data(contentsOf: backup) == backupBytes)
    #expect(!FileManager.default.fileExists(atPath: root.appendingPathComponent("retired-small-maps").path))
}
