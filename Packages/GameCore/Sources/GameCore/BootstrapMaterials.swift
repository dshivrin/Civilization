import Foundation

private struct BasicSupplier {
    let kind: BuildingKind
    let cost: ResourceAmounts
    let outputs: Set<Resource>
}
public extension GameEngine {
    /// Names the first basic supplier to establish if this otherwise affordable payment
    /// would destroy every remaining bootstrap route. Existing/pending selectable sources count.
    func bootstrapRequirement(for cost: ResourceAmounts, constructing kind: BuildingKind? = nil) -> BuildingKind? {
        guard configuration.protectBootstrapMaterials == true, canAfford(cost) else { return nil }
        let suppliers = configuration.buildings.compactMap { definition -> BasicSupplier? in
            guard !definition.requiresResearch,
                  Resource.allCases.allSatisfy({ (definition.maintenancePerMinute?[$0] ?? 0) == 0 }) else { return nil }
            let recipes = definition.recipes ?? []
            let outputs = Set(Resource.allCases.filter { resource in
                if recipes.isEmpty { return definition.ratesPerMinute[resource] > 0 }
                return recipes.contains { recipe in
                    recipe.outputsPerMinute[resource] > 0 && Resource.allCases.allSatisfy { recipe.inputsPerMinute[$0] == 0 }
                }
            })
            return outputs.isEmpty ? nil : BasicSupplier(kind: definition.kind, cost: definition.cost, outputs: outputs)
        }
        let availableOutputs = suppliers.reduce(into: Set<Resource>()) { $0.formUnion($1.outputs) }
        let campfireOutputs = suppliers.first { $0.kind == .campfire }?.outputs ?? []
        let materials = Set(Resource.allCases.filter { resource in
            availableOutputs.contains(resource) && !campfireOutputs.contains(resource) && configuration.buildings.contains { $0.cost[resource] > 0 }
        })
        let establishedKinds = Set(state.buildings.map(\.kind))
        let established = suppliers.filter { establishedKinds.contains($0.kind) }.reduce(into: Set<Resource>()) { $0.formUnion($1.outputs) }
        let candidates = suppliers.filter { $0.kind != .campfire }
        // Each step establishes at least one missing material: recursion is bounded by the resource catalog.
        func plan(_ stock: ResourceAmounts, _ produced: Set<Resource>) -> [BuildingKind]? {
            let missing = materials.subtracting(produced)
            if missing.isEmpty { return [] }
            for supplier in candidates where !supplier.outputs.isDisjoint(with: missing) {
                guard Resource.allCases.allSatisfy({ produced.contains($0) || stock[$0] >= supplier.cost[$0] }) else { continue }
                var next = stock
                for resource in Resource.allCases where !produced.contains(resource) { next[resource] -= supplier.cost[resource] }
                if let rest = plan(next, produced.union(supplier.outputs)) { return [supplier.kind] + rest }
            }
            return nil
        }
        guard let before = plan(state.resources, established), let first = before.first else { return nil }
        var after = state.resources
        for resource in Resource.allCases { after[resource] -= cost[resource] }
        var future = established
        if let kind, let supplier = suppliers.first(where: { $0.kind == kind }) { future.formUnion(supplier.outputs) }
        return plan(after, future) == nil ? first : nil
    }
    func bootstrapSpendIssue(for cost: ResourceAmounts, constructing kind: BuildingKind? = nil) -> GameError? {
        guard let supplier = bootstrapRequirement(for: cost, constructing: kind) else { return nil }
        return .placement("Starter materials are reserved for " + configuration.definition(supplier).name + ". Build this basic supplier first so you can replenish construction materials.")
    }
    func upgradeIssue(buildingID: Int) -> GameError? {
        guard let building = state.buildings.first(where: { $0.id == buildingID }), let cost = upgradeCost(for: building) else {
            return .placement("This building cannot be upgraded further.")
        }
        if let id = upgradeResearch(for: building), !researchedIDs.contains(id) {
            return .researchUnavailable("Requires " + (configuration.technologyDefinitions.first { $0.id == id }?.name ?? id) + ".")
        }
        guard canAfford(cost) else { return .insufficientResources }
        return bootstrapSpendIssue(for: cost)
    }
}
