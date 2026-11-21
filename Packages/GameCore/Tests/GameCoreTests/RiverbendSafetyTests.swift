import Foundation
import Testing
import GameCore
import GameApplication
import GamePersistence

private let safetyEpoch = Date(timeIntervalSince1970: 90_000_000)
private func safetyRoot() -> URL { FileManager.default.temporaryDirectory.appendingPathComponent("riverbend-safety-" + UUID().uuidString) }

@Test(arguments: RoadStyle.allCases) @MainActor
func playerFoundingPreservesPrelaidEntranceAndContinue(style: RoadStyle) async throws {
    let root = safetyRoot(); defer { try? FileManager.default.removeItem(at: root) }
    let library = try await GameLibrary.startNewGame(rootURL: root, clock: { safetyEpoch })
    library.session.chooseRoadTool(.draw(style)); library.session.extendRoadStroke(to: Tile(x: 18,y: 12)); library.session.confirmRoadStroke()
    library.session.upgrade(buildingID: 0)
    #expect(library.session.state.roads?.filter { $0.tile == Tile(x: 18,y: 12) }.count == 1)
    #expect(library.session.state.roads?.first?.style == style)
    let reopened = try await GameLibrary.load(rootURL: root, clock: { safetyEpoch })
    #expect(reopened.session.persistenceWarning == nil)
    #expect(reopened.session.state == library.session.state)
}

@Test(arguments: ["small", "large"], ["review", "reviewFalse", "developer", "profile", "unknown"]) @MainActor
func ordinaryContinuePreservesMarkedPrimaryAndAllBackups(map: String, marker: String) async throws {
    let root = safetyRoot(); defer { try? FileManager.default.removeItem(at: root) }
    let store = GameLibraryStore(rootURL: root)
    let game = SavedGame(id: "legacy", name: "Preserve", createdAt: safetyEpoch, mapID: "river-clearing-64x48-v1")
    try store.save(GameLibraryIndex(activeGameID: "legacy", games: [game]))
    let url = try store.saveURL(for: game)
    try SaveStore(url: url).save(GameEngine(configuration: map == "small" ? .legacyDevelopment() : .bundled(), now: safetyEpoch).state)
    var json = try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
    switch marker {
    case "review": json["isGameplayReview"] = true
    case "reviewFalse": json["isGameplayReview"] = false
    case "developer": json["developerScenario"] = "early"
    case "profile": json["profile"] = "unknown-review"
    default: json["futureEnvelope"] = "unknown"
    }
    try JSONSerialization.data(withJSONObject: json).write(to: url)
    let backup = url.appendingPathExtension("original.bak")
    let bytes = try Data(contentsOf: url); try bytes.write(to: backup)
    let indexBytes = try Data(contentsOf: store.indexURL)
    do {
        let library = try await GameLibrary.load(rootURL: root, clock: { safetyEpoch.addingTimeInterval(60) })
        #expect(library.session.persistenceWarning != nil)
        library.setActive(true); library.session.tick(); library.session.save()
    } catch { /* Refusal is also safe; a protected temporary view must never adopt the body. */ }
    #expect(try Data(contentsOf: url) == bytes)
    #expect(try Data(contentsOf: backup) == bytes)
    #expect(try Data(contentsOf: store.indexURL) == indexBytes)
    #expect(!FileManager.default.fileExists(atPath: url.appendingPathExtension("pre-geography-64x48.bak").path))
    #expect(!FileManager.default.fileExists(atPath: root.appendingPathComponent("retired-small-maps").path))
}

@Test @MainActor func unindexedRetirementFailureCannotPublishNewSelection() async throws {
    let root = safetyRoot(); defer { try? FileManager.default.removeItem(at: root) }
    let url = root.appendingPathComponent("settlement-v1.json")
    try SaveStore(url: url).save(GameEngine(configuration: .legacyDevelopment(), now: safetyEpoch).state)
    let bytes = try Data(contentsOf: url)
    try Data("blocked".utf8).write(to: root.appendingPathComponent("retired-small-maps"))
    await #expect(throws: Error.self) { try await GameLibrary.startNewGame(rootURL: root, clock: { safetyEpoch }) }
    #expect(!FileManager.default.fileExists(atPath: root.appendingPathComponent("games-index.json").path))
    #expect(!FileManager.default.fileExists(atPath: root.appendingPathComponent("games").path))
    #expect(try Data(contentsOf: url) == bytes)
}

@Test func retirementRetryRetainsExactOriginalIndexBytes() throws {
    let root = safetyRoot(); defer { try? FileManager.default.removeItem(at: root) }
    let store = GameLibraryStore(rootURL: root)
    let game = SavedGame(id: "legacy", name: "Small", createdAt: safetyEpoch, mapID: "river-clearing-v1")
    let index = GameLibraryIndex(activeGameID: "legacy", games: [game]); try store.save(index)
    // A partial prior archive has the exact index bytes, including intentional whitespace.
    var raw = try Data(contentsOf: store.indexURL); raw.append(Data("\n\n".utf8)); try raw.write(to: store.indexURL)
    let url = try store.saveURL(for: game)
    try SaveStore(url: url).save(GameEngine(configuration: .legacyDevelopment(), now: safetyEpoch).state)
    let archive = root.appendingPathComponent("retired-small-maps/legacy")
    try FileManager.default.createDirectory(at: archive, withIntermediateDirectories: true)
    try raw.write(to: archive.appendingPathComponent("library-index-before-retirement.json"))
    let result = try store.retiringObsoleteSmallMaps(index)
    #expect(result.games.first?.retiredSmallMap == true)
    #expect(try Data(contentsOf: archive.appendingPathComponent("library-index-before-retirement.json")) == raw)
}

