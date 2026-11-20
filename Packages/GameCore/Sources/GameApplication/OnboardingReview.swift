import GameCore

/// Gate A presentation data. Never persisted or installed into a running session.
public struct OnboardingForestRegion: Equatable, Sendable {
    public let forestTiles: Set<Tile>
    public let tiles: Set<Tile>
    public let woodcutterOrigins: [Tile]
}

public struct OnboardingReviewSnapshot: Equatable, Sendable {
    public let sourceDiscoveredTiles: Set<Tile>?
    public let initialDiscoveredTiles: Set<Tile>
    public let region: OnboardingForestRegion
    public var revealedDiscoveredTiles: Set<Tile> { initialDiscoveredTiles.union(region.tiles) }

    /// Builds an independent discovery proposal from real terrain and transaction checks.
    /// The six legacy known-resource routes are omitted only from this review snapshot.
    public static func make(configuration: GameConfiguration, state: GameState, includeWholeForest: Bool = false) throws -> Self? {
        let engine = try GameEngine(state: state, configuration: configuration)
        guard let rules = configuration.explorationRules else { return nil }
        let map = configuration.map
        let initial = configuration.tiles(within: rules.initialRadius)
        let reach = rules.initialRadius + rules.revealRadiusStep
        let footprint = configuration.definition(.woodcutter).footprint
        let occupied = Set(state.buildings.flatMap { $0.tiles(in: configuration) })
        let roads = Set((state.roads ?? []).map(\.tile))
        func open(_ tile: Tile) -> Bool {
            guard let terrain = map.terrain(at: tile), terrain == .grass || terrain == .clearing else { return false }
            return !occupied.contains(tile) && !roads.contains(tile)
        }
        func walkable(_ tile: Tile) -> Bool {
            guard let terrain = map.terrain(at: tile), terrain == .grass || terrain == .clearing else { return false }
            return !occupied.contains(tile)
        }
        func neighbors(_ tile: Tile) -> [Tile] { RoadGeometry.neighbors(of: tile).map(\.tile) }
        func distance(_ tile: Tile) -> Int {
            let dx = tile.x - map.campfire.x, dy = tile.y - map.campfire.y
            return dx * dx + dy * dy
        }
        func nearer(_ a: Tile, _ b: Tile) -> Bool {
            if distance(a) != distance(b) { return distance(a) < distance(b) }
            return a.y == b.y ? a.x < b.x : a.y < b.y
        }
        // Reachability is tested on terrain, not by revealing a skinny route through fog.
        let civic = state.buildings.first { $0.kind == .campfire }?.origin ?? map.campfire
        var reachable: Set<Tile> = [civic], frontier = [civic], index = 0
        while index < frontier.count {
            for tile in neighbors(frontier[index]) where walkable(tile) && reachable.insert(tile).inserted { frontier.append(tile) }
            index += 1
        }
        let seeds = (0..<map.height).flatMap { y in (0..<map.width).compactMap { x -> Tile? in
            let tile = Tile(x: x, y: y)
            return map.terrain(at: tile) == .forest &&
                max(abs(x - map.campfire.x), abs(y - map.campfire.y)) <= reach + 1 ? tile : nil
        } }.sorted(by: nearer)
        var considered: Set<Tile> = []
        for seed in seeds where !considered.contains(seed) {
            // Default local lobe versus explicit whole-component review alternative.
            // Both follow actual cardinal forest connectivity; neither moves terrain.
            // Whole western forest reveals the existing wood source but exposes232cells.
            var forest: Set<Tile> = [seed], queue = [seed], cursor = 0
            while cursor < queue.count {
                for tile in neighbors(queue[cursor]) {
                    let dx = tile.x - seed.x, dy = tile.y - seed.y
                    if (includeWholeForest || dx * dx + dy * dy <= 25), map.terrain(at: tile) == .forest,
                       forest.insert(tile).inserted { queue.append(tile) }
                }
                cursor += 1
            }
            considered.formUnion(forest)
            var candidates: [Tile] = []
            var proposal = forest
            for y in 0..<map.height { for x in 0..<map.width {
                let origin = Tile(x: x, y: y)
                guard max(abs(x - map.campfire.x), abs(y - map.campfire.y)) <= reach else { continue }
                let cells = footprint.tiles(at: origin)
                guard cells.allSatisfy(open), cells.allSatisfy(reachable.contains),
                      cells.contains(where: { neighbors($0).contains(where: forest.contains) }) else { continue }
                candidates.append(origin)
                proposal.formUnion(cells)
            } }
            guard !candidates.isEmpty else { continue }
            var previewState = engine.state
            // Engine validation still sees every original discovered tile. The preview
            // renderer receives a separate set and cannot erase original knowledge.
            previewState.discoveredTiles = (state.discoveredTiles ?? initial).union(initial).union(proposal)
            let preview = try GameEngine(state: previewState, configuration: configuration)
            let valid = candidates.filter { preview.placementIssue(.woodcutter, at: $0) == nil }.sorted(by: nearer)
            guard !valid.isEmpty else { continue }
            let validTiles = forest.union(valid.flatMap { footprint.tiles(at: $0) })
            return Self(sourceDiscoveredTiles: state.discoveredTiles, initialDiscoveredTiles: initial,
                        region: OnboardingForestRegion(forestTiles: forest, tiles: validTiles, woodcutterOrigins: valid))
        }
        return nil
    }
}

