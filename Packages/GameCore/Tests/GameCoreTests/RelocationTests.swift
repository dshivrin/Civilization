import Foundation
import Testing
import GameCore
import GamePersistence
import GameApplication

private let moveEpoch = Date(timeIntervalSince1970: 80_000)
private func moveConfiguration() throws -> GameConfiguration {
    var c = try GameConfiguration.bundled()
    c.workforceRules = nil
    c.explorationRules = nil
    c.progressionGoals = nil
    for i in c.buildings.indices { c.buildings[i].requiresResearch = false; c.buildings[i].cost = .init(); c.buildings[i].constructionSeconds = 0 }
    return c
}
private func openTile(_ g: GameEngine, kind: BuildingKind, excluding: Set<Tile> = []) throws -> Tile {
    try #require((0..<24).flatMap { y in (0..<32).map { Tile(x: $0, y: y) } }.first { !excluding.contains($0) && g.placementIssue(kind, at: $0) == nil })
}
@Test func relocationIsFreePreservesIdentityAndAllowsSelfOverlap() throws {
    let c = try moveConfiguration()
    var g = try GameEngine(configuration: c, now: moveEpoch)
    try g.build(.hut, at: Tile(x: 12, y: 12))
    var state = g.state
    state.buildings[1].workerPriority = 2; state.buildings[1].upgradeLevel = 2
    state.resources = .init()
    g = try GameEngine(state: state, configuration: c)
    let before = g.state
    #expect(g.relocationIssue(buildingID: 1, at: Tile(x: 13, y: 12)) == nil)
    try g.relocate(buildingID: 1, to: Tile(x: 13, y: 12))
    var expected = before; expected.buildings[1].origin = Tile(x: 13, y: 12)
    #expect(g.state == expected)
    try g.relocate(buildingID: 1, to: Tile(x: 13, y: 12))
    #expect(g.state == expected)
}
@Test func relocationRejectsInvalidSitesAtomically() throws {
    var g = try GameEngine(configuration: moveConfiguration(), now: moveEpoch)
    try g.build(.hut, at: Tile(x: 12, y: 12))
    try g.build(.woodcutter, at: Tile(x: 14, y: 12))
    let before = g.state
    for tile in [Tile(x: 14, y: 12), Tile(x: -1, y: 0), Tile(x: Int.max, y: Int.min), Tile(x: 31, y: 23)] {
        #expect(throws: GameError.self) { try g.relocate(buildingID: 1, to: tile) }
        #expect(g.state == before)
    }
    #expect(throws: GameError.self) { try g.relocate(buildingID: 0, to: Tile(x: 14, y: 12)) } // Occupied site, including for the movable civic center.
    #expect(throws: GameError.self) { try g.relocate(buildingID: 999, to: Tile(x: 13, y: 14)) }
    #expect(g.state == before)
}
@Test func relocationRetainsConstructionAndRecipeThroughSave() throws {
    var c = try moveConfiguration()
    c.buildings[c.buildings.firstIndex { $0.kind == .stoneGatherer }!].constructionSeconds = 20
    var g = try GameEngine(configuration: c, now: moveEpoch)
    try g.build(.stoneGatherer, at: Tile(x: 12, y: 12))
    var state = g.state
    state.buildings[1].productionModeID = "clay"
    state.buildings[1].constructionDurationSeconds = 20
    state.buildings[1].constructionRemainingSeconds = 8
    g = try GameEngine(state: state, configuration: c)
    let tile = try openTile(g, kind: .stoneGatherer)
    try g.relocate(buildingID: 1, to: tile)
    #expect(g.state.buildings[1].constructionRemainingSeconds == 8)
    #expect(g.state.buildings[1].productionModeID == "clay")
    #expect(g.state.completedGoals == state.completedGoals)
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: url) }
    let store = SaveStore(url: url); try store.save(g.state)
    #expect(try store.load(configuration: c) == g.state)
}
@Test func relocationRecalculatesGeographyAndHonorsFishingRestriction() throws {
    let c = try moveConfiguration()
    var g = try GameEngine(configuration: c, now: moveEpoch)
    let kind = BuildingKind.woodcutter
    let sites = (0..<24).flatMap { y in (0..<32).map { Tile(x: $0, y: y) } }.filter { g.placementIssue(kind, at: $0) == nil }
    let near = try #require(sites.first { g.geographicMultiplier(PlacedBuilding(id: 1, kind: kind, origin: $0)) > 1 })
    let far = try #require(sites.first { g.geographicMultiplier(PlacedBuilding(id: 1, kind: kind, origin: $0)) == 1 })
    try g.build(kind, at: near)
    let boosted = g.grossRates[.wood]
    try g.relocate(buildingID: 1, to: far)
    #expect(g.grossRates[.wood] < boosted)
    let fishing = try openTile(g, kind: .fishingShelter)
    try g.build(.fishingShelter, at: fishing)
    let before = g.state
    #expect(throws: GameError.self) { try g.relocate(buildingID: 2, to: Tile(x: 12, y: 12)) }
    #expect(g.state == before)
}
@Test func relocationCannotUseUnknownTerritory() throws {
    var c = try moveConfiguration(); c.explorationRules = try GameConfiguration.bundled().explorationRules
    var g = try GameEngine(configuration: c, now: moveEpoch)
    try g.build(.hut, at: try openTile(g, kind: .hut))
    let before = g.state
    #expect(throws: GameError.self) { try g.relocate(buildingID: 1, to: Tile(x: 0, y: 23)) }
    #expect(g.state == before)
}
@MainActor @Test func relocationPreviewCancelAndCommitDoNotLeakIntoSaves() throws {
    let c = try moveConfiguration()
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("save.json")
    defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
    let session = try GameSession(clock: { moveEpoch }, saveURL: url, configuration: c)
    session.choose(.hut); session.confirm()
    let original = session.state
    let building = try #require(session.state.buildings.last)
    session.beginRelocation(buildingID: building.id)
    session.tap(Tile(x: 0, y: 23))
    #expect(session.state == original)
    session.cancel()
    #expect(session.state == original && session.movingBuildingID == nil)
    session.beginRelocation(buildingID: building.id)
    session.tap(Tile(x: 14, y: 12))
    session.finishRelocation()
    #expect(session.state.buildings.last?.origin == Tile(x: 14, y: 12))
    let reloaded = try GameSession(clock: { moveEpoch }, saveURL: url, configuration: c)
    #expect(reloaded.state == session.state)
}
@Test func resourceProducerCountsFollowActualOperatingOutput() throws {
    let c = try moveConfiguration()
    var g = try GameEngine(configuration: c, now: moveEpoch)
    try g.build(.stoneGatherer, at: Tile(x: 12, y: 12))
    #expect(g.producingBuildingCount(for: .stone) == 1)
    try g.setProductionMode(buildingID: 1, recipeID: "clay")
    #expect(g.producingBuildingCount(for: .stone) == 0)
    #expect(g.producingBuildingCount(for: .clay) == 1)
}
@Test func goalsStartCollapsedAndOnlyEraChangeAutomaticallyOpensThem() {
    var disclosure = SettlementGoalsDisclosure(eraID: "stoneAge")
    #expect(!disclosure.isExpanded)
    disclosure.observeEra("stoneAge"); #expect(!disclosure.isExpanded)
    disclosure.isExpanded = true; disclosure.isExpanded = false
    disclosure.observeEra("future-test-era"); #expect(disclosure.isExpanded)
}

