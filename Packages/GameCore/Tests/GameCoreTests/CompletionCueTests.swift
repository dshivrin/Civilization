import Foundation
import Testing
import GameCore
import GameApplication
import GamePersistence

private let cueEpoch = Date(timeIntervalSince1970: 100_000_000)
private func cueInbox(_ state: GameState) throws -> [String: Any] {
    let json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as? [String: Any])
    return json["completionInbox"] as? [String: Any] ?? [:]
}

// Catches missing compatible per-game delivery state and historical snapshot inference.
@Test @MainActor func completionCueNewGameAndLegacySnapshotStartQuiet() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let url = root.appendingPathComponent("save.json")
    let c = try GameConfiguration.riverbendPlayer()
    let session = try GameSession(clock: { cueEpoch }, saveURL: url, configuration: c)
    let inbox = try cueInbox(session.state)
    #expect(inbox["unread"] as? [String] == [])
}

private func cueUnread(_ state: GameState) -> Set<String> { state.completionInbox?.unread ?? [] }
// Catches missing authoritative command delivery, duplicate pulses and cross-destination clearing.
@Test @MainActor func completionCueSuccessfulResearchAndObjectivesCoalesceAndPersist() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let url = root.appendingPathComponent("save.json")
    var c = try GameConfiguration.bundled(); c.initialResources.knowledge = 100
    let session = try GameSession(clock: { cueEpoch }, saveURL: url, configuration: c)
    session.research("oralTradition")
    #expect(session.researchedIDs.contains("oralTradition"))
    #expect(cueUnread(session.state).contains("research:oralTradition"))
    #expect(cueUnread(session.state).contains("objective:1:technology-oralTradition"))
    let earned = session.state
    session.research("oralTradition")
    #expect(session.state == earned)
    let loaded = try GameSession(clock: { cueEpoch }, saveURL: url, configuration: c)
    #expect(cueUnread(loaded.state) == cueUnread(earned))
    loaded.setActive(false); loaded.setActive(true)
    #expect(cueUnread(loaded.state) == cueUnread(earned))
}

// Catches bootstrapping a pre-feature completed snapshot as newly earned.
@Test @MainActor func completionCueHistoricalResearchStaysReadAndGamesStayIndependent() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let url = root.appendingPathComponent("old.json")
    var c = try GameConfiguration.bundled(); c.initialResources.knowledge = 100
    var old = try GameEngine(configuration: c, now: cueEpoch)
    try old.research("oralTradition")
    try SaveStore(url: url).save(old.state)
    let loaded = try GameSession(clock: { cueEpoch }, saveURL: url, configuration: c)
    #expect(cueUnread(loaded.state).isEmpty)
    loaded.tick()
    #expect(cueUnread(loaded.state).isEmpty)
    loaded.research("hunting")
    #expect(cueUnread(loaded.state) == ["research:hunting", "objective:2:technology-hunting"])
    let other = try GameSession(clock: { cueEpoch }, saveURL: root.appendingPathComponent("other.json"), configuration: c)
    #expect(cueUnread(other.state).isEmpty)
}

