import Foundation
import Testing
@testable import GameCore
import GamePersistence
import GameApplication

private let guidanceEpoch = Date(timeIntervalSince1970: 20_000_000)

@Test func guidanceStartsWithUsefulBuildAndNeverMutatesState() throws {
    let game = try GameEngine(configuration: .bundled(), now: guidanceEpoch)
    let before = game.state
    #expect(game.settlementGuidance.action == .build(.gatheringShelter))
    #expect(game.settlementGuidance.explanation.contains("Drag"))
    #expect(game.state == before)
}

@Test func guidanceFindsKnowledgeProducerBeforeLaterChapter() throws {
    var game = try GameEngine(configuration: .bundled(), now: guidanceEpoch)
    for kind: BuildingKind in [.gatheringShelter, .woodcutter, .hut] {
        let tile = try #require((0..<24).flatMap { y in (0..<32).map { Tile(x: $0, y: y) } }.first { game.placementIssue(kind, at: $0) == nil })
        try game.build(kind, at: tile)
        game.advance(to: game.state.lastUpdated.addingTimeInterval(60))
    }
    try game.research("oralTradition")
    let hint = game.guidance(for: "technology-hunting")
    #expect(hint.action == .build(.storytellingCircle))
    #expect(hint.explanation.contains("knowledge") || hint.explanation.contains("Knowledge"))
    #expect(!game.journeyChapters[4].isComplete)
}

@Test func guidanceOffersCapacityInsteadOfLongKnowledgeIdle() throws {
    var game = try GameEngine(configuration: .bundled(), now: guidanceEpoch)
    for kind: BuildingKind in [.gatheringShelter, .woodcutter, .stoneGatherer, .hut] {
        let tile = try #require((0..<24).flatMap { y in (0..<32).map { Tile(x: $0, y: y) } }.first { game.placementIssue(kind, at: $0) == nil })
        try game.build(kind, at: tile); game.advance(to: game.state.lastUpdated.addingTimeInterval(60))
    }
    try game.research("oralTradition")
    let tile = try #require((0..<24).flatMap { y in (0..<32).map { Tile(x: $0, y: y) } }.first { game.placementIssue(.storytellingCircle, at: $0) == nil })
    try game.build(.storytellingCircle, at: tile)
    game.advance(to: game.state.lastUpdated.addingTimeInterval(30))
    #expect(game.guidance(for: "technology-naturalKnowledge").action == .build(.storytellingCircle))
}

@Test(arguments: [15.0, 60.0])
func ordinaryPlayerCanFollowGuidanceThroughEntireEra(pollSeconds: Double) throws {
    var game = try GameEngine(configuration: .bundled(), now: guidanceEpoch)
    var chapterTimes: [Int: Int] = [:]
    var actions = 0, waitSeconds = 0.0, longestWait = 0.0, currentWait = 0.0
    var counts: [String: Int] = [:]
    var last: [String] = []
    for _ in 0..<5000 {
        let hint = game.settlementGuidance
        last.append(hint.title); if last.count > 12 { last.removeFirst() }
        if hint.action == .complete { break }
        if hint.waitSeconds != nil {
            let seconds = min(pollSeconds, max(1, hint.waitSeconds!))
            game.advance(to: game.state.lastUpdated.addingTimeInterval(seconds))
            waitSeconds += seconds; currentWait += seconds; longestWait = max(longestWait, currentWait)
        } else {
            currentWait = 0; actions += 1
            switch hint.action {
            case .build(let kind):
                let map = game.configuration.map
                let tile = try #require((0..<map.height).flatMap { y in (0..<map.width).map { Tile(x: $0, y: y) } }.first { game.placementIssue(kind, at: $0) == nil }, "No valid site: \(hint.title)")
                try game.build(kind, at: tile); counts["build", default: 0] += 1
            case .research(let id): try game.research(id); counts["research", default: 0] += 1
            case .recipe(let id, let recipe): try game.setProductionMode(buildingID: id, recipeID: recipe); counts["recipe", default: 0] += 1
            case .priority(let id, let priority): try game.setWorkerPriority(buildingID: id, priority: priority); counts["priority", default: 0] += 1
            case .explore: try game.startExploration(); counts["explore", default: 0] += 1
            default: Issue.record("Unactionable guidance: \(hint.title) — \(hint.explanation). Recent: \(last)"); return
            }
            // Ordinary decision cadence, not fast construction or a developer clock override.
            game.advance(to: game.state.lastUpdated.addingTimeInterval(pollSeconds))
        }
        for chapter in game.journeyChapters where chapter.isComplete && chapterTimes[chapter.id] == nil {
            chapterTimes[chapter.id] = Int(game.state.lastUpdated.timeIntervalSince(guidanceEpoch))
        }
    }
    #expect(game.state.stoneAgeCompleted == true, "Recent recommendations: \(last)")
    #expect(game.fullStoneAgeRequirementsMet)
    #expect(game.journeyChapters.allSatisfy { $0.isComplete })
    #expect(game.constructedKinds == Set(game.configuration.buildings.map(\.kind)))
    #expect(game.researchedIDs == Set(game.configuration.technologyDefinitions.map(\.id)))
    #expect(game.state.completedPillarGoals?.count == 5)
    #expect(game.discoveredTileCount < game.configuration.map.width * game.configuration.map.height)
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let store = SaveStore(url: folder.appendingPathComponent("normal.json"))
    try store.save(game.state)
    let saved = try #require(try store.load(configuration: game.configuration))
    let restored = try GameEngine(state: saved, configuration: game.configuration)
    #expect(restored.settlementGuidance.action == .complete)
    #expect(restored.state.completedGoals == game.state.completedGoals)
    print("GUIDED pace=\(pollSeconds)s total=\(Int(game.state.lastUpdated.timeIntervalSince(guidanceEpoch)))s actions=\(actions) wait=\(Int(waitSeconds))s longestCostOrConstructionWait=\(Int(longestWait))s chapters=\(chapterTimes.sorted { $0.key < $1.key }) choices=\(counts) pop=\(game.state.population) workers=\(game.workforceAvailable)/\(game.workforceRequired) netFood=\(game.rates.food) netWater=\(game.rates[.water]) knowledge=\(game.rates.knowledge) discovery=\(game.discoveredTileCount)")
}

@Test @MainActor func sessionGuidanceRefreshesAfterRealConstructionWithoutSpendingOnRead() throws {
    var now = guidanceEpoch
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let session = try GameApplication.GameSession(clock: { now }, saveURL: folder.appendingPathComponent("normal.json"))
    let original = session.state
    #expect(session.nextGuidance.action == .build(.gatheringShelter))
    #expect(session.state == original)
    session.choose(.gatheringShelter)
    let engine = try GameEngine(state: session.state, configuration: session.configuration)
    let tile = try #require((0..<24).flatMap { y in (0..<32).map { Tile(x: $0, y: y) } }.first { engine.placementIssue(.gatheringShelter, at: $0) == nil })
    session.tap(tile); session.confirm()
    #expect(session.nextGuidance.waitSeconds != nil)
    now.addTimeInterval(60); session.tick()
    #expect(session.nextGuidance.action == .build(.woodcutter))
}
