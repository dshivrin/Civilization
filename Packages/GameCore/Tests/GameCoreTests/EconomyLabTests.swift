#if DEBUG
import Foundation
import Testing
import GameCore
import GameApplication
import GamePersistence

private let labEpoch = Date(timeIntervalSince1970: 40_000_000)
private func newLab() throws -> RiverbendEconomyLab { try RiverbendEconomyLab(now: labEpoch) }
private func buildLab(_ kind: BuildingKind, _ lab: inout RiverbendEconomyLab) throws {
    try lab.build(kind, at: #require(lab.sites(for: kind).first))
    try lab.advance(by: lab.engine.configuration.definition(kind).constructionSeconds ?? 0)
}

@Test func economyLabOpeningCostsWorkersAndWaterlessGrowth() throws {
    var lab = try newLab()
    #expect(lab.engine.state.population == 3)
    #expect(lab.engine.state.resources == ResourceAmounts(food: 32, wood: 32))
    #expect(lab.engine.rates.food == -1)
    #expect(lab.engine.workforceAvailable == 2)
    #expect(lab.engine.housingCapacity == 3)
    #expect(lab.engine.rates[.water] == 0)
    try buildLab(.hut, &lab)
    #expect(lab.engine.state.resources.wood == 20)
    #expect(lab.engine.housingCapacity == 6)
    try buildLab(.gatheringShelter, &lab)
    #expect(lab.engine.state.resources.wood == 12)
    #expect(lab.engine.rates.food == 7)
    try lab.advance(by: 240)
    #expect(lab.engine.state.population == 4)
    #expect(lab.engine.state.resources[.water] == 0)
}

@Test func economyLabSurveyIsContiguousPaidOnceAndReloadable() throws {
    var lab = try newLab()
    #expect(throws: (any Error).self) { try lab.startSurvey() }
    try buildLab(.hut, &lab)
    let forest = lab.region.forestTiles
    var visited: Set<Tile> = [try #require(forest.first)]
    var queue = Array(visited), cursor = 0
    while cursor < queue.count {
        for edge in RoadGeometry.neighbors(of: queue[cursor]) where forest.contains(edge.tile) && visited.insert(edge.tile).inserted { queue.append(edge.tile) }
        cursor += 1
    }
    #expect(visited == forest)
    #expect(lab.region.woodcutterOrigins.count > 1)
    let food = lab.engine.state.resources.food
    try lab.startSurvey()
    #expect(lab.engine.state.resources.food == food - 8)
    #expect(lab.engine.workforceAvailable == 2)
    let paid = try lab.encoded()
    #expect(throws: (any Error).self) { try lab.startSurvey() }
    lab = try RiverbendEconomyLab(data: paid)
    try lab.advance(by: 30)
    #expect(!lab.surveyComplete)
    #expect(lab.engine.state.resources.knowledge == 0)
    lab = try RiverbendEconomyLab(data: lab.encoded())
    try lab.advance(by: 30)
    #expect(lab.surveyComplete)
    #expect(lab.region.tiles.allSatisfy(lab.engine.isDiscovered))
    var accessible: Set<Tile> = [lab.engine.configuration.map.campfire]
    var accessQueue = Array(accessible), accessIndex = 0
    while accessIndex < accessQueue.count {
        for edge in RoadGeometry.neighbors(of: accessQueue[accessIndex]) {
            let t = edge.tile, terrain = lab.engine.configuration.map.terrain(at: t)
            if lab.engine.isDiscovered(t), (terrain == .grass || terrain == .clearing),
               lab.engine.building(at: t) == nil, accessible.insert(t).inserted { accessQueue.append(t) }
        }
        accessIndex += 1
    }
    #expect(lab.sites(for: .woodcutter).filter { accessible.contains($0) }.count >= 2)
    #expect(lab.engine.state.resources.knowledge == 6)
    #expect(throws: (any Error).self) { try lab.startSurvey() }
    lab = try RiverbendEconomyLab(data: lab.encoded())
    try lab.advance(by: 60)
    #expect(lab.engine.state.resources.knowledge == 6)
    try buildLab(.woodcutter, &lab)
    try buildLab(.gatheringShelter, &lab)
    #expect(lab.engine.rates.wood == 6)
    #expect(lab.engine.rates.food > 0)
}

@Test func economyLabRecoveryHandlesEmptyBeforeAndAfterHutAndDelayedStart() throws {
    for afterHut in [false, true] {
        var lab = try newLab()
        if afterHut { try buildLab(.hut, &lab) }
        // Isolated lab save fixture, never a player save edit.
        var object = try #require(JSONSerialization.jsonObject(with: lab.encoded()) as? [String: Any])
        var state = try #require(object["state"] as? [String: Any])
        var resources = try #require(state["resources"] as? [String: Any])
        resources["food"] = 0; resources["wood"] = 0; state["resources"] = resources; object["state"] = state
        lab = try RiverbendEconomyLab(data: JSONSerialization.data(withJSONObject: object))
        try lab.recover(.food); try lab.recover(.wood)
        #expect(lab.engine.state.resources.food == 12)
        #expect(lab.engine.state.resources.wood == (afterHut ? 8 : 12))
        try lab.recover(.wood); try lab.recover(.food)
        #expect(lab.engine.state.resources.food == 12)
        if !afterHut { try buildLab(.hut, &lab); try lab.recover(.wood) }
        try lab.startSurvey()
        try lab.advance(by: 60)
        try buildLab(.gatheringShelter, &lab)
        try lab.recover(.wood)
        try buildLab(.woodcutter, &lab)
        #expect(lab.engine.rates.food > 0 && lab.engine.rates.wood > 0)
    }
    var delayed = try newLab()
    try delayed.advance(by: 3600)
    #expect(delayed.engine.state.resources.food == 0)
    try delayed.recover(.food)
    try buildLab(.hut, &delayed)
    try delayed.startSurvey()
    try delayed.advance(by: 60)
    try buildLab(.woodcutter, &delayed)
    try buildLab(.gatheringShelter, &delayed)
    #expect(delayed.checkpointReached)
}

@Test func economyLabInvalidTransactionsAndCapacityStayDeterministic() throws {
    var lab = try newLab()
    let before = lab.engine.state
    #expect(throws: (any Error).self) { try lab.build(.hut, at: lab.engine.configuration.map.campfire) }
    #expect(throws: (any Error).self) { try lab.build(.woodcutter, at: Tile(x: -1,y: -1)) }
    #expect(throws: (any Error).self) { try lab.recover(.stone) }
    #expect(throws: (any Error).self) { try lab.advance(by: .nan) }
    #expect(lab.engine.state == before)
    try buildLab(.hut, &lab)
    try lab.startSurvey(); try lab.advance(by: 60)
    // Occupy the primary cutter site with the legal optional gatherer; fallback survives.
    let primary = try #require(lab.sites(for: .woodcutter).first)
    try lab.build(.gatheringShelter, at: primary)
    #expect(!lab.sites(for: .woodcutter).contains(primary))
    try lab.advance(by: 60)
    try buildLab(.woodcutter, &lab)
    try lab.advance(by: 3600)
    #expect(lab.engine.state.resources.food == 60)
    #expect(lab.engine.state.resources.wood == 60)
    #expect(lab.engine.state.population == 6)
    #expect(lab.engine.state.resources[.water] == 0)
    #expect(lab.engine.rates.food == 4)
    #expect(throws: (any Error).self) { try lab.build(.storehouse, at: primary) }
    let normal = try GameConfiguration.bundled()
    #expect(normal.initialResources[.water] == 60)
    #expect(normal.map.id != lab.engine.configuration.map.id)
    #expect(normal.definition(.hut).cost != lab.engine.configuration.definition(.hut).cost)
}

@Test func economyLabStoreFailureNeverPublishesAndOtherModesRemainByteIdentical() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let originals = ["settlement-v1.json", "developer.json", "round2.json", "games-index.json"]
    for name in originals { try Data(("preserve-" + name).utf8).write(to: root.appendingPathComponent(name)) }
    var store = try RiverbendEconomyLabStore(directory: root, now: labEpoch)
    try store.perform { try buildLab(.hut, &$0) }
    try store.perform { try $0.startSurvey() }
    let paid = store.lab.engine.state
    store = try RiverbendEconomyLabStore(directory: root, now: labEpoch.addingTimeInterval(100000))
    #expect(store.lab.engine.state == paid)
    #expect(store.lab.surveyRemaining == 60)
    try store.perform { try $0.advance(by: 60) }
    let before = store.lab.engine.state
    let bytes = try Data(contentsOf: store.url)
    // A directory at the target filename makes atomic publication fail deterministically.
    try FileManager.default.removeItem(at: store.url)
    try FileManager.default.createDirectory(at: store.url, withIntermediateDirectories: false)
    #expect(throws: (any Error).self) { try store.perform { try $0.advance(by: 60) } }
    #expect(store.lab.engine.state == before)
    try FileManager.default.removeItem(at: store.url)
    try bytes.write(to: store.url)
    for name in originals { #expect(try Data(contentsOf: root.appendingPathComponent(name)) == Data(("preserve-" + name).utf8)) }
    try Data("corrupt".utf8).write(to: store.url)
    #expect(throws: (any Error).self) { _ = try RiverbendEconomyLabStore(directory: root, now: labEpoch) }
    #expect(try Data(contentsOf: store.url) == Data("corrupt".utf8))
}

@Test func economyLabRejectsWrongProfileAndSurveyContradictions() throws {
    let lab = try newLab()
    var object = try #require(JSONSerialization.jsonObject(with: lab.encoded()) as? [String: Any])
    object["profile"] = "normal"
    #expect(throws: (any Error).self) { _ = try RiverbendEconomyLab(data: JSONSerialization.data(withJSONObject: object)) }
    object["profile"] = GameConfiguration.riverbendLabID
    object["surveyComplete"] = true
    #expect(throws: (any Error).self) { _ = try RiverbendEconomyLab(data: JSONSerialization.data(withJSONObject: object)) }
}

@Test @MainActor func economyLabPreservesAuthenticNormalDeveloperRound2AndLibraryFiles() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent("economy-isolation-" + UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let library = try await GameLibrary.load(rootURL: root, clock: { labEpoch })
    let session = library.session
    session.loadDeveloperScenario(.early)
    #expect(session.returnToNormalGame())
    session.startGameplayReview(); session.activateReviewConnectivity(); session.save()
    #expect(session.isGameplayReview && session.usesConnectedPaths)
    #expect(session.returnToNormalGame())
    session.save()
    func files() throws -> [URL: Data] {
        let enumerator = try #require(FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.isRegularFileKey]))
        var result: [URL: Data] = [:]
        for case let url as URL in enumerator where try url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true {
            if !url.path.contains(GameConfiguration.riverbendLabID) { result[url] = try Data(contentsOf: url) }
        }
        return result
    }
    let before = try files()
    #expect(before.count >= 4)
    var store = try RiverbendEconomyLabStore(directory: root, now: labEpoch)
    try store.perform { lab in
        try buildLab(.hut, &lab); try lab.startSurvey(); try lab.advance(by: 60)
        try buildLab(.woodcutter, &lab); try buildLab(.gatheringShelter, &lab)
    }
    #expect(store.lab.checkpointReached)
    try store.perform { lab in
        try lab.advance(by: 600); try lab.revealStone()
        try lab.build(.stoneGatherer, at: #require(lab.sites(for: .stoneGatherer).first))
        try lab.advance(by: 600)
        try lab.buildStorage(.granary, at: #require(lab.storageSites(for: .granary).first))
        try lab.advance(by: 120)
        try lab.buildStorage(.stockyard, at: #require(lab.storageSites(for: .stockyard).first))
        try lab.advance(by: 120)
    }
    try store.perform { lab in
        try lab.unlockCraft(); try lab.setGatheringMode(.flint); try lab.advance(by: 90)
        for _ in 0..<3 { try lab.startToolBatch(); try lab.advance(by: 60) }
        try lab.improveWoodcutter()
    }
    #expect(store.lab.craft?.woodcutterImproved == true)
    for find in store.lab.availableFinds {
        try store.perform { try $0.resolveFind(find.id, at: #require(find.tile)) }
    }
    _ = try RiverbendEconomyLabStore(directory: root, now: labEpoch.addingTimeInterval(5000))
    #expect(try files() == before)
}

@Test func economyLabTenMinuteTrace() throws {
    var lab = try newLab()
    func trace(_ label: String) {
        print("LAB_TRACE \(label) seconds=\(lab.engine.state.lastUpdated.timeIntervalSince(labEpoch)) food=\(lab.engine.state.resources.food) wood=\(lab.engine.state.resources.wood) foodNet=\(lab.engine.rates.food) woodNet=\(lab.engine.rates.wood) people=\(lab.engine.state.population)")
    }
    trace("start")
    try buildLab(.hut, &lab); trace("hut")
    try lab.startSurvey(); trace("survey-paid")
    try lab.advance(by: 60); trace("forest")
    try buildLab(.woodcutter, &lab); trace("woodcutter")
    try buildLab(.gatheringShelter, &lab); trace("gatherer")
    let remaining = 600 - lab.engine.state.lastUpdated.timeIntervalSince(labEpoch)
    try lab.advance(by: remaining); trace("minute10")
    #expect(lab.checkpointReached)
    #expect(lab.engine.state.resources.food == 60)
    #expect(lab.engine.state.resources.wood > 0)
}

@Test func economyLabInsufficientSurveyAndFailedCompletionCannotChargeOrReveal() throws {
    var lab = try newLab(); try buildLab(.hut, &lab)
    try lab.advance(by: 3600)
    let before = lab.engine.state
    #expect(throws: (any Error).self) { try lab.startSurvey() }
    #expect(lab.engine.state == before && lab.surveyRemaining == nil)
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    var store = try RiverbendEconomyLabStore(directory: root, now: labEpoch)
    try store.perform { try buildLab(.hut, &$0) }
    func blockFile(_ url: URL) throws -> Data {
        let data = try Data(contentsOf: url)
        try FileManager.default.removeItem(at: url)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
        return data
    }
    func restoreFile(_ data: Data, _ url: URL) throws {
        try FileManager.default.removeItem(at: url); try data.write(to: url)
    }
    var paidBefore = store.lab.engine.state
    var saved = try blockFile(store.url)
    #expect(throws: (any Error).self) { try store.perform { try $0.startSurvey() } }
    #expect(store.lab.engine.state == paidBefore && store.lab.surveyRemaining == nil)
    try restoreFile(saved, store.url)
    try store.perform { try $0.startSurvey() }
    paidBefore = store.lab.engine.state; saved = try blockFile(store.url)
    #expect(throws: (any Error).self) { try store.perform { try $0.advance(by: 60) } }
    #expect(store.lab.engine.state == paidBefore && store.lab.surveyRemaining == 60 && !store.lab.surveyComplete)
    try restoreFile(saved, store.url)
    try store.perform { try $0.advance(by: 60) }
    #expect(store.lab.surveyComplete && store.lab.engine.state.resources.knowledge == 6)
    let reloaded = try RiverbendEconomyLabStore(directory: root, now: labEpoch)
    #expect(reloaded.lab.surveyComplete && reloaded.lab.engine.state.resources.knowledge == 6)
}
#endif