// Catches replay on reload/foreground and loss of an unrelated unread destination.
@Test @MainActor func completionCueDurablePulseAndTargetedAcknowledgement() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let url = root.appendingPathComponent("save.json"), c = try GameConfiguration.riverbendPlayer()
    let s = try GameSession(clock: { cueEpoch }, saveURL: url, configuration: c)
    #expect(s.completionSequence == 0 && s.latestCompletions.isEmpty)
    s.research("oralTradition")
    #expect(s.completionSequence == 1)
    #expect(Set(s.latestCompletions.map(\.destination)) == [.research, .goals])
    #expect(s.unreadCompletions(for: .research) == ["research:oralTradition"])
    #expect(s.unreadCompletions(for: .goals) == ["objective:3:technology-oralTradition"])
    s.research("oralTradition"); s.tick(); s.setActive(false); s.setActive(true)
    #expect(s.completionSequence == 1)
    let loaded = try GameSession(clock: { cueEpoch }, saveURL: url, configuration: c)
    #expect(loaded.completionSequence == 0 && loaded.latestCompletions.isEmpty)
    #expect(loaded.unreadCompletions(for: .research) == ["research:oralTradition"])
    loaded.acknowledgeCompletions(["research:unknown", "research:oralTradition"])
    #expect(loaded.unreadCompletions(for: .research).isEmpty)
    #expect(loaded.unreadCompletions(for: .goals) == ["objective:3:technology-oralTradition"])
    let again = try GameSession(clock: { cueEpoch }, saveURL: url, configuration: c)
    #expect(again.unreadCompletions(for: .research).isEmpty)
    #expect(again.unreadCompletions(for: .goals) == ["objective:3:technology-oralTradition"])
    again.acknowledgeCompletions(["objective:3:technology-oralTradition"])
    #expect(again.unreadCompletions(for: .goals).isEmpty)
    #expect(again.completionSequence == 0)
}

// Catches falsely celebrating an action that could not be durably saved.
@Test @MainActor func completionCueFailedSaveRollsBackEarnAndAcknowledgement() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let held = root.appendingPathExtension("held")
    defer { try? FileManager.default.removeItem(at: root); try? FileManager.default.removeItem(at: held) }
    let url = root.appendingPathComponent("save.json"), c = try GameConfiguration.riverbendPlayer()
    let s = try GameSession(clock: { cueEpoch }, saveURL: url, configuration: c)
    let before = s.state
    try FileManager.default.moveItem(at: root, to: held)
    try Data("blocked".utf8).write(to: root)
    s.research("oralTradition")
    #expect(s.state == before)
    #expect(s.completionSequence == 0 && s.latestCompletions.isEmpty)
    #expect(s.persistenceWarning != nil)
    try FileManager.default.removeItem(at: root)
    try FileManager.default.moveItem(at: held, to: root)
    s.research("oralTradition")
    #expect(s.completionSequence == 1)
    let earned = s.state
    try FileManager.default.moveItem(at: root, to: held)
    try Data("blocked".utf8).write(to: root)
    s.acknowledgeCompletions(["research:oralTradition"])
    #expect(s.state == earned)
    #expect(s.unreadCompletions(for: .research) == ["research:oralTradition"])
}

// Exercises a real chapter earned by normal construction at supplied model time.
@Test @MainActor func completionCueChapterCompletionAndLegacyReadBaselineAreDurable() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let url = root.appendingPathComponent("save.json"), c = try GameConfiguration.riverbendPlayer()
    var now = cueEpoch
    let s = try GameSession(clock: { now }, saveURL: url, configuration: c)
    s.upgrade(buildingID: 0)
    s.choose(.hut); s.tap(Tile(x: 20, y: 10)); s.confirm()
    #expect(s.state.buildings.count == 2)
    now = now.addingTimeInterval(60); s.tick()
    #expect(s.state.civicProgress?.completedChapters.contains(1) == true)
    #expect(s.unreadCompletions(for: .goals).isSuperset(of: ["chapter:1", "objective:1:civic-level-2", "objective:1:building-hut"]))
    let sequence = s.completionSequence
    s.tick(); #expect(s.completionSequence == sequence)
    let loaded = try GameSession(clock: { now }, saveURL: url, configuration: c)
    #expect(loaded.unreadCompletions(for: .goals) == s.unreadCompletions(for: .goals))
    #expect(loaded.completionSequence == 0)
    loaded.acknowledgeCompletions(["chapter:1"])
    #expect(!loaded.unreadCompletions(for: .goals).contains("chapter:1"))
    #expect(loaded.unreadCompletions(for: .goals).isSuperset(of: ["objective:1:civic-level-2", "objective:1:building-hut"]))
    var legacy = s.state; legacy.completionInbox = nil
    let legacyURL = root.appendingPathComponent("legacy.json")
    try SaveStore(url: legacyURL).save(legacy)
    let historical = try GameSession(clock: { now }, saveURL: legacyURL, configuration: c)
    historical.tick()
    #expect(historical.unreadCompletions(for: .goals).isEmpty)
    #expect(historical.completionSequence == 0)
}

