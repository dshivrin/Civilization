import Foundation

public enum StorageSpecialization: String, Codable, CaseIterable, Sendable {
    case granary, stockyard
    public var cost: ResourceAmounts { self == .granary ? .init(wood: 14, stone: 4) : .init(wood: 18, stone: 6) }
}
public struct RiverbendProgress: Codable, Equatable, Sendable {
    public internal(set) var resolvedFinds: Set<RiverbendFindKind> = []
    public internal(set) var storage: [Int: StorageSpecialization] = [:]
    public internal(set) var craftRemainingSeconds: Double?
    public internal(set) var woodcutterImproved = false
    public internal(set) var enclosed = false
    public internal(set) var gateOpen = true
    public init() {}
}
public enum RiverbendPlayerRules {
    public static let buildings: Set<BuildingKind> = [.campfire, .hut, .gatheringShelter, .woodcutter, .stoneGatherer, .storehouse, .scoutCamp]
    public static let technologies: Set<String> = ["oralTradition", "stoneTools", "construction", "socialOrder", "naturalKnowledge", "exploration", "surveillance", "fortification"]
}
public extension GameEngine {
    var riverbendOpeningComplete: Bool {
        configuration.isRiverbendPlayer && [.hut, .gatheringShelter, .woodcutter].allSatisfy { kind in state.buildings.contains { $0.kind == kind && isServiceOperational($0) } }
    }
    var riverbendCraftAvailable: Bool {
        riverbendOpeningComplete && state.buildings.contains { $0.kind == .stoneGatherer && isServiceOperational($0) }
    }
    var riverbendBoundary: RiverbendBoundary {
        RiverbendBoundary(configuration: configuration, buildings: state.buildings, enclosed: state.riverbend?.enclosed == true, gateOpen: state.riverbend?.gateOpen ?? true)
    }
    mutating func recoverRiverbendFood() throws {
        try requireRiverbend()
        state.resources.food = max(state.resources.food, 12)
        evaluateGoals()
    }
    mutating func recoverRiverbendWood() throws {
        try requireRiverbend()
        let floor = state.buildings.contains { $0.kind == .hut } ? 8.0 : 12.0
        state.resources.wood = max(state.resources.wood, floor)
        evaluateGoals()
    }
    mutating func buildRiverbendStorage(_ role: StorageSpecialization, at tile: Tile, orientation: BuildingOrientation = .north) throws {
        try requireRiverbend()
        guard riverbendCraftAvailable, !(state.riverbend?.storage.values.contains(role) ?? false) else { throw GameError.placement("Complete the Stone gatherer, then build one of each storage specialization.") }
        try build(.storehouse, at: tile, orientation: orientation, storageRole: role)
    }
    mutating func startRiverbendTools() throws {
        try requireRiverbend()
        guard riverbendCraftAvailable, researchedIDs.contains("stoneTools") else { throw GameError.placement("Complete and connect the Stone gatherer; research Stone Tools to make Tools.") }
        guard state.riverbend?.craftRemainingSeconds == nil else { throw GameError.placement("A Tool batch is already underway.") }
        guard state.resources[.stoneTools] + 1 <= capacities[.stoneTools] else { throw GameError.placement("Need room for one Tool. Ingredients remain untouched.") }
        var cost = ResourceAmounts(wood: 2); cost[.flint] = 2
        guard canAfford(cost) else { throw GameError.insufficientResources }
        state.resources.wood -= 2; state.resources[.flint] -= 2
        state.riverbend?.craftRemainingSeconds = 60
        evaluateGoals()
    }
    mutating func improveRiverbendWoodcutter() throws {
        try requireRiverbend()
        guard riverbendCraftAvailable, state.riverbend?.woodcutterImproved == false else { throw GameError.placement("The permanent Woodcutter improvement is unavailable or already complete.") }
        guard state.resources[.stoneTools] >= 3 else { throw GameError.insufficientResources }
        state.resources[.stoneTools] -= 3
        state.riverbend?.woodcutterImproved = true
        evaluateGoals()
    }
    mutating func purchaseRiverbendEnclosure() throws {
        try requireRiverbend()
        guard civicLevel >= 2, researchedIDs.contains("fortification"), state.riverbend?.enclosed == false else { throw GameError.placement("Research Fortification to build the cliff-backed enclosure once.") }
        guard state.resources.wood >= RiverbendBoundary.cliffCost else { throw GameError.insufficientResources }
        guard RiverbendBoundary.wall.allSatisfy(isDiscovered), state.buildings.flatMap({ $0.tiles(in: configuration) }).allSatisfy({ !RiverbendBoundary.reserved.contains($0) }) else { throw GameError.placement("Reveal and clear the wall, gate path and landing first.") }
        var candidate = self
        try candidate.editRoads(at: Array(RiverbendBoundary.gateRoad), style: .trodden)
        candidate.state.resources.wood -= RiverbendBoundary.cliffCost
        candidate.state.riverbend?.enclosed = true
        candidate.state.riverbend?.gateOpen = true
        candidate.evaluateGoals()
        self = candidate
    }
    mutating func setRiverbendGate(open: Bool) throws {
        try requireRiverbend()
        guard state.riverbend?.enclosed == true else { throw GameError.placement("Build the enclosure before using its gate.") }
        state.riverbend?.gateOpen = open
    }
}
extension GameEngine {
    func requireRiverbend() throws {
        guard configuration.isRiverbendPlayer, state.riverbend != nil else { throw GameError.placement("This action belongs to new Riverbend campaigns.") }
    }
    func validateRiverbendProgress() throws {
        guard configuration.isRiverbendPlayer else {
            guard state.riverbend == nil else { throw GameError.invalidSave("New Riverbend rules cannot be adopted by an existing campaign.") }
            return
        }
        guard let progress = state.riverbend else { throw GameError.invalidSave("Missing Riverbend rules.") }
        guard state.resources[.water] == 0, state.buildings.allSatisfy({ RiverbendPlayerRules.buildings.contains($0.kind) }),
              researchedIDs.isSubset(of: RiverbendPlayerRules.technologies),
              state.buildings.first(where: { $0.kind == .campfire })?.origin == configuration.map.campfire,
              (civicLevel == 1 ? state.operatingRules == nil : usesConnectedPaths),
              Set(progress.storage.keys) == Set(state.buildings.filter { $0.kind == .storehouse }.map(\.id)),
              Set(progress.storage.values).count == progress.storage.count,
              progress.enclosed || progress.gateOpen else { throw GameError.invalidSave("Inconsistent Riverbend campaign.") }
        if let remaining = progress.craftRemainingSeconds {
            guard remaining.isFinite && remaining > 0 && remaining <= 60, researchedIDs.contains("stoneTools"),
                  state.buildings.contains(where: { $0.kind == .stoneGatherer && $0.isOperational }),
                  state.resources[.stoneTools] + 1 <= structuralCapacities[.stoneTools] else { throw GameError.invalidSave("Invalid Tool batch.") }
        }
        if progress.woodcutterImproved {
            guard researchedIDs.contains("stoneTools"), state.buildings.contains(where: { $0.kind == .woodcutter && $0.isOperational }) else { throw GameError.invalidSave("Woodcutter project has no witness.") }
        }
        if progress.enclosed {
            let roads = Set((state.roads ?? []).map(\.tile))
            guard researchedIDs.contains("fortification"), RiverbendBoundary.gateRoad.isSubset(of: roads),
                  state.buildings.flatMap({ $0.tiles(in: configuration) }).allSatisfy({ !RiverbendBoundary.reserved.contains($0) }) else { throw GameError.invalidSave("Enclosure has no valid entrance.") }
        }
    }
    var riverbendRequirements: [JourneyObjective] {
        let completedStorage = Set(state.buildings.filter { $0.kind == .storehouse && $0.isOperational }.compactMap { state.riverbend?.storage[$0.id] })
        return [
            JourneyObjective(id: "buildings", title: "Complete the Riverbend producers, home, storage and scout camp", completed: constructedKinds.intersection(RiverbendPlayerRules.buildings).count, total: RiverbendPlayerRules.buildings.count),
            JourneyObjective(id: "research", title: "Research Riverbend's eight first-era technologies", completed: researchedIDs.intersection(RiverbendPlayerRules.technologies).count, total: RiverbendPlayerRules.technologies.count),
            JourneyObjective(id: "storage", title: "Complete a Granary and Stockyard", completed: completedStorage.count, total: 2),
            JourneyObjective(id: "craft-project", title: "Spend 3 Tools on the permanent Woodcutter improvement", completed: state.riverbend?.woodcutterImproved == true ? 1 : 0, total: 1),
            JourneyObjective(id: "enclosure", title: "Build the cliff-backed enclosure and gate", completed: state.riverbend?.enclosed == true ? 1 : 0, total: 1),
            JourneyObjective(id: "pillars", title: "Earn all five development pillars", completed: state.completedPillarGoals?.count ?? 0, total: 5),
            civicObjective(level: 3)
        ]
    }
    var riverbendChapters: [JourneyChapter] {
        func b(_ kind: BuildingKind) -> JourneyObjective { JourneyObjective(id: "building-" + kind.rawValue, title: "Complete " + configuration.definition(kind).name, completed: constructedKinds.contains(kind) ? 1 : 0, total: 1) }
        func t(_ id: String) -> JourneyObjective { JourneyObjective(id: "technology-" + id, title: "Research " + configuration.technologyDefinitions.first { $0.id == id }!.name, completed: researchedIDs.contains(id) ? 1 : 0, total: 1) }
        func requirement(_ id: String) -> JourneyObjective { riverbendRequirements.first { $0.id == id }! }
        return [
            JourneyChapter(id: 1, title: "Founding Riverbend", objectives: [civicObjective(level: 2), b(.hut)]),
            JourneyChapter(id: 2, title: "Food and the whole forest", objectives: [b(.gatheringShelter), b(.woodcutter)]),
            JourneyChapter(id: 3, title: "Stone and shared knowledge", objectives: [b(.stoneGatherer), t("oralTradition"), t("naturalKnowledge")]),
            JourneyChapter(id: 4, title: "Storage and one useful craft", objectives: [requirement("storage"), t("stoneTools"), requirement("craft-project")]),
            JourneyChapter(id: 5, title: "A lasting civic community", objectives: [t("socialOrder"), civicObjective(level: 3)]),
            JourneyChapter(id: 6, title: "Exploration and enclosure", objectives: [b(.scoutCamp), t("fortification"), requirement("enclosure")]),
            JourneyChapter(id: 7, title: "Bronze readiness", objectives: riverbendRequirements)
        ]
    }
}

