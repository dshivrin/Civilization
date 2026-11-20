import Foundation

public struct ExplorationRules: Codable, Sendable {
    public var initialRadius: Int
    public var revealRadiusStep: Int
    public var durationSeconds: Double
    public var cost: ResourceAmounts
    public var initialKnownDepositIDs: [String]
    public var requiresScoutAfterRadius: Int
}
public extension GameConfiguration {
    var initialDiscoveredTiles: Set<Tile>? {
        guard let rules = explorationRules else { return nil }
        var result = tiles(within:rules.initialRadius)
        for deposit in naturalDeposits ?? [] where rules.initialKnownDepositIDs.contains(deposit.id) {
            // Handcrafted known routes preserve existing deposit locations and expose the bootstrap sources.
            var p = map.campfire
            while p.x != deposit.origin.x { p.x += p.x < deposit.origin.x ? 1 : -1; result.insert(p) }
            while p.y != deposit.origin.y { p.y += p.y < deposit.origin.y ? 1 : -1; result.insert(p) }
        }
        return result
    }
    func tiles(within radius:Int) -> Set<Tile> {
        Set((0..<map.height).flatMap { y in (0..<map.width).compactMap { x in
            max(abs(x-map.campfire.x),abs(y-map.campfire.y)) <= radius ? Tile(x:x,y:y) : nil
        } })
    }
    func validateExploration() throws {
        func require(_ value:Bool,_ reason:String) throws { if !value { throw GameError.invalidConfiguration(reason) } }
        guard let rules = explorationRules else { return }
        try require(economyRules != nil && (1...16).contains(rules.initialRadius) && (1...8).contains(rules.revealRadiusStep) && rules.durationSeconds.isFinite && (1...28800).contains(rules.durationSeconds) && (rules.initialRadius...32).contains(rules.requiresScoutAfterRadius), "Invalid exploration rules")
        try require(Resource.allCases.allSatisfy { rules.cost[$0].isFinite && rules.cost[$0] >= 0 && rules.cost[$0] <= baseCapacities[$0] }, "Invalid exploration cost")
        try require(Set(rules.initialKnownDepositIDs).count == rules.initialKnownDepositIDs.count && rules.initialKnownDepositIDs.allSatisfy { id in (naturalDeposits ?? []).contains { $0.id == id } }, "Unknown starting deposit")
        for b in buildings {
            if let terrain = b.requiredNearbyTerrain { try require(terrain.count == 1 && terrain.first.flatMap(Terrain.init(rawValue:)) != nil && (0...32).contains(b.nearbyTerrainRadius ?? -1), "Invalid terrain restriction") }
        }
        for d in naturalDeposits ?? [] { try require(d.requiredTechnology == nil || !d.requiredTechnology!.isEmpty, "Invalid resource identification technology") }
    }
}
public extension GameEngine {
    func isDiscovered(_ tile:Tile) -> Bool { configuration.map.contains(tile) && (state.discoveredTiles?.contains(tile) ?? true) }
    func isIdentified(_ deposit:NaturalDeposit) -> Bool { deposit.requiredTechnology.map { researchedIDs.contains($0) } ?? true }
    var discoveredTileCount: Int { state.discoveredTiles?.count ?? configuration.map.width * configuration.map.height }
    var discoveredDeposits: [NaturalDeposit] { (configuration.naturalDeposits ?? []).filter { ([$0.origin] + ($0.accessSites ?? [])).contains(where: isDiscovered) } }
    var explorationIssue: GameError? {
        guard let rules = configuration.explorationRules else { return .placement("Exploration is unavailable in this ruleset.") }
        if state.explorationRemainingSeconds != nil { return .placement("An expedition is already underway.") }
        if discoveredTileCount == configuration.map.width * configuration.map.height { return .placement("The entire valley is discovered.") }
        let next = min(configuration.maximumExplorationRadius,(state.explorationRadius ?? rules.initialRadius) + rules.revealRadiusStep)
        if next > rules.requiresScoutAfterRadius && !state.buildings.contains(where: { $0.kind == .scoutCamp && $0.isOperational }) { return .placement("Build a scout camp to explore farther.") }
        return canAfford(rules.cost) ? nil : .insufficientResources
    }
    func hasNearbyTerrain(_ terrain:String,at origin:Tile,radius:Int) -> Bool {
        for y in max(0,origin.y-radius)...min(configuration.map.height-1,origin.y+radius) {
            for x in max(0,origin.x-radius)...min(configuration.map.width-1,origin.x+radius) {
                let tile = Tile(x:x,y:y)
                if isDiscovered(tile) && configuration.map.terrain(at:tile).map({ String($0.rawValue) }) == terrain { return true }
            }
        }
        return false
    }
}

/// Concealment is independent of terrain art and defends partial/corrupt render snapshots.
public enum DiscoveryVisibility {
    public static func isVisible(_ building: PlacedBuilding, in configuration: GameConfiguration, discovered: Set<Tile>?) -> Bool {
        building.tiles(in: configuration).allSatisfy { configuration.map.contains($0) && (discovered?.contains($0) ?? true) }
    }
}
