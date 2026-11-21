import Foundation
import Testing
import GameCore
import GameApplication
import GamePersistence

@Test @MainActor func riverbendPlayerNormalNewGameUsesDistinctLargeRulesWithoutWater() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent("riverbend-player-" + UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let library = try await GameLibrary.startNewGame(rootURL: root, clock: { Date(timeIntervalSince1970: 90_000_000) })
    let c = library.session.configuration
    #expect(c.map.id == "riverbend-player-64x48-v1")
    #expect(c.map.width == 64 && c.map.height == 48)
    #expect(c.initialResources == ResourceAmounts(food: 32, wood: 32))
    #expect(library.session.visibleProductionRecipes(for: .stoneGatherer).map(\.id) == ["stone", "flint"])
    #expect(c.workforceRules?.waterPerPersonPerMinute == 0)
    #expect(c.workforceRules?.minimumWaterForGrowth == 0)
    #expect(c.civicLevels?[1].name == "Founder’s Lodge")
    #expect(c.civicLevels?[1].cost.stone == 0)
    #expect(library.session.state.buildings.count == 1)
    #expect(library.session.state.buildings.first?.id == 0)
    #expect(try GameConfiguration.bundled().map.id == "river-clearing-64x48-v1")
}

@Test func riverbendPlayerFoundingAndWholeForestUseOrdinaryCommands() throws {
    let c = try GameConfiguration.riverbendPlayer()
    var game = try GameEngine(configuration: c, now: Date(timeIntervalSince1970: 90_000_000))
    #expect(c.definition(.hut).cost.wood == 12)
    #expect(c.definition(.gatheringShelter).cost.wood == 8)
    #expect(c.definition(.woodcutter).cost == ResourceAmounts(wood: 4))
    #expect(!game.isDiscovered(Tile(x: 8, y: 15)))
    #expect(game.placementIssue(.woodcutter, at: Tile(x: 9, y: 15)) != nil)
    try game.upgrade(buildingID: 0)
    #expect(game.civicCenter?.id == 0 && game.civicLevel == 2)
    #expect(game.usesConnectedPaths)
    #expect(game.placementIssue(.hut, at: Tile(x: 18,y: 10)) != nil)
    #expect(game.state.roads?.contains { $0.tile == Tile(x: 18, y: 12) } == true)
    try game.build(.hut, at: Tile(x: 20, y: 10))
    game.advance(to: game.state.lastUpdated.addingTimeInterval(60))
    let hut = try #require(game.state.buildings.first { $0.kind == .hut })
    #expect(!game.isServiceOperational(hut))
    try game.editRoads(at: [Tile(x: 19, y: 12),Tile(x: 20, y: 12)], style: .trodden)
    #expect(game.isServiceOperational(hut))
    try game.startExploration()
    game.advance(to: game.state.lastUpdated.addingTimeInterval(60))
    #expect((13...17).allSatisfy { y in (7...8).allSatisfy { x in game.isDiscovered(Tile(x: x, y: y)) } })
    #expect(game.state.resources[.water] == 0)
    #expect(!game.requiredDiscoveryResources.contains(.water))
    #expect(game.growthStatus != .waterDeficit && game.growthStatus != .waterReserve)
    let state = game.state
    #expect(try GameEngine(state: state, configuration: c).state == state)
}

@Test func riverbendPlayerRecoveryIsBoundedAndLegacyRulesRejectIt() throws {
    let c = try GameConfiguration.riverbendPlayer()
    var game = try GameEngine(configuration: c, now: Date(timeIntervalSince1970: 90_000_000))
    try game.upgrade(buildingID: 0)
    try game.build(.hut, at: Tile(x: 20,y: 10))
    try game.build(.gatheringShelter, at: Tile(x: 14,y: 14))
    #expect(game.state.resources.wood == 0)
    try game.recoverRiverbendWood()
    #expect(game.state.resources.wood == 8)
    let recovered = game.state
    try game.recoverRiverbendWood()
    #expect(game.state == recovered)
    game.advance(to: game.state.lastUpdated.addingTimeInterval(3600))
    try game.recoverRiverbendFood()
    #expect(game.state.resources.food == 12)
    let food = game.state
    try game.recoverRiverbendFood()
    #expect(game.state == food)
    var legacy = try GameEngine(configuration: .bundled(), now: game.state.lastUpdated)
    let original = legacy.state
    #expect(throws: Error.self) { try legacy.recoverRiverbendWood() }
    #expect(legacy.state == original)
}

