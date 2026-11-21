#if DEBUG
import Foundation
import GameCore
import GamePersistence

/// Isolated UI2 founding/menu review. Uses the ordinary engine and topology.
public struct RiverbendFoundingReview {
    public private(set) var engine: GameEngine
    public private(set) var foothillEnclosed = false
    public private(set) var foothillGateOpen = true
    public init(now: Date, foothill: Bool = false) throws { engine = try GameEngine(configuration: foothill ? .riverbendFoothillReview() : .riverbendFoundingReview(), now: now) }
    public init(state: GameState, enclosed: Bool = false, gateOpen: Bool = true) throws {
        let foothill = state.mapID == GameConfiguration.riverbendFoothillID
        engine = try GameEngine(state: state, configuration: foothill ? .riverbendFoothillReview() : .riverbendFoundingReview())
        guard foothill || (!enclosed && gateOpen) else { throw GameError.invalidSave("Unexpected enclosure identity") }
        foothillEnclosed = enclosed; foothillGateOpen = gateOpen
        if foothill {
            guard enclosed || gateOpen else { throw GameError.invalidSave("An unpurchased Foothill gate cannot be closed") }
            if enclosed {
                let occupied = Set(state.buildings.flatMap { $0.tiles(in: engine.configuration) })
                let roads = Set((state.roads ?? []).map(\.tile))
                guard engine.civicLevel == 2, engine.usesConnectedPaths,
                      FoothillBoundary.gateRoad.isSubset(of: roads),
                      occupied.isDisjoint(with: FoothillBoundary.reserved),
                      roads.isDisjoint(with: FoothillBoundary.wall.subtracting([FoothillBoundary.gate])) else { throw GameError.invalidSave("Foothill enclosure or gate connection is inconsistent") }
            }
        }
        guard (engine.civicLevel == 1 && state.operatingRules == nil) ||
              (engine.civicLevel == 2 && engine.usesConnectedPaths) else {
            throw GameError.invalidSave("Unsupported founding review stage")
        }
    }
    public var foothillBoundary: FoothillBoundary {
        FoothillBoundary(configuration: engine.configuration, buildings: engine.state.buildings, enclosed: foothillEnclosed, gateOpen: foothillGateOpen)
    }
    public mutating func purchaseFoothillEnclosure() throws {
        guard engine.configuration.isRiverbendFoothillReview, founded, !foothillEnclosed else { throw GameError.placement("Found Foothill before buying one enclosure.") }
        guard engine.state.resources.wood >= FoothillBoundary.cliffCost else { throw GameError.insufficientResources }
        guard engine.state.buildings.flatMap({ $0.tiles(in: engine.configuration) }).allSatisfy({ !FoothillBoundary.wall.contains($0) }),
              (engine.state.roads ?? []).allSatisfy({ $0.tile == FoothillBoundary.gate || !FoothillBoundary.wall.contains($0.tile) }) else { throw GameError.placement("Clear the wall line before purchase.") }
        var next = engine
        // Road from the free civic entrance through the single gate to exterior ground.
        let route = Array(FoothillBoundary.gateRoad)
        try next.editRoads(at: route, style: .trodden)
        var state = next.state; state.resources.wood -= FoothillBoundary.cliffCost
        engine = try GameEngine(state: state, configuration: next.configuration)
        foothillEnclosed = true; foothillGateOpen = true
    }
    public mutating func setFoothillGate(open: Bool) throws {
        guard engine.configuration.isRiverbendFoothillReview, foothillEnclosed else { throw GameError.placement("Purchase the Foothill enclosure first.") }
        foothillGateOpen = open
    }
    public var founded: Bool { engine.civicLevel == 2 }
    public var hut: PlacedBuilding? { engine.state.buildings.first { $0.kind == .hut } }
    public var objective: String {
        if !founded { return "Upgrade Campfire to Founder’s Lodge" }
        guard let hut else { return "Build your first hut" }
        if !hut.isOperational { return "Complete your hut" }
        return engine.isServiceOperational(hut) ? "Founding connected" : "Connect your hut to the Lodge"
    }
    /// Clear, existing grass/clearing near the founding center; terrain is never rewritten.
    public var hutSites: [Tile] {
        let center = engine.configuration.map.campfire
        let candidates = engine.configuration.tiles(within: 5).filter { tile in
            let distance = abs(tile.x - center.x) + abs(tile.y - center.y)
            return (3...5).contains(distance) && hutIssue(at: tile) == nil &&
                !route(to: tile).isEmpty
        }.sorted {
            // Lateral separation keeps the existing tall hut art off the doorway.
            let a = abs(($0.x - $0.y) - (center.x - center.y))
            let b = abs(($1.x - $1.y) - (center.x - center.y))
            if a != b { return a > b }
            return $0.y == $1.y ? $0.x < $1.x : $0.y > $1.y
        }
        guard let first = candidates.first else { return [] }
        let alternate = candidates.dropFirst().filter {
            abs(($0.x - $0.y) - (center.x - center.y)) >= 4
        }.max {
            abs($0.x - first.x) + abs($0.y - first.y) < abs($1.x - first.x) + abs($1.y - first.y)
        }
        guard let alternate else { return candidates }
        return [first, alternate] + candidates.filter { $0 != first && $0 != alternate }
    }
    public var entrance: Tile {
        // All cardinal civic edges remain valid. Prefer the visible south-east edge.
        RoadGeometry.neighbors(of: engine.configuration.map.campfire).map(\.tile)
            .sorted { $0.x > $1.x }
            .first { engine.roadIssue(at: $0) == nil } ?? engine.configuration.map.campfire
    }
    public func route(to tile: Tile) -> [Tile] {
        let c = engine.configuration
        let footprint = c.definition(.hut).footprint.tiles(at: tile)
        if c.isRiverbendFoothillReview && !footprint.allSatisfy(FoothillBoundary.interior.contains) { return [] }
        let edges = Set(footprint.flatMap { RoadGeometry.neighbors(of: $0).map(\.tile) }).subtracting(footprint)
        // Existing bounded staircase geometry; reject blocked strokes, never redefine terrain.
        return edges.sorted { $0.y == $1.y ? $0.x < $1.x : $0.y < $1.y }.compactMap { edge -> [Tile]? in
            let path = RoadGeometry.path(from: entrance, to: edge, width: c.map.width, height: c.map.height)
            return !path.isEmpty && path.allSatisfy { !footprint.contains($0) && engine.roadIssue(at: $0) == nil && (!foothillEnclosed || !FoothillBoundary.wall.contains($0) || $0 == FoothillBoundary.gate) } ? path : nil
        }.min { $0.count < $1.count } ?? []
    }
    public mutating func found() throws {
        guard !founded else { throw GameError.placement("The Lodge is already founded.") }
        var next = engine
        try next.upgrade(buildingID: next.civicCenter!.id)
        var state = next.state; state.operatingRules = .connectedPathsV1
        next = try GameEngine(state: state, configuration: next.configuration)
        try next.editRoads(at: [entrance], style: .trodden)
        engine = next
    }
    public func hutIssue(at tile: Tile) -> GameError? {
        if let issue = engine.placementIssue(.hut, at: tile) { return issue }
        if engine.configuration.isRiverbendFoothillReview && engine.configuration.definition(.hut).footprint.tiles(at: tile).contains(where: { FoothillBoundary.reserved.contains($0) }) { return .placement("Keep the marked wall, gate road and traversal landing clear.") }
        let center = engine.configuration.map.campfire
        let footprint = engine.configuration.definition(.hut).footprint.tiles(at: tile)
        guard footprint.allSatisfy({ abs($0.x - center.x) + abs($0.y - center.y) >= 3 }) else {
            return .placement("Keep the entire hut outside the Lodge’s clear yard.")
        }
        guard !route(to: tile).isEmpty else { return .placement("This opening hut needs a clear route to the Lodge. Choose a marked plot; terrain across the river is unchanged.") }
        return nil
    }
    public mutating func buildHut(at tile: Tile) throws {
        guard founded, hut == nil else { throw GameError.placement("Found the Lodge, then build one hut.") }
        if let issue = hutIssue(at: tile) { throw issue }
        try engine.build(.hut, at: tile)
    }
    public mutating func drawPath(to tile: Tile) throws {
        guard founded else { throw GameError.placement("Found the Lodge before routing buildings.") }
        let path = route(to: tile)
        guard !path.isEmpty else { throw GameError.placement("Choose a clear cardinal route to a hut edge.") }
        try editPath(path)
    }
    public mutating func editPath(_ tiles: [Tile], erase: Bool = false) throws {
        guard founded else { throw GameError.placement("Found the Lodge before drawing paths.") }
        if erase && foothillEnclosed && !FoothillBoundary.gateRoad.isDisjoint(with: tiles) { throw GameError.placement("Keep the purchased gate connected. Disconnect only the hut’s branch.") }
        if !erase && foothillEnclosed && tiles.contains(where: { FoothillBoundary.wall.contains($0) && $0 != FoothillBoundary.gate }) { throw GameError.placement("Solid palisade blocks this road; use the gate.") }
        try engine.editRoads(at: tiles, style: erase ? nil : .trodden)
    }
    public mutating func disconnect() throws {
        guard founded else { throw GameError.placement("Found the Lodge first.") }
        try engine.editRoads(at: (engine.state.roads ?? []).map(\.tile).filter { !foothillEnclosed || !FoothillBoundary.gateRoad.contains($0) }, style: nil)
    }
    public mutating func advance(seconds: Double) throws {
        guard seconds.isFinite && (0...60).contains(seconds) else { throw GameError.placement("Review step must be zero to 60 seconds.") }
        engine.advance(to: engine.state.lastUpdated.addingTimeInterval(seconds))
    }
}

