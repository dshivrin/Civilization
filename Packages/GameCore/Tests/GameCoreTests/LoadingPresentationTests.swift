import Testing
import GameApplication

@Test func loadingProgressRequiresAnActualValidMeasurement() {
    #expect(LoadingPresentation(stage: "Restoring settlement…").progress == nil)
    #expect(LoadingProgress(completed: 0, total: 0).fraction == nil)
    #expect(LoadingProgress(completed: .nan, total: 20).fraction == nil)
    #expect(LoadingProgress(completed: 4, total: .infinity).fraction == nil)
    #expect(LoadingProgress(completed: -1, total: 20).fraction == nil)
    #expect(LoadingProgress(completed: 5, total: 20).fraction == 0.25)
    #expect(LoadingProgress(completed: 21, total: 20).fraction == 1)
}

@Test func loadingSkipOnlyHidesSceneryAndNeverChangesReadinessInformation() {
    var presentation = LoadingPresentation(stage: "Preparing the valley…", measurement: .init(completed: 3, total: 8))
    #expect(presentation.showsScenery)
    presentation.skipScenery()
    #expect(!presentation.showsScenery)
    #expect(presentation.showsEra)
    #expect(presentation.stage == "Preparing the valley…")
    #expect(presentation.progress == 0.375)
}

@Test func loadingBrandStageDoesNotClaimAnEraOrShowScenery() {
    let presentation = LoadingPresentation(stage: "Preparing menu…", context: .brand)
    #expect(!presentation.showsScenery)
    #expect(!presentation.showsEra)
    #expect(presentation.progress == nil)
}

@Test func loadingDecorativeMotionHonorsEverySuspensionReason() {
    let presentation = LoadingPresentation(stage: "Restoring settlement…")
    #expect(presentation.animatesScenery(isActive: true, reduceMotion: false, lowPower: false))
    #expect(!presentation.animatesScenery(isActive: false, reduceMotion: false, lowPower: false))
    #expect(!presentation.animatesScenery(isActive: true, reduceMotion: true, lowPower: false))
    #expect(!presentation.animatesScenery(isActive: true, reduceMotion: false, lowPower: true))
    var skipped = presentation
    skipped.skipScenery()
    #expect(!skipped.animatesScenery(isActive: true, reduceMotion: false, lowPower: false))
}
