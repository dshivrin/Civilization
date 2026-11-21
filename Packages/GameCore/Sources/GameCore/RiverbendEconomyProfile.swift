#if DEBUG
import Foundation

public extension GameConfiguration {
    static let riverbendLabID = "riverbend-economy-lab-v1"
    var isRiverbendEconomyLab: Bool { map.id == Self.riverbendLabID }
    /// Review profile only. Seed terrain, original definitions and player saves are never edited.
    static func riverbendEconomyLab() throws -> Self {
        var c = try bundled()
        c.map.id = riverbendLabID
        c.initialPopulation = 3
        c.initialResources = ResourceAmounts(food: 32, wood: 32)
        c.resourceCaps = ResourceAmounts(repeating: 24)
        c.resourceCaps?.food = 60; c.resourceCaps?.wood = 60; c.resourceCaps?.stone = 40
        c.resourceCaps?.knowledge = 60
        c.constructionGoalWoodReward = 0
        c.protectBootstrapMaterials = false
        c.civicLevels = nil; c.progressionGoals = nil
        c.populationRules = PopulationRules(foodPerPersonPerMinute: 1, growthIntervalSeconds: 240, minimumFoodForGrowth: 20)
        c.workforceRules = WorkforceRules(workingPopulationFraction: 0.7, survivalReserveFraction: 1, waterPerPersonPerMinute: 0, minimumWaterForGrowth: 0)
        c.explorationRules?.initialKnownDepositIDs = []
        c.explorationRules?.durationSeconds = 60
        c.explorationRules?.cost = ResourceAmounts(food: 8)
        for i in c.buildings.indices {
            c.buildings[i].ratesPerMinute = .init()
            c.buildings[i].recipes = nil; c.buildings[i].maintenancePerMinute = nil
            c.buildings[i].geographicBonus = nil; c.buildings[i].storageBonus = nil
            c.buildings[i].workersRequired = 0
            switch c.buildings[i].kind {
            case .campfire:
                c.buildings[i].allowedOrientations = [.north]
                c.buildings[i].housing = 3; c.buildings[i].ratesPerMinute.food = 2
            case .hut:
                c.buildings[i].cost = ResourceAmounts(wood: 12); c.buildings[i].housing = 3
                c.buildings[i].requiresResearch = false
            case .gatheringShelter:
                c.buildings[i].cost = ResourceAmounts(wood: 8); c.buildings[i].ratesPerMinute.food = 8
                c.buildings[i].workersRequired = 1; c.buildings[i].requiresResearch = false
            case .woodcutter:
                c.buildings[i].cost = ResourceAmounts(wood: 4); c.buildings[i].ratesPerMinute.wood = 6
                c.buildings[i].workersRequired = 1; c.buildings[i].requiresResearch = false
                c.buildings[i].requiredNearbyTerrain = "f"; c.buildings[i].nearbyTerrainRadius = 1
            case .stoneGatherer:
                c.buildings[i].cost = ResourceAmounts(wood: 10); c.buildings[i].ratesPerMinute.stone = 5
                c.buildings[i].workersRequired = 1; c.buildings[i].requiresResearch = false
                c.buildings[i].requiredNearbyTerrain = nil
            case .storehouse:
                c.buildings[i].cost = ResourceAmounts(wood: 18, stone: 6)
                c.buildings[i].requiresResearch = false
            default: break
            }
        }
        try c.validate()
        return c
    }
}
#endif
