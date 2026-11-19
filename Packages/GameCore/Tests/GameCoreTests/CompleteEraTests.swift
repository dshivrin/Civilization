import Foundation
import Testing
@testable import GameCore
import GamePersistence

@Test func completeEraRequirementsComeFromCatalog() throws {
    let c = try GameConfiguration.bundled()
    let g = try GameEngine(configuration: c, now: Date())
    #expect(g.stoneAgeRequirements.first { $0.id == "buildings" }?.total == c.buildings.count)
    #expect(g.stoneAgeRequirements.first { $0.id == "research" }?.total == c.technologyDefinitions.count)
    #expect(g.requiredDiscoveryResources == Set(c.buildings.flatMap { ($0.recipes ?? []).compactMap(\.depositResource) }))
    #expect(!g.fullStoneAgeRequirementsMet)
    #expect(!g.stoneAgeRequirements.allSatisfy { $0.isComplete })
}

@Test func chaptersCreditOutOfOrderAndRetainOriginalRewardHistory() throws {
    var g = try GameEngine(configuration: .bundled(), now: Date(timeIntervalSince1970: 50_000))
    let tile = try #require((0..<24).flatMap { y in (0..<32).map { Tile(x: $0, y: y) } }.first { g.placementIssue(.hut, at: $0) == nil })
    try g.build(.hut, at: tile)
    g.advance(to: g.state.lastUpdated.addingTimeInterval(60))
    #expect(g.state.completedGoals.contains(.hut))
    #expect(g.journeyChapters.flatMap(\.objectives).contains { $0.id == "building-hut" && $0.isComplete })
    #expect(!g.journeyChapters[0].isComplete)
    let laterTile = try #require((0..<24).flatMap { y in (0..<32).map { Tile(x: $0, y: y) } }.first { g.placementIssue(.stoneGatherer, at: $0) == nil })
    try g.build(.stoneGatherer, at: laterTile)
    g.advance(to: g.state.lastUpdated.addingTimeInterval(60))
    #expect(!g.journeyChapters[0].isComplete)
    #expect(g.journeyChapters[1].objectives.first { $0.id == "building-stoneGatherer" }?.isComplete == true)
    let state = g.state
    let data = try JSONEncoder().encode(state)
    var restored = try GameEngine(state: JSONDecoder().decode(GameState.self, from: data), configuration: g.configuration)
    restored.advance(to: state.lastUpdated.addingTimeInterval(60))
    #expect(restored.state.resources.wood == state.resources.wood)
    #expect(restored.state.completedGoals == state.completedGoals)
    #expect(restored.journeyChapters.count == 7)
}

@Test func newReadinessRequiresMoreThanFivePillarsAndOldReadinessSurvives() throws {
    var c = try GameConfiguration.bundled()
    for i in c.progressionGoals!.indices {
        c.progressionGoals![i].requiredBuildings = [.campfire]
        c.progressionGoals![i].requiredTechnologies = []
        c.progressionGoals![i].minimumPopulation = 0
        c.progressionGoals![i].minimumResources = .init()
        c.progressionGoals![i].minimumNetRates = .init()
        c.progressionGoals![i].minimumDiscoveredTiles = 0
    }
    let epoch = Date(timeIntervalSince1970: 20_000)
    var current = try GameEngine(configuration: c, now: epoch)
    current.advance(to: epoch.addingTimeInterval(1))
    #expect(current.state.completedPillarGoals?.count == 5)
    #expect(current.state.stoneAgeCompleted == false)
    c.requiresCompleteStoneAgeCatalog = false
    var historical = try GameEngine(configuration: c, now: epoch)
    historical.advance(to: epoch.addingTimeInterval(1))
    #expect(historical.state.stoneAgeCompleted == true)
    c.requiresCompleteStoneAgeCatalog = true
    var migrated = try GameEngine(state: historical.state, configuration: c)
    migrated.advance(to: epoch.addingTimeInterval(2))
    #expect(migrated.state.stoneAgeCompleted == true)
    #expect(!migrated.fullStoneAgeRequirementsMet)
    #expect(migrated.state.completedGoals == historical.state.completedGoals)
}

