import Foundation
import Testing
import GameCore
import GamePersistence

@Test func connectivityV7EnvelopeRetainsExplicitRulesAndHistoricalState() throws {
    let c = try GameConfiguration.bundled()
    let original = try GameEngine(configuration: c, now: Date(timeIntervalSince1970: 1000)).state
    var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any])
    object["operatingRules"] = "connectedPathsV1"
    let bytes = try JSONSerialization.data(withJSONObject: ["version": 7, "state": object])
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let file = root.appendingPathComponent("save.json"); try bytes.write(to: file)
    let loaded = try #require(try SaveStore(url: file).load(configuration: c))
    #expect(loaded.buildings == original.buildings && loaded.civicProgress == original.civicProgress)
    #expect(loaded.resources == original.resources && loaded.completedGoals == original.completedGoals)
    let encoded = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(loaded)) as? [String: Any])
    #expect(encoded["operatingRules"] as? String == "connectedPathsV1")
    #expect(try Data(contentsOf: file) == bytes)
}

@Test func connectivityVersionBoundariesAndBackupPreserveSource() throws {
    let c = try GameConfiguration.bundled()
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let store = SaveStore(url: root.appendingPathComponent("save.json"))
    var state = try GameEngine(configuration: c, now: Date(timeIntervalSince1970: 1000)).state
    try store.save(state)
    let bytes = try Data(contentsOf: store.url)
    #expect(try store.load(configuration: c)?.operatingRules == nil)
    state.operatingRules = .connectedPathsV1
    try store.save(state)
    let backup = store.url.appendingPathExtension("pre-connectivity-v6.bak")
    #expect(try Data(contentsOf: backup) == bytes)
    #expect(try store.load(configuration: c) == state)
    try store.save(state); #expect(try Data(contentsOf: backup) == bytes)
    let strict = try Data(contentsOf: store.url)
    state.operatingRules = nil
    #expect(throws: Error.self) { try store.save(state) }
    #expect(try Data(contentsOf: store.url) == strict)
}
@Test func connectivityV7RejectsMissingUnknownAndDowngradedMarkersWithoutWrites() throws {
    let c = try GameConfiguration.bundled()
    let state = try GameEngine(configuration: c, now: Date(timeIntervalSince1970: 1000)).state
    let original = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as? [String: Any])
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let file = root.appendingPathComponent("save.json")
    for (version, marker) in [(7, ""), (7, "unknown"), (6, "connectedPathsV1"), (8, "connectedPathsV1")] {
        var object = original
        if !marker.isEmpty { object["operatingRules"] = marker }
        let bytes = try JSONSerialization.data(withJSONObject: ["version": version, "state": object])
        try bytes.write(to: file)
        #expect(throws: Error.self) { try SaveStore(url: file).load(configuration: c) }
        #expect(try Data(contentsOf: file) == bytes)
    }
}
@Test func connectivityMigrationBackupConflictKeepsV6SourceIntact() throws {
    let c = try GameConfiguration.bundled()
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let store = SaveStore(url: root.appendingPathComponent("save.json"))
    var state = try GameEngine(configuration: c, now: Date(timeIntervalSince1970: 1000)).state
    try store.save(state); let bytes = try Data(contentsOf: store.url)
    let conflicting = Data("retain this conflicting backup".utf8)
    let backup = store.url.appendingPathExtension("pre-connectivity-v6.bak")
    try conflicting.write(to: backup)
    state.operatingRules = .connectedPathsV1
    #expect(throws: Error.self) { try store.save(state) }
    #expect(try Data(contentsOf: store.url) == bytes)
    #expect(try Data(contentsOf: backup) == conflicting)
}