@MainActor @Test func asyncRestorationPreservesSaveAndCorruptFileProtection() async throws {
    let c = try moveConfiguration()
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = folder.appendingPathComponent("save.json")
    let initial = try GameSession(clock: { moveEpoch }, saveURL: url, configuration: c)
    initial.choose(.hut); initial.confirm()
    let restored = try await GameSession.load(clock: { moveEpoch }, saveURL: url, configuration: c)
    #expect(restored.state == initial.state)
    let broken = folder.appendingPathComponent("broken.json")
    let bytes = Data("damaged".utf8); try bytes.write(to: broken)
    let temporary = try await GameSession.load(clock: { moveEpoch }, saveURL: broken, configuration: c)
    temporary.choose(.hut); temporary.confirm(); temporary.save()
    #expect(temporary.persistenceWarning != nil)
    #expect(try Data(contentsOf: broken) == bytes)
}

@MainActor @Test func asyncLoadedSessionWaitsForActivationAndCapsStartupSuspension() async throws {
    var now = moveEpoch
    var c = try baselineConfiguration(); c.resourceCap = 10_000
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("save.json")
    defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
    let session = try await GameSession.load(clock: { now }, saveURL: url, configuration: c)
    let before = session.state
    now = now.addingTimeInterval(100_000)
    session.tick()
    #expect(session.state == before)
    session.setActive(true)
    #expect(abs(session.state.resources.food - (before.resources.food + 2 * c.offlineCapSeconds / 60)) < 1e-6)
    #expect(session.state.lastUpdated == now)
    let after = session.state
    session.setActive(true); session.tick()
    #expect(session.state == after)
}