@Test @MainActor func riverbendPlayerCraftStorageEnclosureEarnedRoutePersists() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent("riverbend-earned-" + UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let library = try await GameLibrary.startNewGame(rootURL: root, clock: { Date(timeIntervalSince1970: 90_000_000) })
    let c = library.session.configuration
    var game = try GameEngine(state: library.session.state, configuration: c)
    func export(_ stage: String) throws {
        guard let path = ProcessInfo.processInfo.environment["CIVILIZATION_RIVERBEND_EARNED_EXPORT"] else { return }
        let folder = URL(fileURLWithPath: path).appendingPathComponent(stage)
        #expect(!FileManager.default.fileExists(atPath: folder.path))
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var aligned = game.state
        aligned.lastUpdated = Date() // Clock alignment only; every stock, history and timer is earned above.
        try SaveStore(url: folder.appendingPathComponent("settlement-v1.json")).save(aligned)
        try GameLibraryStore(rootURL: folder).save(library.index)
        let receipt: [String: Any] = ["synthetic": true, "source": "riverbendPlayerCraftStorageEnclosureEarnedRoutePersists", "stage": stage, "modelSeconds": game.state.lastUpdated.timeIntervalSince1970 - 90_000_000, "grants": false, "debugCommands": false, "clockAlignmentOnly": true]
        try JSONSerialization.data(withJSONObject: receipt, options: [.sortedKeys, .prettyPrinted]).write(to: folder.appendingPathComponent("qa-earned.json"))
    }
    func wait(_ seconds: Double = 60) { game.advance(to: game.state.lastUpdated.addingTimeInterval(seconds)) }
    func road(_ tiles: [Tile]) throws { try game.editRoads(at: tiles, style: .trodden) }
    try game.upgrade(buildingID: 0)
    try game.build(.hut, at: Tile(x: 20,y: 10)); wait()
    try road([Tile(x: 19,y: 12),Tile(x: 20,y: 12)])
    try game.build(.gatheringShelter, at: Tile(x: 14,y: 14))
    try road([Tile(x: 17,y: 13),Tile(x: 16,y: 13),Tile(x: 15,y: 13),Tile(x: 14,y: 13)])
    try game.recoverRiverbendWood(); wait()
    try game.startExploration(); wait()
    try game.build(.woodcutter, at: Tile(x: 11,y: 15))
    try road((11...14).map { Tile(x: $0,y: 13) } + [Tile(x: 11,y: 14)]); wait()
    #expect(game.rates.wood > 0 && game.rates.food > 0)
    for _ in 0..<12 { wait() }
    try game.build(.stoneGatherer, at: Tile(x: 19,y: 16))
    try road([Tile(x: 18,y: 13),Tile(x: 18,y: 14),Tile(x: 18,y: 15),Tile(x: 18,y: 16)])
    wait(600)
    let before = game.state.resources
    #expect(throws: Error.self) { try game.startRiverbendTools() }
    #expect(game.state.resources == before)
    let stone = try #require(game.state.buildings.first { $0.kind == .stoneGatherer })
    let beforeMode = game.state
    #expect(throws: Error.self) { try game.setProductionMode(buildingID: stone.id, recipeID: "clay") }
    #expect(game.state == beforeMode)
    try game.setProductionMode(buildingID: stone.id, recipeID: "flint")
    wait(180)
    try game.setProductionMode(buildingID: stone.id, recipeID: "stone")
    try game.research("oralTradition"); try game.research("stoneTools")
    try export("craft")
    for _ in 0..<3 { try game.startRiverbendTools(); wait() }
    #expect(game.state.resources[.stoneTools] == 3)
    try game.improveRiverbendWoodcutter()
    #expect(game.state.resources[.stoneTools] == 0)
    #expect(game.state.riverbend?.woodcutterImproved == true)
    let once = game.state
    #expect(throws: Error.self) { try game.improveRiverbendWoodcutter() }
    #expect(game.state == once)
    try game.buildRiverbendStorage(.stockyard, at: Tile(x: 14,y: 10))
    try road([Tile(x: 14,y: 12)]);wait()
    #expect(game.capacities.food == 60 && game.capacities.wood == 120)
    let stockyard = try #require(game.state.buildings.first { $0.kind == .storehouse })
    #expect(game.upgradeCost(for: stockyard) == nil)
    let stockState = game.state
    #expect(throws: Error.self) { try game.build(.storehouse, at: Tile(x: 15,y: 16)) }
    #expect(game.state == stockState)
    try game.buildRiverbendStorage(.granary, at: Tile(x: 15,y: 16))
    try road([Tile(x: 16,y: 14),Tile(x: 16,y: 15)]);wait()
    #expect(game.capacities.food == 120 && game.capacities.wood == 120)
    for id in ["oralTradition","stoneTools","construction","socialOrder","naturalKnowledge","exploration","surveillance","fortification"] {
        for _ in 0..<30 where !game.researchedIDs.contains(id) && game.researchIssue(id) != nil { wait() }
        if !game.researchedIDs.contains(id) { try game.research(id) }
    }
    wait(600)
    print("Riverbend earned route: civic upgrade", game.state.resources)
    try game.upgrade(buildingID: 0)
    wait(600)
    try game.build(.scoutCamp, at: Tile(x: 24,y: 16))
    try road(Array(RiverbendBoundary.gateRoad) + [Tile(x: 24,y: 15)])
    wait(600)
    print("Riverbend earned route: enclosure", game.state.resources)
    try export("enclosure")
    try game.purchaseRiverbendEnclosure()
    let enclosureState = game.state
    #expect(throws: Error.self) { try game.editRoads(at: [RiverbendBoundary.gate], style: nil) }
    #expect(throws: Error.self) { try game.editRoads(at: [Tile(x: 23,y: 13)], style: .trodden) }
    #expect(game.state == enclosureState)
    let open = game.riverbendBoundary
    #expect(!open.path(from: RiverbendBoundary.outside, to: RiverbendBoundary.inside).isEmpty)
    try game.setRiverbendGate(open: false)
    #expect(game.riverbendBoundary.reachable(from: RiverbendBoundary.outside).isDisjoint(with: RiverbendBoundary.interior))
    wait()
    #expect(game.state.stoneAgeCompleted == true)
    #expect(game.journeyChapters.count == 7 && game.journeyChapters.allSatisfy(\.isComplete))
    let save = SaveStore(url: root.appendingPathComponent("settlement-v1.json"))
    try save.save(game.state)
    let restored = try #require(try save.load(configuration: c))
    #expect(restored == game.state)
    #expect(try GameEngine(state: restored, configuration: c).state.stoneAgeCompleted == true)
    let continued = try await GameLibrary.load(rootURL: root, clock: { game.state.lastUpdated })
    #expect(continued.activeGameID == library.activeGameID)
    #expect(continued.session.state == game.state)
    try export("ending")
    print("Riverbend earned simulated model seconds:", game.state.lastUpdated.timeIntervalSince1970 - 90_000_000)
}

