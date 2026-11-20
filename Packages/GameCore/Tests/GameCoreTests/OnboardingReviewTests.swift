import Foundation
import Testing
import GameCore
import GameApplication

private let onboardingEpoch = Date(timeIntervalSince1970: 20_000_000)

@Test func onboardingForestProposalIsDeterministicConnectedAndContainsOnlyRealTerrain() throws {
    let configuration = try GameConfiguration.bundled()
    let engine = try GameEngine(configuration: configuration, now: onboardingEpoch)
    let first = try #require(try OnboardingReviewSnapshot.make(configuration: configuration, state: engine.state))
    let second = try #require(try OnboardingReviewSnapshot.make(configuration: configuration, state: engine.state))
    #expect(first == second)
    #expect(!first.region.forestTiles.isEmpty)
    #expect(first.region.forestTiles.allSatisfy { configuration.map.terrain(at: $0) == .forest })
    #expect(first.region.tiles.allSatisfy(configuration.map.contains))
    let seed = try #require(first.region.forestTiles.first)
    var visited: Set<Tile> = [seed], queue = [seed], index = 0
    while index < queue.count {
        for neighbor in RoadGeometry.neighbors(of: queue[index]).map(\.tile)
        where first.region.forestTiles.contains(neighbor) && visited.insert(neighbor).inserted { queue.append(neighbor) }
        index += 1
    }
    #expect(visited == first.region.forestTiles)
    #expect(first.initialDiscoveredTiles == configuration.tiles(within: configuration.explorationRules!.initialRadius))
    #expect(!first.initialDiscoveredTiles.contains(Tile(x: 2, y: 12)))
}

@Test func onboardingProposedWoodcutterSitesPassActualTransactionValidationWithoutSpending() throws {
    let configuration = try GameConfiguration.bundled()
    let engine = try GameEngine(configuration: configuration, now: onboardingEpoch)
    let before = engine.state
    let snapshot = try #require(try OnboardingReviewSnapshot.make(configuration: configuration, state: before))
    #expect(!snapshot.region.woodcutterOrigins.isEmpty)
    var previewState = before
    previewState.discoveredTiles = before.discoveredTiles!.union(snapshot.revealedDiscoveredTiles)
    let preview = try GameEngine(state: previewState, configuration: configuration)
    for origin in snapshot.region.woodcutterOrigins {
        #expect(preview.placementIssue(.woodcutter, at: origin) == nil)
        #expect(configuration.definition(.woodcutter).footprint.tiles(at: origin).allSatisfy(snapshot.revealedDiscoveredTiles.contains))
        #expect(max(abs(origin.x - configuration.map.campfire.x), abs(origin.y - configuration.map.campfire.y)) <= 9)
    }
    #expect(engine.state == before)
    #expect(snapshot.sourceDiscoveredTiles == before.discoveredTiles)
    #expect(snapshot.initialDiscoveredTiles.isSubset(of: snapshot.revealedDiscoveredTiles))
}

@Test func onboardingReviewReturnsNoInventedForestWhenMapHasNone() throws {
    var configuration = try GameConfiguration.bundled()
    configuration.map.rows = configuration.map.rows.map { $0.replacingOccurrences(of: "f", with: ".") }
    let engine = try GameEngine(configuration: configuration, now: onboardingEpoch)
    #expect(try OnboardingReviewSnapshot.make(configuration: configuration, state: engine.state) == nil)
}

@Test func onboardingGuideRetainsOutOfOrderFactsWithoutInventingEarlierCompletion() {
    var guide = OnboardingReviewGuide(requiresConnection: false)
    guide.observe(.woodcutterCompleted)
    guide.observe(.woodcutterCompleted)
    #expect(guide.nextStep == .campfire)
    guide.observe(.campfireEstablished)
    #expect(guide.nextStep == .hut)
    guide.observe(.hutCompleted)
    #expect(guide.nextStep == .expedition)
    guide.skip()
    guide.observe(.forestRevealed)
    #expect(guide.isSkipped)
    guide.reopen()
    #expect(guide.nextStep == .expedition)
    guide.observe(.expeditionStarted)
    #expect(guide.nextStep == .handoff)
    #expect(guide.observedEvents.count == 5)
}

@Test func onboardingGuideRequiresConnectionOnlyUnderExplicitConnectedRules() {
    var connected = OnboardingReviewGuide(requiresConnection: true)
    var legacy = OnboardingReviewGuide(requiresConnection: false)
    for event: OnboardingReviewEvent in [.campfireEstablished, .hutCompleted, .expeditionStarted, .forestRevealed, .woodcutterCompleted] {
        connected.observe(event); legacy.observe(event)
    }
    #expect(connected.nextStep == .connection)
    #expect(legacy.nextStep == .handoff)
    connected.observe(.woodcutterConnected)
    #expect(connected.nextStep == .handoff)
}

@Test func onboardingGuideCanReconstructActualCompletedBuildingsAndPaidExpedition() throws {
    let configuration = try GameConfiguration.bundled()
    var engine = try GameEngine(configuration: configuration, now: onboardingEpoch)
    let region = try #require(try OnboardingReviewSnapshot.make(configuration: configuration, state: engine.state)).region
    let before = engine.state
    let first = OnboardingReviewGuide(engine: engine, region: region)
    #expect(first.nextStep == .hut)
    #expect(engine.state == before)
    try engine.build(.hut, at: Tile(x: 14, y: 8))
    #expect(OnboardingReviewGuide(engine: engine, region: region).nextStep == .hut)
    engine.advance(to: onboardingEpoch.addingTimeInterval(15))
    #expect(OnboardingReviewGuide(engine: engine, region: region).nextStep == .expedition)
    try engine.startExploration()
    let paid = engine.state
    #expect(OnboardingReviewGuide(engine: engine, region: region).nextStep == .forest)
    #expect(OnboardingReviewGuide(engine: engine, region: region).nextStep == .forest)
    #expect(engine.state == paid)
}
