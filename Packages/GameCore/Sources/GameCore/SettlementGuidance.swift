import Foundation

/// Read-only advice. UI actions navigate; they never bypass the engine's real transactions.
public enum GuidanceAction: Equatable, Sendable {
    case build(BuildingKind), research(String), recipe(Int, String), priority(Int, Int)
    case inspect(Int), upgrade(Int), explore, resource(Resource), population, journey, complete
}
public struct SettlementGuidance: Equatable, Sendable {
    public let title: String
    public let explanation: String
    public let action: GuidanceAction
    /// A current-rate estimate or active timer, not a promise or a simulated clock override.
    public let waitSeconds: Double?
}
public extension GameEngine {
    var settlementGuidance: SettlementGuidance {
        var resolver = GuidanceResolver(game: self, net: rates)
        if state.stoneAgeCompleted == true && !fullStoneAgeRequirementsMet {
            return SettlementGuidance(title: "Stone Age complete", explanation: "Bronze Age unlocked — your previously earned readiness, chapters and rewards are preserved. Further civic upgrades remain available at your pace. Bronze Age gameplay is not available yet.", action: .complete, waitSeconds: nil)
        }
        if fullStoneAgeRequirementsMet {
            return SettlementGuidance(title: "Stone Age complete", explanation: "Bronze Age unlocked — readiness milestone earned. Every building type, technology, required resource territory and development pillar is complete. Bronze Age gameplay is not available yet. Keep building in this settlement.", action: .complete, waitSeconds: nil)
        }
        guard let objective = journeyChapters.first(where: { !$0.isComplete })?.objectives.first(where: { !$0.isComplete }) else { return resolver.help }
        return resolver.objective(objective.id)
    }
    func guidance(for objectiveID: String) -> SettlementGuidance {
        var resolver = GuidanceResolver(game: self, net: rates)
        return resolver.objective(objectiveID)
    }
}

