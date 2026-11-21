#if DEBUG
import Foundation
import Testing
import GameCore
import GameApplication

private let foundingEpoch = Date(timeIntervalSince1970: 9_000_000)

@Test func foundingReviewUpgradeConservesStocksIdentityAndHistory() throws {
    var review = try RiverbendFoundingReview(now: foundingEpoch)
    let before = review.engine.state
    let civic = try #require(review.engine.civicCenter)
    #expect(review.objective == "Upgrade Campfire to Founder’s Lodge")
    #expect(review.engine.upgradeIssue(buildingID: civic.id) == nil)
    #expect(before.roads?.isEmpty != false && before.researchedTechnologies?.isEmpty != false)
    try review.found()
    let after = review.engine.state
    #expect(review.engine.civicCenter?.id == civic.id)
    #expect(review.engine.civicCenter?.origin == civic.origin)
    #expect(review.engine.civicCenter?.occupiedFootprint(in: review.engine.configuration) == civic.occupiedFootprint(in: review.engine.configuration))
    #expect(review.engine.civicLevel == 2 && review.engine.usesConnectedPaths)
    #expect(after.resources.wood == before.resources.wood - 12)
    #expect(after.resources.stone == before.resources.stone - 4)
    #expect(after.resources.food == before.resources.food)
    #expect(after.completedGoals == before.completedGoals)
    #expect(!after.completedGoals.contains(.storytellingCircle))
    #expect(after.civicProgress?.reachedLevels == [1, 2])
    #expect(after.civicProgress?.completedObjectives == ["1:civic-level-2"])
    #expect(after.roads?.count == 1)
    #expect(review.entrance == Tile(x: civic.origin.x + 1, y: civic.origin.y))
    #expect(review.engine.isServiceOperational(try #require(review.engine.civicCenter)))
    #expect(review.objective == "Build your first hut")
    let once = review.engine.state
    #expect(throws: GameError.self) { try review.found() }
    #expect(review.engine.state == once)
    _ = try GameEngine(state: once, configuration: review.engine.configuration)
}

@Test func foundingReviewHutConnectionRetainsPaidWorkStocksAndCompletedHistory() throws {
    var r = try RiverbendFoundingReview(now: foundingEpoch)
    #expect(r.hutSites.count >= 2)
    let civicOrigin = r.engine.configuration.map.campfire
    for site in r.hutSites.prefix(2) {
        #expect(abs(MapGeometry.point(for: site).x - MapGeometry.point(for: civicOrigin).x) >= 128)
    }
    #expect(throws: GameError.self) { try r.buildHut(at: r.hutSites[0]) }
    try r.found()
    let site = try #require(r.hutSites.first)
    let stock = r.engine.state.resources
    try r.buildHut(at: site)
    let hut = try #require(r.engine.state.buildings.first { $0.kind == .hut })
    #expect(r.engine.state.resources.wood == stock.wood - r.engine.configuration.definition(.hut).cost.wood)
    try r.drawPath(to: site)
    let paid = r.engine.state
    try r.disconnect()
    #expect(r.engine.state.resources == paid.resources)
    #expect(r.engine.state.buildings == paid.buildings)
    try r.advance(seconds: 60)
    let complete = r.engine.state
    let completedHut = try #require(complete.buildings.first { $0.id == hut.id })
    #expect(completedHut.isOperational && !r.engine.isServiceOperational(completedHut))
    #expect(r.objective == "Connect your hut to the Lodge")
    try r.drawPath(to: site)
    #expect(r.engine.isServiceOperational(completedHut))
    #expect(r.objective == "Founding connected")
    let earned = r.engine.state
    try r.disconnect()
    #expect(r.engine.state.resources == earned.resources)
    #expect(r.engine.state.completedGoals == earned.completedGoals)
    #expect(r.engine.state.civicProgress == earned.civicProgress)
    #expect(!r.engine.isServiceOperational(completedHut))
    let reopened = try RiverbendFoundingReview(state: r.engine.state)
    #expect(reopened.engine.state == r.engine.state && reopened.objective == r.objective)
    #expect(reopened.engine.civicCenter?.id == 0)
}

