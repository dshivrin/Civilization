import Foundation

public struct PillarGoalDefinition: Codable, Identifiable, Sendable {
    public var id: String
    public var title: String
    public var pillar: DevelopmentPillar
    public var requiredBuildings: [BuildingKind]
    public var requiredTechnologies: [String]
    public var minimumPopulation: Int
    public var minimumResources: ResourceAmounts
    public var minimumDiscoveredTiles: Int
    public var minimumNetRates: ResourceAmounts
    public var requiredCivicLevel: Int?
}
public extension GameEngine {
    var pillarGoals: [PillarGoalDefinition] { configuration.progressionGoals ?? [] }
    func isPillarGoalComplete(id:String) -> Bool { state.completedPillarGoals?.contains(id) ?? false }
    func pillarGoalProgress(id:String) -> String {
        guard let goal = pillarGoals.first(where: { $0.id == id }) else { return "Unknown goal" }
        if isPillarGoalComplete(id:id) { return "Complete" }
        return unmetRequirements(goal).joined(separator:" · ")
    }
    func unmetRequirements(_ goal:PillarGoalDefinition) -> [String] {
        var missing: [String] = []
        if let level = goal.requiredCivicLevel, civicLevel < level {
            missing.append("Upgrade civic center to " + (configuration.civicLevels?.first { $0.level == level }?.name ?? "level \(level)"))
        }
        for kind in goal.requiredBuildings where !state.buildings.contains(where: { $0.kind == kind && $0.isOperational }) {
            missing.append("Build " + configuration.definition(kind).name)
        }
        for id in goal.requiredTechnologies where !researchedIDs.contains(id) {
            missing.append("Research " + configuration.technologyDefinitions.first { $0.id == id }!.name)
        }
        if state.population < goal.minimumPopulation { missing.append("Population \(state.population)/\(goal.minimumPopulation)") }
        if discoveredTileCount < goal.minimumDiscoveredTiles { missing.append("Discover \(discoveredTileCount)/\(goal.minimumDiscoveredTiles) tiles") }
        for r in Resource.allCases where state.resources[r] + 1e-9 < goal.minimumResources[r] {
            missing.append("\(r.rawValue): \(Int(state.resources[r]))/\(Int(goal.minimumResources[r]))")
        }
        let net = rates
        for r in Resource.allCases where goal.minimumNetRates[r] > 0 && net[r] + 1e-9 < goal.minimumNetRates[r] {
            missing.append("Need +\(goal.minimumNetRates[r]) \(r.rawValue)/min net")
        }
        return missing
    }
}
public extension GameConfiguration {
    func validateProgression() throws {
        func require(_ value:Bool,_ reason:String) throws { if !value { throw GameError.invalidConfiguration(reason) } }
        guard let goals = progressionGoals else { return }
        try require(explorationRules != nil && goals.count == 5 && Set(goals.map(\.id)).count == 5 && Set(goals.map(\.pillar)) == Set(DevelopmentPillar.allCases), "Progression needs one goal per pillar")
        for goal in goals {
            try require(!goal.id.isEmpty && !goal.title.isEmpty && (0...768_000_000).contains(goal.minimumPopulation) && (0...768).contains(goal.minimumDiscoveredTiles), "Invalid pillar goal")
            try require(Set(goal.requiredBuildings).count == goal.requiredBuildings.count && goal.requiredBuildings.allSatisfy { kind in buildings.contains { $0.kind == kind } }, "Unknown or duplicate goal building")
            try require(Set(goal.requiredTechnologies).count == goal.requiredTechnologies.count && goal.requiredTechnologies.allSatisfy { id in technologyDefinitions.contains { $0.id == id } }, "Unknown or duplicate goal technology")
            try require(Resource.allCases.allSatisfy { goal.minimumResources[$0].isFinite && goal.minimumResources[$0] >= 0 && goal.minimumResources[$0] <= 1_000_000 && goal.minimumNetRates[$0].isFinite && (0...1_000_000).contains(goal.minimumNetRates[$0]) }, "Invalid pillar thresholds")
        }
    }
}