private struct GuidanceResolver {
    let game: GameEngine
    let net: ResourceAmounts
    var visited: Set<String> = []
    var config: GameConfiguration { game.configuration }
    var help: SettlementGuidance { advice("Choose another objective", "Open the journey checklist for remaining buildings, research, resource discoveries and pillar conditions. Work in any chapter counts immediately.", .journey) }
    func advice(_ title: String, _ text: String, _ action: GuidanceAction, wait: Double? = nil) -> SettlementGuidance {
        SettlementGuidance(title: title, explanation: text, action: action, waitSeconds: wait)
    }
    func name(_ resource: Resource) -> String {
        switch resource { case .animalHides: "Animal hides"; case .stoneTools: "Stone tools"; default: resource.rawValue.capitalized }
    }
    mutating func enter(_ id: String) -> Bool { visited.count < 48 && visited.insert(id).inserted }
    mutating func objective(_ id: String) -> SettlementGuidance {
        if id.hasPrefix("building-"), let kind = BuildingKind(rawValue: String(id.dropFirst(9))) { return build(kind) }
        if id.hasPrefix("technology-") { return research(String(id.dropFirst(11))) }
        if id.hasPrefix("civic-level-"), let level = Int(id.dropFirst(12)) { return civicUpgrade(to: level) }
        switch id {
        case "onboarding-knowledge": return resource(.knowledge, target: config.knowledgeGoalUnits)
        case "buildings":
            if let definition = config.buildings.first(where: { !(config.civicLevels != nil && $0.kind == .storytellingCircle) && !game.constructedKinds.contains($0.kind) }) { return build(definition.kind) }
        case "research":
            if let technology = config.technologyDefinitions.first(where: { !game.researchedIDs.contains($0.id) }) { return research(technology.id) }
        case "discovery":
            for r in Resource.allCases where game.requiredDiscoveryResources.contains(r) && !game.discoveredRequiredResources.contains(r) { return discover(r) }
        case "pillars":
            if let goal = game.pillarGoals.first(where: { !game.isPillarGoalComplete(id: $0.id) }) {
                if let level = goal.requiredCivicLevel, game.civicLevel < level { return civicUpgrade(to: level) }
                for kind in goal.requiredBuildings where !game.constructedKinds.contains(kind) { return build(kind) }
                for tech in goal.requiredTechnologies where !game.researchedIDs.contains(tech) { return research(tech) }
                if game.state.population < goal.minimumPopulation { return grow() }
                if game.discoveredTileCount < goal.minimumDiscoveredTiles { return explore() }
                for r in Resource.allCases where game.state.resources[r] + 1e-9 < goal.minimumResources[r] { return resource(r, target: goal.minimumResources[r]) }
                for r in Resource.allCases where net[r] + 1e-9 < goal.minimumNetRates[r] { return resource(r, target: game.state.resources[r] + 1, minimumNet: goal.minimumNetRates[r]) }
                return advice("Your settlement is developing", "The pillar achievement will be recorded as time advances. You can continue in other chapters.", .journey, wait: 1)
            }
        default: break
        }
        return help
    }
    mutating func civicUpgrade(to level: Int) -> SettlementGuidance {
        guard enter("civic-\(level)"), let center = game.civicCenter,
              let next = config.civicLevels?.first(where: { $0.level == center.level + 1 }), center.level < level else { return help }
        if let id = next.requiredTechnology, !game.researchedIDs.contains(id) { return research(id) }
        if let missing = Resource.allCases.first(where: { game.state.resources[$0] < next.cost[$0] }) { return resource(missing, target: next.cost[missing]) }
        if let supplier = game.bootstrapRequirement(for: next.cost) { return build(supplier) }
        return advice("Upgrade to " + next.name, "Inspect your permanent civic center and upgrade it. It produces knowledge and culture with one shared worker; founding food, water and housing remain available. No additional storytelling building is required.", .upgrade(center.id))
    }
    mutating func build(_ kind: BuildingKind, reason: String = "") -> SettlementGuidance {
        guard enter("build-" + kind.rawValue), let definition = config.buildings.first(where: { $0.kind == kind }), kind != .campfire else { return help }
        if game.usesConnectedPaths, let disconnected = game.state.buildings.first(where: { $0.kind == kind && $0.isOperational && !game.isServiceOperational($0) }) {
            return advice("Connect " + definition.name, "Connect a path from this building to the civic center, or move it to reachable land. Existing progress is preserved.", .inspect(disconnected.id))
        }
        if let pending = game.state.buildings.first(where: { $0.kind == kind && !$0.isOperational }) {
            return advice("Finish " + definition.name, "Construction is underway. Its effects and chapter credit start when it finishes. You may work on another objective meanwhile.", .inspect(pending.id), wait: pending.constructionRemainingSeconds)
        }
        if !game.isUnlocked(kind), let technology = config.technologyDefinitions.first(where: { $0.effects.unlockedBuildings.contains(kind) }) { return research(technology.id) }
        if let missing = Resource.allCases.first(where: { game.state.resources[$0] < definition.cost[$0] }) { return resource(missing, target: definition.cost[missing]) }
        if let supplier = game.bootstrapRequirement(for: definition.cost, constructing: kind) { return build(supplier, reason: "Establish this source before using your last construction materials. ") }
        let hasSite = (0..<config.map.height).contains { y in (0..<config.map.width).contains { x in game.placementIssue(kind, at: Tile(x: x, y: y)) == nil } }
        if !hasSite {
            if game.discoveredTileCount < config.map.width * config.map.height { return explore() }
            return advice("Make room for " + definition.name, "Move an existing building to open grass or clearing. Keep the whole footprint clear; fishing buildings need revealed nearby water. Moving is free and preserves progress.", .journey)
        }
        return advice("Build " + definition.name, reason + "Choose Build in the catalog. Drag the preview onto clear, revealed land, then tap the green check to confirm it. Costs are paid only for a valid placement; construction then finishes over time.", .build(kind))
    }
    mutating func research(_ id: String) -> SettlementGuidance {
        guard enter("research-" + id), let technology = config.technologyDefinitions.first(where: { $0.id == id }) else { return help }
        for prerequisite in technology.prerequisites where !game.researchedIDs.contains(prerequisite) { return research(prerequisite) }
        if let missing = Resource.allCases.first(where: { game.state.resources[$0] < technology.cost[$0] }) { return resource(missing, target: technology.cost[missing]) }
        if let supplier = game.bootstrapRequirement(for: technology.cost) { return build(supplier, reason: "Establish this source before spending its starter materials on research. ") }
        return advice("Research " + technology.name, technology.summary + " Open Research and confirm the purchase. Red costs show any resources still missing; researching never consumes population.", .research(id))
    }
    mutating func resource(_ r: Resource, target: Double, minimumNet: Double = 0) -> SettlementGuidance {
        guard enter("resource-" + r.rawValue) else {
            return advice("Restore " + name(r) + " production", "Check existing producers, their input supplies and worker priorities. A producer needs staff and its recipe inputs; avoid spending the last construction materials before establishing a source.", .resource(r))
        }
        if net[r] > max(1e-9, minimumNet - 1e-9), target <= game.capacities[r], game.state.resources[r] < target {
            let seconds = ceil((target - game.state.resources[r]) * 60 / net[r])
            // Optional investment advice, not a chapter prerequisite or balance change.
            // The existing tested two-circle route avoids long knowledge-only waits.
            if r == .knowledge && seconds > 300 {
                let growthGoal = game.pillarGoals.map(\.minimumPopulation).max() ?? 0
                if game.state.population >= game.housingCapacity && game.housingCapacity <= growthGoal && net.food > 0 && net[.water] > 0 {
                    return build(.hut, reason: "More inhabitants provide more workers for research and materials. ")
                }
                if let source = config.buildings.first(where: { $0.kind != .campfire && ($0.recipes ?? []).contains { $0.outputsPerMinute[.knowledge] > 0 } }),
                   game.state.buildings.filter({ $0.kind == source.kind && $0.isOperational }).count == 1,
                   game.canAfford(source.cost) {
                    return build(source.kind, reason: "A second knowledge producer can shorten this research wait. Workers remain shared with other production. ")
                }
            }
            let detail = r == .knowledge ? " Your upgraded civic center makes knowledge. Optional storytelling circles and Natural Knowledge can help; cultural workers are shared with material producers." : " You can work on other chapters while resources accumulate."
            return advice("Gather " + name(r), "\(Int(game.state.resources[r]))/\(Int(ceil(target))) stored; net +\(String(format: "%.1f", net[r])) per minute. About \(Int(seconds))s at the current rate; staffing and growth can change it." + detail, .resource(r), wait: max(1, seconds))
        }
        if config.civicLevels != nil && game.civicLevel < 2 && (r == .knowledge || r == .culture) { return civicUpgrade(to: 2) }
        let sources = config.buildings.filter { $0.kind != .campfire && ($0.recipes ?? []).contains { $0.outputsPerMinute[r] > 0 } }
        guard let source = sources.first, let recipe = source.recipes?.first(where: { $0.outputsPerMinute[r] > 0 }) else { return help }
        let matching = game.state.buildings.filter { $0.isOperational && ((game.recipe(for: $0)?.outputsPerMinute[r] ?? 0) + (game.civicDefinition(for: $0)?.culturalOutputPerMinute[r] ?? 0)) > 0 }
        if let producer = matching.first {
            if !game.isServiceOperational(producer) {
                return advice("Connect " + config.definition(producer.kind).name, "Open this building and connect paths to the civic center. It uses no workers or inputs while disconnected. Moving it to reachable land is free.", .inspect(producer.id))
            }
            let inputs = game.recipe(for: producer)?.inputsPerMinute ?? ResourceAmounts()
            for input in Resource.allCases where inputs[input] > 0 && game.state.resources[input] < 1 && net[input] <= 0 { return resource(input, target: max(1, inputs[input])) }
            if let depositResource = game.recipe(for: producer)?.depositResource, !game.discoveredRequiredResources.contains(depositResource) { return discover(depositResource) }
            if let altered = game.state.buildings.first(where: { $0.isOperational && game.workersRequired(for: $0) > 0 && ($0.workerPriority ?? 1) != 1 }) {
                return advice("Balance worker priorities", "Set " + config.definition(altered.kind).name + " to Normal priority. High priorities can starve other production; food and water retain a protected share.", .priority(altered.id, 1))
            }
            if game.workforceProductivity(producer) == 0 {
                return advice("Staff " + config.definition(producer.kind).name, "Set this building to High priority to restore its output. Other buildings may slow down; more inhabitants provide more workers.", .priority(producer.id, 2))
            }
        }
        if let depositResource = recipe.depositResource, !game.discoveredRequiredResources.contains(depositResource) { return discover(depositResource) }
        if !game.isUnlocked(source.kind) { return build(source.kind) }
        if matching.isEmpty {
            // Prefer dedicated suppliers; reuse an existing selectable mode if a duplicate cannot safely be funded.
            if let idleMode = game.state.buildings.reversed().first(where: { b in
                guard b.kind == source.kind && b.isOperational, let current = game.recipe(for: b), current.id != recipe.id else { return false }
                return game.state.buildings.filter { $0.kind == b.kind && $0.isOperational && game.recipe(for: $0)?.id == current.id }.count > 1 || !game.canAfford(source.cost) || game.bootstrapRequirement(for: source.cost, constructing: source.kind) != nil
            }) {
                return advice("Choose " + recipe.name, "Inspect " + source.name + " and select the “" + recipe.name + "” production mode to make " + name(r) + ". Separate gatherers can keep stone, flint and clay flowing together.", .recipe(idleMode.id, recipe.id))
            }
        }
        return build(source.kind, reason: "This producer supplies " + name(r) + ". ")
    }
    mutating func discover(_ r: Resource) -> SettlementGuidance {
        for deposit in game.discoveredDeposits where deposit.resource == r && !game.isIdentified(deposit) {
            if let id = deposit.requiredTechnology { return research(id) }
        }
        return explore()
    }
    mutating func explore() -> SettlementGuidance {
        guard enter("explore"), let rules = config.explorationRules else { return help }
        if let seconds = game.state.explorationRemainingSeconds {
            return advice("Wait for the expedition", "The expedition will reveal more land when it returns. You can build or research meanwhile; a full map is not required for readiness.", .explore, wait: seconds)
        }
        if (game.state.explorationRadius ?? rules.initialRadius) + rules.revealRadiusStep > rules.requiresScoutAfterRadius && !game.state.buildings.contains(where: { $0.kind == .scoutCamp && game.isServiceOperational($0) }) { return build(.scoutCamp) }
        if let missing = Resource.allCases.first(where: { game.state.resources[$0] < rules.cost[$0] }) { return resource(missing, target: rules.cost[missing]) }
        return advice("Send an expedition", "Open Explore and send an expedition to reveal the next ring. Discover required resource territories and the security pillar's territory target; you do not need every map tile or future-era resources.", .explore)
    }
    mutating func grow() -> SettlementGuidance {
        switch game.growthStatus {
        case .housingFull: return build(.hut, reason: "More free housing lets the population grow. ")
        case .foodReserve: return resource(.food, target: config.populationRules?.minimumFoodForGrowth ?? 20)
        case .foodDeficit: return resource(.food, target: game.state.resources.food + 1, minimumNet: 0.01)
        case .waterReserve: return resource(.water, target: config.workforceRules?.minimumWaterForGrowth ?? 10)
        case .waterDeficit: return resource(.water, target: game.state.resources[.water] + 1, minimumNet: 0.01)
        case .growing: return advice("Let the settlement grow", "Free housing, food and water are available. Growth increases your workforce; inspect Population for the current conditions and timer.", .population, wait: max(1, game.growthIntervalSeconds - (game.state.populationGrowthSeconds ?? 0)))
        case .disabled: return help
        }
    }
}
