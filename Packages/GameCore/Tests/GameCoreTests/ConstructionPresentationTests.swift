import Testing
import GameCore
import GameApplication

#if DEBUG
@Test func constructionReviewShowsWallsWithoutChangingLegacyStages() {
    for (remaining, expected): (Double, ConstructionPresentation.ReviewStage) in [
        (100, .foundation), (85, .frame), (60, .walls), (25, .roof), (0, .finished)
    ] {
        #expect(ConstructionPresentation(remaining: remaining, duration: 100).reviewStage == expected)
    }
    #expect(ConstructionPresentation(remaining: 60, duration: 100).stage == .frame)
    #expect(ConstructionPresentation(remaining: .nan, duration: 100).reviewStage == .foundation)
    #expect(ConstructionPresentation(remaining: 10, duration: 0).reviewStage == .foundation)
    #expect(ConstructionPresentation(remaining: 101, duration: 100).reviewStage == .foundation)
    #expect(ConstructionPresentation(remaining: -1, duration: 100).reviewStage == .foundation)
}
#endif

@Test func constructionPresentationUsesActualRemainingWorkAndClampsCorruptProgress() {
    #expect(ConstructionPresentation(remaining: 100, duration: 100).stage == .foundation)
    #expect(ConstructionPresentation(remaining: 70, duration: 100).stage == .frame)
    #expect(ConstructionPresentation(remaining: 20, duration: 100).stage == .roof)
    #expect(ConstructionPresentation(remaining: 0, duration: 100).stage == .finished)
    #expect(ConstructionPresentation(remaining: 500, duration: 100).fraction == 0)
    #expect(ConstructionPresentation(remaining: -1, duration: 100).fraction == 1)
    #expect(ConstructionPresentation(remaining: .nan, duration: 100).fraction == 0)
    #expect(ConstructionPresentation(remaining: 1, duration: 0).fraction == 0)
}
