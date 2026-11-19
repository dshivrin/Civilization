import Foundation

/// Authoritative value-type simulation. Callers supply wall time; rendering frames never drive production.
public struct GameEngine: Sendable {
    public let configuration: GameConfiguration
    public private(set) var state: GameState
    #if DEBUG
    /// Session-only override, never encoded in saves or present in release builds.
    public var developerFastConstruction = false
    #endif
    public init(configuration: GameConfiguration, now: Date) throws {
        try configuration.validate()
        self.configuration = configuration
        state = GameState(mapID: configuration.map.id, resources: configuration.initialResources,
                          population: configuration.initialPopulation,
                          buildings: [PlacedBuilding(id: 0, kind: .campfire, origin: configuration.map.campfire)],
                          researchedOralTradition: false, completedGoals: [], nextBuildingID: 1, lastUpdated: now,
                          populationGrowthSeconds: configuration.populationRules == nil ? nil : 0,
                          researchedTechnologies: configuration.technologies == nil ? nil : [],
                          completedPillarGoals: configuration.progressionGoals == nil ? nil : [],
                          stoneAgeCompleted: configuration.progressionGoals == nil ? nil : false,
                          grandfatheredBuildingKinds: configuration.progressionGoals == nil ? nil : [],
                          discoveredTiles: configuration.initialDiscoveredTiles,
                          explorationRemainingSeconds: nil, explorationRadius: configuration.explorationRules?.initialRadius,
                          depositRemaining: configuration.economyRules == nil ? nil : Dictionary(uniqueKeysWithValues: (configuration.naturalDeposits ?? []).filter { !$0.renewable }.map { ($0.id, $0.capacity) }))
    }
    public init(state: GameState, configuration: GameConfiguration) throws {
        try configuration.validate()
        self.configuration = configuration
        self.state = state
        try validateState()
    }
    public var researchedIDs: Set<String> { state.researchedTechnologies ?? (state.researchedOralTradition ? ["oralTradition"] : []) }
    private var activeTechnologies: [TechnologyDefinition] { configuration.technologyDefinitions.filter { researchedIDs.contains($0.id) } }
    public var grossRates: ResourceAmounts {
        if configuration.economyRules != nil { return economySnapshot.gross }
        var result = ResourceAmounts()
        for b in state.buildings where b.isOperational {
            for r in Resource.allCases { result[r] += configuration.definition(b.kind).ratesPerMinute[r] }
        }
        for r in Resource.allCases { result[r] *= 1 + activeTechnologies.reduce(0) { $0 + $1.effects.productionBonus[r] } }
        return result
    }
    public var consumption: ResourceAmounts {
        if configuration.economyRules != nil { return economySnapshot.consumption }
        return ResourceAmounts(food: Double(state.population) * (configuration.populationRules?.foodPerPersonPerMinute ?? 0))
    }
    public var rates: ResourceAmounts {
        var result = grossRates
        let used = consumption
        for r in Resource.allCases { result[r] -= used[r] }
        return result
    }
    public var capacities: ResourceAmounts {
        var result = configuration.baseCapacities
        for tech in activeTechnologies { for r in Resource.allCases { result[r] += tech.effects.storageBonus[r] } }
        for b in state.buildings where b.isOperational {
            for r in Resource.allCases { result[r] += (configuration.definition(b.kind).storageBonus?[r] ?? 0) * Double(b.level) }
        }
        return result
    }
    public var housingCapacity: Int { state.buildings.filter(\.isOperational).reduce(0) { $0 + configuration.definition($1.kind).housing * $1.level } }
    public var growthIntervalSeconds: Double {
        activeTechnologies.reduce(configuration.populationRules?.growthIntervalSeconds ?? 0) { $0 * $1.effects.growthIntervalMultiplier }
    }
    public var growthStatus: GrowthStatus {
        guard let rules = configuration.populationRules else { return .disabled }
        if state.population >= housingCapacity { return .housingFull }
        if state.resources.food + 1e-9 < rules.minimumFoodForGrowth { return .foodReserve }
        if rates.food <= 0 { return .foodDeficit }
        if let water = configuration.workforceRules {
            if state.resources[.water] + 1e-9 < water.minimumWaterForGrowth { return .waterReserve }
            if rates[.water] <= 0 { return .waterDeficit }
        }
        return .growing
    }
    public func isUnlocked(_ kind: BuildingKind) -> Bool {
        guard configuration.buildings.contains(where: { $0.kind == kind }) else { return false }
        return !configuration.definition(kind).requiresResearch || (state.grandfatheredBuildingKinds?.contains(kind) ?? false) || activeTechnologies.contains { $0.effects.unlockedBuildings.contains(kind) }
    }
    public func researchIssue(_ id: String) -> GameError? {
        guard let tech = configuration.technologyDefinitions.first(where: { $0.id == id }) else { return .researchUnavailable("Unknown technology.") }
        if researchedIDs.contains(id) { return .alreadyResearched }
        let missing = tech.prerequisites.filter { !researchedIDs.contains($0) }
        if !missing.isEmpty {
            let names = missing.map { id in configuration.technologyDefinitions.first { $0.id == id }!.name }
            return .researchUnavailable("Requires " + names.joined(separator: ", ") + ".")
        }
        if !canAfford(tech.cost) { return .insufficientResources }
        return bootstrapSpendIssue(for: tech.cost)
    }
    public var currentGoal: Goal? { Goal.allCases.first { !state.completedGoals.contains($0) } }
    public func canAfford(_ costs: ResourceAmounts) -> Bool { Resource.allCases.allSatisfy { state.resources[$0] >= costs[$0] } }
    public func building(at tile: Tile) -> PlacedBuilding? {
        state.buildings.first { $0.tiles(in: configuration).contains(tile) }
    }
    public func placementIssue(_ kind: BuildingKind, at origin: Tile, orientation: BuildingOrientation = .north) -> GameError? {
        if kind == .campfire { return .uniqueCampfire }
        guard configuration.buildings.contains(where: { $0.kind == kind }) else { return .placement("Building is not in this ruleset.") }
        let definition = configuration.definition(kind)
        guard definition.resolvedOrientations.contains(orientation) else { return .placement("This building does not support that orientation.") }
        if !isUnlocked(kind) { return .researchRequired }
        if let issue = siteIssue(kind, at: origin, footprint: definition.footprint.oriented(orientation)) { return issue }
        guard canAfford(definition.cost) else { return .insufficientResources }
        return bootstrapSpendIssue(for: definition.cost, constructing: kind)
    }
    /// Site checks shared by construction and free relocation. The moving footprint may overlap itself.
    private func siteIssue(_ kind: BuildingKind, at origin: Tile, footprint: BuildingFootprint, excludingBuildingID: Int? = nil) -> GameError? {
        let definition = configuration.definition(kind)
        guard origin.x >= 0, origin.y >= 0, origin.x <= configuration.map.width - footprint.width,
              origin.y <= configuration.map.height - footprint.height else { return .placement("Keep the whole footprint inside the map.") }
        for tile in footprint.tiles(at: origin) {
            guard isDiscovered(tile) else { return .placement("Explore the whole footprint before building here.") }
            guard let terrain = configuration.map.terrain(at: tile), terrain == .grass || terrain == .clearing else {
                return .placement("Choose open grass or clearing. Water, hills and forest are protected.")
            }
            if let occupant = building(at: tile), occupant.id != excludingBuildingID { return .placement("Another building occupies this footprint.") }
            if state.roads?.contains(where: { $0.tile == tile }) == true { return .placement("Remove the road from this footprint before building or moving here.") }
        }
        if let terrain = definition.requiredNearbyTerrain, !hasNearbyTerrain(terrain, at: origin, radius: definition.nearbyTerrainRadius ?? 0) {
            return .placement("This building needs nearby discovered \(terrain == "w" ? "water" : "suitable terrain").")
        }
        return nil
    }
    public func relocationIssue(buildingID: Int, at origin: Tile, orientation: BuildingOrientation? = nil) -> GameError? {
        guard let building = state.buildings.first(where: { $0.id == buildingID }) else { return .placement("Choose an existing building to move.") }
        guard building.kind != .campfire else { return .placement("The campfire is the fixed settlement anchor.") }
        let target = orientation ?? building.resolvedOrientation
        if target != building.resolvedOrientation && !configuration.definition(building.kind).resolvedOrientations.contains(target) {
            return .placement("This building does not support that orientation.")
        }
        return siteIssue(building.kind, at: origin, footprint: building.resolvedFootprint(in: configuration).oriented(target), excludingBuildingID: buildingID)
    }
    public mutating func relocate(buildingID: Int, to origin: Tile, orientation: BuildingOrientation? = nil) throws {
        if let issue = relocationIssue(buildingID: buildingID, at: origin, orientation: orientation) { throw issue }
        let index = state.buildings.firstIndex { $0.id == buildingID }!
        evaluateGoals()
        state.buildings[index].origin = origin
        if let orientation, orientation != state.buildings[index].resolvedOrientation { state.buildings[index].orientation = orientation }
        evaluateGoals()
    }
    public func constructionDuration(for kind: BuildingKind) -> Double {
        #if DEBUG
        if developerFastConstruction { return 3 }
        #endif
        return activeTechnologies.reduce(configuration.definition(kind).constructionSeconds ?? 0) { $0 * $1.effects.constructionDurationMultiplier }
    }
    public mutating func build(_ kind: BuildingKind, at origin: Tile, orientation: BuildingOrientation = .north) throws {
        if let issue = placementIssue(kind, at: origin, orientation: orientation) { throw issue }
        evaluateGoals()
        spend(configuration.definition(kind).cost)
        var building = PlacedBuilding(id: state.nextBuildingID, kind: kind, origin: origin)
        building.footprint = configuration.definition(kind).footprint
        building.orientation = orientation
        let effectiveDuration = constructionDuration(for: kind)
        if effectiveDuration > 0 { building.constructionRemainingSeconds = effectiveDuration; building.constructionDurationSeconds = effectiveDuration }
        state.buildings.append(building)
        state.nextBuildingID += 1
        evaluateGoals()
    }
    /// Free decorative transaction. Validate every tile before modifying even one road.
    public mutating func editRoads(at tiles: [Tile], style: RoadStyle?) throws {
        guard tiles.count <= configuration.map.width * configuration.map.height else { throw GameError.placement("This road stroke is too large.") }
        for tile in tiles { if let issue = roadIssue(at: tile) { throw issue } }
        var roads = Dictionary((state.roads ?? []).map { ($0.tile, $0.style) }, uniquingKeysWith: { _, last in last })
        let original = roads
        for tile in tiles { roads[tile] = style }
        guard roads != original else { return }
        state.roads = roads.map { RoadTile(tile: $0.key, style: $0.value) }.sorted {
            $0.tile.y == $1.tile.y ? $0.tile.x < $1.tile.x : $0.tile.y < $1.tile.y
        }
    }
    public mutating func research(_ id: String = "oralTradition") throws {
        if let issue = researchIssue(id) { throw issue }
        let tech = configuration.technologyDefinitions.first { $0.id == id }!
        evaluateGoals()
        spend(tech.cost)
        if state.researchedTechnologies != nil { state.researchedTechnologies!.insert(id) }
        if id == "oralTradition" { state.researchedOralTradition = true }
        resolveEvents()
        evaluateGoals()
    }
    public mutating func startExploration() throws {
        if let issue = explorationIssue { throw issue }
        let rules = configuration.explorationRules!
        evaluateGoals()
        spend(rules.cost)
        state.explorationRemainingSeconds = rules.durationSeconds
    }
    public mutating func setWorkerPriority(buildingID: Int, priority: Int) throws {
        guard configuration.workforceRules != nil, (0...2).contains(priority), let index = state.buildings.firstIndex(where: { $0.id == buildingID }) else { throw GameError.placement("Choose an available building priority.") }
        evaluateGoals()
        state.buildings[index].workerPriority = priority
        evaluateGoals()
    }
    public mutating func setProductionMode(buildingID: Int, recipeID: String) throws {
        guard let index = state.buildings.firstIndex(where: { $0.id == buildingID }), state.buildings[index].isOperational,
              configuration.definition(state.buildings[index].kind).recipes?.contains(where: { $0.id == recipeID }) == true else {
            throw GameError.placement("Choose an available production mode on an operational building.")
        }
        evaluateGoals()
        state.buildings[index].productionModeID = recipeID
        evaluateGoals()
    }
    public mutating func upgrade(buildingID: Int) throws {
        guard let index = state.buildings.firstIndex(where: { $0.id == buildingID }), let cost = upgradeCost(for: state.buildings[index]) else {
            throw GameError.placement("This building cannot be upgraded further.")
        }
        if let issue = upgradeIssue(buildingID: buildingID) { throw issue }
        evaluateGoals()
        spend(cost)
        state.buildings[index].upgradeLevel = state.buildings[index].level + 1
        evaluateGoals()
    }
    /// Integrates constant rates between construction, food-threshold and growth events.
    /// No rendering-frame steps; offline excess is discarded for ALL mechanics, including timers.
    public mutating func advance(to now: Date, offline: Bool = false) {
        let elapsed = now.timeIntervalSince(state.lastUpdated)
        guard elapsed.isFinite && elapsed > 0 else { return }
        var remaining = offline ? min(elapsed, configuration.offlineCapSeconds) : elapsed
        resolveEvents()
        evaluateGoals()
        while remaining > 0 {
            let snapshot = configuration.economyRules == nil ? nil : economySnapshot
            var net = snapshot?.gross ?? grossRates
            let used = snapshot?.consumption ?? consumption
            for r in Resource.allCases { net[r] -= used[r] }
            let capacity = capacities
            let growing = growthStatus == .growing
            var step = remaining
            if let seconds = state.explorationRemainingSeconds { step = min(step,seconds) }
            for building in state.buildings {
                if let seconds = building.constructionRemainingSeconds { step = min(step, seconds) }
            }
            if growing { step = min(step, max(0, growthIntervalSeconds - (state.populationGrowthSeconds ?? 0))) }
            else if let rules = configuration.populationRules, net.food > 0,
                    state.population < housingCapacity, state.resources.food + 1e-9 < rules.minimumFoodForGrowth {
                step = min(step, (rules.minimumFoodForGrowth - state.resources.food) * 60 / net.food)
            }
            if let water = configuration.workforceRules, !growing, net[.water] > 0,
               state.population < housingCapacity, state.resources[.water] + 1e-9 < water.minimumWaterForGrowth {
                step = min(step,(water.minimumWaterForGrowth - state.resources[.water]) * 60 / net[.water])
            }
            // Sticky achievements can hold only briefly when one stock rises while another falls.
            // Visit every increasing requirement boundary instead of sampling at the end of catch-up.
            for goal in pillarGoals where !isPillarGoalComplete(id:goal.id) {
                for r in Resource.allCases where net[r] > 0 && state.resources[r] + 1e-9 < goal.minimumResources[r] && goal.minimumResources[r] <= capacity[r] {
                    step = min(step,(goal.minimumResources[r] - state.resources[r]) * 60 / net[r])
                }
            }
            for r in Resource.allCases where net[r] < 0 && state.resources[r] > 1e-9 {
                step = min(step, state.resources[r] * 60 / -net[r])
            }
            for (id, rate) in snapshot?.deposits ?? [:] where rate > 0 {
                step = min(step, (state.depositRemaining?[id] ?? 0) * 60 / rate)
            }
            // resolveEvents drains zero-time events before each integration.
            for r in Resource.allCases { state.resources[r] = min(capacity[r], max(0, state.resources[r] + net[r] * step / 60)) }
            for (id, rate) in snapshot?.deposits ?? [:] {
                let reserve = state.depositRemaining?[id] ?? 0
                state.depositRemaining?[id] = max(0,reserve - rate * step / 60)
            }
            for index in state.buildings.indices {
                if let seconds = state.buildings[index].constructionRemainingSeconds {
                    state.buildings[index].constructionRemainingSeconds = max(0, seconds - step)
                }
            }
            if let seconds = state.explorationRemainingSeconds { state.explorationRemainingSeconds = max(0,seconds-step) }
            if growing { state.populationGrowthSeconds = (state.populationGrowthSeconds ?? 0) + step }
            remaining = max(0, remaining - step)
            evaluateGoals()
            resolveEvents()
            evaluateGoals()
        }
        state.lastUpdated = now
    }
    private mutating func resolveEvents() {
        if let seconds = state.explorationRemainingSeconds, seconds <= 1e-9, let rules = configuration.explorationRules {
            let radius = min(32,(state.explorationRadius ?? rules.initialRadius) + rules.revealRadiusStep)
            let revealed = configuration.tiles(within:radius)
            state.discoveredTiles?.formUnion(revealed)
            state.explorationRadius = radius
            state.explorationRemainingSeconds = nil
        }
        for index in state.buildings.indices {
            if let seconds = state.buildings[index].constructionRemainingSeconds, seconds <= 1e-9 {
                state.buildings[index].constructionRemainingSeconds = nil
            }
        }
        // Completion is processed before growth when both occur at the same instant.
        while growthStatus == .growing && (state.populationGrowthSeconds ?? 0) + 1e-9 >= growthIntervalSeconds {
            state.populationGrowthSeconds = max(0, (state.populationGrowthSeconds ?? 0) - growthIntervalSeconds)
            state.population += 1
        }
    }
    private mutating func spend(_ costs: ResourceAmounts) {
        for r in Resource.allCases { state.resources[r] -= costs[r] }
    }
    private mutating func evaluateGoals() {
        for goal in Goal.allCases where !state.completedGoals.contains(goal) {
            let achieved: Bool
            if let kind = goal.building { achieved = state.buildings.contains { $0.kind == kind && $0.isOperational } }
            else if goal == .oralTradition { achieved = state.researchedOralTradition }
            else { achieved = state.resources[.knowledge] >= configuration.knowledgeGoalUnits }
            if achieved {
                state.completedGoals.insert(goal)
                if goal.building != nil { state.resources[.wood] = min(capacities.wood, state.resources[.wood] + configuration.constructionGoalWoodReward) }
            }
        }
        if configuration.progressionGoals != nil {
            for goal in pillarGoals where !isPillarGoalComplete(id:goal.id) && unmetRequirements(goal).isEmpty {
                state.completedPillarGoals?.insert(goal.id)
            }
            if state.completedPillarGoals?.count == pillarGoals.count && (configuration.requiresCompleteStoneAgeCatalog != true || fullStoneAgeRequirementsMet) { state.stoneAgeCompleted = true }
        }
    }
    private func validateState() throws {
        func require(_ condition: Bool, _ reason: String) throws { if !condition { throw GameError.invalidSave(reason) } }
        try require(state.mapID == configuration.map.id, "Map identity is unsupported")
        try require(state.lastUpdated.timeIntervalSince1970.isFinite && state.population >= configuration.initialPopulation && state.population <= 768_000_000, "Invalid clock or population")
        // Validate references and bounded levels before derived capacities consult definitions.
        try require(state.buildings.allSatisfy { building in configuration.buildings.contains(where: { $0.kind == building.kind }) && building.level >= 1 && building.level <= (configuration.economyRules?.maximumUpgradeLevel ?? 1) }, "Unsupported building or invalid level")
        try require(Resource.allCases.allSatisfy { state.resources[$0].isFinite && state.resources[$0] >= 0 && state.resources[$0] <= capacities[$0] }, "Invalid resource balances")
        try require(state.buildings.count <= configuration.map.width * configuration.map.height && Set(state.buildings.map(\.id)).count == state.buildings.count, "Invalid building IDs")
        try require(state.buildings.filter { $0.kind == .campfire }.count == 1 && state.buildings.first { $0.kind == .campfire }?.origin == configuration.map.campfire, "Missing or moved campfire")
        try require(state.nextBuildingID > (state.buildings.map(\.id).max() ?? -1) && state.nextBuildingID < Int.max - 768 && state.buildings.allSatisfy { $0.id >= 0 }, "Invalid next building ID")
        if configuration.progressionGoals != nil {
            let validGoals = Set(pillarGoals.map(\.id))
            try require(state.completedPillarGoals != nil && state.stoneAgeCompleted != nil && state.grandfatheredBuildingKinds != nil, "Missing progression history")
            try require(state.completedPillarGoals!.isSubset(of:validGoals) && (state.stoneAgeCompleted != true || state.completedPillarGoals == validGoals), "Invalid Stone Age completion history")
            try require(state.grandfatheredBuildingKinds!.isSubset(of:Set(state.buildings.map(\.kind))), "Inherited construction knowledge has no building witness")
            for goal in pillarGoals where state.completedPillarGoals!.contains(goal.id) {
                try require(goal.requiredTechnologies.allSatisfy(researchedIDs.contains) &&
                            goal.requiredBuildings.allSatisfy { kind in state.buildings.contains { $0.kind == kind && $0.isOperational } } &&
                            state.population >= goal.minimumPopulation && discoveredTileCount >= goal.minimumDiscoveredTiles, "Completed pillar has no permanent achievement history")
            }
        }
        if let rules = configuration.explorationRules {
            try require(state.discoveredTiles != nil && state.discoveredTiles!.contains(configuration.map.campfire) && state.discoveredTiles!.allSatisfy(configuration.map.contains), "Invalid discovered territory")
            try require((rules.initialRadius...32).contains(state.explorationRadius ?? -1), "Invalid exploration radius")
            try require(configuration.tiles(within:state.explorationRadius!).isSubset(of:state.discoveredTiles!), "Exploration radius exceeds revealed territory")
            if let timer = state.explorationRemainingSeconds { try require(timer.isFinite && timer > 0 && timer <= rules.durationSeconds && discoveredTileCount < 768, "Invalid expedition timer") }
        }
        if configuration.economyRules != nil {
            let finite = (configuration.naturalDeposits ?? []).filter { !$0.renewable }
            try require(Set(state.depositRemaining?.keys.map { $0 } ?? []) == Set(finite.map(\.id)), "Missing or unknown deposit state")
            for deposit in finite {
                let value = state.depositRemaining?[deposit.id] ?? -1
                try require(value.isFinite && value >= 0 && value <= deposit.capacity, "Invalid deposit reserve")
            }
        }
        try require(state.buildings.allSatisfy { building in configuration.buildings.contains(where: { $0.kind == building.kind }) }, "Unsupported building")
        let definitions = configuration.technologyDefinitions
        try require(researchedIDs.allSatisfy { id in definitions.contains { $0.id == id } }, "Unknown researched technology")
        for tech in definitions where researchedIDs.contains(tech.id) {
            try require(tech.prerequisites.allSatisfy { researchedIDs.contains($0) }, "Missing researched prerequisite")
        }
        try require(researchedIDs.contains("oralTradition") == state.researchedOralTradition, "Research state mismatch")
        let growth = state.populationGrowthSeconds ?? 0
        try require(growth.isFinite && growth >= 0 && (configuration.populationRules == nil || growth < configuration.maximumGrowthIntervalSeconds + 1e-9), "Invalid population progress")
        var occupied: Set<Tile> = []
        for b in state.buildings {
            let d = configuration.definition(b.kind)
            let base = b.resolvedFootprint(in: configuration)
            try require(base.width > 0 && base.height > 0 && base.width <= configuration.map.width && base.height <= configuration.map.height, "Invalid saved footprint")
            let footprint = b.occupiedFootprint(in: configuration)
            try require(footprint.width <= configuration.map.width && footprint.height <= configuration.map.height, "Invalid oriented saved footprint")
            try require(b.kind != .campfire || (base == BuildingFootprint(width: 1, height: 1) && b.resolvedOrientation == .north), "Invalid campfire geometry")
            try require((0...2).contains(b.workerPriority ?? 1), "Invalid worker priority")
            try require(b.level >= 1 && b.level <= (configuration.economyRules?.maximumUpgradeLevel ?? 1), "Invalid building level")
            try require(b.productionModeID == nil || d.recipes?.contains(where: { $0.id == b.productionModeID }) == true, "Unknown production mode")
            try require(isUnlocked(b.kind), "Locked building")
            if let seconds = b.constructionRemainingSeconds {
                try require(seconds.isFinite && seconds > 0 && b.kind != .campfire, "Invalid construction timer")
                try require(b.constructionDurationSeconds != nil && b.constructionDurationSeconds!.isFinite && b.constructionDurationSeconds! >= seconds, "Invalid construction duration")
            }
            try require(b.origin.x >= 0 && b.origin.y >= 0 && b.origin.x <= configuration.map.width - footprint.width && b.origin.y <= configuration.map.height - footprint.height, "Building outside map")
            for tile in footprint.tiles(at: b.origin) {
                let terrain = configuration.map.terrain(at: tile)
                try require(isDiscovered(tile), "Building occupies undiscovered territory")
                try require((terrain == .grass || terrain == .clearing) && occupied.insert(tile).inserted, "Blocked or overlapping building")
            }
        }
        try validateRoads()
        for goal in state.completedGoals {
            if let kind = goal.building { try require(state.buildings.contains { $0.kind == kind && $0.isOperational }, "Goal has no building") }
            if goal == .oralTradition { try require(state.researchedOralTradition, "Research goal has no research") }
        }
        // All persistent achievements must match; otherwise a damaged save could regrant rewards.
        for goal in Goal.allCases {
            if let kind = goal.building { try require(state.completedGoals.contains(goal) == state.buildings.contains { $0.kind == kind && $0.isOperational }, "Construction reward history mismatch") }
        }
        try require(state.completedGoals.contains(.oralTradition) == state.researchedOralTradition, "Research history mismatch")
    }
}

