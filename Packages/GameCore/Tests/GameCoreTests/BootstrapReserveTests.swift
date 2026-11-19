import Foundation
import Testing
@testable import GameCore
import GamePersistence

private let reserveEpoch = Date(timeIntervalSince1970: 30_000_000)
private func reserveSite(_ game: GameEngine, _ kind: BuildingKind) throws -> Tile {
    try #require((0..<24).flatMap { y in (0..<32).map { Tile(x: $0, y: y) } }.first { game.placementIssue(kind, at: $0) == nil })
}

@Test func starterReservePreventsRepeatedShelterInsolvencyAtomically() throws {
    var game = try GameEngine(configuration: .bundled(), now: reserveEpoch)
    for _ in 0..<6 {
        try game.build(.gatheringShelter, at: reserveSite(game, .gatheringShelter))
        game.advance(to: game.state.lastUpdated.addingTimeInterval(30))
    }
    #expect(game.state.resources.wood == 20)
    #expect(game.canAfford(game.configuration.definition(.gatheringShelter).cost))
    #expect(game.bootstrapRequirement(for: game.configuration.definition(.gatheringShelter).cost, constructing: .gatheringShelter) == .woodcutter)
    let before = game.state
    var oldRules = game.configuration; oldRules.protectBootstrapMaterials = false
    let geometricSite = try reserveSite(GameEngine(state: game.state, configuration: oldRules), .gatheringShelter)
    #expect(game.placementIssue(.gatheringShelter, at: geometricSite)?.localizedDescription.contains("Woodcutter") == true)
    #expect(throws: GameError.self) { try game.build(.gatheringShelter, at: geometricSite) }
    #expect(game.state == before)
    try game.build(.woodcutter, at: reserveSite(game, .woodcutter))
    for _ in 0..<20 {
        if game.canAfford(game.configuration.definition(.stoneGatherer).cost) { break }
        game.advance(to: game.state.lastUpdated.addingTimeInterval(60))
    }
    try game.build(.stoneGatherer, at: reserveSite(game, .stoneGatherer))
    game.advance(to: game.state.lastUpdated.addingTimeInterval(120))
    #expect(game.rates.wood > 0)
    #expect(game.bootstrapRequirement(for: game.configuration.definition(.hut).cost, constructing: .hut) == nil)
}

@Test func reserveAllowsAnySafeSupplierOrderAndDoesNotLockCombinedCost() throws {
    var c = try GameConfiguration.bundled(); c.initialResources.wood = 35; c.initialResources.stone = 5
    var game = try GameEngine(configuration: c, now: reserveEpoch)
    #expect(game.bootstrapRequirement(for: c.definition(.gatheringShelter).cost, constructing: .gatheringShelter) == nil) //20wood is enough to establish wood first.
    c.initialResources.wood = 25; c.initialResources.stone = 0
    game = try GameEngine(configuration: c, now: reserveEpoch)
    #expect(game.bootstrapRequirement(for: c.definition(.gatheringShelter).cost, constructing: .gatheringShelter) == .stoneGatherer)
    try game.build(.stoneGatherer, at: reserveSite(game, .stoneGatherer))
    game.advance(to: game.state.lastUpdated.addingTimeInterval(60))
    try game.build(.woodcutter, at: reserveSite(game, .woodcutter))
}

@Test func researchAndUpgradeCannotBypassStarterReserve() throws {
    var c = try GameConfiguration.bundled(); c.initialResources.wood = 15; c.initialResources.stone = 5
    var game = try GameEngine(configuration: c, now: reserveEpoch)
    let before = game.state
    #expect(game.canAfford(c.technologyDefinitions.first { $0.id == "oralTradition" }!.cost))
    #expect(throws: GameError.self) { try game.research("oralTradition") }
    #expect(game.state == before)
    c.initialResources.wood = 35
    game = try GameEngine(configuration: c, now: reserveEpoch)
    try game.build(.hut, at: reserveSite(game, .hut)); game.advance(to: game.state.lastUpdated.addingTimeInterval(30))
    let snapshot = game.state
    let hut = try #require(game.state.buildings.first { $0.kind == .hut })
    #expect(game.canAfford(game.upgradeCost(for: hut)!))
    #expect(throws: GameError.self) { try game.upgrade(buildingID: hut.id) }
    #expect(game.state == snapshot)
}

@Test func pendingAndSelectableRecipeSourcesRemainUsable() throws {
    var c = try GameConfiguration.bundled(); c.initialResources.wood = 35; c.initialResources.stone = 5
    var game = try GameEngine(configuration: c, now: reserveEpoch)
    try game.build(.woodcutter, at: reserveSite(game, .woodcutter))
    #expect(!game.state.buildings.last!.isOperational)
    #expect(game.bootstrapRequirement(for: c.definition(.hut).cost, constructing: .hut) == nil)
    c.initialResources.wood = 50; c.initialResources.stone = 0
    game = try GameEngine(configuration: c, now: reserveEpoch)
    try game.build(.stoneGatherer, at: reserveSite(game, .stoneGatherer)); game.advance(to: game.state.lastUpdated.addingTimeInterval(30))
    try game.setProductionMode(buildingID: game.state.buildings.last!.id, recipeID: "clay")
    #expect(game.bootstrapRequirement(for: c.definition(.hut).cost, constructing: .hut) == nil)
    c.initialResources.wood = 15
    game = try GameEngine(configuration: c, now: reserveEpoch)
    try game.build(.stoneGatherer, at: reserveSite(game, .stoneGatherer)); game.advance(to: game.state.lastUpdated.addingTimeInterval(30))
    try game.setProductionMode(buildingID: game.state.buildings.last!.id, recipeID: "clay")
    // Only10wood (the historical reward) remains; a duplicate costs15. Select a free stone mode to bootstrap wood.
    #expect(game.guidance(for: "building-woodcutter").action == .recipe(game.state.buildings.last!.id, "stone"))
}

@Test func starterReserveDerivesSupplierCostsFromCatalog() throws {
    var c = try GameConfiguration.bundled()
    let index = try #require(c.buildings.firstIndex { $0.kind == .woodcutter })
    c.buildings[index].cost.wood = 17; c.buildings[index].cost.stone = 9
    c.initialResources.wood = 31; c.initialResources.stone = 9
    var game = try GameEngine(configuration: c, now: reserveEpoch)
    #expect(game.bootstrapRequirement(for: c.definition(.gatheringShelter).cost, constructing: .gatheringShelter) == .woodcutter)
    c.initialResources.wood = 35
    game = try GameEngine(configuration: c, now: reserveEpoch)
    #expect(game.bootstrapRequirement(for: c.definition(.gatheringShelter).cost, constructing: .gatheringShelter) == nil)
}

@Test func oldRulesAndAlreadyInsolventSavesDoNotGainResourcesOrReset() throws {
    var c = try GameConfiguration.bundled(); c.protectBootstrapMaterials = false
    var game = try GameEngine(configuration: c, now: reserveEpoch)
    for _ in 0..<7 {
        try game.build(.gatheringShelter, at: reserveSite(game, .gatheringShelter)); game.advance(to: game.state.lastUpdated.addingTimeInterval(30))
    }
    #expect(game.state.resources.wood == 5) //Exact historical trap, preserved as evidence.
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let store = SaveStore(url: folder.appendingPathComponent("legacy.json")); try store.save(game.state)
    let restored = try #require(try store.load(configuration: .bundled()))
    #expect(restored == game.state)
}
