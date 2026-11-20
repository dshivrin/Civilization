import Foundation
import Testing
@testable import GameCore
import GamePersistence
import GameApplication

private let productionEpoch = Date(timeIntervalSince1970: 20_000_000)

@Test func productionWorldUsesApprovedAnnexAndAuthenticStart() throws {
    let c = try GameConfiguration.bundled()
    let old = try geographyConfiguration()
    #expect(c.map.width == 64 && c.map.height == 48)
    #expect(c.map.id == "river-clearing-64x48-v1")
    for y in 0..<24 { for x in 0..<32 {
        #expect(c.map.terrain(at: Tile(x:x,y:y)) == old.map.terrain(at: Tile(x:x,y:y)))
    } }
    #expect(c.maximumExplorationRadius == 46)
    #expect(c.buildings.allSatisfy { $0.width == (($0.kind == .campfire || $0.kind == .palisade) ? 1 : 2) && $0.height == $0.width })
    let g = try GameEngine(configuration:c,now:productionEpoch)
    #expect(g.state.buildings.count == 1 && g.state.buildings[0].kind == .campfire)
    #expect(g.state.resources == c.initialResources)
    #expect((g.state.roads ?? []).isEmpty)
    #expect(!g.isDiscovered(Tile(x:40,y:30)))
}

@Test func developmentConversionBacksUpProgressAndKeepsAnnexHidden() throws {
    // A fully explored old test world must retain all its cells without exposing the new annex.
    var old = try GameConfiguration.bundled()
    old.map = try geographyConfiguration().map
    var g = try GameEngine(configuration:old,now:productionEpoch)
    var state = g.state
    state.discoveredTiles = old.tiles(within:32); state.explorationRadius = 32
    g = try GameEngine(state:state,configuration:old)
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at:root) }
    let store = SaveStore(url:root.appendingPathComponent("save.json"))
    try store.save(g.state)
    let bytes = try Data(contentsOf:store.url)
    let converted = try #require(try store.load(configuration:GameConfiguration.bundled()))
    #expect(converted.mapID == "river-clearing-64x48-v1")
    #expect(converted.buildings == g.state.buildings)
    #expect(converted.resources == g.state.resources)
    #expect(converted.discoveredTiles == g.state.discoveredTiles)
    #expect(converted.depositRemaining == g.state.depositRemaining)
    #expect(converted.explorationRadius == 11)
    #expect(try Data(contentsOf:store.url) == bytes)
    #expect(try Data(contentsOf:store.url.appendingPathExtension("pre-geography-64x48.bak")) == bytes)
    try store.save(converted)
    #expect(try store.load(configuration:GameConfiguration.bundled()) == converted)
}

@Test func settlementSideQuarrySharesOriginalStoneReserve() throws {
    let c = try GameConfiguration.bundled()
    let stone = try #require(c.naturalDeposits?.first { $0.id == "valley-stone" })
    let site = Tile(x:18,y:16)
    #expect(stone.accessSites?.contains(site) == true)
    #expect(stone.origin == Tile(x:27,y:4) && stone.capacity == 12000)
    var visited: Set<Tile> = [c.map.campfire], queue = [c.map.campfire], i = 0
    while i < queue.count {
        for t in RoadGeometry.neighbors(of:queue[i]).map(\.tile) where c.map.contains(t) && c.map.terrain(at:t) != .water && c.map.terrain(at:t) != .hill && visited.insert(t).inserted { queue.append(t) }
        i += 1
    }
    #expect(visited.contains(site))
    var g = try GameEngine(configuration:c,now:productionEpoch)
    try g.build(.stoneGatherer,at:Tile(x:16,y:16))
    g.advance(to:productionEpoch.addingTimeInterval(30))
    #expect(g.grossRates.stone > 0)
    let before = try #require(g.state.depositRemaining?[stone.id])
    g.advance(to:productionEpoch.addingTimeInterval(90))
    #expect(try #require(g.state.depositRemaining?[stone.id]) < before)
    #expect(g.state.depositRemaining?.keys.filter { $0.contains("stone") }.count == 1)
}

@Test func cloudVisibilityRequiresWholeFootprintAndKnownInteractionTile() throws {
    let c = try GameConfiguration.bundled()
    let building = PlacedBuilding(id:1,kind:.hut,origin:Tile(x:11,y:10))
    let footprint = Set(building.tiles(in:c))
    #expect(DiscoveryVisibility.isVisible(building,in:c,discovered:footprint))
    #expect(!DiscoveryVisibility.isVisible(building,in:c,discovered:[building.origin]))
    #expect(!DiscoveryVisibility.isVisible(building,in:c,discovered:[]))
}

@Test func productionExpeditionsPersistAndRevealOnlyAtCompletionWithoutDuplicateCharge() throws {
    let c = try GameConfiguration.bundled()
    var g = try GameEngine(configuration:c,now:productionEpoch)
    let initial = g.state
    try g.startExploration()
    #expect(g.state.resources.food == initial.resources.food - 10)
    let paid = g.state
    #expect(throws:GameError.self) { try g.startExploration() }
    #expect(g.state == paid)
    g.advance(to:productionEpoch.addingTimeInterval(44.9))
    #expect(g.state.discoveredTiles == initial.discoveredTiles)
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at:root) }
    let store = SaveStore(url:root.appendingPathComponent("save.json")); try store.save(g.state)
    var resumed = try GameEngine(state:try #require(try store.load(configuration:c)),configuration:c)
    resumed.advance(to:productionEpoch.addingTimeInterval(45),offline:true)
    #expect(resumed.state.explorationRemainingSeconds == nil)
    #expect(resumed.state.explorationRadius == 9)
    #expect(initial.discoveredTiles!.isSubset(of:resumed.state.discoveredTiles!))
    #expect(resumed.discoveredTileCount > initial.discoveredTiles!.count)
    let completed = resumed.state
    resumed.advance(to:productionEpoch.addingTimeInterval(45),offline:true)
    #expect(resumed.state == completed)
}

