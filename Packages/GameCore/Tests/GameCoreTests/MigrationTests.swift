import Foundation
import Testing
import GameCore
import GamePersistence
import GameApplication

@Test func realVersionOneSaveMigratesAndBacksUpBeforeReplacement() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let source = Bundle.module.url(forResource: "save-v1", withExtension: "json", subdirectory: "Fixtures")!
    let original = try Data(contentsOf: source)
    let url = folder.appendingPathComponent("save.json")
    try original.write(to: url)
    let store = SaveStore(url: url)
    let config = try GameConfiguration.bundled()
    let state = try #require(try store.load(configuration: config))
    #expect(state.researchedTechnologies == ["oralTradition"])
    #expect(state.populationGrowthSeconds == 0)
    #expect(state.resources == ResourceAmounts(food:40,wood:80,stone:50))
    #expect(state.buildings.count == 2 && state.buildings.allSatisfy(\.isOperational))
    #expect(state.completedGoals == [.hut, .oralTradition])
    #expect(state.nextBuildingID == 2 && state.mapID == config.map.id)
    #expect(try Data(contentsOf: url) == original) // Loading does not mutate the original.
    try store.save(state)
    let object = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String:Any])
    #expect(object["version"] as? Int == 5)
    #expect(try Data(contentsOf: url.appendingPathExtension("seed-0.1.bak")) == original)
    try store.save(state)
    #expect(try Data(contentsOf: url.appendingPathExtension("seed-0.1.bak")) == original)
    #expect(try store.load(configuration: config) == state)
}
@Test func partialConstructionAndGrowthSurviveCurrentSave() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("save.json")
    defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
    let time = Date(timeIntervalSince1970:2_000_000)
    var game = try GameEngine(configuration: .bundled(), now: time)
    try game.build(.gatheringShelter, at: Tile(x:10,y:10))
    game.advance(to: time.addingTimeInterval(7))
    let store = SaveStore(url:url)
    try store.save(game.state)
    var resumed = try GameEngine(state: #require(try store.load(configuration: game.configuration)), configuration: game.configuration)
    #expect(resumed.state.buildings.last?.constructionRemainingSeconds == 13)
    resumed.advance(to: time.addingTimeInterval(80), offline: true)
    #expect(resumed.state.populationGrowthSeconds == 60)
    try store.save(resumed.state)
    var again = try GameEngine(state: #require(try store.load(configuration: game.configuration)), configuration: game.configuration)
    again.advance(to: time.addingTimeInterval(140), offline: true)
    #expect(again.state.population == 4)
    #expect(again.state.resources.wood == 95)
    #expect(again.state.buildings.last?.id == 1)
}
@MainActor @Test func currentSessionReloadResumesConstructionWithoutChargingAgain() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("save.json")
    defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
    var now = Date(timeIntervalSince1970:2_000_000)
    let first = try GameSession(clock: { now }, saveURL:url)
    first.choose(.hut); first.confirm()
    #expect(first.state.resources.wood == 80 && first.housingCapacity == 5)
    now = now.addingTimeInterval(7)
    first.background()
    let second = try GameSession(clock: { now }, saveURL:url)
    #expect(second.state.buildings.last?.constructionRemainingSeconds == 8)
    now = now.addingTimeInterval(8)
    second.tick()
    #expect(second.state.resources.wood == 90 && second.housingCapacity == 10)
    #expect(second.state.buildings.count == 2)
}
