import Foundation
import Testing
import GameCore
import GameApplication

@Test func artCatalogCoversCompleteEraAndRejectsUnsafePaths() throws {
    let configuration = try GameConfiguration.bundled()
    let catalog = try ArtCatalog.bundled()
    try catalog.validate(configuration: configuration)
    #expect(Set(catalog.buildings.map(\.id)) == Set(configuration.buildings.map { $0.kind.rawValue }))
    #expect(Set(catalog.research.map(\.id)) == Set(configuration.technologyDefinitions.map(\.id)))
    #expect(Set(catalog.resources.map(\.id)) == Set(Resource.allCases.map(\.rawValue)))
    #expect(Set(catalog.research.map(\.motif)).count == configuration.technologyDefinitions.count)
    #expect(catalog.pillars.count == DevelopmentPillar.allCases.count)
    var damaged = catalog
    damaged.buildings[0].file = "../settlement-v1.json"
    #expect(throws: ArtCatalogError.self) { try damaged.validate(configuration: configuration) }
}

@Test func visualAnchorsAndAnimationBudgetsAreIndependentOfEconomy() throws {
    let catalog = try ArtCatalog.bundled()
    for visual in catalog.buildings {
        #expect(visual.anchorX == 0.5)
        #expect((0...1).contains(visual.anchorY))
        #expect(visual.worldWidth > 0 && visual.worldWidth <= 192)
        #expect(visual.worldHeight > 0 && visual.worldHeight <= 224)
    }
    #expect(VisualActivityPolicy.allowsProduction(isOperational: true, productivity: 1, reduceMotion: false))
    #expect(!VisualActivityPolicy.allowsProduction(isOperational: false, productivity: 1, reduceMotion: false))
    #expect(!VisualActivityPolicy.allowsProduction(isOperational: true, productivity: 0, reduceMotion: false))
    #expect(!VisualActivityPolicy.allowsProduction(isOperational: true, productivity: 1, reduceMotion: true))
}

@Test func transparentSpriteCornersCannotStealMapTaps() throws {
    let mask = try SpriteAlphaMask(width: 2, height: 2, alpha: [0, 255, 255, 0])
    #expect(!mask.contains(normalizedX: 0.1, normalizedY: 0.1))
    #expect(mask.contains(normalizedX: 0.8, normalizedY: 0.1))
    #expect(!mask.contains(normalizedX: -.infinity, normalizedY: 0.5))
    #expect(!mask.contains(normalizedX: 1.1, normalizedY: 0.5))
    #expect(throws: ArtCatalogError.self) { try SpriteAlphaMask(width: 2, height: 2, alpha: [255]) }
}

@Test @MainActor func renderPauseFollowsLifecycleWithoutChangingSaveState() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("normal.json")
    defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
    let session = try GameSession(clock: { Date(timeIntervalSince1970: 1000) }, saveURL: url)
    #expect(!session.shouldPauseRendering)
    session.setActive(false)
    #expect(session.shouldPauseRendering)
    session.setActive(true)
    #expect(!session.shouldPauseRendering)
    #if DEBUG
    session.loadDeveloperScenario(.early)
    session.setDeveloperPaused(true)
    #expect(!session.shouldPauseRendering) // Keep the map drawable for paused placement/inspection.
    #expect(session.shouldPauseAnimation)
    session.setDeveloperPaused(false)
    #expect(!session.shouldPauseRendering)
    #endif
}

@Test func frameSummaryRejectsSuspensionAndNonfiniteSamples() throws {
    let samples = Array(repeating: 1.0 / 60, count: 120) + [.nan, -.infinity, 0, 5]
    let summary = try #require(RenderFrameSummary(samples: samples))
    #expect(abs(summary.framesPerSecond - 60) < 0.001)
    #expect(abs(summary.p95Milliseconds - 1000 / 60) < 0.001)
    #expect(summary.frameCount == 120)
    #expect(RenderFrameSummary(samples: [.nan, 0, 2]) == nil)
}

@Test func productionActivityUsesActualOutputAndExcludesHousing() throws {
    let epoch = Date(timeIntervalSince1970: 10_000)
    var engine = try GameEngine(configuration: .bundled(), now: epoch)
    #expect(engine.operatingProductionBuildingIDs == [0])
    let tile = try #require((0..<24).flatMap { y in (0..<32).map { Tile(x: $0,y: y) } }.first { engine.placementIssue(.hut, at: $0) == nil })
    try engine.build(.hut, at: tile)
    engine.advance(to: epoch.addingTimeInterval(60))
    #expect(engine.state.buildings.contains { $0.kind == .hut && $0.isOperational })
    #expect(engine.operatingProductionBuildingIDs == [0])
}

@Test @MainActor func economicPresentationRefreshesAfterRealStateChanges() throws {
    var now = Date(timeIntervalSince1970: 1000)
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let session = try GameSession(clock: { now }, saveURL: folder.appendingPathComponent("normal.json"))
    let original = session.economicOverview
    #expect(session.rates == original.net)
    session.choose(.gatheringShelter);session.confirm()
    now = now.addingTimeInterval(60);session.tick()
    let updated = session.economicOverview
    #expect(updated.gross.food > original.gross.food)
    #expect(updated.net == session.rates)
    #expect(updated.gross == session.grossRates)
    #expect(updated.consumption == session.consumption)
    #expect(updated.productiveBuildingIDs == session.operatingProductionBuildingIDs)
}
