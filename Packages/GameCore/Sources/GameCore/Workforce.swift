import Foundation

public struct WorkforceRules: Codable, Sendable {
    public var workingPopulationFraction: Double
    public var survivalReserveFraction: Double
    public var waterPerPersonPerMinute: Double
    public var minimumWaterForGrowth: Double
}
public extension GameEngine {
    var workforceAvailable: Double {
        let available = floor(Double(state.population) * (configuration.workforceRules?.workingPopulationFraction ?? 0))
        if configuration.isRiverbendPlayer { return max(2, available) }
        #if DEBUG
        if configuration.isRiverbendEconomyLab { return max(2, available) }
        #endif
        return available
    }
    var workforceRequired: Double {
        state.buildings.filter(isServiceOperational).reduce(0) { $0 + workersRequired(for: $1) }
    }
    func workersAllocated(to building: PlacedBuilding) -> Double { workforceAllocation[building.id,default:0] }
    func workforceProductivity(_ building: PlacedBuilding) -> Double {
        guard isServiceOperational(building) else { return 0 }
        let demand = workersRequired(for: building)
        return demand == 0 || configuration.workforceRules == nil ? 1 : min(1,workersAllocated(to:building) / demand)
    }
}
extension GameEngine {
    var workforceAllocation: [Int:Double] {
        guard let rules = configuration.workforceRules else { return [:] }
        let buildings = state.buildings.filter(isServiceOperational).sorted { $0.id < $1.id }
        var allocations: [Int:Double] = [:]
        var available = workforceAvailable
        func share(_ group: [PlacedBuilding], budget: Double) -> Double {
            let unmet = group.reduce(0.0) { $0 + max(0,workersRequired(for: $1) - allocations[$1.id,default:0]) }
            guard unmet > 0 else { return 0 }
            let used = min(budget,unmet)
            for b in group {
                let need = max(0,workersRequired(for: b) - allocations[b.id,default:0])
                allocations[b.id,default:0] += used * need / unmet
            }
            return used
        }
        // A protected survival share precedes player priorities. No worker is consumed permanently.
        available -= share(buildings.filter { configuration.definition($0.kind).survivalProduction == true },budget:available * rules.survivalReserveFraction)
        for priority in (0...2).reversed() {
            available -= share(buildings.filter { ($0.workerPriority ?? 1) == priority },budget:available)
        }
        return allocations
    }
}
public extension GameConfiguration {
    func validateWorkforce() throws {
        func require(_ value:Bool,_ reason:String) throws { if !value { throw GameError.invalidConfiguration(reason) } }
        guard let rules = workforceRules else { return }
        try require(economyRules != nil && rules.workingPopulationFraction.isFinite && (0.01...1).contains(rules.workingPopulationFraction) &&
                    rules.survivalReserveFraction.isFinite && (0.01...1).contains(rules.survivalReserveFraction) &&
                    rules.waterPerPersonPerMinute.isFinite && (0...100).contains(rules.waterPerPersonPerMinute) &&
                    rules.minimumWaterForGrowth.isFinite && (0...baseCapacities[.water]).contains(rules.minimumWaterForGrowth), "Invalid workforce or water rules")
        for b in buildings {
            let demand = b.workersRequired ?? 0
            try require(demand.isFinite && (0...100).contains(demand), "Invalid workforce requirement")
            if b.survivalProduction == true {
                try require(Resource.allCases.allSatisfy { (b.maintenancePerMinute?[$0] ?? 0) == 0 } &&
                            (b.recipes ?? []).allSatisfy { recipe in Resource.allCases.allSatisfy { recipe.inputsPerMinute[$0] == 0 } }, "Survival production must be input independent")
            }
        }
    }
}
