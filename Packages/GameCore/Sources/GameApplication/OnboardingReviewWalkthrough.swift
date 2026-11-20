#if DEBUG
import Foundation
import GameCore

/// Disposable, in-memory Gate A rehearsal. This type has no persistence dependencies.
/// Current production transactions run on a fresh engine; only the area reveal is a
/// proposed discovery union applied to this copy, never to a player session.
public struct OnboardingReviewWalkthrough {
    public private(set) var engine: GameEngine
    public let snapshot: OnboardingReviewSnapshot
    private var skipped = false
    public var guide: OnboardingReviewGuide {
        var value = OnboardingReviewGuide(engine: engine, region: snapshot.region)
        if skipped { value.skip() }
        return value
    }
    public init(configuration: GameConfiguration, now: Date) throws {
        let source = try GameEngine(configuration: configuration, now: now)
        guard let snapshot = try OnboardingReviewSnapshot.make(configuration: configuration,
            state: source.state, includeWholeForest: true) else {
            throw GameError.invalidConfiguration("No usable forest area is available for the onboarding review.")
        }
        self.snapshot = snapshot
        var state = source.state
        state.discoveredTiles = snapshot.initialDiscoveredTiles
        engine = try GameEngine(state: state, configuration: configuration)
    }
    public func suggestedOrigin(for kind: BuildingKind) -> Tile? {
        if kind == .woodcutter {
            return snapshot.region.woodcutterOrigins.first { engine.placementIssue(kind, at: $0) == nil }
        }
        let center = engine.configuration.map.campfire
        return (engine.state.discoveredTiles ?? []).sorted {
            let a = abs($0.x - center.x) + abs($0.y - center.y)
            let b = abs($1.x - center.x) + abs($1.y - center.y)
            if a != b { return a < b }
            return $0.y == $1.y ? $0.x < $1.x : $0.y < $1.y
        }.first { engine.placementIssue(kind, at: $0) == nil }
    }
    public mutating func build(_ kind: BuildingKind, at tile: Tile) throws {
        guard kind == .hut || kind == .woodcutter else { throw GameError.placement("This review guides Hut and Woodcutter placement.") }
        try engine.build(kind, at: tile)
    }
    public mutating func startExpedition() throws { try engine.startExploration() }
    public mutating func advanceReview(by seconds: Double) throws {
        guard seconds.isFinite, (0...3600).contains(seconds) else { throw GameError.placement("Review time must be between zero and 3600 seconds.") }
        var candidate = engine
        let wasExploring = candidate.state.explorationRemainingSeconds != nil
        candidate.advance(to: candidate.state.lastUpdated.addingTimeInterval(seconds))
        if wasExploring && candidate.state.explorationRemainingSeconds == nil {
            var state = candidate.state
            // Current expedition cost/duration/completion ran above. This additive
            // whole-area result is the explicitly labeled Gate A proposal only.
            state.discoveredTiles = (state.discoveredTiles ?? []).union(snapshot.region.tiles)
            candidate = try GameEngine(state: state, configuration: candidate.configuration)
        }
        engine = candidate
    }
    public mutating func skipGuide() { skipped = true }
    public mutating func reopenGuide() { skipped = false }
}
#endif
