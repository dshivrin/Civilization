import Foundation
import Testing
import GameCore
import GameApplication
import GamePersistence

#if DEBUG
@Test func developerScenariosValidateAndRoundTrip() throws {
    let config = try GameConfiguration.bundled()
    for scenario in DeveloperScenario.allCases {
        let engine = try scenario.makeEngine(configuration: config, now: Date(timeIntervalSince1970: 1000))
        _ = try GameEngine(state: engine.state, configuration: engine.configuration)
        #expect(engine.state.population <= engine.housingCapacity)
        #expect(engine.state.mapID == engine.configuration.map.id)
        #expect(engine.state.nextBuildingID > engine.state.buildings.map(\.id).max()!)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        let store = SaveStore(url: url)
        try store.save(engine.state)
        #expect(try store.load(configuration: engine.configuration) == engine.state)
        switch scenario {
        case .early: #expect((3...5).contains(engine.state.population)); #expect(engine.researchedIDs.count <= 1)
        case .developed:
            #expect((20...30).contains(engine.state.population))
            #expect(engine.researchedIDs.count > 5 && engine.researchedIDs.count < config.technologyDefinitions.count)
            #expect(engine.discoveredTileCount > config.initialDiscoveredTiles!.count && engine.discoveredTileCount < 768)
            #expect(engine.state.buildings.contains { $0.kind == .toolmaker && engine.workersAllocated(to: $0) > 0 })
        case .late:
            #expect((50...70).contains(engine.state.population))
            #expect(engine.state.completedPillarGoals?.count == 4)
            #expect(engine.state.stoneAgeCompleted == false)
            #expect(engine.discoveredTileCount >= 600)
            #expect(engine.rates[.water] > 0)
            #expect(engine.rates[.food] > 0)
            #expect(!engine.state.buildings.contains { $0.kind == .palisade })
        case .grouped:
            #expect(engine.configuration.map.width == 64)
            #expect(engine.state.buildings.count == 64)
            #expect((engine.state.roads?.count ?? 0) > 200)
        }
    }
}
@Test func developerUnlockIncludesDependenciesAndPopulationClamps() throws {
    var engine = try GameEngine(configuration: .bundled(), now: .now)
    try engine.developerUnlockTechnology("fortification")
    #expect(engine.researchedIDs.contains("oralTradition"))
    #expect(engine.researchedIDs.contains("surveillance"))
    engine.developerAddPopulation(1_000)
    #expect(engine.state.population == engine.housingCapacity)
    let before = engine.state
    #expect(throws: GameError.self) { try engine.developerUnlockTechnology("missing") }
    #expect(engine.state == before)
    engine.developerAddResources(1_000_000)
    for resource in Resource.allCases { #expect(engine.state.resources[resource] == engine.capacities[resource]) }
    _ = try GameEngine(state: engine.state, configuration: engine.configuration)
}
@Test func developerFastConstructionIsExactlyThreeSeconds() throws {
    var engine = try DeveloperScenario.late.makeEngine(configuration: .bundled(), now: Date(timeIntervalSince1970: 1000))
    engine.developerAddResources(1000)
    let tile = try #require((0..<24).flatMap { y in (0..<32).map { Tile(x: $0, y: y) } }.first { engine.placementIssue(.hut, at: $0) == nil })
    engine.developerFastConstruction = true
    #expect(engine.constructionDuration(for: .hut) == 3)
    try engine.build(.hut, at: tile)
    #expect(engine.state.buildings.last?.constructionRemainingSeconds == 3)
    engine.advance(to: engine.state.lastUpdated.addingTimeInterval(2.9))
    #expect(engine.state.buildings.last?.isOperational == false)
    engine.advance(to: engine.state.lastUpdated.addingTimeInterval(0.1))
    #expect(engine.state.buildings.last?.isOperational == true)
    #expect(engine.configuration.definition(.hut).constructionSeconds == 15)
    #expect(engine.state.completedPillarGoals?.count == 4)
}
@MainActor @Test func developerSaveAndClockAreIsolated() throws {
    var now = Date(timeIntervalSince1970: 1000)
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = folder.appendingPathComponent("normal.json")
    let session = try GameSession(clock: { now }, saveURL: url)
    let normal = try Data(contentsOf: url)
    session.loadDeveloperScenario(.early)
    #expect(session.isDeveloperMode)
    session.setDeveloperPaused(true)
    let paused = session.state
    now = now.addingTimeInterval(60); session.tick()
    #expect(session.state.resources == paused.resources)
    session.setDeveloperSpeed(5); session.setDeveloperPaused(false)
    now = now.addingTimeInterval(1); session.tick()
    #expect(session.state.lastUpdated == now)
    session.advanceDeveloperTime(seconds: 60)
    session.background()
    #expect(try Data(contentsOf: url) == normal)
    #expect(FileManager.default.fileExists(atPath: url.appendingPathExtension("developer").path))
    session.returnToNormalGame()
    #expect(!session.isDeveloperMode)
    #expect(session.state.population == 3)
    #expect(session.state.buildings.count == 1)
}
@MainActor @Test func developerDoesNotRemoveCorruptNormalSaveProtection() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: url); try? FileManager.default.removeItem(at: url.appendingPathExtension("developer")) }
    let original = Data("corrupt".utf8); try original.write(to: url)
    let session = try GameSession(saveURL: url)
    session.loadDeveloperScenario(.developed)
    session.returnToNormalGame(); session.save()
    #expect(session.persistenceWarning != nil)
    #expect(try Data(contentsOf: url) == original)
}
@Test func lateScenarioFinalObjectiveIsReachable() throws {
    var engine = try DeveloperScenario.late.makeEngine(configuration: .bundled(), now: .now)
    try engine.developerUnlockTechnology("fortification")
    engine.developerAddResources(1000)
    let tile = try #require((0..<24).flatMap { y in (0..<32).map { Tile(x: $0, y: y) } }.first { engine.placementIssue(.palisade, at: $0) == nil })
    engine.developerFastConstruction = true
    try engine.build(.palisade, at: tile)
    engine.advance(to: engine.state.lastUpdated.addingTimeInterval(3))
    #expect(engine.state.completedPillarGoals?.count == 5)
    #expect(engine.state.stoneAgeCompleted == true)
    _ = try GameEngine(state: engine.state, configuration: engine.configuration)
}
@MainActor @Test func developerSpeedPauseAndBackgroundRespectConstructionClock() throws {
    var now = Date(timeIntervalSince1970: 1000)
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("normal.json")
    defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
    let session = try GameSession(clock: { now }, saveURL: url)
    session.loadDeveloperScenario(.early)
    session.setDeveloperFastConstruction(true)
    session.choose(.hut); session.confirm()
    #expect(session.constructionQueue.last?.constructionRemainingSeconds == 3)
    session.setDeveloperSpeed(2)
    now = now.addingTimeInterval(1); session.tick()
    #expect(session.constructionQueue.last?.constructionRemainingSeconds == 1)
    session.setDeveloperPaused(true)
    now = now.addingTimeInterval(100); session.tick()
    #expect(session.constructionQueue.last?.constructionRemainingSeconds == 1)
    session.setActive(false)
    now = now.addingTimeInterval(10000)
    session.setActive(true)
    #expect(session.constructionQueue.last?.constructionRemainingSeconds == 1)
    session.advanceDeveloperTime(seconds: 1)
    #expect(session.constructionQueue.isEmpty)
    session.returnToNormalGame()
    session.choose(.hut); session.confirm()
    #expect(session.constructionQueue.last?.constructionRemainingSeconds == 15)
}
@MainActor @Test func developerSaveResumesWithoutOfflineOrSettings() throws {
    var now = Date(timeIntervalSince1970: 1000)
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("normal.json")
    defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
    let first = try GameSession(clock: { now }, saveURL: url)
    first.loadDeveloperScenario(.developed)
    first.setDeveloperPaused(true); first.setDeveloperSpeed(10); first.setDeveloperFastConstruction(true)
    first.save()
    let expected = first.state
    now = now.addingTimeInterval(100_000)
    let second = try GameSession(clock: { now }, saveURL: url)
    #expect(!second.isDeveloperMode)
    second.resumeDeveloperSettlement()
    #expect(second.isDeveloperMode)
    #expect(second.developerScenario == .developed)
    #expect(second.state.resources == expected.resources)
    #expect(second.state.buildings == expected.buildings)
    #expect(second.state.lastUpdated == now)
    #expect(!second.developerPaused && second.developerSpeed == 1 && !second.developerFastConstruction)
    second.loadDeveloperScenario(second.developerScenario)
    #expect(second.state.population == 24)
}

