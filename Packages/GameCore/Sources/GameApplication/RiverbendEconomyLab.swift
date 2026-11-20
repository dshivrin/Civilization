#if DEBUG
import Foundation
import GameCore

/// The paid survey adapter is confined to this versioned review profile.
/// It reuses real terrain, placement and whole-component forest selection.
public struct RiverbendEconomyLab {
    public private(set) var engine: GameEngine
    public let region: OnboardingForestRegion
    public private(set) var surveyRemaining: Double?
    public private(set) var surveyComplete = false
    private struct Envelope: Codable {
        var profile: String
        var version: Int
        var state: GameState
        var surveyRemaining: Double?
        var surveyComplete: Bool
    }
    public init(now: Date) throws {
        let c = try GameConfiguration.riverbendEconomyLab()
        let fresh = try GameEngine(configuration: c, now: now)
        guard let proposal = try OnboardingReviewSnapshot.make(configuration: c, state: fresh.state, includeWholeForest: true),
              proposal.region.woodcutterOrigins.count >= 2 else { throw GameError.invalidConfiguration("Forest and fallback unavailable") }
        region = proposal.region
        var state = fresh.state
        state.discoveredTiles = proposal.initialDiscoveredTiles
        engine = try GameEngine(state: state, configuration: c)
    }
    public init(data: Data) throws {
        let saved = try JSONDecoder().decode(Envelope.self, from: data)
        guard saved.profile == GameConfiguration.riverbendLabID, saved.version == 1 else { throw GameError.invalidSave("Not an Economy Lab v1 save") }
        try self.init(now: saved.state.lastUpdated)
        let c = engine.configuration
        let candidate = try GameEngine(state: saved.state, configuration: c)
        let hut = candidate.state.buildings.contains { $0.kind == .hut && $0.isOperational }
        let allowed: Set<BuildingKind> = [.campfire, .hut, .gatheringShelter, .woodcutter]
        guard candidate.state.mapID == c.map.id, candidate.state.operatingRules == nil,
              candidate.state.population <= 6,
              candidate.state.buildings.allSatisfy({ allowed.contains($0.kind) }),
              allowed.allSatisfy({ k in candidate.state.buildings.filter { $0.kind == k }.count <= 1 }),
              candidate.state.explorationRemainingSeconds == nil,
              candidate.state.explorationRadius == c.explorationRules?.initialRadius,
              candidate.state.researchedTechnologies?.isEmpty == true,
              Resource.allCases.allSatisfy({ [.food, .wood, .knowledge].contains($0) || candidate.state.resources[$0] == 0 }),
              candidate.state.resources.knowledge == (saved.surveyComplete ? 6 : 0),
              (!saved.surveyComplete || (hut && saved.surveyRemaining == nil)),
              (saved.surveyRemaining == nil || (hut && !saved.surveyComplete && saved.surveyRemaining!.isFinite && saved.surveyRemaining! > 0 && saved.surveyRemaining! <= 60)),
              !candidate.state.buildings.contains(where: { $0.kind == .woodcutter }) || saved.surveyComplete else {
            throw GameError.invalidSave("Inconsistent Economy Lab progress")
        }
        let expected = c.tiles(within: c.explorationRules!.initialRadius).union(saved.surveyComplete ? region.tiles : [])
        guard candidate.state.discoveredTiles == expected else { throw GameError.invalidSave("Unexpected survey territory") }
        engine = candidate; surveyRemaining = saved.surveyRemaining; surveyComplete = saved.surveyComplete
    }
    public func encoded() throws -> Data {
        try JSONEncoder().encode(Envelope(profile: GameConfiguration.riverbendLabID, version: 1, state: engine.state,
            surveyRemaining: surveyRemaining, surveyComplete: surveyComplete))
    }
    public var hutComplete: Bool { engine.state.buildings.contains { $0.kind == .hut && $0.isOperational } }
    public var checkpointReached: Bool {
        surveyComplete && engine.state.buildings.contains { $0.kind == .woodcutter && $0.isOperational } && engine.rates.food > 0 && engine.rates.wood > 0
    }
    public func issue(for kind: BuildingKind, at tile: Tile) -> GameError? {
        guard [.hut, .gatheringShelter, .woodcutter].contains(kind) else { return .placement("Outside this lab") }
        guard !engine.state.buildings.contains(where: { $0.kind == kind }) else { return .placement("One of each building in this short lab") }
        if kind == .woodcutter && (!surveyComplete || !region.woodcutterOrigins.contains(tile)) { return .placement("Survey the forest and choose its reachable edge") }
        return engine.placementIssue(kind, at: tile)
    }
    public func sites(for kind: BuildingKind) -> [Tile] {
        let center = engine.configuration.map.campfire
        let candidates = kind == .woodcutter ? region.woodcutterOrigins : Array(engine.state.discoveredTiles ?? [])
        return candidates.filter { issue(for: kind, at: $0) == nil }.sorted {
            let a = abs($0.x-center.x) + abs($0.y-center.y), b = abs($1.x-center.x) + abs($1.y-center.y)
            return a == b ? ($0.y == $1.y ? $0.x < $1.x : $0.y < $1.y) : a < b
        }
    }
    public mutating func build(_ kind: BuildingKind, at tile: Tile) throws {
        if let issue = issue(for: kind, at: tile) { throw issue }
        try engine.build(kind, at: tile)
    }
    public mutating func startSurvey() throws {
        guard hutComplete else { throw GameError.placement("Complete your Hut first") }
        guard surveyRemaining == nil && !surveyComplete else { throw GameError.placement("This forest survey is already paid") }
        guard engine.state.resources.food >= 8 else { throw GameError.insufficientResources }
        var state = engine.state; state.resources.food -= 8
        let candidate = try GameEngine(state: state, configuration: engine.configuration)
        engine = candidate; surveyRemaining = 60
    }
    public mutating func recover(_ resource: Resource) throws {
        guard resource == .food || resource == .wood else { throw GameError.placement("Recover Food or Wood only") }
        var state = engine.state
        let floor: Double = resource == .food ? 12 : state.buildings.contains(where: { $0.kind == .hut }) ? 8 : 12
        state.resources[resource] = max(state.resources[resource], floor)
        engine = try GameEngine(state: state, configuration: engine.configuration)
    }
    public mutating func advance(by seconds: Double) throws {
        guard seconds.isFinite, (0...3600).contains(seconds) else { throw GameError.placement("Advance between 0 and 3600 seconds") }
        var candidate = self
        candidate.engine.advance(to: engine.state.lastUpdated.addingTimeInterval(seconds))
        if let remaining = surveyRemaining {
            candidate.surveyRemaining = max(0, remaining - seconds)
            if candidate.surveyRemaining == 0 {
                var state = candidate.engine.state
                state.discoveredTiles?.formUnion(region.tiles)
                state.resources.knowledge = 6
                candidate.engine = try GameEngine(state: state, configuration: engine.configuration)
                candidate.surveyRemaining = nil; candidate.surveyComplete = true
            }
        }
        self = candidate
    }
}

/// Separate from GameLibrary/SaveStore and every Normal, Developer and Round2 mode.
/// All commands write a validated candidate before publishing it to the screen.
public struct RiverbendEconomyLabStore {
    public private(set) var lab: RiverbendEconomyLab
    public let url: URL
    public init(directory: URL, now: Date) throws {
        url = directory.appendingPathComponent(GameConfiguration.riverbendLabID).appendingPathComponent("lab.json")
        if FileManager.default.fileExists(atPath: url.path) {
            lab = try RiverbendEconomyLab(data: Data(contentsOf: url))
        } else {
            lab = try RiverbendEconomyLab(now: now)
            try Self.write(lab, to: url)
        }
    }
    public mutating func perform(_ command: (inout RiverbendEconomyLab) throws -> Void) throws {
        var candidate = lab
        try command(&candidate)
        try Self.write(candidate, to: url)
        lab = candidate
    }
    private static func write(_ lab: RiverbendEconomyLab, to url: URL) throws {
        let data = try lab.encoded()
        _ = try RiverbendEconomyLab(data: data)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }
}
#endif