public extension GameEngine {
    var riverbendGuidance: SettlementGuidance {
        func advice(_ title: String, _ text: String, _ action: GuidanceAction, _ wait: Double? = nil) -> SettlementGuidance { SettlementGuidance(title: title, explanation: text, action: action, waitSeconds: wait) }
        func building(_ kind: BuildingKind) -> SettlementGuidance? {
            guard let b = state.buildings.first(where: { $0.kind == kind }) else {
                let cost = configuration.definition(kind).cost
                if !canAfford(cost) { return advice("Find materials for " + configuration.definition(kind).name, "The price is retained. Food and Wood have free bounded recovery in Explore; connected producers supply the rest.", .explore) }
                return advice("Build " + configuration.definition(kind).name, "Choose a legal visible plot. A completed building needs a cardinal path to the Lodge entrance.", .build(kind))
            }
            if let remaining = b.constructionRemainingSeconds { return advice("Complete " + buildingName(b), "Paid construction continues in real time. You can explore or inspect other actions while waiting.", .inspect(b.id), remaining) }
            if !isServiceOperational(b) { return advice("Connect " + buildingName(b), "Draw the suggested path to the Lodge. Completed work and stored materials are preserved while disconnected.", .inspect(b.id)) }
            return nil
        }
        if state.stoneAgeCompleted == true { return advice("Stone Age complete", "Bronze readiness earned through your settlement, research and permanent craft project. Keep building here; Bronze gameplay comes later.", .complete) }
        if civicLevel < 2 { return advice("Found Founder’s Lodge", "Upgrade the original Campfire in place for 12 Wood. Its entrance footpath is free; no Stone or research is needed.", .upgrade(civicCenter!.id)) }
        if let next = building(.hut) { return next }
        if state.resources.food < 8 && rates.food <= 0 { return advice("Forage for recovery", "Explore offers free Food up to 12. It is bounded recovery, not a recurring reward.", .explore) }
        if let next = building(.gatheringShelter) { return next }
        if (state.explorationRadius ?? 0) == configuration.explorationRules?.initialRadius { return advice("Survey the whole nearby forest", "Send a 60-second expedition for 8 Food. It reveals the complete forest and legal work faces, rather than a tunnel.", .explore) }
        if let next = building(.woodcutter) { return next }
        if let next = building(.stoneGatherer) { return next }
        for id in ["oralTradition", "naturalKnowledge", "stoneTools"] where !researchedIDs.contains(id) { return advice("Research " + configuration.technologyDefinitions.first { $0.id == id }!.name, "Open this exact technology to see its price and any unmet prerequisite.", .research(id)) }
        if state.riverbend?.woodcutterImproved != true { return advice("Make Tools and improve the Woodcutter", "In Explore, switch the connected Stone gatherer to Flint, craft three 60-second batches (2 Wood + 2 Flint each), then spend 3 Tools once. Base Wood output rises 6→8/min permanently.", .explore, state.riverbend?.craftRemainingSeconds) }
        let roles = Set(state.buildings.filter { $0.kind == .storehouse && $0.isOperational }.compactMap { state.riverbend?.storage[$0.id] })
        if roles.count < 2 { return advice("Build a Granary and Stockyard", "Choose the specialization in the storage inspector. Granary adds only Food capacity; Stockyard adds material capacity after connection and completion.", .build(.storehouse)) }
        for id in ["construction", "socialOrder", "exploration", "surveillance", "fortification"] where !researchedIDs.contains(id) { return advice("Research " + configuration.technologyDefinitions.first { $0.id == id }!.name, "This is the next required technology. Its inspector routes to the exact prerequisite and material source.", .research(id)) }
        if civicLevel < 3 { return advice("Establish the Council Circle", "Upgrade the same civic center with earned Wood, Stone and Knowledge.", .upgrade(civicCenter!.id)) }
        if let next = building(.scoutCamp) { return next }
        if state.riverbend?.enclosed != true { return advice("Build the cliff-backed enclosure", "Explore offers the 36-Wood enclosure and its single road-connected gate. The cliff replaces the back wall.", .explore) }
        return advice("Let the community grow", "Maintain connected Food production, housing and a reserve. Five inhabitants and all five earned pillars complete readiness.", .population)
    }
}

