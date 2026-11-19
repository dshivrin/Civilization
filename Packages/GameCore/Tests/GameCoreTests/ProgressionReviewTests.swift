import Foundation
import Testing
@testable import GameCore
private let progressReviewEpoch = Date(timeIntervalSince1970:11_000_000)
@Test func reviewCompletedScienceCannotExistWithoutItsPermanentResearchHistory() throws {
    let c = try GameConfiguration.bundled()
    var state = try GameEngine(configuration:c,now:progressReviewEpoch).state
    state.completedPillarGoals = ["scienceFoundation"]
    #expect(throws:GameError.self) { _ = try GameEngine(state:state,configuration:c) }
}
@Test func reviewInheritedConstructionKnowledgeRequiresAnExistingBuildingWitness() throws {
    let c = try GameConfiguration.bundled()
    var state = try GameEngine(configuration:c,now:progressReviewEpoch).state
    state.grandfatheredBuildingKinds = [.farm]
    #expect(throws:GameError.self) { _ = try GameEngine(state:state,configuration:c) }
}
@Test func reviewTransientConfiguredAchievementIsIndependentOfElapsedPartition() throws {
    var c = try GameConfiguration.bundled()
    // A valid experimental economy goal combining an increasing and decreasing stock.
    // It holds between 60 and 600 seconds, but not at 0 or 1200 seconds.
    let index = c.progressionGoals!.firstIndex { $0.pillar == .economy }!
    c.progressionGoals![index].requiredBuildings = []
    c.progressionGoals![index].requiredTechnologies = []
    c.progressionGoals![index].minimumResources = .init(food:50)
    c.progressionGoals![index].minimumResources[.water] = 61.5
    let id = c.progressionGoals![index].id
    var a = try GameEngine(configuration:c,now:progressReviewEpoch), b = a
    a.advance(to:progressReviewEpoch.addingTimeInterval(1200),offline:true)
    for second in 1...1200 { b.advance(to:progressReviewEpoch.addingTimeInterval(Double(second))) }
    #expect(b.isPillarGoalComplete(id:id))
    #expect(a.isPillarGoalComplete(id:id) == b.isPillarGoalComplete(id:id))
}