@Test func foundingReviewAtomicSaveIsolationAndFailure() throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: dir) }
    var store = try RiverbendFoundingStore(directory: dir, now: foundingEpoch)
    try store.perform { try $0.found() }
    let bytes = try Data(contentsOf: store.url)
    let saved = store.review.engine.state
    let reopened = try RiverbendFoundingStore(directory: dir, now: foundingEpoch.addingTimeInterval(3600))
    #expect(reopened.review.engine.state == saved)
    #expect(try Data(contentsOf: store.url) == bytes)
    try FileManager.default.removeItem(at: store.url)
    try FileManager.default.createDirectory(at: store.url, withIntermediateDirectories: false)
    #expect(throws: (any Error).self) { try store.perform { try $0.buildHut(at: $0.hutSites[0]) } }
    #expect(store.review.engine.state == saved)
    let normal = try GameEngine(configuration: .bundled(), now: foundingEpoch)
    #expect(normal.upgradeIssue(buildingID: 0) != nil && !normal.usesConnectedPaths)
    #expect(normal.configuration.constructionGoalWoodReward == 10)
    #expect(try GameConfiguration.riverbendEconomyLab().civicLevels == nil)
}
@Test func foundingReviewKeepsEntireHutFootprintOutsideCivicYard() throws {
    var r = try RiverbendFoundingReview(now: foundingEpoch); try r.found()
    let civic = r.engine.configuration.map.campfire
    let adjacent = Tile(x: civic.x - 2, y: civic.y - 1)
    #expect(r.hutIssue(at: adjacent) != nil)
    let before = r.engine.state
    #expect(throws: GameError.self) { try r.buildHut(at: adjacent) }
    #expect(r.engine.state == before)
    for tile in r.hutSites { #expect(r.hutIssue(at: tile) == nil) }
}

@Test func foundingReviewRejectsUnroutableOpeningBeforePayment() throws {
    var r = try RiverbendFoundingReview(now: foundingEpoch); try r.found()
    let acrossRiver = Tile(x: 23, y: 12)
    #expect(r.engine.placementIssue(.hut, at: acrossRiver) == nil)
    let before = r.engine.state
    #expect(throws: GameError.self) { try r.buildHut(at: acrossRiver) }
    #expect(r.engine.state == before)
}

@Test func foundingReviewStaleWindowCannotOverwritePaidProgress() throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: dir) }
    var first = try RiverbendFoundingStore(directory: dir, now: foundingEpoch)
    try first.perform { try $0.found() }
    var stale = try RiverbendFoundingStore(directory: dir, now: foundingEpoch)
    try first.perform { try $0.buildHut(at: $0.hutSites[0]) }
    let paid = try Data(contentsOf: first.url)
    #expect(throws: (any Error).self) { try stale.perform { try $0.advance(seconds: 1) } }
    #expect(try Data(contentsOf: first.url) == paid)
}

@Test func foundingReviewHistoryIsScopedBeforeUpgradeAndRejectsLegacyCreditOnReload() throws {
    var r = try RiverbendFoundingReview(now: foundingEpoch)
    try r.advance(seconds: 1)
    #expect(r.engine.state.civicProgress?.completedObjectives.isEmpty == true)
    try r.found()
    #expect(r.engine.state.civicProgress?.completedObjectives == ["1:civic-level-2"])
    var invalid = r.engine.state
    invalid.civicProgress?.completedObjectives.insert("7:discovery")
    #expect(throws: GameError.self) { try RiverbendFoundingReview(state: invalid) }
}