@Test func discoveryExcludesFutureDepositsAndCatalogTotalsAdapt() throws {
    var c = try GameConfiguration.bundled()
    c.technologies!.removeAll { $0.id == "foodPreservation" }
    let g = try GameEngine(configuration: c, now: Date())
    #expect(g.stoneAgeRequirements.first { $0.id == "research" }?.total == c.technologyDefinitions.count)
    #expect(g.requiredDiscoveryResources.count == 6)
    #expect(!(g.missingDiscoveryResourceNames.contains("copper")))
    #expect(g.journeyChapters.flatMap(\.objectives).filter { $0.id.hasPrefix("technology-") }.count == c.technologyDefinitions.count)
}

#if DEBUG
import GameApplication
@Test @MainActor func developerScenarioSelectionAndOriginalStateSurviveResume() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("normal.json")
    defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
    let now = Date(timeIntervalSince1970: 500_000)
    let session = try GameSession(clock: { now }, saveURL: url)
    #expect(!session.isSelectedDeveloperScenario(.early))
    session.loadDeveloperScenario(.developed)
    #expect(session.isSelectedDeveloperScenario(.developed))
    #expect(!session.isSelectedDeveloperScenario(.early))
    #expect(session.developerStateDescription == "Original scenario")
    session.advanceDeveloperTime(seconds: 60)
    #expect(session.developerStateDescription == "Modified developer state")
    session.save()
    let resumed = try GameSession(clock: { now }, saveURL: url)
    resumed.resumeDeveloperSettlement()
    #expect(resumed.isSelectedDeveloperScenario(.developed))
    #expect(resumed.developerStateDescription == "Modified developer state")
    resumed.returnToNormalGame()
    #expect(!resumed.isSelectedDeveloperScenario(.developed))
}

@Test func incompleteCatalogAndResourceDiscoveryAreIndividuallyRejected() throws {
    let c = try GameConfiguration.bundled()
    var g = try DeveloperScenario.late.makeEngine(configuration: c, now: Date(timeIntervalSince1970: 1000))
    #expect(g.stoneAgeRequirements.first { $0.id == "research" }?.isComplete == false)
    try g.developerUnlockTechnology("fortification")
    #expect(g.stoneAgeRequirements.first { $0.id == "research" }?.isComplete == true)
    #expect(g.stoneAgeRequirements.first { $0.id == "buildings" }?.isComplete == false)
    let tile = try #require((0..<24).flatMap { y in (0..<32).map { Tile(x: $0, y: y) } }.first { g.placementIssue(.palisade, at: $0) == nil })
    try g.build(.palisade, at: tile)
    #expect(g.state.stoneAgeCompleted == false) // A construction site is insufficient.
    g.advance(to: g.state.lastUpdated.addingTimeInterval(60))
    #expect(g.fullStoneAgeRequirementsMet)
    var state = g.state
    // Leave pillar history intact, but hide the only revealed wood source outside the full radius.
    state.discoveredTiles?.remove(c.naturalDeposits!.first { $0.resource == .wood }!.origin)
    state.explorationRadius = 11
    // Validate discovery predicate independently; a preserved historical readiness remains sticky.
    let reduced = try GameEngine(state: state, configuration: c)
    #expect(reduced.stoneAgeRequirements.first { $0.id == "discovery" }?.isComplete == false)
    #expect(!reduced.fullStoneAgeRequirementsMet)
    #expect(reduced.state.stoneAgeCompleted == true)
    state.stoneAgeCompleted = false
    var undiscovered = try GameEngine(state: state, configuration: c)
    undiscovered.advance(to: state.lastUpdated.addingTimeInterval(1))
    #expect(undiscovered.state.stoneAgeCompleted == false)
    var missingTechnology = g.state
    missingTechnology.stoneAgeCompleted = false
    missingTechnology.researchedTechnologies?.remove("foodPreservation")
    let removedStorage = c.technologyDefinitions.first { $0.id == "foodPreservation" }!.effects.storageBonus
    for resource in Resource.allCases {
        missingTechnology.resources[resource] = min(missingTechnology.resources[resource], g.capacities[resource] - removedStorage[resource])
    }
    var unresearched = try GameEngine(state: missingTechnology, configuration: c)
    unresearched.advance(to: missingTechnology.lastUpdated.addingTimeInterval(1))
    #expect(unresearched.state.stoneAgeCompleted == false)
    var missingBuilding = g.state
    missingBuilding.stoneAgeCompleted = false
    missingBuilding.buildings.removeAll { $0.kind == .animalPen }
    var unbuilt = try GameEngine(state: missingBuilding, configuration: c)
    unbuilt.advance(to: missingBuilding.lastUpdated.addingTimeInterval(1))
    #expect(unbuilt.state.stoneAgeCompleted == false)
}
#endif