private func safetyWorkshop() throws -> GameEngine {
    var game = try GameEngine(configuration: .riverbendPlayer(), now: safetyEpoch)
    func wait(_ seconds: Double = 60) { game.advance(to: game.state.lastUpdated.addingTimeInterval(seconds)) }
    func path(_ tiles: [Tile]) throws { try game.editRoads(at: tiles, style: .trodden) }
    try game.upgrade(buildingID: 0); try game.build(.hut, at: Tile(x:20,y:10)); wait()
    try path([Tile(x:19,y:12),Tile(x:20,y:12)])
    try game.build(.gatheringShelter, at: Tile(x:14,y:14))
    try path([Tile(x:17,y:13),Tile(x:16,y:13),Tile(x:15,y:13),Tile(x:14,y:13)])
    try game.recoverRiverbendWood(); wait(); try game.startExploration(); wait()
    try game.build(.woodcutter, at: Tile(x:11,y:15))
    try path((11...14).map { Tile(x:$0,y:13) } + [Tile(x:11,y:14)]); wait(780)
    try game.build(.stoneGatherer, at: Tile(x:19,y:16))
    try path([Tile(x:18,y:13),Tile(x:18,y:14),Tile(x:18,y:15),Tile(x:18,y:16)]); wait(600)
    try game.setProductionMode(buildingID: game.state.buildings.last!.id, recipeID: "flint"); wait(180)
    try game.setProductionMode(buildingID: game.state.buildings.last!.id, recipeID: "stone")
    try game.research("oralTradition"); try game.research("stoneTools")
    return game
}

@Test(arguments: ["tool", "survey"], ["tick", "resume", "background", "action"]) @MainActor
func playerFailedWritesDoNotPublishCompletedTimers(timer: String, operation: String) async throws {
    let root = safetyRoot(); defer { try? FileManager.default.removeItem(at: root) }
    var game = try safetyWorkshop()
    if timer == "tool" { try game.startRiverbendTools() } else { try game.startExploration() }
    var now = game.state.lastUpdated
    _ = try await GameLibrary.startNewGame(rootURL: root, clock: { now })
    let url = root.appendingPathComponent("settlement-v1.json")
    try SaveStore(url: url).save(game.state)
    let library = try await GameLibrary.load(rootURL: root, clock: { now })
    let session = library.session; library.setActive(true)
    let before = session.state, bytes = try Data(contentsOf: url)
    try FileManager.default.removeItem(at: url); try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
    now.addTimeInterval(60)
    switch operation {
    case "tick": session.tick()
    case "resume": session.resume()
    case "background": session.background()
    default: session.recoverRiverbendFood()
    }
    #expect(session.state == before)
    #expect(session.persistenceWarning != nil)
    try FileManager.default.removeItem(at: url); try bytes.write(to: url)
    session.resume()
    #expect(session.persistenceWarning == nil)
    if timer == "tool" { #expect(session.state.resources[.stoneTools] == before.resources[.stoneTools] + 1) }
    else { #expect(session.discoveredTileCount > before.discoveredTiles!.count) }
}

@Test @MainActor func playerFailedRoadConfirmRetainsDraftAndReportsFailure() async throws {
    let root = safetyRoot(); defer { try? FileManager.default.removeItem(at: root) }
    let library = try await GameLibrary.startNewGame(rootURL: root, clock: { safetyEpoch })
    let session = library.session; session.upgrade(buildingID: 0)
    session.chooseRoadTool(.draw(.trodden)); session.extendRoadStroke(to: Tile(x:19,y:12))
    let before = session.state, draft = session.roadDraft
    let url = root.appendingPathComponent("settlement-v1.json")
    try FileManager.default.removeItem(at: url); try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
    session.confirmRoadStroke()
    #expect(session.state == before && session.roadDraft == draft)
    #expect(!session.message.contains("applied"))
    #expect(session.persistenceWarning != nil)
}

@Test func playerSourcesAppearContextuallyAndRequireLocalWorksites() throws {
    var game = try GameEngine(configuration: .riverbendPlayer(), now: safetyEpoch)
    #expect(!game.discoveredDeposits.contains { $0.resource == .stone || $0.resource == .flint })
    game = try safetyWorkshop()
    let stone = try #require(game.discoveredDeposits.first { $0.resource == .stone })
    let flint = try #require(game.discoveredDeposits.first { $0.resource == .flint })
    #expect(stone.origin == flint.origin && stone.renewable && flint.renewable)
    #expect(game.placementIssue(.stoneGatherer, at: Tile(x:24,y:10)) != nil)
    let gatherer = try #require(game.state.buildings.first { $0.kind == .stoneGatherer })
    #expect(game.relocationIssue(buildingID: gatherer.id, at: Tile(x:24,y:10)) != nil)
    #expect(game.grossRates.stone > 0)
}

@Test func playerAdoptedProducerDefaultsRemainSelectable() throws {
    var game = try safetyWorkshop()
    for kind: BuildingKind in [.gatheringShelter, .woodcutter] {
        let building = try #require(game.state.buildings.first { $0.kind == kind })
        let recipe = try #require(game.configuration.definition(kind).recipes?.first)
        try game.setProductionMode(buildingID: building.id, recipeID: recipe.id)
        #expect(game.state.buildings.first { $0.id == building.id }?.productionModeID == recipe.id)
    }
}
