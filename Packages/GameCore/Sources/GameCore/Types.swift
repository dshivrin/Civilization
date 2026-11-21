import Foundation

public enum Resource: String, Codable, CaseIterable, Sendable { case food, wood, stone, water, flint, clay, animalHides, stoneTools, leather, pottery, knowledge, culture }

/// Material units are fractional Doubles. Only the presentation layer rounds down.
public struct ResourceAmounts: Codable, Equatable, Sendable {
    private var values: [Resource: Double] = [:]
    public init(food: Double = 0, wood: Double = 0, stone: Double = 0, knowledge: Double = 0) {
        values = [.food: food, .wood: wood, .stone: stone, .knowledge: knowledge]
    }
    public static func == (lhs: Self, rhs: Self) -> Bool { Resource.allCases.allSatisfy { lhs[$0] == rhs[$0] } }
    public init(repeating amount: Double) { for r in Resource.allCases { values[r] = amount } }
    public var food: Double { get { self[.food] } set { self[.food] = newValue } }
    public var wood: Double { get { self[.wood] } set { self[.wood] = newValue } }
    public var stone: Double { get { self[.stone] } set { self[.stone] = newValue } }
    public var knowledge: Double { get { self[.knowledge] } set { self[.knowledge] = newValue } }
    public subscript(_ resource: Resource) -> Double {
        get { values[resource, default: 0] }
        set { values[resource] = newValue }
    }
    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode([String: Double].self)
        for (key, amount) in raw {
            guard let resource = Resource(rawValue: key) else {
                throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown resource: \(key)"))
            }
            values[resource] = amount
        }
        for resource in Resource.allCases where values[resource] == nil { values[resource] = 0 }
    }
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(Dictionary(uniqueKeysWithValues: Resource.allCases.map { ($0.rawValue, self[$0]) }))
    }
}
public struct Tile: Codable, Hashable, Sendable {
    public var x: Int
    public var y: Int
    public init(x: Int, y: Int) { self.x = x; self.y = y }
}
public enum Terrain: Character, Sendable { case grass = ".", clearing = "c", forest = "f", water = "w", hill = "h" }
public enum BuildingKind: String, Codable, CaseIterable, Sendable {
    case campfire, hut, gatheringShelter, woodcutter, stoneGatherer, storytellingCircle
    case huntingLodge, fishingShelter, farm, animalPen, storehouse, toolmaker, tannery, potteryWorkshop, healersHut, shrine, burialGround, scoutCamp, watchtower, palisade
}
public struct BuildingDefinition: Codable, Sendable {
    public var kind: BuildingKind
    public var name: String
    public var width: Int
    public var height: Int
    public var allowedOrientations: [BuildingOrientation]?
    public var cost: ResourceAmounts
    public var ratesPerMinute: ResourceAmounts
    public var housing: Int
    public var description: String?
    public var assetKey: String
    public var requiresResearch: Bool
    public var constructionSeconds: Double?
    public var requiredNearbyTerrain: String?
    public var nearbyTerrainRadius: Int?
    public var workersRequired: Double?
    public var survivalProduction: Bool?
    public var category: String?
    public var recipes: [ProductionRecipe]?
    public var maintenancePerMinute: ResourceAmounts?
    public var upgradeCost: ResourceAmounts?
    public var storageBonus: ResourceAmounts?
    public var geographicBonus: GeographicBonus?
    public func tiles(at origin: Tile) -> [Tile] {
        footprint.tiles(at: origin)
    }
}
public struct PlacedBuilding: Codable, Equatable, Identifiable, Sendable {
    public var id: Int
    public var kind: BuildingKind
    public var origin: Tile
    /// Optional for v1–v5 compatibility. New construction captures catalog dimensions.
    public var footprint: BuildingFootprint?
    public var orientation: BuildingOrientation?
    public var constructionRemainingSeconds: Double?
    public var constructionDurationSeconds: Double?
    public var workerPriority: Int?
    public var productionModeID: String?
    public var upgradeLevel: Int?
    public var level: Int { upgradeLevel ?? 1 }
    public var isOperational: Bool { constructionRemainingSeconds == nil }
    public init(id: Int, kind: BuildingKind, origin: Tile) { self.id = id; self.kind = kind; self.origin = origin }
}
public enum Goal: String, Codable, CaseIterable, Sendable {
    case gatheringShelter, woodcutter, hut, stoneGatherer, oralTradition, storytellingCircle, knowledge
    public var title: String {
        switch self {
        case .gatheringShelter: "Build a gathering shelter"
        case .woodcutter: "Build a woodcutter"
        case .hut: "Build a hut"
        case .stoneGatherer: "Build a stone gatherer"
        case .oralTradition: "Research Oral Tradition"
        case .storytellingCircle: "Build a storytelling circle"
        case .knowledge: "Accumulate knowledge"
        }
    }
    public var building: BuildingKind? { BuildingKind(rawValue: rawValue) }
}
public enum SettlementOperatingRules: String, Codable, Sendable {
    case connectedPathsV1
}

public struct GameState: Codable, Equatable, Sendable {
    /// Additive presentation history; absent in pre-cue saves.
    public var completionInbox: CompletionInbox? = nil
    public var riverbend: RiverbendProgress? = nil
    public var mapID: String
    public var resources: ResourceAmounts
    public var population: Int
    public var buildings: [PlacedBuilding]
    public var researchedOralTradition: Bool
    public var completedGoals: Set<Goal>
    public var nextBuildingID: Int
    public var lastUpdated: Date
    public var populationGrowthSeconds: Double?
    public var researchedTechnologies: Set<String>?
    public var completedPillarGoals: Set<String>?
    public var stoneAgeCompleted: Bool?
    public var grandfatheredBuildingKinds: Set<BuildingKind>?
    public var discoveredTiles: Set<Tile>?
    public var explorationRemainingSeconds: Double?
    public var explorationRadius: Int?
    public var depositRemaining: [String: Double]?
    public var roads: [RoadTile]?
    public var civicProgress: CivicProgress?
    /// Absent in legacy games; explicit activation belongs to this save only.
    public var operatingRules: SettlementOperatingRules?
}
public enum GameError: Error, Equatable, LocalizedError, Sendable {
    case invalidConfiguration(String), invalidSave(String), placement(String), researchUnavailable(String), insufficientResources, researchRequired, alreadyResearched, uniqueCampfire
    public var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let reason): "Invalid configuration: \(reason)"
        case .invalidSave(let reason): "Cannot load save: \(reason)"
        case .placement(let reason): reason
        case .researchUnavailable(let reason): reason
        case .insufficientResources: "Not enough resources. Let your settlement produce more."
        case .researchRequired: "Research Oral Tradition first."
        case .alreadyResearched: "This technology is already complete."
        case .uniqueCampfire: "Your settlement already has its campfire."
        }
    }
}
