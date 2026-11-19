import Foundation
import Testing
import GameCore
import GamePersistence

@Test func saveRoundtripAndOfflineResume() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("save.json")
    defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
    let config = try baselineConfiguration()
    let clock = Date(timeIntervalSince1970: 1000)
    var game = try GameEngine(configuration: config, now: clock)
    let store = SaveStore(url: url)
    #expect(try store.load(configuration: config) == nil)
    try game.build(.gatheringShelter, at: Tile(x: 10, y: 10))
    game.advance(to: clock.addingTimeInterval(0.5))
    try store.save(game.state)
    let saved = try #require(try store.load(configuration: config))
    #expect(saved == game.state)
    var restored = try GameEngine(state: saved, configuration: config)
    restored.advance(to: clock.addingTimeInterval(60.5), offline: true)
    #expect(abs(restored.state.resources[.food] - saved.resources[.food] - 14) < 0.000001)
    try store.save(restored.state)
    var again = try GameEngine(state: #require(try store.load(configuration: config)), configuration: config)
    again.advance(to: clock.addingTimeInterval(60.5), offline: true)
    #expect(again.state == restored.state)
    again.advance(to: clock)
    #expect(again.state == restored.state)
}
@Test func corruptSaveIsPreserved() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: url) }
    let data = Data("broken save".utf8)
    try data.write(to: url)
    #expect(throws: (any Error).self) { try SaveStore(url: url).load(configuration: baselineConfiguration()) }
    #expect(try Data(contentsOf: url) == data)
}
@Test func unsupportedVersionAndInvalidStateAreRejected() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: url) }
    let config = try baselineConfiguration()
    var state = try GameEngine(configuration: config, now: Date()).state
    let store = SaveStore(url: url)
    try store.save(state)
    var object = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
    object["version"] = 999
    try JSONSerialization.data(withJSONObject: object).write(to: url)
    #expect(throws: (any Error).self) { try store.load(configuration: config) }
    state.mapID = "other-map"
    try FileManager.default.removeItem(at: url)
    try store.save(state)
    #expect(throws: (any Error).self) { try store.load(configuration: config) }
}