@Test @MainActor func riverbendPlayerNormalContinueAndIndependentGamesKeepRules() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent("riverbend-continue-" + UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let now = Date(timeIntervalSince1970: 90_000_000)
    let library = try await GameLibrary.startNewGame(rootURL: root, clock: { now })
    library.session.upgrade(buildingID: 0)
    let first = library.session.state
    let second = try await library.createGame(name: "Independent Riverbend")
    #expect(library.session.configuration.isRiverbendPlayer)
    #expect(library.session.state.buildings.first?.level == 1)
    try await library.openGame(id: "legacy")
    #expect(library.session.state == first)
    let reopened = try await GameLibrary.load(rootURL: root, clock: { now })
    #expect(reopened.session.state == first)
    try await reopened.openGame(id: second.id)
    #expect(reopened.session.configuration.isRiverbendPlayer)
    #expect(reopened.session.state.buildings.first?.level == 1)
}

@Test func riverbendPlayerRejectsUnadoptedCatalogWithoutSpending() throws {
    var game = try GameEngine(configuration: .riverbendPlayer(), now: Date(timeIntervalSince1970: 90_000_000))
    #expect(game.settlementGuidance.action == .upgrade(0))
    try game.upgrade(buildingID: 0)
    try game.research("oralTradition")
    game.advance(to: game.state.lastUpdated.addingTimeInterval(1200))
    let state = game.state
    #expect(throws: Error.self) { try game.research("hunting") }
    #expect(throws: Error.self) { try game.build(.toolmaker, at: Tile(x: 14,y: 10)) }
    #expect(game.state == state)
}