@MainActor @Test func developerResetArchivesCorruptDeveloperFile() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = folder.appendingPathComponent("normal.json")
    let session = try GameSession(saveURL: url)
    let damaged = Data("broken developer save".utf8)
    try damaged.write(to: url.appendingPathExtension("developer"))
    session.loadDeveloperScenario(.early)
    #expect(session.isDeveloperMode && session.persistenceWarning == nil)
    let files = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
    let backup = try #require(files.first { $0.pathExtension == "bak" })
    #expect(try Data(contentsOf: backup) == damaged)
    #expect(try SaveStore(url: url).load(configuration: .bundled())?.buildings.count == 1)
}

#else
@Test func releaseUsesNormalConstructionAndPersistence() throws {
    let config = try GameConfiguration.bundled()
    var engine = try GameEngine(configuration: config, now: .now)
    let tile = try #require((0..<24).flatMap { y in (0..<32).map { Tile(x: $0, y: y) } }.first { engine.placementIssue(.hut, at: $0) == nil })
    try engine.build(.hut, at: tile)
    #expect(engine.state.buildings.last?.constructionRemainingSeconds == config.definition(.hut).constructionSeconds)
}
#endif

#if DEBUG
@MainActor @Test func renderBenchmarkNeverTouchesExistingSettlementFiles() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: folder) }
    let normal = folder.appendingPathComponent("settlement-v1.json")
    let original = Data("protected normal save".utf8)
    try original.write(to: normal)
    let session = try GameSession.renderBenchmark(in: folder, clock: { Date(timeIntervalSince1970: 1000) })
    #expect(session.isDeveloperMode)
    #expect(session.developerScenario == .late)
    #expect(session.state.buildings.count >= 20)
    session.tick();session.save()
    #expect(try Data(contentsOf: normal) == original)
    #expect(!FileManager.default.fileExists(atPath: normal.appendingPathExtension("developer").path))
}
#endif
