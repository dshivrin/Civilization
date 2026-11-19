import Foundation

public enum DevelopmentPillar: String, Codable, CaseIterable, Sendable {
    case economy, science, militarySecurity, culture, population
    public var title: String {
        switch self { case .economy: "Economy"; case .science: "Science"; case .militarySecurity: "Military & Security"; case .culture: "Culture"; case .population: "Population" }
    }
}
public struct TechnologyEffects: Codable, Sendable {
    /// Additive fractions: 0.2 means +20%. Each technology applies once.
    public var productionBonus: ResourceAmounts
    public var storageBonus: ResourceAmounts
    public var growthIntervalMultiplier: Double
    public var constructionDurationMultiplier: Double
    public var unlockedBuildings: [BuildingKind]
    public init(productionBonus: ResourceAmounts = .init(), storageBonus: ResourceAmounts = .init(), growthIntervalMultiplier: Double = 1, constructionDurationMultiplier: Double = 1, unlockedBuildings: [BuildingKind] = []) {
        self.productionBonus = productionBonus; self.storageBonus = storageBonus
        self.growthIntervalMultiplier = growthIntervalMultiplier; self.constructionDurationMultiplier = constructionDurationMultiplier
        self.unlockedBuildings = unlockedBuildings
    }
}
public struct TechnologyDefinition: Codable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var pillar: DevelopmentPillar
    public var summary: String
    public var prerequisites: [String]
    public var cost: ResourceAmounts
    public var effects: TechnologyEffects
    public init(id: String, name: String, pillar: DevelopmentPillar, summary: String, prerequisites: [String] = [], cost: ResourceAmounts, effects: TechnologyEffects = .init()) {
        self.id = id; self.name = name; self.pillar = pillar; self.summary = summary
        self.prerequisites = prerequisites; self.cost = cost; self.effects = effects
    }
}
public struct PopulationRules: Codable, Sendable {
    public var foodPerPersonPerMinute: Double
    public var growthIntervalSeconds: Double
    public var minimumFoodForGrowth: Double
}
public enum GrowthStatus: Equatable, Sendable {
    case disabled, housingFull, foodReserve, foodDeficit, waterReserve, waterDeficit, growing
    public var description: String {
        switch self {
        case .disabled: "Population is fixed in this ruleset."
        case .housingFull: "Growth paused · more housing needed"
        case .foodReserve: "Growth paused · build food reserves"
        case .foodDeficit: "Growth paused · positive net food needed"
        case .waterReserve: "Growth paused · build water reserves"
        case .waterDeficit: "Growth paused · positive net water needed"
        case .growing: "Population growing"
        }
    }
}
public extension GameConfiguration {
    var technologyDefinitions: [TechnologyDefinition] {
        technologies ?? [TechnologyDefinition(id: "oralTradition", name: "Oral Tradition", pillar: .culture,
            summary: "Unlocks storytelling circles.", cost: researchCost,
            effects: TechnologyEffects(unlockedBuildings: [.storytellingCircle]))]
    }
    var baseCapacities: ResourceAmounts {
        { guard var caps = resourceCaps else { return ResourceAmounts(repeating: resourceCap) }
            // Historical files predate the expanded resource catalog.
            if economyRules == nil { for r in Resource.allCases where ![Resource.food,.wood,.stone,.knowledge].contains(r) && caps[r] == 0 { caps[r] = resourceCap } }
            return caps }()
    }
    /// Upper bound over every research subset; retained paused growth may come from an earlier interval.
    var maximumGrowthIntervalSeconds: Double {
        technologyDefinitions.reduce(populationRules?.growthIntervalSeconds ?? 0) {
            $0 * max(1, $1.effects.growthIntervalMultiplier)
        }
    }
    func validateFoundation() throws {
        func require(_ condition: Bool, _ reason: String) throws { if !condition { throw GameError.invalidConfiguration(reason) } }
        func validAmounts(_ amounts: ResourceAmounts) -> Bool { Resource.allCases.allSatisfy { amounts[$0].isFinite && amounts[$0] >= 0 } }
        try require(validAmounts(baseCapacities) && Resource.allCases.allSatisfy { baseCapacities[$0] > 0 && initialResources[$0] <= baseCapacities[$0] }, "Invalid resource capacities")
        if let rules = populationRules {
            try require(rules.foodPerPersonPerMinute.isFinite && rules.foodPerPersonPerMinute >= 0 && rules.growthIntervalSeconds.isFinite && rules.growthIntervalSeconds >= 1 && rules.minimumFoodForGrowth.isFinite && rules.minimumFoodForGrowth >= 0 && rules.minimumFoodForGrowth <= baseCapacities.food, "Invalid population rules")
        }
        for building in buildings {
            let duration = building.constructionSeconds ?? 0
            try require(duration.isFinite && duration >= 0 && building.housing <= 1_000_000, "Invalid construction duration or housing")
        }
        let definitions = technologyDefinitions
        let ids = Set(definitions.map(\.id))
        try require(ids.count == definitions.count && ids.contains("oralTradition"), "Missing or duplicate technology IDs")
        var aggregateBonus = ResourceAmounts(), aggregateStorage = baseCapacities
        var minimumGrowthMultiplier = 1.0, maximumGrowthMultiplier = 1.0
        var minimumConstructionMultiplier = 1.0, maximumConstructionMultiplier = 1.0
        for tech in definitions {
            try require(!tech.id.isEmpty && !tech.name.isEmpty && Set(tech.prerequisites).count == tech.prerequisites.count && tech.prerequisites.allSatisfy { ids.contains($0) }, "Missing or duplicate technology prerequisite")
            try require(validAmounts(tech.cost) && validAmounts(tech.effects.productionBonus) && validAmounts(tech.effects.storageBonus), "Invalid technology amounts")
            try require(tech.effects.growthIntervalMultiplier.isFinite && tech.effects.growthIntervalMultiplier > 0 && tech.effects.constructionDurationMultiplier.isFinite && tech.effects.constructionDurationMultiplier > 0, "Invalid technology multipliers")
            for r in Resource.allCases {
                aggregateBonus[r] += tech.effects.productionBonus[r]
                aggregateStorage[r] += tech.effects.storageBonus[r]
            }
            minimumGrowthMultiplier *= min(1, tech.effects.growthIntervalMultiplier)
            maximumGrowthMultiplier *= max(1, tech.effects.growthIntervalMultiplier)
            minimumConstructionMultiplier *= min(1, tech.effects.constructionDurationMultiplier)
            maximumConstructionMultiplier *= max(1, tech.effects.constructionDurationMultiplier)
        }
        try require(Resource.allCases.allSatisfy { aggregateBonus[$0].isFinite && aggregateStorage[$0].isFinite }, "Technology effects overflow")
        // Check worst-case arithmetic over the bounded map population/building count.
        for r in Resource.allCases {
            let rate = buildings.map { $0.ratesPerMinute[r] }.max() ?? 0
            try require((rate * 768 * (1 + aggregateBonus[r])).isFinite, "Production overflow")
        }
        let baseInterval = populationRules?.growthIntervalSeconds ?? 120
        let shortestInterval = baseInterval * minimumGrowthMultiplier
        let longestInterval = baseInterval * maximumGrowthMultiplier
        try require(shortestInterval.isFinite && shortestInterval >= 0.001 && longestInterval.isFinite &&
                    minimumConstructionMultiplier > 0 && maximumConstructionMultiplier.isFinite &&
                    buildings.allSatisfy {
                        let duration = $0.constructionSeconds ?? 0
                        return (duration * maximumConstructionMultiplier).isFinite && (duration == 0 || duration * minimumConstructionMultiplier > 0)
                    }, "A research subset produces invalid durations")
        var visiting: Set<String> = [], visited: Set<String> = []
        func visit(_ id: String) throws {
            if visited.contains(id) { return }
            try require(visiting.insert(id).inserted, "Research dependency cycle")
            for prerequisite in definitions.first(where: { $0.id == id })!.prerequisites { try visit(prerequisite) }
            visiting.remove(id); visited.insert(id)
        }
        for id in ids { try visit(id) }
        let oral = definitions.first { $0.id == "oralTradition" }!
        try require(oral.cost.knowledge == 0 && oral.prerequisites.isEmpty && oral.effects.unlockedBuildings.contains(.storytellingCircle), "Oral Tradition must bootstrap knowledge")
        for building in buildings where building.requiresResearch {
            try require(definitions.contains { $0.effects.unlockedBuildings.contains(building.kind) }, "Locked building has no unlock")
        }
    }
}
