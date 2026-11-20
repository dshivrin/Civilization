import Testing
import GameCore
import GameApplication

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
