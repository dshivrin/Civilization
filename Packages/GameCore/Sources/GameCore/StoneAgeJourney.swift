import Foundation

/// A measurable objective. Totals always come from the active catalog or retained pillar rules.
public struct JourneyObjective: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let completed: Int
    public let total: Int
    public var isComplete: Bool { completed >= total }
    public var progress: String { "\(completed)/\(total)" }
}
public struct JourneyChapter: Identifiable, Sendable {
    public let id: Int
    public let title: String
    public let objectives: [JourneyObjective]
    public var completedCount: Int { objectives.filter(\.isComplete).count }
    public var isComplete: Bool { objectives.allSatisfy(\.isComplete) }
}
public extension GameEngine {
    var constructedKinds: Set<BuildingKind> { Set(state.buildings.filter(\.isOperational).map(\.kind)) }
    /// Current-era extraction recipes define the resource scope, not all map markers.
    var requiredDiscoveryResources: Set<Resource> {
        Set(configuration.buildings.flatMap { ($0.recipes ?? []).compactMap(\.depositResource) })
    }
    var discoveredRequiredResources: Set<Resource> {
        Set(discoveredDeposits.compactMap { deposit in
            guard isIdentified(deposit), let resource = deposit.resource,
                  requiredDiscoveryResources.contains(resource) else { return nil }
            return resource
        })
    }
    var stoneAgeRequirements: [JourneyObjective] {
        let kinds = Set(configuration.buildings.map(\.kind))
        let technologies = Set(configuration.technologyDefinitions.map(\.id))
        return [
            JourneyObjective(id: "buildings", title: "Construct every Stone Age building type", completed: constructedKinds.intersection(kinds).count, total: kinds.count),
            JourneyObjective(id: "research", title: "Research every Stone Age technology", completed: researchedIDs.intersection(technologies).count, total: technologies.count),
            JourneyObjective(id: "discovery", title: "Discover Stone Age resource territories", completed: discoveredRequiredResources.count, total: requiredDiscoveryResources.count),
            JourneyObjective(id: "pillars", title: "Complete all five development pillars", completed: pillarGoals.filter { isPillarGoalComplete(id: $0.id) }.count, total: pillarGoals.count)
        ]
    }
    var fullStoneAgeRequirementsMet: Bool { stoneAgeRequirements.allSatisfy(\.isComplete) }
    var missingDiscoveryResourceNames: [String] {
        Resource.allCases.filter { requiredDiscoveryResources.contains($0) && !discoveredRequiredResources.contains($0) }.map(\.rawValue)
    }
    var journeyChapters: [JourneyChapter] {
        func building(_ kind: BuildingKind) -> JourneyObjective {
            JourneyObjective(id: "building-" + kind.rawValue, title: "Build " + configuration.definition(kind).name,
                             completed: constructedKinds.contains(kind) ? 1 : 0, total: 1)
        }
        func technology(_ id: String) -> JourneyObjective? {
            guard let definition = configuration.technologyDefinitions.first(where: { $0.id == id }) else { return nil }
            return JourneyObjective(id: "technology-" + id, title: "Research " + definition.name, completed: researchedIDs.contains(id) ? 1 : 0, total: 1)
        }
        func chapter(_ id: Int, _ title: String, _ kinds: [BuildingKind], _ techs: [String]) -> JourneyChapter {
            JourneyChapter(id: id, title: title, objectives: kinds.filter { kind in configuration.buildings.contains { $0.kind == kind } }.map(building) + techs.compactMap(technology))
        }
        var result = [
            chapter(1, "Founding a settlement", [.gatheringShelter, .woodcutter, .hut], ["oralTradition"]),
            chapter(2, "Mastering nature", [.stoneGatherer, .huntingLodge, .fishingShelter], ["hunting", "fishing", "naturalKnowledge"]),
            chapter(3, "Establishing agriculture", [.farm, .animalPen], ["cultivation", "animalDomestication", "foodPreservation"]),
            chapter(4, "Developing craftsmanship", [.toolmaker, .tannery, .potteryWorkshop, .storehouse], ["stoneTools", "leatherworking", "pottery", "construction", "basketry"]),
            chapter(5, "Building a society", [.storytellingCircle, .shrine, .healersHut, .burialGround], ["socialOrder", "rituals", "permanentSettlement", "herbalMedicine", "burialTraditions"]),
            chapter(6, "Exploring and protecting", [.scoutCamp, .watchtower, .palisade], ["exploration", "surveillance", "fortification"])
        ]
        // The original knowledge milestone is sticky in completedGoals; spending it never revokes credit.
        let knowledge = JourneyObjective(id: "onboarding-knowledge", title: "Accumulate \(Int(configuration.knowledgeGoalUnits)) knowledge", completed: state.completedGoals.contains(.knowledge) ? Int(configuration.knowledgeGoalUnits) : min(Int(state.resources.knowledge), Int(configuration.knowledgeGoalUnits)), total: Int(configuration.knowledgeGoalUnits))
        result[4] = JourneyChapter(id: 5, title: result[4].title, objectives: result[4].objectives + [knowledge])
        result.append(JourneyChapter(id: 7, title: "Completing the Stone Age", objectives: stoneAgeRequirements))
        return result
    }
}