@MainActor @Test func catalogChoiceRequiresExplicitConfirmationAfterValidDrop() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("save.json")
    defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
    let session = try GameSession(clock: { moveEpoch }, saveURL: url, configuration: moveConfiguration())
    #expect(!session.isDragMode)
    let before = session.state
    session.choose(.hut)
    #expect(session.isDragMode && session.previewKind == .hut)
    #expect(!session.canDragPreview(from: Tile(x: 0, y: 0)))
    #expect(session.state == before)
    session.tap(Tile(x: 12, y: 12))
    session.finishDragging()
    #expect(session.isDragMode)
    #expect(session.state == before)
    session.confirm()
    #expect(!session.isDragMode)
    #expect(session.state.buildings.count == before.buildings.count + 1)
    #expect(session.state.buildings.last?.origin == Tile(x: 12, y: 12))
    let placed = session.state
    session.finishDragging()
    #expect(session.state == placed)
    session.choose(.woodcutter); session.cancel()
    #expect(!session.isDragMode && session.state == placed)
}
@MainActor @Test func invalidNewBuildingDropStaysInDragModeWithoutCharging() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("save.json")
    defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
    let session = try GameSession(clock: { moveEpoch }, saveURL: url)
    session.choose(.hut)
    let before = session.state
    session.tap(session.configuration.map.campfire)
    session.finishDragging()
    #expect(session.isDragMode && session.placementIssue != nil)
    #expect(session.state == before)
    session.cancel()
    #expect(!session.isDragMode)
}

@Test func relocationTileIndicatorsDistinguishSelfOpenOccupiedRoadAndBounds() throws {
    var g = try GameEngine(configuration: moveConfiguration(), now: moveEpoch)
    try g.build(.hut, at: Tile(x: 12, y: 12))
    try g.build(.woodcutter, at: Tile(x: 14, y: 12))
    let before = g.state
    #expect(g.siteTileIssue(at: Tile(x: 13, y: 12), excludingBuildingID: 1) == nil)
    #expect(g.siteTileIssue(at: Tile(x: 14, y: 12), excludingBuildingID: 1) != nil)
    #expect(g.siteTileIssue(at: Tile(x: 12, y: 12)) != nil)
    #expect(g.siteTileIssue(at: Tile(x: -1, y: 12), excludingBuildingID: 1) != nil)
    #expect(g.state == before)
    try g.editRoads(at: [Tile(x: 13, y: 14)], style: .dirt)
    #expect(g.siteTileIssue(at: Tile(x: 13, y: 14), excludingBuildingID: 1) != nil)
    #expect(g.siteTileIssue(at: Tile(x: 12, y: 14), excludingBuildingID: 1) == nil)
}

@MainActor @Test func invalidRelocationDropRetainsPreviewThenCanRetryOrCancelWithoutSaveLeak() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = folder.appendingPathComponent("save.json")
    let c = try moveConfiguration()
    let session = try GameSession(clock: { moveEpoch }, saveURL: url, configuration: c)
    session.choose(.hut); session.tap(Tile(x: 12, y: 12)); session.confirm()
    let before = session.state
    let bytes = try Data(contentsOf: url)
    let id = try #require(session.state.buildings.last?.id)
    session.beginRelocation(buildingID: id)
    session.tap(Tile(x: -1, y: 12)); session.finishRelocation()
    #expect(session.movingBuildingID == id)
    #expect(session.selectedTile == Tile(x: -1, y: 12))
    #expect(session.state == before)
    #expect(try Data(contentsOf: url) == bytes)
    session.tap(Tile(x: 13, y: 12))
    #expect(session.isPreviewTileAvailable(Tile(x: 13, y: 12)))
    #expect(session.canDragPreview(from: Tile(x: 13, y: 12)))
    #expect(!session.canDragPreview(from: Tile(x: 12, y: 12)))
    session.finishRelocation()
    #expect(session.movingBuildingID == nil)
    #expect(session.state.buildings.last?.origin == Tile(x: 13, y: 12))
    let moved = session.state
    session.finishRelocation(); #expect(session.state == moved)
    session.beginRelocation(buildingID: id)
    session.tap(Tile(x: -1, y: 12)); session.finishRelocation(); session.cancel()
    #expect(session.state == moved && session.movingBuildingID == nil)
    #expect(try SaveStore(url: url).load(configuration: c) == moved)
}