#if DEBUG
public extension GameEngine {
    mutating func developerAddResources(_ amount: Double) {
        guard amount.isFinite, amount >= 0 else { return }
        for r in Resource.allCases { state.resources[r] = min(capacities[r], state.resources[r] + min(amount, capacities[r])) }
        evaluateGoals()
    }
    mutating func developerAddPopulation(_ amount: Int) {
        guard amount > 0 else { return }
        state.population += min(amount, max(0, housingCapacity - state.population))
        evaluateGoals()
    }
    /// Grant the dependency closure, preserving Oral Tradition and reward history.
    mutating func developerUnlockTechnology(_ id: String) throws {
        guard let tech = configuration.technologyDefinitions.first(where: { $0.id == id }) else { throw GameError.researchUnavailable("Unknown technology.") }
        for prerequisite in tech.prerequisites where !researchedIDs.contains(prerequisite) { try developerUnlockTechnology(prerequisite) }
        state.researchedTechnologies?.insert(id)
        if id == "oralTradition" { state.researchedOralTradition = true }
        evaluateGoals()
    }
    mutating func developerRevealTerritory(radius: Int = 32) {
        guard let rules = configuration.explorationRules else { return }
        let radius = min(32, max(rules.initialRadius, max(state.explorationRadius ?? 0, radius)))
        let revealed = configuration.tiles(within: radius)
        state.discoveredTiles?.formUnion(revealed)
        state.explorationRadius = radius
        state.explorationRemainingSeconds = nil
        evaluateGoals()
    }
    /// Rebase after explicitly simulated debug time; ordinary clock logic is untouched.
    mutating func developerRebaseClock(to now: Date) { state.lastUpdated = now }
}
#endif
