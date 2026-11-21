#if DEBUG
import Foundation
import GameCore

public enum RiverbendGatheringMode: String, Codable, Sendable { case stone, flint }
public struct RiverbendCraft: Codable, Equatable, Sendable {
    public fileprivate(set) var mode: RiverbendGatheringMode = .stone
    public fileprivate(set) var batchRemaining: Double?
    public fileprivate(set) var woodcutterImproved = false
}

public enum RiverbendStorageRole: String, Codable, CaseIterable, Sendable {
    case granary, stockyard
    public var cost: ResourceAmounts { self == .granary ? .init(wood: 14, stone: 4) : .init(wood: 18, stone: 6) }
}
public struct RiverbendStorage: Codable, Equatable, Sendable {
    public let buildingID: Int
    public let role: RiverbendStorageRole
}

public enum RiverbendMapFindID: String, Codable, CaseIterable, Sendable { case berries, tracks }
public struct RiverbendMapFind: Codable, Equatable, Sendable, Identifiable {
    public let id: RiverbendMapFindID
    public var tile: Tile?
    public var resolved: Bool
}

/// The paid survey adapter is confined to this versioned review profile.
/// It reuses real terrain, placement and whole-component forest selection.
public struct RiverbendEconomyLab {
    public private(set) var engine: GameEngine
    public let region: OnboardingForestRegion
    public private(set) var surveyRemaining: Double?
    public private(set) var surveyComplete = false
    public private(set) var mapFinds: [RiverbendMapFind] = []
    public private(set) var stoneSource: Tile?
    public private(set) var storage: [RiverbendStorage] = []
    public private(set) var craft: RiverbendCraft?
    private struct Envelope: Codable {
        var profile: String
        var version: Int
        var state: GameState
        var surveyRemaining: Double?
        var surveyComplete: Bool
        var mapFinds: [RiverbendMapFind]?
        var stoneSource: Tile?
        var storage: [RiverbendStorage]?
        var craft: RiverbendCraft?
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
        storage = saved.storage ?? []; stoneSource = saved.stoneSource; craft = saved.craft
        let storehouses = saved.state.buildings.filter { $0.kind == .storehouse }
        guard storage.count <= 2, Set(storage.map(\.role)).count == storage.count,
              Set(storage.map(\.buildingID)).count == storage.count,
              Set(storage.map(\.buildingID)) == Set(storehouses.map(\.id)),
              saved.state.buildings.allSatisfy({ $0.level == 1 }),
              stoneSource != nil || (storage.isEmpty && !saved.state.buildings.contains { $0.kind == .stoneGatherer } && saved.state.resources.stone == 0)
        else { throw GameError.invalidSave("Invalid lab storage or Stone metadata") }
        let c = try configuration(for: saved.state)
        let candidate = try GameEngine(state: saved.state, configuration: c)
        let hut = candidate.state.buildings.contains { $0.kind == .hut && $0.isOperational }
        let allowed: Set<BuildingKind> = [.campfire, .hut, .gatheringShelter, .woodcutter, .stoneGatherer, .storehouse]
        guard candidate.state.mapID == c.map.id, candidate.state.operatingRules == nil,
              candidate.state.population <= 6,
              candidate.state.buildings.allSatisfy({ allowed.contains($0.kind) }),
              allowed.allSatisfy({ k in candidate.state.buildings.filter { $0.kind == k }.count <= (k == .storehouse ? 2 : 1) }),
              candidate.state.explorationRemainingSeconds == nil,
              candidate.state.explorationRadius == c.explorationRules?.initialRadius,
              candidate.state.researchedTechnologies?.isEmpty == true,
              Resource.allCases.allSatisfy({ [.food, .wood, .stone, .knowledge].contains($0) || (craft != nil && [.flint, .stoneTools].contains($0)) || candidate.state.resources[$0] == 0 }),
              candidate.state.resources.knowledge == (saved.surveyComplete ? 6 : 0),
              (!saved.surveyComplete || (hut && saved.surveyRemaining == nil)),
              (saved.surveyRemaining == nil || (hut && !saved.surveyComplete && saved.surveyRemaining!.isFinite && saved.surveyRemaining! > 0 && saved.surveyRemaining! <= 60)),
              !candidate.state.buildings.contains(where: { $0.kind == .woodcutter }) || saved.surveyComplete else {
            throw GameError.invalidSave("Inconsistent Economy Lab progress")
        }
        let expected = c.tiles(within: c.explorationRules!.initialRadius).union(saved.surveyComplete ? region.tiles : [])
        guard candidate.state.discoveredTiles == expected else { throw GameError.invalidSave("Unexpected survey territory") }
        engine = candidate; surveyRemaining = saved.surveyRemaining; surveyComplete = saved.surveyComplete
        if let source = stoneSource {
            guard checkpointReached, legalFindSites.contains(source),
                  candidate.state.buildings.filter({ $0.kind == .stoneGatherer }).allSatisfy({ abs($0.origin.x-source.x) + abs($0.origin.y-source.y) <= 3 })
            else { throw GameError.invalidSave("Stone source must remain reachable on revealed land") }
        }
        if let craft {
            guard checkpointReached, stoneSource != nil,
                  candidate.state.buildings.contains(where: { $0.kind == .stoneGatherer && $0.isOperational }),
                  craft.batchRemaining == nil || (craft.batchRemaining!.isFinite && craft.batchRemaining! > 0 && craft.batchRemaining! <= 60 && candidate.state.resources[.stoneTools] + 1 <= candidate.capacities[.stoneTools])
            else { throw GameError.invalidSave("Invalid Toolmaking opportunity or reserved output") }
        }
        if let finds = saved.mapFinds {
            let ids = finds.map(\.id)
            guard (finds.isEmpty && candidate.state.buildings.count == 1) ||
                    (finds.count == 2 && Set(ids) == Set(RiverbendMapFindID.allCases)),
                  Set(finds.filter { !$0.resolved }.compactMap(\.tile)).count == finds.filter({ !$0.resolved && $0.tile != nil }).count,
                  finds.allSatisfy({ find in
                      guard let tile = find.tile else { return !find.resolved }
                      return candidate.isDiscovered(tile) && (find.resolved || legalFindSites.contains(tile))
                  }) else { throw GameError.invalidSave("Invalid Map Finds") }
            mapFinds = finds
        } else {
            // Additive compatibility with the exact Goal 1 lab envelope only.
            reconcileFindSites()
        }
    }
    public func encoded() throws -> Data {
        try JSONEncoder().encode(Envelope(profile: GameConfiguration.riverbendLabID, version: 1, state: engine.state,
            surveyRemaining: surveyRemaining, surveyComplete: surveyComplete, mapFinds: mapFinds, stoneSource: stoneSource, storage: storage, craft: craft))
    }
    /// Sites are flood-filled from the civic center over revealed open unoccupied land.
    /// Stable distance/y/x ordering also defines every fallback, without exposing fog.
    public var legalFindSites: [Tile] {
        let center = engine.configuration.map.campfire
        var visited: Set<Tile> = [center], queue = [center], cursor = 0
        while cursor < queue.count {
            for edge in RoadGeometry.neighbors(of: queue[cursor]) {
                let tile = edge.tile, terrain = engine.configuration.map.terrain(at: tile)
                if engine.isDiscovered(tile), terrain == .grass || terrain == .clearing,
                   engine.building(at: tile) == nil, visited.insert(tile).inserted { queue.append(tile) }
            }
            cursor += 1
        }
        return visited.filter { tile in tile != center && !(engine.state.roads ?? []).contains(where: { $0.tile == tile }) }.sorted {
            let a = abs($0.x-center.x) + abs($0.y-center.y), b = abs($1.x-center.x) + abs($1.y-center.y)
            return a == b ? ($0.y == $1.y ? $0.x < $1.x : $0.y < $1.y) : a < b
        }
    }
    public var availableFinds: [RiverbendMapFind] { mapFinds.filter { !$0.resolved && $0.tile != nil } }
    /// World-space hit selection; caller scales the 22-point screen target with its camera.
    public func find(near point: WorldPoint, radius: Double) -> RiverbendMapFindID? {
        availableFinds.compactMap { find -> (id: RiverbendMapFindID, distance: Double)? in
            guard let tile = find.tile else { return nil }
            let site = MapGeometry.point(for: tile)
            let distance = hypot(site.x - point.x, site.y - point.y)
            return distance <= radius ? (find.id, distance) : nil
        }.min { $0.distance < $1.distance }?.id
    }
    private mutating func reconcileFindSites() {
        if mapFinds.isEmpty && engine.state.buildings.count > 1 {
            mapFinds = RiverbendMapFindID.allCases.map { RiverbendMapFind(id: $0, tile: nil, resolved: false) }
        }
        let legal = legalFindSites
        var claimed = Set(mapFinds.filter { !$0.resolved }.compactMap(\.tile).filter(legal.contains))
        for index in mapFinds.indices where !mapFinds[index].resolved {
            if let tile = mapFinds[index].tile, legal.contains(tile) { continue }
            let fallback = legal.first { !claimed.contains($0) }
            mapFinds[index].tile = fallback
            if let fallback { claimed.insert(fallback) }
        }
    }
    public mutating func resolveFind(_ id: RiverbendMapFindID, at tile: Tile) throws {
        guard let index = mapFinds.firstIndex(where: { $0.id == id && !$0.resolved && $0.tile == tile }),
              legalFindSites.contains(tile) else { throw GameError.placement("This find is unavailable; inspect its current site") }
        var state = engine.state
        if id == .berries {
            guard state.resources.food + 3 <= engine.capacities.food else {
                throw GameError.placement("Need room for all 3 Food. Berries remain here; use Food and retry.")
            }
            state.resources.food += 3
        }
        let candidate = try GameEngine(state: state, configuration: engine.configuration)
        engine = candidate; mapFinds[index].resolved = true
    }
    /// Derived solely from validated instance roles; a storage shell has no generic bonus.
    private func configuration(for state: GameState) throws -> GameConfiguration {
        var c = try GameConfiguration.riverbendEconomyLab()
        if craft?.mode == .flint {
            let i = c.buildings.firstIndex { $0.kind == .stoneGatherer }!
            c.buildings[i].ratesPerMinute.stone = 0
            c.buildings[i].ratesPerMinute[.flint] = 4
        }
        if craft?.woodcutterImproved == true {
            c.buildings[c.buildings.firstIndex { $0.kind == .woodcutter }!].ratesPerMinute.wood = 8
        }
        for entry in storage where state.buildings.contains(where: { $0.id == entry.buildingID && $0.kind == .storehouse && $0.isOperational }) {
            if entry.role == .granary { c.resourceCaps?.food += 60 }
            else {
                c.resourceCaps?.wood += 60; c.resourceCaps?.stone += 60
                if craft != nil { c.resourceCaps?[.flint] += 24; c.resourceCaps?[.stoneTools] += 24 }
            }
        }
        return c
    }
    public var craftOpportunityAvailable: Bool {
        checkpointReached && stoneSource != nil && engine.state.buildings.contains { $0.kind == .stoneGatherer && $0.isOperational }
    }
    public mutating func unlockCraft() throws {
        guard craft == nil, craftOpportunityAvailable else { throw GameError.placement("Complete the opening and Stone gatherer, then reveal Toolmaking once") }
        var candidate = self
        candidate.craft = RiverbendCraft()
        candidate.engine = try GameEngine(state: engine.state, configuration: candidate.configuration(for: engine.state))
        self = candidate
    }
    public mutating func setGatheringMode(_ mode: RiverbendGatheringMode) throws {
        guard craft != nil else { throw GameError.placement("Reveal the Toolmaking opportunity first") }
        var candidate = self
        candidate.craft?.mode = mode
        candidate.engine = try GameEngine(state: engine.state, configuration: candidate.configuration(for: engine.state))
        self = candidate
    }
    public var toolBatchIssue: String? {
        guard craft != nil else { return "Reveal Toolmaking first" }
        guard craft?.batchRemaining == nil else { return "One paid batch is already in progress" }
        guard engine.state.resources[.stoneTools] + 1 <= engine.capacities[.stoneTools] else { return "Tools storage full · need room for all 1 Tool before paying" }
        guard engine.state.resources.wood >= 2 else { return "Need 2 Wood · use the forest Woodcutter" }
        guard engine.state.resources[.flint] >= 2 else { return "Need 2 Flint · switch the outcrop gatherer to Flint" }
        return nil
    }
    public mutating func startToolBatch() throws {
        if let issue = toolBatchIssue { throw GameError.placement(issue) }
        var state = engine.state
        state.resources.wood -= 2; state.resources[.flint] -= 2
        let candidate = try GameEngine(state: state, configuration: engine.configuration)
        engine = candidate; craft?.batchRemaining = 60
    }
    public mutating func improveWoodcutter() throws {
        guard let craft, !craft.woodcutterImproved else { throw GameError.placement("Reveal Toolmaking; sharpen Woodcutter equipment only once") }
        guard engine.state.resources[.stoneTools] >= 3 else { throw GameError.placement("Need 3 Tools · craft three batches; total 6 Wood + 6 Flint") }
        var candidate = self, state = engine.state
        state.resources[.stoneTools] -= 3
        candidate.craft?.woodcutterImproved = true
        candidate.engine = try GameEngine(state: state, configuration: candidate.configuration(for: state))
        self = candidate
    }
    public mutating func revealStone() throws {
        guard checkpointReached, stoneSource == nil else { throw GameError.placement("Finish the Food/Wood route before revealing Stone; reveal once") }
        var geometryConfiguration = engine.configuration
        geometryConfiguration.buildings[geometryConfiguration.buildings.firstIndex { $0.kind == .stoneGatherer }!].cost = .init()
        let geometryEngine = try GameEngine(state: engine.state, configuration: geometryConfiguration)
        let footprint = engine.configuration.definition(.stoneGatherer).footprint
        let source = legalFindSites.first { source in
            legalFindSites.contains { site in
                abs(site.x-source.x) + abs(site.y-source.y) <= 3 && !footprint.tiles(at: site).contains(source) && geometryEngine.placementIssue(.stoneGatherer, at: site) == nil
            }
        }
        guard let source else { throw GameError.placement("No reachable outcrop face is available; keep access clear") }
        stoneSource = source
    }
    public func storageIssue(_ role: RiverbendStorageRole, at tile: Tile) -> GameError? {
        guard stoneSource != nil else { return .placement("Reveal Stone after the opening route") }
        guard !storage.contains(where: { $0.role == role }) else { return .placement("One of each storage specialization in this lab") }
        if let source = stoneSource, engine.configuration.definition(.storehouse).footprint.tiles(at: tile).contains(source) { return .placement("Keep the outcrop clear") }
        do {
            var c = engine.configuration
            let index = c.buildings.firstIndex { $0.kind == .storehouse }!
            c.buildings[index].cost = role.cost
            return try GameEngine(state: engine.state, configuration: c).placementIssue(.storehouse, at: tile)
        } catch { return .placement(error.localizedDescription) }
    }
    public func storageSites(for role: RiverbendStorageRole) -> [Tile] {
        legalFindSites.filter { storageIssue(role, at: $0) == nil }
    }
    public mutating func buildStorage(_ role: RiverbendStorageRole, at tile: Tile) throws {
        if let issue = storageIssue(role, at: tile) { throw issue }
        var c = engine.configuration
        c.buildings[c.buildings.firstIndex { $0.kind == .storehouse }!].cost = role.cost
        var candidate = try GameEngine(state: engine.state, configuration: c)
        let id = candidate.state.nextBuildingID
        try candidate.build(.storehouse, at: tile)
        storage.append(RiverbendStorage(buildingID: id, role: role))
        engine = try GameEngine(state: candidate.state, configuration: configuration(for: candidate.state))
        reconcileFindSites()
    }
    public var hutComplete: Bool { engine.state.buildings.contains { $0.kind == .hut && $0.isOperational } }
    public var checkpointReached: Bool {
        surveyComplete && engine.state.buildings.contains { $0.kind == .woodcutter && $0.isOperational } && engine.rates.food > 0 && engine.rates.wood > 0
    }
    public func issue(for kind: BuildingKind, at tile: Tile) -> GameError? {
        guard [.hut, .gatheringShelter, .woodcutter, .stoneGatherer].contains(kind) else { return .placement("Outside this lab") }
        guard !engine.state.buildings.contains(where: { $0.kind == kind }) else { return .placement("One of each building in this short lab") }
        if kind == .woodcutter && (!surveyComplete || !region.woodcutterOrigins.contains(tile)) { return .placement("Survey the forest and choose its reachable edge") }
        if let source = stoneSource, engine.configuration.definition(kind).footprint.tiles(at: tile).contains(source) { return .placement("Keep the outcrop and its access clear") }
        if kind == .stoneGatherer {
            guard let source = stoneSource, abs(tile.x-source.x) + abs(tile.y-source.y) <= 3 else { return .placement("Reveal Stone, then choose a reachable site beside the outcrop") }
        }
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
        reconcileFindSites()
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
        var remainingTime = seconds
        repeat {
            let boundary = candidate.engine.state.buildings.filter { b in candidate.storage.contains { $0.buildingID == b.id } && !b.isOperational }
                .compactMap(\.constructionRemainingSeconds).filter { $0 > 0 }.min() ?? remainingTime
            let step = min(remainingTime, boundary)
            candidate.engine.advance(to: candidate.engine.state.lastUpdated.addingTimeInterval(step))
            candidate.engine = try GameEngine(state: candidate.engine.state, configuration: candidate.configuration(for: candidate.engine.state))
            remainingTime -= step
        } while remainingTime > 1e-9
        if let remaining = surveyRemaining {
            candidate.surveyRemaining = max(0, remaining - seconds)
            if candidate.surveyRemaining == 0 {
                var state = candidate.engine.state
                state.discoveredTiles?.formUnion(region.tiles)
                state.resources.knowledge = 6
                candidate.engine = try GameEngine(state: state, configuration: candidate.engine.configuration)
                candidate.surveyRemaining = nil; candidate.surveyComplete = true
            }
        }
        if let remaining = craft?.batchRemaining {
            if seconds >= remaining {
                var state = candidate.engine.state
                state.resources[.stoneTools] += 1
                candidate.engine = try GameEngine(state: state, configuration: candidate.engine.configuration)
                candidate.craft?.batchRemaining = nil
            } else { candidate.craft?.batchRemaining = remaining - seconds }
        }
        candidate.reconcileFindSites()
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
