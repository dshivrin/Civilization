import Foundation
import Testing
import GameCore
import GameApplication

private func connectionBuilding(_ id: Int, _ kind: BuildingKind, _ x: Int, _ y: Int, level: Int = 1) -> PlacedBuilding {
    var building = PlacedBuilding(id: id, kind: kind, origin: Tile(x: x, y: y))
    building.upgradeLevel = level
    return building
}

private func connectionBuilding(_ id: Int, _ x: Int, _ y: Int, level: Int = 1) -> PlacedBuilding {
    connectionBuilding(id, .hut, x, y, level: level)
}

@Test func visualConnectionsJoinCardinalMixedLevelHomesOnce() throws {
    let configuration = try GameConfiguration.bundled()
    let buildings = [connectionBuilding(7, 6, 4, level: 3), connectionBuilding(2, 4, 4)]
    let edges = BuildingVisualConnections.segments(buildings: buildings, configuration: configuration, discovered: nil)
    #expect(edges.count == 2)
    #expect(edges.allSatisfy { $0.family == .housing && $0.firstBuildingID == 2 && $0.secondBuildingID == 7 })
    #expect(edges.map(\.tile) == [Tile(x: 5, y: 4), Tile(x: 5, y: 5)])
    #expect(edges.allSatisfy { $0.direction == .east })
}

@Test func visualConnectionsRejectCornersGapsAndUnrelatedFamilies() throws {
    let configuration = try GameConfiguration.bundled()
    let home = connectionBuilding(1, 4, 4)
    for neighbor in [connectionBuilding(2, 6, 6), connectionBuilding(2, 7, 4), connectionBuilding(2, .storehouse, 6, 4), connectionBuilding(2, .healersHut, 6, 4)] {
        #expect(BuildingVisualConnections.segments(buildings: [home, neighbor], configuration: configuration, discovered: nil).isEmpty)
    }
}

@Test func visualConnectionsJoinStorageAcrossLevelsWithoutGameplayRules() throws {
    let configuration = try GameConfiguration.bundled()
    let buildings = [connectionBuilding(1, .storehouse, 4, 4, level: 1), connectionBuilding(2, .storehouse, 4, 6, level: 3)]
    let edges = BuildingVisualConnections.segments(buildings: buildings, configuration: configuration, discovered: nil)
    #expect(edges.count == 2)
    #expect(edges.allSatisfy { $0.family == .storage && $0.direction == .south })
}

@Test func visualConnectionsHideIncompleteFoggedAndMovingBuildings() throws {
    let configuration = try GameConfiguration.bundled()
    let a = connectionBuilding(1, 4, 4)
    var b = connectionBuilding(2, 6, 4)
    let discovered = Set(a.tiles(in: configuration) + b.tiles(in: configuration))
    #expect(BuildingVisualConnections.segments(buildings: [a, b], configuration: configuration, discovered: discovered).count == 2)
    #expect(BuildingVisualConnections.segments(buildings: [a, b], configuration: configuration, discovered: discovered.subtracting([Tile(x: 7, y: 5)])).isEmpty)
    #expect(BuildingVisualConnections.segments(buildings: [a, b], configuration: configuration, discovered: nil, excludingIDs: [2]).isEmpty)
    b.constructionRemainingSeconds = 1
    #expect(BuildingVisualConnections.segments(buildings: [a, b], configuration: configuration, discovered: nil).isEmpty)
}

@Test func visualConnectionsHonorCapturedOrientedFootprints() throws {
    let configuration = try GameConfiguration.bundled()
    var a = connectionBuilding(1, 4, 4)
    a.footprint = BuildingFootprint(width: 3, height: 2)
    a.orientation = .east
    let b = connectionBuilding(2, 6, 5)
    let edges = BuildingVisualConnections.segments(buildings: [a, b], configuration: configuration, discovered: nil)
    #expect(edges.map(\.tile) == [Tile(x: 5, y: 5), Tile(x: 5, y: 6)])
}

@Test func visualConnectionsAreStableBoundedAndReadOnly() throws {
    let configuration = try GameConfiguration.bundled()
    let buildings = [connectionBuilding(8, 6, 4), connectionBuilding(2, 4, 4), connectionBuilding(4, 4, 6), connectionBuilding(9, 6, 6)]
    let encoded = try JSONEncoder().encode(buildings)
    let edges = BuildingVisualConnections.segments(buildings: buildings, configuration: configuration, discovered: nil)
    #expect(edges.count == 8)
    #expect(edges == BuildingVisualConnections.segments(buildings: buildings.reversed(), configuration: configuration, discovered: nil))
    #expect(Array(edges.prefix(3)) == BuildingVisualConnections.segments(buildings: buildings, configuration: configuration, discovered: nil, maximumSegments: 3))
    #expect(BuildingVisualConnections.segments(buildings: buildings, configuration: configuration, discovered: nil, maximumSegments: 0).isEmpty)
    #expect(try JSONDecoder().decode([PlacedBuilding].self, from: encoded) == buildings)
}

@Test func visualConnectionsRejectInvalidAndAmbiguousSnapshots() throws {
    let configuration = try GameConfiguration.bundled()
    let a = connectionBuilding(1, 4, 4), b = connectionBuilding(2, 6, 4)
    for footprint in [BuildingFootprint(width: 0, height: 2), .init(width: Int.max, height: 2)] {
        var invalid = a; invalid.footprint = footprint
        #expect(BuildingVisualConnections.segments(buildings: [invalid, b], configuration: configuration, discovered: nil).isEmpty)
    }
    #expect(BuildingVisualConnections.segments(buildings: [a, b, connectionBuilding(3, .storehouse, 6, 4)], configuration: configuration, discovered: nil).isEmpty)
    #expect(BuildingVisualConnections.segments(buildings: [a, b, a], configuration: configuration, discovered: nil).isEmpty)
}