@Test func threeStateGoalsStartMinimalAndCycleToSummaryThenGuidance() {
    var disclosure = SettlementGoalsDisclosure(eraID: "stoneAge")
    #expect(disclosure.state == .minimal)
    disclosure.cycle(); #expect(disclosure.state == .compact && !disclosure.isExpanded)
    disclosure.cycle(); #expect(disclosure.state == .expanded && disclosure.isExpanded)
    disclosure.cycle(); #expect(disclosure.state == .minimal)
    disclosure.isExpanded = true; #expect(disclosure.state == .expanded)
    disclosure.isExpanded = false; #expect(disclosure.state == .minimal)
    disclosure.observeEra("stoneAge"); #expect(disclosure.state == .minimal)
    disclosure.observeEra("future-fixture-only"); #expect(disclosure.state == .expanded)
}

@MainActor @Test func relocationGridExcludesFogAndKeepsSourceCellsAvailable() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    var c = try moveConfiguration()
    c.explorationRules = try GameConfiguration.bundled().explorationRules
    let s = try GameSession(clock: { moveEpoch }, saveURL: folder.appendingPathComponent("save.json"), configuration: c)
    #expect(s.relocationGrid == nil)
    s.choose(.hut); s.confirm()
    let b = try #require(s.state.buildings.last { $0.kind == .hut })
    let before = s.state
    s.beginRelocation(buildingID: b.id)
    let grid = try #require(s.relocationGrid)
    #expect(Set(grid.keys) == s.state.discoveredTiles)
    #expect(grid[b.origin] == true)
    #expect(grid[c.map.campfire] == false)
    #expect(grid[Tile(x: 0, y: 23)] == nil)
    #expect(s.state == before)
    s.cancel(); #expect(s.relocationGrid == nil && s.state == before)
}

@MainActor @Test func relocationDragReleaseDoesNotCommitUntilExplicitConfirmation() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = folder.appendingPathComponent("save.json")
    let session = try GameSession(clock: { moveEpoch }, saveURL: url, configuration: moveConfiguration())
    session.choose(.hut); session.tap(Tile(x: 12, y: 12)); session.confirm()
    let before = session.state
    let bytes = try Data(contentsOf: url)
    let id = try #require(session.state.buildings.last?.id)
    session.beginRelocation(buildingID: id); session.tap(Tile(x: 14, y: 12))
    session.finishDragging()
    #expect(session.state == before)
    #expect(session.movingBuildingID == id)
    #expect(try Data(contentsOf: url) == bytes)
    session.confirm()
    #expect(session.state.buildings.last?.origin == Tile(x: 14, y: 12))
    let placed = session.state
    session.confirm(); #expect(session.state == placed)
}

@MainActor @Test func clearingTerrainMessageExplainsOpenBuildableGround() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let session = try GameSession(clock: { moveEpoch }, saveURL: folder.appendingPathComponent("save.json"), configuration: moveConfiguration())
    let c = session.configuration
    let tile = try #require((0..<c.map.height).flatMap { y in (0..<c.map.width).map { Tile(x: $0, y: y) } }.first {
        c.map.terrain(at: $0) == .clearing && $0 != c.map.campfire
    })
    session.tap(tile)
    #expect(session.message.contains("Open clearing · buildable ground"))
}

@MainActor @Test func backgroundCancelsRotatedNewCandidateWithoutCharging() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let session = try GameSession(clock: { moveEpoch }, saveURL: folder.appendingPathComponent("save.json"), configuration: moveConfiguration())
    let before = session.state
    session.choose(.hut); session.rotatePreview(); session.background(); session.resume()
    #expect(!session.isDragMode && session.previewOrientation == .north)
    session.confirm(); #expect(session.state == before)
}