// Existing gameplay preservation tests compare authoritative state independently of
// the newly added silent presentation baseline, whose behavior is tested above.
func withoutCompletionInbox(_ state: GameState) -> GameState {
    var gameplay = state; gameplay.completionInbox = nil; return gameplay
}

@Test @MainActor func completionCueLibraryGamesKeepIndependentUnreadForIdenticalEarnIDs() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let library = try await GameLibrary.startNewGame(rootURL: root, clock: { cueEpoch })
    let firstID = library.activeGameID
    library.session.research("oralTradition")
    #expect(library.session.unreadCompletions(for: .research) == ["research:oralTradition"])
    let second = try await library.createGame(name: "Independent")
    #expect(library.session.unreadCompletions(for: .research).isEmpty)
    library.session.research("oralTradition")
    library.session.acknowledgeCompletions(["research:oralTradition"])
    try await library.openGame(id: firstID)
    #expect(library.session.unreadCompletions(for: .research) == ["research:oralTradition"])
    #expect(library.session.completionSequence == 0)
    try await library.openGame(id: second.id)
    #expect(library.session.unreadCompletions(for: .research).isEmpty)
    #expect(library.session.completionSequence == 0)
}

// Foreground catch-up can earn legacy progress, but must never start a HUD pulse.
@Test @MainActor func completionCueLegacyOfflineEarnIsUnreadWithoutForegroundPulse() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let url = root.appendingPathComponent("save.json"), c = try GameConfiguration.bundled()
    var engine = try GameEngine(configuration: c, now: cueEpoch)
    try engine.build(.hut, at: Tile(x: 12, y: 12))
    try SaveStore(url: url).save(engine.state)
    var now = cueEpoch
    let s = try GameSession(clock: { now }, saveURL: url, configuration: c)
    s.setActive(false); now = now.addingTimeInterval(60); s.setActive(true)
    #expect(s.unreadCompletions(for: .goals).contains("objective:1:building-hut"))
    #expect(s.completionSequence == 0 && s.latestCompletions.isEmpty)
}

@Test @MainActor func completionCueFirstLegacyContinueKeepsNewOfflineEarnUnread() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let url = root.appendingPathComponent("save.json"), c = try GameConfiguration.bundled()
    var engine = try GameEngine(configuration: c, now: cueEpoch)
    try engine.build(.hut, at: Tile(x: 12, y: 12))
    try SaveStore(url: url).save(engine.state)
    let s = try GameSession(clock: { cueEpoch.addingTimeInterval(60) }, saveURL: url, configuration: c)
    #expect(s.unreadCompletions(for: .goals).contains("objective:1:building-hut"))
    #expect(s.completionSequence == 0 && s.latestCompletions.isEmpty)
}

@Test @MainActor func completionCueLegacyHUDWaitsForSuccessfulPublication() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let held = root.appendingPathExtension("held")
    defer { try? FileManager.default.removeItem(at: root); try? FileManager.default.removeItem(at: held) }
    let url = root.appendingPathComponent("save.json")
    var c = try GameConfiguration.bundled(); c.initialResources.knowledge = 100
    var now = cueEpoch
    let s = try GameSession(clock: { now }, saveURL: url, configuration: c)
    s.choose(.hut); s.tap(Tile(x: 12, y: 12)); s.confirm()
    now = now.addingTimeInterval(60); s.tick() // Prior autosave completes construction.
    s.choose(.gatheringShelter); s.tap(Tile(x: 14, y: 14)); s.confirm()
    // A research action whose file publication fails must not expose a new HUD marker.
    try FileManager.default.moveItem(at: root, to: held); try Data("blocked".utf8).write(to: root)
    s.research("oralTradition")
    #expect(s.unreadCompletions(for: .research).isEmpty)
    try FileManager.default.removeItem(at: root); try FileManager.default.moveItem(at: held, to: root)
    s.save()
    #expect(s.unreadCompletions(for: .research) == ["research:oralTradition"])
}