/// Dedicated identity and atomic candidate publication; reopen never grants offline time.
public struct RiverbendFoundingStore {
    public let url: URL
    public private(set) var review: RiverbendFoundingReview
    private var expectedBytes: Data
    private static func coordinated<T>(_ url: URL, _ body: () throws -> T) throws -> T {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var error: NSError?
        var result: Result<T, any Error>?
        coordinator.coordinate(writingItemAt: url, options: .forReplacing, error: &error) { _ in
            result = Result { try body() }
        }
        if let error { throw error }
        guard let result else { throw GameError.invalidSave("Could not coordinate founding save.") }
        return try result.get()
    }
    public init(directory: URL, now: Date, foothill: Bool = false) throws {
        let destination = directory.appendingPathComponent(foothill ? "ui2-foothill-v1.json" : "ui2-founding-v1.json")
        let loaded = try Self.coordinated(destination) {
            let store = SaveStore(url: destination)
            let review: RiverbendFoundingReview
            if foothill, FileManager.default.fileExists(atPath: destination.path) {
                let envelope = try JSONDecoder().decode(FoothillEnvelope.self, from: Data(contentsOf: destination))
                guard envelope.version == 1, envelope.state.mapID == GameConfiguration.riverbendFoothillID else { throw GameError.invalidSave("Unsupported Foothill envelope") }
                review = try RiverbendFoundingReview(state: envelope.state, enclosed: envelope.enclosed, gateOpen: envelope.gateOpen)
            } else if !foothill, let state = try store.load(configuration: .riverbendFoundingReview()) {
                review = try RiverbendFoundingReview(state: state)
            } else {
                review = try RiverbendFoundingReview(now: now, foothill: foothill)
                if foothill { try Self.saveFoothill(review, to: destination) }
                else { try store.save(review.engine.state) }
            }
            return (review, try Data(contentsOf: destination))
        }
        url = destination; review = loaded.0; expectedBytes = loaded.1
    }
    private struct FoothillEnvelope: Codable {
        var version: Int = 1
        var state: GameState
        var enclosed: Bool
        var gateOpen: Bool
    }
    private static func saveFoothill(_ review: RiverbendFoundingReview, to url: URL) throws {
        let data = try JSONEncoder().encode(FoothillEnvelope(state: review.engine.state, enclosed: review.foothillEnclosed, gateOpen: review.foothillGateOpen))
        try data.write(to: url, options: .atomic)
    }
    public mutating func perform(_ command: (inout RiverbendFoundingReview) throws -> Void) throws {
        var candidate = review
        try command(&candidate)
        guard candidate.engine.state.mapID == review.engine.state.mapID else { throw GameError.invalidSave("A review transaction cannot change this save slot’s map identity") }
        let checked = try RiverbendFoundingReview(state: candidate.engine.state, enclosed: candidate.foothillEnclosed, gateOpen: candidate.foothillGateOpen)
        let bytes = try Self.coordinated(url) {
            guard try Data(contentsOf: url) == expectedBytes else {
                throw GameError.invalidSave("This review changed in another window. Close and reopen it before continuing; saved progress is preserved.")
            }
            if checked.engine.configuration.isRiverbendFoothillReview { try Self.saveFoothill(checked, to: url) }
            else { try SaveStore(url: url).save(checked.engine.state) }
            return try Data(contentsOf: url)
        }
        review = checked; expectedBytes = bytes
    }
}
public enum FoundingCatalogAction: Equatable { case build, materials, research(String) }
public struct FoundingMaterialNeed {
    public let resource: Resource
    public let amount: Double
    public let suppliers: [BuildingKind]
}
public extension RiverbendFoundingReview {
    func catalogPlacementIssue(_ kind: BuildingKind, at tile: Tile) -> GameError? {
        if kind == .hut { return hutIssue(at: tile) }
        if let issue = engine.placementIssue(kind, at: tile) { return issue }
        if engine.configuration.isRiverbendFoothillReview && engine.configuration.definition(kind).footprint.tiles(at: tile).contains(where: { FoothillBoundary.reserved.contains($0) }) { return .placement("Keep the marked wall, gate road and traversal landing clear.") }
        let center = engine.configuration.map.campfire
        guard engine.configuration.definition(kind).footprint.tiles(at: tile).allSatisfy({ abs($0.x - center.x) + abs($0.y - center.y) >= 3 }) else {
            return .placement("Keep the entire building outside the Lodge’s clear yard.")
        }
        return nil
    }
    func researchSupplier(_ id: String) -> BuildingKind? {
        guard let tech = engine.configuration.technologyDefinitions.first(where: { $0.id == id }) else { return nil }
        return engine.bootstrapRequirement(for: tech.cost)
    }
    func catalogAction(_ kind: BuildingKind) -> FoundingCatalogAction {
        let definition = engine.configuration.definition(kind)
        if !engine.isUnlocked(kind), let technology = engine.configuration.technologyDefinitions.first(where: { $0.effects.unlockedBuildings.contains(kind) }) {
            return .research(nextRequiredTechnology(technology.id))
        }
        return !engine.canAfford(definition.cost) || engine.bootstrapRequirement(for: definition.cost, constructing: kind) != nil ? .materials : .build
    }
    func nextRequiredTechnology(_ id: String) -> String {
        guard let technology = engine.configuration.technologyDefinitions.first(where: { $0.id == id }) else { return id }
        if let prerequisite = technology.prerequisites.first(where: { !engine.researchedIDs.contains($0) }) {
            return nextRequiredTechnology(prerequisite)
        }
        return id
    }
    func materialNeeds(for cost: ResourceAmounts) -> [FoundingMaterialNeed] {
        Resource.allCases.compactMap { resource in
            let missing = cost[resource] - engine.state.resources[resource]
            guard missing > 0 else { return nil }
            let suppliers = engine.configuration.buildings.filter { definition in
                (definition.recipes ?? []).contains { $0.outputsPerMinute[resource] > 0 } || definition.ratesPerMinute[resource] > 0
            }.map(\.kind)
            return FoundingMaterialNeed(resource: resource, amount: missing, suppliers: suppliers)
        }
    }
    mutating func research(_ id: String) throws { try engine.research(id) }
    mutating func build(_ kind: BuildingKind, at tile: Tile) throws {
        if kind == .hut { try buildHut(at: tile) }
        else {
            guard founded else { throw GameError.placement("Found the Lodge first.") }
            if let issue = catalogPlacementIssue(kind, at: tile) { throw issue }
            try engine.build(kind, at: tile)
        }
    }
}
#endif
