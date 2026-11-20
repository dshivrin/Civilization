import Foundation

public struct MapDefinition: Codable, Sendable {
    public var id: String
    public var width: Int
    public var height: Int
    public var rows: [String]
    public var campfire: Tile
    public func contains(_ tile: Tile) -> Bool { (0..<width).contains(tile.x) && (0..<height).contains(tile.y) }
    public func terrain(at tile: Tile) -> Terrain? {
        guard contains(tile) else { return nil }
        return Terrain(rawValue: Array(rows[tile.y])[tile.x])
    }
}
public struct GameConfiguration: Codable, Sendable {
    /// The farthest logical map corner, independent of build configuration.
    public var maximumExplorationRadius: Int {
        max(32, map.campfire.x, map.width - 1 - map.campfire.x, map.campfire.y, map.height - 1 - map.campfire.y)
    }
    /// Private compatibility data for validating development progress before the additive transition.
    public static func legacyDevelopment() throws -> GameConfiguration {
        let url = Bundle.module.url(forResource: "development-32x24", withExtension: "json")!
        let c = try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
        try c.validate()
        return c
    }
    public var resourceCap: Double
    public var offlineCapSeconds: Double
    public var initialResources: ResourceAmounts
    public var initialPopulation: Int
    public var constructionGoalWoodReward: Double
    public var knowledgeGoalUnits: Double
    public var researchCost: ResourceAmounts
    public var buildings: [BuildingDefinition]
    public var map: MapDefinition
    public var resourceCaps: ResourceAmounts?
    public var populationRules: PopulationRules?
    public var technologies: [TechnologyDefinition]?
    public var requiresCompleteStoneAgeCatalog: Bool?
    public var protectBootstrapMaterials: Bool?
    public var progressionGoals: [PillarGoalDefinition]?
    public var explorationRules: ExplorationRules?
    public var workforceRules: WorkforceRules?
    public var economyRules: EconomyRules?
    public var naturalDeposits: [NaturalDeposit]?
    public var civicLevels: [CivicLevelDefinition]?
    public static func bundled() throws -> GameConfiguration {
        guard let url = Bundle.module.url(forResource: "seed", withExtension: "json") else { throw GameError.invalidConfiguration("Missing seed.json") }
        let config = try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
        try config.validate()
        return config
    }
    public func definition(_ kind: BuildingKind) -> BuildingDefinition {
        // validate() guarantees exactly one definition for every kind.
        buildings.first { $0.kind == kind }!
    }
    public func validate() throws {
        func require(_ condition: Bool, _ reason: String) throws { if !condition { throw GameError.invalidConfiguration(reason) } }
        try require(resourceCap.isFinite && resourceCap > 0 && offlineCapSeconds.isFinite && offlineCapSeconds >= 0, "Invalid capacities or seconds")
        try require(initialPopulation >= 0 && constructionGoalWoodReward.isFinite && constructionGoalWoodReward >= 0 && knowledgeGoalUnits > 0 && knowledgeGoalUnits <= baseCapacities.knowledge, "Invalid population or goals")
        try require(Set(buildings.map(\.kind)).count == buildings.count && Set([BuildingKind.campfire, .hut, .gatheringShelter, .woodcutter, .stoneGatherer, .storytellingCircle]).isSubset(of: Set(buildings.map(\.kind))) && (economyRules == nil || buildings.count == BuildingKind.allCases.count), "Building definitions must be complete and unique")
        for amounts in [initialResources, researchCost] + buildings.flatMap({ [$0.cost, $0.ratesPerMinute] }) {
            try require(Resource.allCases.allSatisfy { amounts[$0].isFinite && amounts[$0] >= 0 }, "Amounts must be finite nonnegative units")
        }
        try require(Resource.allCases.allSatisfy { initialResources[$0] <= baseCapacities[$0] }, "Initial resource exceeds capacity")
        var supportedDimensions = (map.width == 32 && map.height == 24) || (map.id == "river-clearing-64x48-v1" && map.width == 64 && map.height == 48)
        #if DEBUG
        supportedDimensions = supportedDimensions || (map.id == "river-clearing-review-64x48-v1" && map.width == 64 && map.height == 48)
        #endif
        try require(supportedDimensions && map.rows.count == map.height && !map.id.isEmpty, "Invalid seed map dimensions or identity")
        try require(map.rows.allSatisfy { $0.count == map.width && $0.allSatisfy { Terrain(rawValue: $0) != nil } }, "Invalid terrain rows")
        for b in buildings {
            let orientations = b.resolvedOrientations
            try require(!orientations.isEmpty && orientations.contains(.north) && Set(orientations).count == orientations.count, "Invalid building orientations")
            try require(orientations.allSatisfy { o in
                let size = b.footprint.oriented(o)
                return size.width <= map.width && size.height <= map.height
            }, "Oriented footprint exceeds map")
            try require(b.kind != .campfire || civicLevels != nil || orientations == [.north], "Campfire cannot rotate")
            try require(b.width > 0 && b.height > 0 && b.width <= map.width && b.height <= map.height && b.housing >= 0 && !b.assetKey.isEmpty && !b.name.isEmpty, "Invalid building footprint or metadata")
        }
        try require(definition(.campfire).width == 1 && definition(.campfire).height == 1 && !definition(.campfire).requiresResearch, "Campfire must occupy one tile")
        try require(map.terrain(at: map.campfire) == .clearing, "Campfire must start on a clearing")
        try validateFoundation()
        try validateEconomy()
        try validateWorkforce()
        try validateExploration()
        try validateProgression()
        try validateCivicLevels()
    }
}
