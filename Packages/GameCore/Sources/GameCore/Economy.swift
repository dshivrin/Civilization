import Foundation

public struct EconomicOverview: Sendable, Equatable {
    public let gross: ResourceAmounts
    public let consumption: ResourceAmounts
    public let net: ResourceAmounts
    public let productiveBuildingIDs: Set<Int>
}

public struct ProductionRecipe: Codable, Sendable {
    public var id: String
    public var name: String
    public var inputsPerMinute: ResourceAmounts
    public var outputsPerMinute: ResourceAmounts
    public var depositResource: Resource?
    public var allocationTier: Int
}
public struct GeographicBonus: Codable, Sendable {
    public var terrain: String
    public var radius: Int
    public var outputBonus: Double
}
public struct NaturalDeposit: Codable, Sendable {
    public var id: String
    public var kind: String
    public var resource: Resource?
    public var requiredTechnology: String?
    public var origin: Tile
    public var radius: Int
    /// Additional reachable work faces drawing from this same stable reserve.
    public var accessSites: [Tile]?
    public var renewable: Bool
    public var capacity: Double
}
public struct EconomyRules: Codable, Sendable {
    public var maximumUpgradeLevel: Int
    public var outputBonusPerLevel: Double
}

/// A steady-state flow between depletion, construction and population events.
struct EconomySnapshot {
    var gross = ResourceAmounts()
    var consumption = ResourceAmounts()
    var factors: [Int: Double] = [:]
    var deposits: [String: Double] = [:]
}
private struct Flow {
    var id: Int
    var tier: Int
    var inputs: ResourceAmounts
    var outputs: ResourceAmounts
    var deposit: NaturalDeposit?
    var extraction: Double
    var labor: Double
}
public extension GameEngine {
    /// Read-only presentation values from one authoritative snapshot.
    var economicOverview: EconomicOverview {
        let snapshot = configuration.economyRules == nil ? nil : economySnapshot
        let gross = snapshot?.gross ?? grossRates
        let used = snapshot?.consumption ?? consumption
        var net = gross
        for resource in Resource.allCases { net[resource] -= used[resource] }
        let productive = Set(state.buildings.compactMap { building -> Int? in
            guard isServiceOperational(building) else { return nil }
            let outputs = recipe(for: building)?.outputsPerMinute ?? configuration.definition(building.kind).ratesPerMinute
            guard Resource.allCases.contains(where: { outputs[$0] > 0 }), (snapshot?.factors[building.id] ?? (snapshot == nil ? 1 : 0)) > 1e-9 else { return nil }
            return building.id
        })
        return EconomicOverview(gross: gross, consumption: used, net: net, productiveBuildingIDs: productive)
    }
    var operatingProductionBuildingIDs: Set<Int> { economicOverview.productiveBuildingIDs }
    /// Counts current gross-output sources, excluding construction, staffing/input/deposit shutdowns.
    func producingBuildingCount(for resource: Resource) -> Int {
        let factors = configuration.economyRules == nil ? nil : economySnapshot.factors
        return state.buildings.filter { building in
            guard isServiceOperational(building) else { return false }
            if let civic = civicDefinition(for: building) {
                let founding = recipe(for: building)?.outputsPerMinute ?? configuration.definition(building.kind).ratesPerMinute
                return founding[resource] > 0 || (civic.culturalOutputPerMinute[resource] > 0 && workforceProductivity(building) > 1e-9)
            }
            let outputs = recipe(for: building)?.outputsPerMinute ?? configuration.definition(building.kind).ratesPerMinute
            return outputs[resource] > 0 && (factors?[building.id] ?? (factors == nil ? 1 : 0)) > 1e-9
        }.count
    }
    func recipe(for building: PlacedBuilding) -> ProductionRecipe? {
        let recipes = configuration.definition(building.kind).recipes ?? []
        var selected = recipes.first { $0.id == building.productionModeID } ?? recipes.first
        if configuration.isRiverbendPlayer && building.kind == .woodcutter && state.riverbend?.woodcutterImproved == true { selected?.outputsPerMinute.wood = 8 }
        return selected
    }
    func upgradeCost(for building: PlacedBuilding) -> ResourceAmounts? {
        if configuration.isRiverbendPlayer && building.kind == .storehouse { return nil }
        if building.kind == .campfire, building.isOperational, let levels = configuration.civicLevels {
            return levels.first { $0.level == building.level + 1 }?.cost
        }
        guard let rules = configuration.economyRules, building.kind != .campfire,
              building.isOperational, building.level < rules.maximumUpgradeLevel,
              var cost = configuration.definition(building.kind).upgradeCost else { return nil }
        for r in Resource.allCases { cost[r] *= Double(building.level) }
        return cost
    }
    func productivity(_ building: PlacedBuilding) -> Double {
        guard isServiceOperational(building) else { return 0 }
        return configuration.economyRules == nil ? 1 : economySnapshot.factors[building.id, default: 0]
    }
    func operatingStatus(_ building: PlacedBuilding) -> String {
        if !building.isOperational { return "Under construction" }
        if !isServiceOperational(building) { return "Not connected · connect a path to the civic center" }
        let factor = productivity(building)
        if workforceProductivity(building) < 1 - 1e-9 { return "Workers limited · \(Int((factor * 100).rounded()))% productivity" }
        return factor >= 1 - 1e-9 ? "Operating" : "Shortage · \(Int((factor * 100).rounded()))% productivity"
    }
    func geographicMultiplier(_ building: PlacedBuilding) -> Double {
        guard let bonus = configuration.definition(building.kind).geographicBonus else { return 1 }
        if hasNearbyTerrain(bonus.terrain,at:building.origin,radius:bonus.radius) { return 1 + bonus.outputBonus }
        return 1
    }
}
extension GameEngine {
    var economySnapshot: EconomySnapshot {
        var result = EconomySnapshot()
        result.consumption.food = Double(state.population) * (configuration.populationRules?.foodPerPersonPerMinute ?? 0)
        result.consumption[.water] = Double(state.population) * (configuration.workforceRules?.waterPerPersonPerMinute ?? 0)
        let workers = workforceAllocation
        let techs = configuration.technologyDefinitions.filter { researchedIDs.contains($0.id) }
        var technologyMultipliers = ResourceAmounts()
        for resource in Resource.allCases {
            technologyMultipliers[resource] = 1 + techs.reduce(0) { $0 + $1.effects.productionBonus[resource] }
        }
        var flows: [Flow] = []
        // Stable IDs make summation, tie breaks and resource sharing independent of save array order.
        for building in state.buildings.sorted(by: { $0.id < $1.id }) where isServiceOperational(building) {
            let definition = configuration.definition(building.kind)
            let recipe = recipe(for: building)
            var outputs = recipe?.outputsPerMinute ?? definition.ratesPerMinute
            var inputs = recipe?.inputsPerMinute ?? ResourceAmounts()
            let civic = civicDefinition(for: building)
            let scale = civic == nil ? 1 + Double(building.level - 1) * (configuration.economyRules?.outputBonusPerLevel ?? 0) : 1
            let geo = geographicMultiplier(building)
            let demand = workersRequired(for: building)
            let labor = configuration.workforceRules == nil || demand == 0 ? 1 : min(1,workers[building.id,default:0] / demand)
            for r in Resource.allCases {
                if let civic {
                    outputs[r] = (outputs[r] + civic.culturalOutputPerMinute[r] * labor) * technologyMultipliers[r]
                } else { outputs[r] *= labor * scale * geo * technologyMultipliers[r] }
                inputs[r] = (inputs[r] + (definition.maintenancePerMinute?[r] ?? 0)) * scale * labor
            }
            var deposit: NaturalDeposit?
            if let resource = recipe?.depositResource {
                deposit = (configuration.naturalDeposits ?? []).filter { deposit in
                    deposit.resource == resource && isIdentified(deposit) && ([deposit.origin] + (deposit.accessSites ?? [])).contains(where: { site in isDiscovered(site) && abs(site.x - building.origin.x) + abs(site.y - building.origin.y) <= deposit.radius }) &&
                    (deposit.renewable || (state.depositRemaining?[deposit.id] ?? 0) > 1e-9)
                }.sorted {
                    let a = abs($0.origin.x - building.origin.x) + abs($0.origin.y - building.origin.y)
                    let b = abs($1.origin.x - building.origin.x) + abs($1.origin.y - building.origin.y)
                    return a == b ? $0.id < $1.id : a < b
                }.first
                if deposit == nil { result.factors[building.id] = 0; continue }
            }
            flows.append(Flow(id:building.id,tier:recipe?.allocationTier ?? 0,inputs:inputs,outputs:outputs,
                              deposit:deposit,extraction:recipe?.depositResource.map { outputs[$0] } ?? 0,labor: labor))
        }
        for tier in Set(flows.map(\.tier)).sorted() {
            let group = flows.filter { $0.tier == tier }
            var factors = Array(repeating:0.0,count:group.count)
            var active = Set(group.indices)
            // Max-min fair water filling over empty inputs. Positive stocks run until their next depletion event.
            // Upstream tiers feed zero stocks immediately; survival has first claim on food.
            let constrained = Resource.allCases.filter { state.resources[$0] <= 1e-9 }
            while !active.isEmpty {
                var increment = active.map { 1 - factors[$0] }.min() ?? 0
                for r in constrained {
                    let demand = active.reduce(0.0) { $0 + group[$1].inputs[r] }
                    if demand > 0 {
                        let available = max(0, result.gross[r] - result.consumption[r])
                        let used = group.indices.reduce(0.0) { $0 + group[$1].inputs[r] * factors[$1] }
                        increment = min(increment,max(0,available - used) / demand)
                    }
                }
                for i in active { factors[i] += increment }
                var frozen = Set(active.filter { factors[$0] >= 1 - 1e-12 })
                for r in constrained {
                    let available = max(0,result.gross[r] - result.consumption[r])
                    let used = group.indices.reduce(0.0) { $0 + group[$1].inputs[r] * factors[$1] }
                    if used + 1e-10 >= available {
                        frozen.formUnion(active.filter { group[$0].inputs[r] > 0 })
                    }
                }
                if frozen.isEmpty { break }
                active.subtract(frozen)
            }
            for (i,flow) in group.enumerated() {
                let factor = factors[i]
                // Reuse this snapshot's allocation instead of recalculating all workers per flow.
                result.factors[flow.id] = factor * flow.labor
                for r in Resource.allCases {
                    result.gross[r] += flow.outputs[r] * factor
                    result.consumption[r] += flow.inputs[r] * factor
                }
                if let deposit = flow.deposit, !deposit.renewable { result.deposits[deposit.id,default:0] += flow.extraction * factor }
            }
        }
        return result
    }
}
public extension GameConfiguration {
    func validateEconomy() throws {
        func require(_ value: Bool, _ reason: String) throws { if !value { throw GameError.invalidConfiguration(reason) } }
        func valid(_ amounts: ResourceAmounts) -> Bool { Resource.allCases.allSatisfy { amounts[$0].isFinite && amounts[$0] >= 0 && amounts[$0] <= 1_000_000 } }
        guard let rules = economyRules else { return }
        try require((1...10).contains(rules.maximumUpgradeLevel) && rules.outputBonusPerLevel.isFinite && (0...10).contains(rules.outputBonusPerLevel), "Invalid upgrade tuning")
        let deposits = naturalDeposits ?? []
        try require(!deposits.isEmpty && Set(deposits.map(\.id)).count == deposits.count, "Missing or duplicate deposits")
        for d in deposits {
            try require((d.accessSites ?? []).allSatisfy { map.contains($0) && (map.terrain(at: $0) == .grass || map.terrain(at: $0) == .clearing) }, "Invalid deposit access site")
            try require(!d.id.isEmpty && !d.kind.isEmpty && map.contains(d.origin) && (0...64).contains(d.radius) && d.capacity.isFinite && (d.renewable ? d.capacity >= 0 : d.capacity > 0), "Invalid deposit")
        }
        let recipes = buildings.flatMap { $0.recipes ?? [] }
        for r in Resource.allCases {
            let bonus = technologyDefinitions.reduce(0) { $0 + $1.effects.productionBonus[r] }
            let maximumRate = max(buildings.map { $0.ratesPerMinute[r] }.max() ?? 0, recipes.map { $0.outputsPerMinute[r] }.max() ?? 0)
            try require((maximumRate * 768 * (1 + Double(rules.maximumUpgradeLevel - 1) * rules.outputBonusPerLevel) * 11 * (1 + bonus)).isFinite, "Economy production overflow")
        }
        for b in buildings {
            try require(valid(b.maintenancePerMinute ?? .init()) && valid(b.upgradeCost ?? .init()) && valid(b.storageBonus ?? .init()), "Invalid building economy amounts")
            let modes = b.recipes ?? []
            try require(Set(modes.map(\.id)).count == modes.count, "Duplicate production mode")
            if let geo = b.geographicBonus {
                try require(geo.terrain.count == 1 && geo.terrain.first.flatMap(Terrain.init(rawValue:)) != nil && (0...32).contains(geo.radius) && geo.outputBonus.isFinite && (0...10).contains(geo.outputBonus), "Invalid geographic bonus")
            }
            for recipe in modes {
                try require(!recipe.id.isEmpty && !recipe.name.isEmpty && valid(recipe.inputsPerMinute) && valid(recipe.outputsPerMinute) && (0...10).contains(recipe.allocationTier), "Invalid recipe")
                if let resource = recipe.depositResource {
                    try require(recipe.outputsPerMinute[resource] > 0 && deposits.contains { $0.resource == resource }, "Recipe has no matching deposit")
                }
                for r in Resource.allCases where recipe.inputsPerMinute[r] + (b.maintenancePerMinute?[r] ?? 0) > 0 {
                    try require(recipes.contains { $0.outputsPerMinute[r] > 0 } && recipes.filter { $0.outputsPerMinute[r] > 0 }.allSatisfy { $0.allocationTier < recipe.allocationTier }, "Inputs must be produced in earlier allocation tiers")
                }
            }
            try require(modes.count > 0 || Resource.allCases.allSatisfy { (b.maintenancePerMinute?[$0] ?? 0) == 0 }, "Maintenance requires a recipe tier")
        }
    }
}