@Test @MainActor func foundingReviewPreservesAuthenticNormalDeveloperRound2LibraryAndLab() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let library = try await GameLibrary.load(rootURL: root, clock: { foundingEpoch })
    let session = library.session
    session.loadDeveloperScenario(.early); #expect(session.returnToNormalGame())
    session.startGameplayReview(); session.activateReviewConnectivity(); session.save()
    #expect(session.usesConnectedPaths); #expect(session.returnToNormalGame()); session.save()
    _ = try RiverbendEconomyLabStore(directory: root, now: foundingEpoch)
    let reviewURL = root.appendingPathComponent("ui2-founding-v1.json")
    func files() throws -> [URL: Data] {
        let enumerator = try #require(FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.isRegularFileKey]))
        var result: [URL: Data] = [:]
        for case let url as URL in enumerator where !url.lastPathComponent.hasPrefix(reviewURL.lastPathComponent) {
            if try url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true { result[url] = try Data(contentsOf: url) }
        }
        return result
    }
    let before = try files(); #expect(before.count >= 5)
    var store = try RiverbendFoundingStore(directory: root, now: foundingEpoch)
    try store.perform { try $0.found() }
    try store.perform { try $0.buildHut(at: $0.hutSites[0]) }
    try store.perform { try $0.advance(seconds: 60); try $0.drawPath(to: #require($0.hut).origin) }
    try store.perform { try $0.disconnect() }
    _ = try RiverbendFoundingStore(directory: root, now: foundingEpoch.addingTimeInterval(5000))
    #expect(try files() == before)
}

@Test func foundingReviewRejectsBadTerrainAndPreservesDamagedFile() throws {
    var r = try RiverbendFoundingReview(now: foundingEpoch)
    try r.found()
    let before = r.engine.state
    #expect(throws: GameError.self) { try r.editPath([Tile(x: -1, y: 0)]) }
    #expect(throws: GameError.self) { try r.buildHut(at: r.engine.configuration.map.campfire) }
    #expect(r.engine.state == before)
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: dir) }
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let url = dir.appendingPathComponent("ui2-founding-v1.json")
    let damaged = Data("damaged founding source".utf8); try damaged.write(to: url)
    #expect(throws: (any Error).self) { try RiverbendFoundingStore(directory: dir, now: foundingEpoch) }
    #expect(try Data(contentsOf: url) == damaged)
}
@Test func foundingMenusSelectExactBlockerAndKeepOptionalResearchSecondary() throws {
    var r = try RiverbendFoundingReview(now: foundingEpoch)
    try r.found()
    #expect(r.catalogAction(.hut) == .build)
    #expect(r.catalogAction(.storytellingCircle) == .research("oralTradition"))
    #expect(r.catalogAction(.toolmaker) == .research("oralTradition"))
    var state = r.engine.state
    state.resources.wood = 16
    r = try RiverbendFoundingReview(state: state)
    #expect(r.catalogAction(.storehouse) == .materials)
    #expect(r.materialNeeds(for: r.engine.configuration.definition(.storehouse).cost).map(\.resource) == [.wood])
    #expect(r.materialNeeds(for: r.engine.configuration.definition(.storehouse).cost).first?.amount == 19)
    #expect(r.materialNeeds(for: r.engine.configuration.definition(.storehouse).cost).first?.suppliers.contains(.woodcutter) == true)
    // Toolmaking cannot replace the selected Storehouse's Wood requirement.
    #expect(r.catalogAction(.storehouse) != .research("stoneTools"))
}

@Test func foundingMenusUseExistingResearchAndConstructionValidation() throws {
    var r = try RiverbendFoundingReview(now: foundingEpoch); try r.found()
    let before = r.engine.state.resources
    try r.research("oralTradition")
    #expect(r.engine.researchedIDs.contains("oralTradition"))
    #expect(r.engine.state.resources.wood == before.wood - r.engine.configuration.technologyDefinitions.first { $0.id == "oralTradition" }!.cost.wood)
    #expect(r.catalogAction(.toolmaker) == .research("stoneTools"))
    let locked = r.engine.state
    #expect(throws: GameError.self) { try r.build(.toolmaker, at: r.hutSites[0]) }
    #expect(r.engine.state == locked)
    try r.build(.hut, at: r.hutSites[0])
    #expect(r.hut != nil)
}

@Test func foundingMenusRejectNonHutCivicYardAndExposeResearchReserve() throws {
    var r = try RiverbendFoundingReview(now: foundingEpoch); try r.found()
    let near = try #require(r.engine.configuration.tiles(within: 3).first { tile in
        r.engine.placementIssue(.storehouse, at: tile) == nil && r.engine.configuration.definition(.storehouse).footprint.tiles(at: tile).contains { abs($0.x - r.engine.configuration.map.campfire.x) + abs($0.y - r.engine.configuration.map.campfire.y) < 3 }
    })
    #expect(r.catalogPlacementIssue(.storehouse, at: near) != nil)
    let before = r.engine.state
    #expect(throws: GameError.self) { try r.build(.storehouse, at: near) }
    #expect(r.engine.state == before)
    var state = before; state.resources.wood = 18
    r = try RiverbendFoundingReview(state: state)
    #expect(r.engine.canAfford(r.engine.configuration.technologyDefinitions.first { $0.id == "oralTradition" }!.cost))
    #expect(r.researchSupplier("oralTradition") == .woodcutter)
    #expect(r.catalogAction(.gatheringShelter) == .materials)
}
#endif
