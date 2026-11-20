#if DEBUG
import Foundation
import Testing
import GameCore
import GameApplication

private let walkthroughEpoch = Date(timeIntervalSince1970: 30_000_000)

@Test func onboardingWalkthroughSuggestionsMoveToDifferentValidSitesWithoutSpending() throws {
    let configuration = try GameConfiguration.bundled()
    let review = try OnboardingReviewWalkthrough(configuration: configuration, now: walkthroughEpoch)
    let before = review.engine.state
    let first = try #require(review.suggestedOrigin(for: .hut))
    let second = try #require(review.suggestedOrigin(for: .hut, after: first))
    let third = try #require(review.suggestedOrigin(for: .hut, after: second))
    #expect(second != first)
    #expect(third != second)
    #expect(review.engine.placementIssue(.hut, at: second) == nil)
    #expect(review.engine.placementIssue(.hut, at: third) == nil)
    #expect(review.suggestedOrigin(for: .hut, after: Tile(x: -1, y: -1)) == first)
    #expect(review.engine.state == before)
}

@Test func onboardingWalkthroughWoodSuggestionsStayInReviewedForestSites() throws {
    let configuration = try GameConfiguration.bundled()
    var review = try OnboardingReviewWalkthrough(configuration: configuration, now: walkthroughEpoch)
    try review.startExpedition()
    try review.advanceReview(by: configuration.explorationRules!.durationSeconds)
    let first = try #require(review.suggestedOrigin(for: .woodcutter))
    let second = try #require(review.suggestedOrigin(for: .woodcutter, after: first))
    #expect(first != second)
    #expect(review.snapshot.region.woodcutterOrigins.contains(second))
    #expect(review.engine.placementIssue(.woodcutter, at: second) == nil)
}

@Test func onboardingWalkthroughUsesRealConstructionPaidExpeditionAndWoodProduction() throws {
    let configuration = try GameConfiguration.bundled()
    var review = try OnboardingReviewWalkthrough(configuration: configuration, now: walkthroughEpoch)
    #expect(review.guide.nextStep == .hut)
    let hutSite = try #require(review.suggestedOrigin(for: .hut))
    let woodBefore = review.engine.state.resources.wood
    try review.build(.hut, at: hutSite)
    #expect(review.engine.state.resources.wood == woodBefore - configuration.definition(.hut).cost.wood)
    #expect(review.guide.nextStep == .hut)
    try review.advanceReview(by: try #require(configuration.definition(.hut).constructionSeconds))
    #expect(review.guide.nextStep == .expedition)
    let beforeExpedition = review.engine.state.resources.food
    try review.startExpedition()
    #expect(review.engine.state.resources.food == beforeExpedition - configuration.explorationRules!.cost.food)
    let paid = review.engine.state
    #expect(throws: (any Error).self) { try review.startExpedition() }
    #expect(review.engine.state == paid)
    try review.advanceReview(by: configuration.explorationRules!.durationSeconds)
    #expect(review.snapshot.region.tiles.allSatisfy(review.engine.isDiscovered))
    #expect(review.guide.nextStep == .woodcutter)
    try review.build(.woodcutter, at: try #require(review.suggestedOrigin(for: .woodcutter)))
    try review.advanceReview(by: try #require(configuration.definition(.woodcutter).constructionSeconds))
    #expect(review.guide.nextStep == .handoff)
    let wood = review.engine.state.resources.wood
    try review.advanceReview(by: 60)
    #expect(review.engine.state.resources.wood > wood)
}

@Test func onboardingWalkthroughInvalidPlacementAndTimeLeaveFixtureUnchanged() throws {
    let configuration = try GameConfiguration.bundled()
    var review = try OnboardingReviewWalkthrough(configuration: configuration, now: walkthroughEpoch)
    let before = review.engine.state
    #expect(throws: (any Error).self) { try review.build(.hut, at: configuration.map.campfire) }
    #expect(review.engine.state == before)
    #expect(throws: (any Error).self) { try review.advanceReview(by: -.infinity) }
    #expect(throws: (any Error).self) { try review.advanceReview(by: -1) }
    #expect(review.engine.state == before)
}

@Test func onboardingWalkthroughSkipReopenDoesNotResetIndependentProgress() throws {
    let configuration = try GameConfiguration.bundled()
    let source = try GameEngine(configuration: configuration, now: walkthroughEpoch)
    let original = source.state
    var review = try OnboardingReviewWalkthrough(configuration: configuration, now: walkthroughEpoch)
    try review.build(.hut, at: try #require(review.suggestedOrigin(for: .hut)))
    try review.advanceReview(by: 15)
    let progressed = review.engine.state
    review.skipGuide()
    #expect(review.guide.isSkipped)
    review.reopenGuide()
    #expect(!review.guide.isSkipped)
    #expect(review.guide.nextStep == .expedition)
    #expect(review.engine.state == progressed)
    #expect(source.state == original)
    #expect(!review.engine.isDiscovered(Tile(x: 2, y: 12)))
}
#endif
