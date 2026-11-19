import Foundation
import Testing
import GameApplication

@MainActor @Test func backgroundInactiveForegroundUsesOfflineCapOnce() throws {
    var now = Date(timeIntervalSince1970: 1000)
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let session = try GameSession(clock: { now }, saveURL: folder.appendingPathComponent("save.json"), configuration: baselineConfiguration())
    session.choose(.storytellingCircle) // Locked: cannot build and cannot charge.
    let initial = session.state.resources
    session.confirm()
    #expect(session.state.resources == initial)
    session.setActive(false)
    now = now.addingTimeInterval(100_000)
    session.setActive(false) // Background -> inactive must not run uncapped production.
    session.tick() // Timer callbacks must not simulate while inactive.
    #expect(session.state.resources == initial)
    session.setActive(true)
    #expect(session.state.resources[.food] == 500)
    let after = session.state
    session.setActive(true)
    #expect(session.state == after)
    #expect(session.state.lastUpdated == now)
}
@MainActor @Test func sessionPreservesCorruptSaveAcrossActions() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: url) }
    let original = Data("corrupt".utf8)
    try original.write(to: url)
    let session = try GameSession(saveURL: url, configuration: baselineConfiguration())
    #expect(session.persistenceWarning != nil)
    session.choose(.hut)
    session.confirm()
    session.background()
    #expect(try Data(contentsOf: url) == original)
}

@MainActor @Test func sessionReloadKeepsBuildingsAndDoesNotRegrantGoalReward() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("save.json")
    defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
    let time = Date(timeIntervalSince1970: 1000)
    let first = try GameSession(clock: { time }, saveURL: url, configuration: baselineConfiguration())
    first.choose(.hut); first.confirm()
    #expect(first.state.resources[.wood] == 90)
    let second = try GameSession(clock: { time }, saveURL: url, configuration: baselineConfiguration())
    #expect(second.state == first.state)
    second.choose(.hut); second.confirm()
    #expect(second.state.resources[.wood] == 70)
    #expect(second.state.buildings.count == 3)
    #expect(second.housingCapacity == 15)
}