@Test @MainActor func completionCueBurstRetainsAllCategoriesUntilConsumed() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let s = try GameSession(clock: { cueEpoch }, saveURL: root.appendingPathComponent("save.json"), configuration: .riverbendPlayer())
    s.research("oralTradition"); s.upgrade(buildingID: 0)
    #expect(s.completionSequence == 2)
    #expect(Set(s.latestCompletions.map(\.destination)) == [.research, .goals])
    #expect(Set(s.latestCompletions.map(\.id)).isSuperset(of: ["research:oralTradition", "objective:1:civic-level-2"]))
    #expect(Set(s.consumeCompletionDelivery().map(\.destination)) == [.research, .goals])
    #expect(s.consumeCompletionDelivery().isEmpty)
}

@Test func completionCueHiddenGamesSheetDefersOnePulseAndReduceMotionStaysStatic() {
    var p = CompletionCuePresentation()
    p.enqueue([.research]); p.enqueue([.goals])
    let hidden = p.begin(visible: false, active: true, reduceMotion: false, unread: [.research, .goals]); #expect(!hidden)
    #expect(p.pending == [.research, .goals] && p.pulsing.isEmpty)
    let shown = p.begin(visible: true, active: true, reduceMotion: false, unread: [.research, .goals]); #expect(shown)
    #expect(p.pending.isEmpty && p.pulsing == [.research, .goals])
    p.finish()
    let replay = p.begin(visible: true, active: true, reduceMotion: false, unread: [.research, .goals]); #expect(!replay)
    p.enqueue([.research])
    let reduced = p.begin(visible: true, active: true, reduceMotion: true, unread: [.research]); #expect(!reduced)
    #expect(p.pending.isEmpty && p.pulsing.isEmpty)
    p.enqueue([.goals]); p.clear()
    let foreground = p.begin(visible: true, active: true, reduceMotion: false, unread: [.goals]); #expect(!foreground)
}

@Test @MainActor func completionCueLegacyAutosaveDoesNotExposeUnpublishedEarn() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    var c = try GameConfiguration.bundled()
    c.buildings[c.buildings.firstIndex { $0.kind == .hut }!].constructionSeconds = 1
    var now = cueEpoch
    let s = try GameSession(clock: { now }, saveURL: root.appendingPathComponent("save.json"), configuration: c)
    s.choose(.hut); s.tap(Tile(x: 12, y: 12)); s.confirm()
    now = now.addingTimeInterval(2); s.tick()
    #expect(s.state.civicProgress?.completedObjectives.contains("1:building-hut") == true)
    #expect(!s.unreadCompletions(for: .goals).contains("objective:1:building-hut"))
    now = now.addingTimeInterval(15); s.tick()
    #expect(s.unreadCompletions(for: .goals).contains("objective:1:building-hut"))
}

#if DEBUG
@Test @MainActor func completionCueDeveloperCopyCannotExposeOrAcknowledgeNormalUnread() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let s = try GameSession(clock: { cueEpoch }, saveURL: root.appendingPathComponent("save.json"), configuration: .riverbendPlayer())
    s.research("oralTradition")
    s.loadDeveloperScenario(.early)
    #expect(s.unreadCompletions(for: .research).isEmpty)
    s.acknowledgeCompletions(["research:oralTradition"])
    #expect(s.returnToNormalGame())
    #expect(s.unreadCompletions(for: .research) == ["research:oralTradition"])
}
#endif