public enum RiverbendFindKind: String, Codable, CaseIterable, Sendable { case berries, tracks }
public struct PlayerMapFind: Identifiable, Equatable, Sendable {
    public let id: RiverbendFindKind
    public let tile: Tile
}
public extension GameEngine {
    var availableRiverbendFinds: [PlayerMapFind] {
        guard configuration.isRiverbendPlayer, state.buildings.contains(where: { $0.kind == .hut }), let progress = state.riverbend else { return [] }
        let start = Tile(x: 18, y: 12)
        var seen: Set<Tile> = [start], queue = [start], cursor = 0
        while cursor < queue.count {
            for tile in RoadGeometry.neighbors(of: queue[cursor]).map(\.tile) where isDiscovered(tile) && riverbendBoundary.walkable(tile) && seen.insert(tile).inserted { queue.append(tile) }
            cursor += 1
        }
        let roads = Set((state.roads ?? []).map(\.tile))
        let sites = seen.filter { tile in
            let terrain = configuration.map.terrain(at: tile)
            return (terrain == .grass || terrain == .clearing) && !RiverbendBoundary.reserved.contains(tile) && !roads.contains(tile)
        }.sorted { a, b in
            let da = abs(a.x-start.x)+abs(a.y-start.y), db = abs(b.x-start.x)+abs(b.y-start.y)
            return da == db ? (a.y == b.y ? a.x < b.x : a.y < b.y) : da < db
        }
        return zip(RiverbendFindKind.allCases.filter { !progress.resolvedFinds.contains($0) }, sites).map { PlayerMapFind(id: $0.0, tile: $0.1) }
    }
    mutating func resolveRiverbendFind(_ id: RiverbendFindKind, at tile: Tile) throws {
        try requireRiverbend()
        guard availableRiverbendFinds.contains(where: { $0.id == id && $0.tile == tile }) else { throw GameError.placement("This find is unavailable; inspect its current site.") }
        if id == .berries {
            guard state.resources.food + 3 <= capacities.food else { throw GameError.placement("Need room for all 3 Food. The berries remain; spend Food and retry.") }
            state.resources.food += 3
        }
        state.riverbend?.resolvedFinds.insert(id)
        evaluateGoals()
    }
    /// Preview only: cardinal BFS over revealed, legal road cells, ending at a
    /// footprint edge. Existing free road confirmation owns the actual transaction.
    func riverbendConnection(to buildingID: Int) -> [Tile] {
        guard configuration.isRiverbendPlayer, let building = state.buildings.first(where: { $0.id == buildingID }), building.kind != .campfire else { return [] }
        let footprint = Set(building.tiles(in: configuration))
        let targets = Set(footprint.flatMap { RoadGeometry.neighbors(of: $0).map(\.tile) }).subtracting(footprint)
        let start = Tile(x: 18,y: 12)
        var seen: Set<Tile> = [start], parents: [Tile: Tile] = [:], queue = [start], cursor = 0
        while cursor < queue.count {
            let tile = queue[cursor]
            if targets.contains(tile) {
                var route = [tile], current = tile
                while current != start { guard let previous = parents[current] else { return [] }; route.append(previous); current = previous }
                return route.reversed()
            }
            for next in RoadGeometry.neighbors(of: tile).map(\.tile) where roadIssue(at: next) == nil && (!RiverbendBoundary.wall.contains(next) || next == RiverbendBoundary.gate) && seen.insert(next).inserted { parents[next] = tile; queue.append(next) }
            cursor += 1
        }
        return []
    }
}