@Test func developmentBackupFailurePreservesOriginalBytes() throws {
    let old = try GameConfiguration.legacyDevelopment()
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at:root) }
    let store = SaveStore(url:root.appendingPathComponent("save.json"))
    try store.save(GameEngine(configuration:old,now:productionEpoch).state)
    let bytes = try Data(contentsOf:store.url)
    try Data("different backup".utf8).write(to:store.url.appendingPathExtension("pre-geography-64x48.bak"))
    #expect(throws:(any Error).self) { try store.load(configuration:.bundled()) }
    #expect(try Data(contentsOf:store.url) == bytes)
}

@MainActor @Test func developmentLibraryConvertsWithoutChangingDeveloperCompanion() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at:root) }
    let old = try GameConfiguration.legacyDevelopment()
    let before = try await GameLibrary.load(rootURL:root,clock:{ productionEpoch },configuration:old)
    let second = try await before.createGame(name:"Independent history")
    let firstURL = try GameLibraryStore(rootURL:root).saveURL(for:before.games[0])
    let secondURL = try GameLibraryStore(rootURL:root).saveURL(for:second)
    let developerURL = firstURL.appendingPathExtension("developer")
    // A developer companion is preserved verbatim; its own restoration owns its conversion.
    let developerBytes = Data("independent developer bytes".utf8)
    try developerBytes.write(to:developerURL)
    let untouched = try Data(contentsOf:firstURL)
    let converted = try await GameLibrary.load(rootURL:root,clock:{ productionEpoch })
    #expect(converted.session.configuration.map.width == 64)
    #expect(converted.activeGameID == second.id)
    #expect(try Data(contentsOf:firstURL) == untouched)
    #expect(try Data(contentsOf:developerURL) == developerBytes)
    try await converted.openGame(id:"legacy")
    #expect(converted.session.state.mapID == "river-clearing-64x48-v1")
    #expect(converted.session.state.buildings.count == 1)
    #expect(try Data(contentsOf:developerURL) == developerBytes)
    let reloaded = try await GameLibrary.load(rootURL:root,clock:{ productionEpoch })
    #expect(reloaded.activeGameID == "legacy")
    #expect(reloaded.games.allSatisfy { $0.mapID == "river-clearing-64x48-v1" })
    #expect(FileManager.default.fileExists(atPath:secondURL.appendingPathExtension("pre-geography-64x48.bak").path))
}

@Test func productionRoadStrokesCoverAnnexInRelease() {
    let path = RoadGeometry.path(from:Tile(x:40,y:30),to:Tile(x:44,y:30),width:64,height:48)
    #expect(path == (40...44).map { Tile(x:$0,y:30) })
}

@Test func legacyPendingExpeditionRetainsPaidTimerThroughConversion() throws {
    let old = try GameConfiguration.legacyDevelopment()
    var g = try GameEngine(configuration:old,now:productionEpoch)
    try g.startExploration(); g.advance(to:productionEpoch.addingTimeInterval(20))
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at:root) }
    let store = SaveStore(url:root.appendingPathComponent("save.json")); try store.save(g.state)
    let c = try GameConfiguration.bundled()
    let converted = try #require(try store.load(configuration:c))
    #expect(converted.explorationRemainingSeconds == 25)
    #expect(converted.resources == g.state.resources)
    #expect(converted.discoveredTiles == g.state.discoveredTiles)
    var resumed = try GameEngine(state:converted,configuration:c)
    resumed.advance(to:productionEpoch.addingTimeInterval(44.9))
    #expect(resumed.state.discoveredTiles == g.state.discoveredTiles)
    resumed.advance(to:productionEpoch.addingTimeInterval(45))
    #expect(resumed.state.explorationRadius == 9)
    #expect(resumed.state.explorationRemainingSeconds == nil)
}

@Test func wholeProductionMapIsOptionalAndFullyExplorableAtUnchangedExpeditionPrice() throws {
    var c = try GameConfiguration.bundled()
    c.initialResources.food = c.baseCapacities.food
    let i = try #require(c.buildings.firstIndex { $0.kind == .scoutCamp })
    c.buildings[i].requiresResearch = false; c.buildings[i].cost = .init(); c.buildings[i].constructionSeconds = 0
    var g = try GameEngine(configuration:c,now:productionEpoch)
    try g.build(.scoutCamp,at:Tile(x:14,y:8))
    let requiredResources = g.requiredDiscoveryResources
    var elapsed = 0.0, expeditions = 0
    while g.discoveredTileCount < 3072 {
        let before = g.state.resources.food
        try g.startExploration(); expeditions += 1
        #expect(g.state.resources.food == before - c.explorationRules!.cost.food)
        elapsed += 45; g.advance(to:productionEpoch.addingTimeInterval(elapsed))
        #expect(expeditions <= 20)
    }
    #expect(g.state.explorationRadius == 46)
    #expect(g.requiredDiscoveryResources == requiredResources)
    let complete = g.state
    #expect(throws:GameError.self) { try g.startExploration() }
    #expect(g.state == complete)
}