public enum OnboardingReviewEvent: Hashable, Sendable {
    case campfireEstablished, hutCompleted, expeditionStarted, forestRevealed, woodcutterCompleted, woodcutterConnected
}

public enum OnboardingReviewStep: String, CaseIterable, Sendable {
    case campfire, hut, expedition, forest, woodcutter, connection, handoff
}

/// Reopen/skip and event deduplication are view state, not a save-schema extension.
public struct OnboardingReviewGuide: Equatable, Sendable {
    public let requiresConnection: Bool
    public private(set) var observedEvents: Set<OnboardingReviewEvent> = []
    public private(set) var isSkipped = false

    public init(requiresConnection: Bool) { self.requiresConnection = requiresConnection }

    public init(engine: GameEngine, region: OnboardingForestRegion) {
        self.init(requiresConnection: engine.usesConnectedPaths)
        let complete = engine.state.buildings.filter(\.isOperational)
        if complete.contains(where: { $0.kind == .campfire }) { observe(.campfireEstablished) }
        if complete.contains(where: { $0.kind == .hut }) { observe(.hutCompleted) }
        if engine.state.explorationRemainingSeconds != nil ||
            (engine.state.explorationRadius ?? 0) > (engine.configuration.explorationRules?.initialRadius ?? 0) { observe(.expeditionStarted) }
        if !region.forestTiles.isEmpty && region.forestTiles.allSatisfy(engine.isDiscovered) { observe(.forestRevealed) }
        if complete.contains(where: { $0.kind == .woodcutter }) { observe(.woodcutterCompleted) }
        if complete.contains(where: { $0.kind == .woodcutter && engine.isConnectedToCivicCenter($0) }) { observe(.woodcutterConnected) }
    }

    public mutating func observe(_ event: OnboardingReviewEvent) { observedEvents.insert(event) }
    public mutating func skip() { isSkipped = true }
    public mutating func reopen() { isSkipped = false }
    public var nextStep: OnboardingReviewStep {
        if !observedEvents.contains(.campfireEstablished) { return .campfire }
        if !observedEvents.contains(.hutCompleted) { return .hut }
        if !observedEvents.contains(.expeditionStarted) { return .expedition }
        if !observedEvents.contains(.forestRevealed) { return .forest }
        if !observedEvents.contains(.woodcutterCompleted) { return .woodcutter }
        if requiresConnection && !observedEvents.contains(.woodcutterConnected) { return .connection }
        return .handoff
    }
}
