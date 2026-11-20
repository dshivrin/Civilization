#if DEBUG
import Foundation
import Testing
import GameCore
import GameApplication
import GamePersistence

@Test func largeGroupedVillagePreservesCoreAndConnectsEveryBuilding() throws {
    let original = try GameConfiguration.bundled()
    let engine = try DeveloperScenario.grouped.makeEngine(configuration: original, now: Date(timeIntervalSince1970: 1000))
    let config = engine.configuration
    #expect(config.map.width == 64 && config.map.height == 48)
    #expect(config.map.id != original.map.id)
    for y in 0..<24 { #expect(String(config.map.rows[y].prefix(32)) == original.map.rows[y]) }
    #expect(config.map.campfire == original.map.campfire)
    #expect(engine.state.buildings.count == 64)
    #expect(engine.state.buildings.filter { $0.kind == .hut }.count == 24)
    #expect(Set(engine.state.buildings.map(\.kind)) == Set(original.buildings.map(\.kind)))
    #expect(engine.discoveredTileCount == 3072)
    #expect(engine.state.buildings.contains { $0.origin.x >= 32 && $0.origin.y >= 24 })
    let roads = Set((engine.state.roads ?? []).map(\.tile))
    #expect(roads.count > 200)
    let first = try #require(roads.first)
    var connected: Set<Tile> = [first], queue = [first]
    var i = 0
    while i < queue.count {
        for q in RoadGeometry.neighbors(of: queue[i]).map(\.tile) where roads.contains(q) && connected.insert(q).inserted { queue.append(q) }
        i += 1
    }
    #expect(connected == roads)
    for building in engine.state.buildings {
        #expect(building.tiles(in: config).contains { tile in RoadGeometry.neighbors(of: tile).contains { roads.contains($0.tile) } })
        #expect(building.isOperational)
    }
    #expect(RoadGeometry.path(from: Tile(x: 40,y: 40), to: Tile(x: 50,y: 45), width: 64,height: 48).count == 16)
    _ = try GameEngine(state: engine.state, configuration: config)
}

@MainActor @Test func largePreviewResumesAndSwitchesWithoutChangingNormalWorld() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let url = root.appendingPathComponent("settlement.json")
    let now = Date(timeIntervalSince1970: 1000)
    let session = try GameSession(clock: { now }, saveURL: url)
    let normal = try Data(contentsOf: url)
    let normalState = session.state
    session.loadDeveloperScenario(.grouped)
    #expect(session.isSelectedDeveloperScenario(.grouped))
    #expect(session.configuration.map.width == 64)
    #expect(session.mapIdentity == session.state.mapID)
    #expect(try Data(contentsOf: url) == normal)
    let preview = session.state
    session.returnToNormalGame()
    #expect(session.configuration.map.width == 32)
    #expect(session.mapIdentity == session.state.mapID)
    #expect(try SaveStore(url: url).load(configuration: .bundled()) == normalState)
    session.resumeDeveloperSettlement()
    #expect(session.configuration.map.width == 64)
    #expect(session.mapIdentity == session.state.mapID)
    #expect(session.state == preview)
    session.loadDeveloperScenario(.early)
    #expect(session.configuration.map.width == 32)
    #expect(session.state.buildings.count == 5)
    session.loadDeveloperScenario(.grouped)
    #expect(session.state == preview)
    session.returnToNormalGame()
    #expect(try SaveStore(url: url).load(configuration: .bundled()) == normalState)
}
@MainActor @Test func cancelledLargePreviewPreparationDoesNotPublishOrWriteNormalSave() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let url = root.appendingPathComponent("settlement.json")
    let session = try GameSession(clock: { Date(timeIntervalSince1970:1000) }, saveURL: url)
    let bytes = try Data(contentsOf: url)
    let task = Task { await session.prepareDeveloperScenario(.grouped) }
    while !session.isPreparingDeveloperScenario { await Task.yield() }
    #expect(!session.isDeveloperMode && session.configuration.map.width == 32)
    task.cancel(); await task.value
    #expect(!session.isDeveloperMode && !session.isPreparingDeveloperScenario)
    #expect(try Data(contentsOf: url) == bytes)
    #expect(!FileManager.default.fileExists(atPath: url.appendingPathExtension("developer").path))
}
@Test func largePreviewPendingExpeditionBeyondLegacyAreaRoundTrips() throws {
    let preview = try DeveloperScenario.grouped.makeEngine(configuration: .bundled(), now: Date(timeIntervalSince1970:1000))
    var g = try GameEngine(configuration: preview.configuration, now: preview.state.lastUpdated)
    try g.developerUnlockTechnology("exploration")
    g.developerAddResources(1_000_000); g.developerRevealTerritory(radius: 17)
    #expect(g.discoveredTileCount > 768 && g.discoveredTileCount < 3072)
    try g.build(.scoutCamp, at: Tile(x:14,y:8))
    g.advance(to: g.state.lastUpdated.addingTimeInterval(g.state.buildings.last!.constructionRemainingSeconds ?? 0))
    try g.startExploration()
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: url) }
    try SaveStore(url: url).save(g.state)
    #expect(try SaveStore(url: url).load(configuration: g.configuration) == g.state)
}
@Test func denseVillageFractionalLaborKeepsProductionFactorsAndNetAccounting() throws {
    let full = try DeveloperScenario.grouped.makeEngine(configuration: .bundled(), now: Date(timeIntervalSince1970:1000))
    var state = full.state
    state.population = 10; state.completedPillarGoals = []; state.stoneAgeCompleted = false
    var g = try GameEngine(state: state, configuration: full.configuration)
    let tools = try #require(g.state.buildings.first { $0.kind == .toolmaker })
    try g.setWorkerPriority(buildingID: tools.id,priority: 2)
    let overview = g.economicOverview
    #expect(g.workforceRequired > g.workforceAvailable)
    for b in g.state.buildings where b.isOperational {
        #expect(abs(g.productivity(b) - g.workforceProductivity(b)) < 1e-9)
    }
    for resource in Resource.allCases {
        #expect(abs(overview.net[resource] - (overview.gross[resource] - overview.consumption[resource])) < 1e-9)
        #expect(abs(g.rates[resource] - overview.net[resource]) < 1e-9)
    }
}
#endif
