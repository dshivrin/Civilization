import Foundation
import GameCore

/// Validated v1/v2/v3/v4 -> v5 migration. The filename remains unchanged so installed settlements are found.
public struct SaveStore: Sendable {
    private struct Envelope: Codable { var version: Int; var state: GameState }
    private struct Header: Decodable { var version: Int }
    public let url: URL
    public init(url: URL) { self.url = url }
    public func save(_ state: GameState) throws {
        // A converted development world may replace old bytes only after a verified backup.
        if FileManager.default.fileExists(atPath: url.path), state.mapID == "river-clearing-64x48-v1" {
            let original = try Data(contentsOf: url)
            if let old = try? JSONDecoder().decode(Envelope.self, from: original), old.state.mapID == "river-clearing-v1" {
                _ = try load(configuration: .bundled())
            }
        }
        let data = try JSONEncoder().encode(Envelope(version: 5, state: state))
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: url.path) {
            let original = try Data(contentsOf: url)
            let version = try JSONDecoder().decode(Header.self, from: original).version
            guard (1...5).contains(version) else { throw GameError.invalidSave("Unsupported version \(version)") }
            if version < 5 {
                let suffix = version == 1 ? "seed-0.1.bak" : version == 2 ? "seed-0.2.1.bak" : version == 3 ? "seed-0.2.3.bak" : "seed-0.2.4.bak"
                let backup = url.appendingPathExtension(suffix)
                if !FileManager.default.fileExists(atPath: backup.path) { try original.write(to: backup, options: .atomic) }
            }
        }
        try data.write(to: url, options: .atomic)
    }
    public func load(configuration: GameConfiguration) throws -> GameState? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        let version = try JSONDecoder().decode(Header.self, from: data).version
        guard (1...5).contains(version) else { throw GameError.invalidSave("Unsupported version \(version)") }
        var state = try JSONDecoder().decode(Envelope.self, from: data).state
        if state.mapID == "river-clearing-v1", configuration.map.id == "river-clearing-64x48-v1" {
            let legacy = try GameConfiguration.legacyDevelopment()
            guard let validated = try load(configuration: legacy) else { throw GameError.invalidSave("Missing development world") }
            let backup = url.appendingPathExtension("pre-geography-64x48.bak")
            if !FileManager.default.fileExists(atPath: backup.path) { try data.write(to: backup, options: .atomic) }
            guard try Data(contentsOf: backup) == data else { throw GameError.invalidSave("Development backup differs from the source; original preserved.") }
            state = validated
            state.mapID = configuration.map.id
            // Retain all irregular knowledge; the next expedition expands only the completed square.
            let known = state.discoveredTiles ?? []
            var radius = configuration.explorationRules?.initialRadius ?? 0
            while radius < configuration.maximumExplorationRadius && configuration.tiles(within: radius + 1).isSubset(of: known) { radius += 1 }
            state.explorationRadius = radius
            return try GameEngine(state: state, configuration: configuration).state
        }
        if version == 1 {
            state.researchedTechnologies = state.researchedOralTradition ? ["oralTradition"] : []
            state.populationGrowthSeconds = 0
            for index in state.buildings.indices {
                state.buildings[index].constructionRemainingSeconds = nil
                state.buildings[index].constructionDurationSeconds = nil
            }
        } else if configuration.populationRules != nil || configuration.technologies != nil {
            guard state.populationGrowthSeconds != nil && state.researchedTechnologies != nil else { throw GameError.invalidSave("Missing v2 simulation progress") }
        }
        if configuration.economyRules != nil {
            if version < 3 {
                // Earlier rulesets had no extractable deposit accounting. Existing buildings,
                // resources, construction timers and earned progress remain unchanged.
                state.depositRemaining = Dictionary(uniqueKeysWithValues:
                    (configuration.naturalDeposits ?? []).filter { !$0.renewable }.map { ($0.id, $0.capacity) })
            } else {
                guard state.depositRemaining != nil else { throw GameError.invalidSave("Missing v3 deposit progress") }
            }
        }
        if configuration.explorationRules != nil {
            if version < 4 {
                // All earlier clients displayed the whole handcrafted valley. Preserve
                // that knowledge and every established building rather than re-fogging it.
                state.discoveredTiles = Set((0..<configuration.map.height).flatMap { y in
                    (0..<configuration.map.width).map { x in Tile(x:x,y:y) }
                })
                state.explorationRadius = 32
                state.explorationRemainingSeconds = nil
            } else {
                guard state.discoveredTiles != nil && state.explorationRadius != nil else {
                    throw GameError.invalidSave("Missing v4 exploration progress")
                }
            }
        }
        if configuration.progressionGoals != nil {
            if version < 5 {
                // Preserve established construction knowledge without granting research,
                // production modifiers or achievements that the old client never tracked.
                state.completedPillarGoals = []
                state.stoneAgeCompleted = false
                state.grandfatheredBuildingKinds = Set(state.buildings.map(\.kind))
            } else {
                guard state.completedPillarGoals != nil && state.stoneAgeCompleted != nil && state.grandfatheredBuildingKinds != nil else {
                    throw GameError.invalidSave("Missing v5 progression history")
                }
            }
        }
        return try GameEngine(state: state, configuration: configuration).state
    }
}
