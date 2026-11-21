import Foundation

/// Catalog-authored civic level. Costs purchase this level; output is a total, not a bonus.
public struct CivicLevelDefinition: Codable, Sendable {
    public var level: Int
    public var name: String
    public var requiredTechnology: String?
    public var cost: ResourceAmounts
    public var culturalOutputPerMinute: ResourceAmounts
    public var workersRequired: Double
}

/// Additive achievement witnesses. These never replace or convert a player's buildings.
public struct CivicProgress: Codable, Equatable, Sendable {
    public var foundingBuildingID: Int
    public var reachedLevels: [Int]
    public var completedChapters: Set<Int>
    /// Chapter-qualified objective IDs retain old predicates without confusing similarly named checks.
    public var completedObjectives: Set<String>
    public init(foundingBuildingID: Int, reachedLevels: [Int] = [1], completedChapters: Set<Int> = [], completedObjectives: Set<String> = []) {
        self.foundingBuildingID = foundingBuildingID
        self.reachedLevels = reachedLevels
        self.completedChapters = completedChapters
        self.completedObjectives = completedObjectives
    }
}

public extension GameConfiguration {
    /// The historical rules are only used to validate and snapshot pre-civic achievements.
    var beforeCivicEvolution: GameConfiguration {
        var copy = self
        copy.civicLevels = nil
        if let index = copy.buildings.firstIndex(where: { $0.kind == .campfire }) {
            copy.buildings[index].allowedOrientations = nil // Historical civic anchor supported north only.
        }
        for index in copy.progressionGoals?.indices ?? 0..<0 {
            if copy.progressionGoals![index].requiredCivicLevel != nil {
                copy.progressionGoals![index].requiredCivicLevel = nil
                if !copy.progressionGoals![index].requiredBuildings.contains(.storytellingCircle) {
                    copy.progressionGoals![index].requiredBuildings.insert(.storytellingCircle, at: 0)
                }
            }
        }
        return copy
    }
    /// Existing civic history semantics; the isolated founding review has its own objective.
    internal var civicSharesLegacyStorytellingCredit: Bool {
        #if DEBUG
        if isRiverbendFoundingReview { return false }
        #endif
        return true
    }
    private func permitsFreeFoundingResearch(_ level: CivicLevelDefinition) -> Bool {
        #if DEBUG
        return isRiverbendFoundingReview && level.level == 2 && level.requiredTechnology == nil
        #else
        return false
        #endif
    }
    func validateCivicLevels() throws {
        guard let levels = civicLevels else { return }
        guard economyRules != nil, levels.map(\.level) == [1, 2, 3],
              levels.allSatisfy({ level in
                  !level.name.isEmpty && level.workersRequired.isFinite && (0...100).contains(level.workersRequired) &&
                  (level.level == 1 ? level.requiredTechnology == nil : permitsFreeFoundingResearch(level) || technologyDefinitions.contains { $0.id == level.requiredTechnology }) &&
                  Resource.allCases.allSatisfy { resource in
                      level.cost[resource].isFinite && level.cost[resource] >= 0 && level.cost[resource] <= baseCapacities[resource] &&
                      level.culturalOutputPerMinute[resource].isFinite && level.culturalOutputPerMinute[resource] >= 0 &&
                      ([Resource.knowledge, .culture].contains(resource) || level.culturalOutputPerMinute[resource] == 0)
                  }
              }),
              levels[0].workersRequired == 0,
              Resource.allCases.allSatisfy({ levels[0].cost[$0] == 0 && levels[0].culturalOutputPerMinute[$0] == 0 }),
              progressionGoals?.allSatisfy({ goal in goal.requiredCivicLevel == nil || levels.contains { $0.level == goal.requiredCivicLevel } }) != false else {
            throw GameError.invalidConfiguration("Invalid civic level catalog")
        }
    }
}

public extension GameEngine {
    var civicCenter: PlacedBuilding? { state.buildings.first { $0.kind == .campfire } }
    var civicLevel: Int { civicCenter?.level ?? 1 }
    func civicDefinition(for building: PlacedBuilding) -> CivicLevelDefinition? {
        guard building.kind == .campfire else { return nil }
        return configuration.civicLevels?.first { $0.level == building.level }
    }
    func buildingName(_ building: PlacedBuilding) -> String {
        civicDefinition(for: building)?.name ?? configuration.definition(building.kind).name
    }
    func workersRequired(for building: PlacedBuilding) -> Double {
        civicDefinition(for: building)?.workersRequired ?? configuration.definition(building.kind).workersRequired ?? 0
    }
    func upgradeResearch(for building: PlacedBuilding) -> String? {
        guard building.kind == .campfire else { return nil }
        return configuration.civicLevels?.first { $0.level == building.level + 1 }?.requiredTechnology
    }

    /// Called only after validating the state with the historical configuration.
    static func retainingLegacyCivicProgress(_ legacy: GameEngine) -> GameState {
        var state = legacy.state
        guard let center = legacy.civicCenter else { return state }
        let chapters = legacy.journeyChapters
        state.civicProgress = CivicProgress(foundingBuildingID: center.id, reachedLevels: Array(1...center.level),
            completedChapters: Set(chapters.filter(\.isComplete).map(\.id)),
            completedObjectives: Set(chapters.flatMap { chapter in chapter.objectives.filter(\.isComplete).map { "\(chapter.id):\($0.id)" } }))
        return state
    }
}

extension GameEngine {
    /// Validate credit without consulting the very history being validated.
    func validateCivicAchievementWitnesses() throws {
        guard let history = state.civicProgress else { return }
        let current = unretainedJourneyChapters()
        let previous = unretainedJourneyChapters(legacy: true)
        var witnessed: Set<String> = []
        for chapter in current + previous {
            for objective in chapter.objectives where objective.isComplete {
                witnessed.insert("\(chapter.id):\(objective.id)")
            }
        }
        let priorFounding = previous.first { $0.id == 1 }?.isComplete == true
        let priorCompletion = previous.first { $0.id == 7 }?.isComplete == true
        let priorCircle = witnessed.contains("5:building-storytellingCircle") && state.completedGoals.contains(.storytellingCircle)
        func hasWitness(_ id: String) -> Bool {
            if id == "5:building-storytellingCircle" { return priorCircle }
            if witnessed.contains(id) { return true }
            if id == "1:civic-level-2" { return history.completedChapters.contains(1) && priorFounding }
            if id == "5:civic-level-3" { return priorCircle && history.completedObjectives.contains("5:building-storytellingCircle") }
            if id == "7:civic-level-3" { return history.completedChapters.contains(7) && priorCompletion }
            return false
        }
        guard history.completedObjectives.allSatisfy(hasWitness) else {
            throw GameError.invalidSave("Completed objective has no permanent achievement witness")
        }
        for chapter in current where history.completedChapters.contains(chapter.id) {
            let currentIDs = Set(chapter.objectives.map { "\(chapter.id):\($0.id)" })
            let old = previous.first { $0.id == chapter.id }!
            let oldIDs = Set(old.objectives.map { "\(chapter.id):\($0.id)" })
            let recorded = currentIDs.isSubset(of: history.completedObjectives) || (old.isComplete && oldIDs.isSubset(of: history.completedObjectives))
            guard recorded && chapter.objectives.allSatisfy({ hasWitness("\(chapter.id):\($0.id)") }) else {
                throw GameError.invalidSave("Completed chapter has contradictory objective history")
            }
        }
    }
}
