#if DEBUG
import Foundation
import GameCore

/// Disposable, deterministic fixtures. All placements and upgrades use real commands.
public enum DeveloperScenario: String, CaseIterable, Identifiable, Codable, Sendable {
    case early, developed, late, grouped
    public var id: String { rawValue }
    public var title: String {
        switch self { case .early: "Early settlement"; case .developed: "Developed settlement"; case .late: "Late Stone Age"; case .grouped: "Large grouped village (64×48)" }
    }
    func configuration(from base: GameConfiguration) throws -> GameConfiguration {
        let legacy = try base.isRiverbendPlayer ? GameConfiguration.bundled() : base
        return self == .grouped ? try GroupedDeveloperVillage.configuration(from: legacy) : legacy
    }
    public func makeEngine(configuration: GameConfiguration, now: Date) throws -> GameEngine {
        let configuration = try configuration.isRiverbendPlayer ? GameConfiguration.bundled() : configuration
        if self == .grouped { return try GroupedDeveloperVillage.makeEngine(from: configuration, now: now) }
        var engine = try GameEngine(configuration: configuration, now: now)
        func refill() { engine.developerAddResources(1_000_000) }
        func place(_ kind: BuildingKind, level: Int = 1) throws {
            refill()
            let tiles = (0..<configuration.map.height).flatMap { y in (0..<configuration.map.width).map { Tile(x: $0, y: y) } }
                .sorted { a,b in
                    let da = abs(a.x-configuration.map.campfire.x) + abs(a.y-configuration.map.campfire.y)
                    let db = abs(b.x-configuration.map.campfire.x) + abs(b.y-configuration.map.campfire.y)
                    return da == db ? (a.y == b.y ? a.x < b.x : a.y < b.y) : da < db
                }
            guard let tile = tiles.first(where: { engine.placementIssue(kind, at: $0) == nil }) else { throw GameError.placement("Scenario has no valid location for \(kind.rawValue).") }
            try engine.build(kind, at: tile)
            let id = engine.state.buildings.last!.id
            // Only finish this construction; growth is deliberately paused by full housing until huts exist.
            let seconds = engine.state.buildings.last!.constructionRemainingSeconds ?? 0
            engine.advance(to: engine.state.lastUpdated.addingTimeInterval(seconds))
            for _ in 1..<level { refill(); try engine.upgrade(buildingID: id) }
        }
        refill()
        if self == .early {
            for kind: BuildingKind in [.gatheringShelter, .woodcutter, .stoneGatherer, .hut] { try place(kind) }
        } else {
            let techs = self == .late ? configuration.technologyDefinitions.filter { $0.id != "fortification" }.map(\.id) :
                ["oralTradition", "stoneTools", "socialOrder", "hunting", "fishing", "leatherworking", "pottery", "exploration"]
            for id in techs { try engine.developerUnlockTechnology(id) }
            if configuration.civicLevels != nil { refill(); try engine.upgrade(buildingID: 0); refill(); try engine.upgrade(buildingID: 0) }
            engine.developerRevealTerritory(radius: self == .late ? 32 : 14)
            // Place water-dependent buildings before the central clearing fills.
            if self == .late { try place(.fishingShelter) }
            for kind: BuildingKind in [.fishingShelter, .fishingShelter, .gatheringShelter, .gatheringShelter, .woodcutter, .woodcutter, .stoneGatherer, .stoneGatherer, .stoneGatherer, .huntingLodge, .toolmaker, .tannery, .potteryWorkshop, .storytellingCircle, .storehouse] { try place(kind) }
            let gatherers = engine.state.buildings.filter { $0.kind == .stoneGatherer }
            for (building, resource) in zip(gatherers.dropFirst(), [Resource.flint, .clay]) {
                if let recipe = configuration.definition(.stoneGatherer).recipes?.first(where: { $0.outputsPerMinute[resource] > 0 }) {
                    try engine.setProductionMode(buildingID: building.id, recipeID: recipe.id)
                }
            }
            if self == .late {
                for kind: BuildingKind in [.shrine, .scoutCamp, .watchtower, .farm, .animalPen, .healersHut, .burialGround] { try place(kind) }
            }
            for _ in 0..<(self == .late ? 4 : 2) { try place(.hut, level: 3) }
            // Capture legitimate population readiness at a supported population before loading a stress-test population.
            engine.developerAddPopulation(max(0, 10 - engine.state.population))
            refill()
            engine.developerAddPopulation(max(0, (self == .late ? 60 : 24) - engine.state.population))
            if let building = engine.state.buildings.first(where: { $0.kind == .toolmaker }) {
                try engine.setWorkerPriority(buildingID: building.id, priority: 2)
            }
        }
        refill()
        engine.developerRebaseClock(to: now)
        return try GameEngine(state: engine.state, configuration: configuration)
    }
}
#endif