@Test @MainActor func riverbendPlayerFindsCannotDoubleGrantOrPublishFailedSave() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent("riverbend-find-" + UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let library = try await GameLibrary.startNewGame(rootURL: root, clock: { Date(timeIntervalSince1970: 90_000_000) })
    let session = library.session
    session.upgrade(buildingID: 0)
    session.choose(.hut); session.confirm()
    let berries = try #require(session.availableRiverbendFinds.first { $0.id == .berries })
    let url = root.appendingPathComponent("settlement-v1.json")
    let before = session.state, bytes = try Data(contentsOf: url)
    try FileManager.default.removeItem(at: url)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
    session.resolveRiverbendFind(.berries, at: berries.tile)
    #expect(session.state == before)
    try FileManager.default.removeItem(at: url)
    try bytes.write(to: url)
    session.resolveRiverbendFind(.berries, at: berries.tile)
    #expect(session.state.resources.food == before.resources.food + 3)
    let awarded = session.state
    session.resolveRiverbendFind(.berries, at: berries.tile)
    #expect(session.state == awarded)
    let restored = try await GameLibrary.load(rootURL: root, clock: { Date(timeIntervalSince1970: 90_000_000) })
    #expect(!restored.session.availableRiverbendFinds.contains { $0.id == .berries })
}

#if DEBUG
@Test @MainActor func riverbendPlayerReviewCommandsNeverWriteNormalStore() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent("riverbend-review-" + UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let now = Date(timeIntervalSince1970: 90_000_000)
    let library = try await GameLibrary.startNewGame(rootURL: root, clock: { now })
    let url = root.appendingPathComponent("settlement-v1.json")
    let normal = try Data(contentsOf: url)
    library.session.startGameplayReview()
    #expect(library.session.isGameplayReview)
    library.session.upgrade(buildingID: 0)
    #expect(library.session.state.buildings.first!.level == 2)
    #expect(try Data(contentsOf: url) == normal)
    library.session.returnToNormalGame()
    #expect(library.session.state.buildings.first!.level == 1)
    library.session.resumeGameplayReview()
    #expect(library.session.state.buildings.first!.level == 2)
}
#endif

@Test @MainActor func riverbendPlayerContinueClassifiesLargeBodyBeforeRelabel() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent("riverbend-old-label-" + UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let now = Date(timeIntervalSince1970: 90_000_000)
    let store = GameLibraryStore(rootURL: root)
    let game = SavedGame(id: "legacy", name: "Historical label", createdAt: now, mapID: "river-clearing-v1")
    try store.save(GameLibraryIndex(activeGameID: "legacy", games: [game]))
    let url = try store.saveURL(for: game)
    let state = try GameEngine(configuration: .bundled(), now: now).state
    try SaveStore(url: url).save(state)
    let backup = url.appendingPathExtension("pre-geography-64x48.bak")
    try SaveStore(url: backup).save(GameEngine(configuration: .legacyDevelopment(), now: now).state)
    let bytes = try Data(contentsOf: url), oldBytes = try Data(contentsOf: backup)
    let library = try await GameLibrary.load(rootURL: root, clock: { now })
    #expect(library.session.state == state)
    #expect(library.games.first?.mapID == state.mapID)
    #expect(try Data(contentsOf: url) == bytes && Data(contentsOf: backup) == oldBytes)
}
