import Foundation
import Testing
@testable import GameCore
import GamePersistence
import GameApplication

private let geometryEpoch = Date(timeIntervalSince1970: 40_000_000)
private func rectangleConfiguration() throws -> GameConfiguration {
    var c = try GameConfiguration.bundled()
    c.explorationRules = nil; c.workforceRules = nil; c.progressionGoals = nil
    let i = c.buildings.firstIndex { $0.kind == .hut }!
    c.buildings[i].width = 3; c.buildings[i].height = 2
    c.buildings[i].allowedOrientations = [.north, .east, .south, .west]
    return c
}
private func geometrySite(_ g: GameEngine, _ kind: BuildingKind, _ orientation: BuildingOrientation = .north) throws -> Tile {
    try #require((0..<g.configuration.map.height).flatMap { y in (0..<g.configuration.map.width).map { Tile(x: $0, y: y) } }.first { g.placementIssue(kind, at: $0, orientation: orientation) == nil })
}

@Test func rectangularGeometrySwapsAxesAndCentersBothDimensions() {
    let f = BuildingFootprint(width: 3, height: 2)
    #expect(f.oriented(.north) == f)
    #expect(f.oriented(.south) == f)
    #expect(f.oriented(.east) == BuildingFootprint(width: 2, height: 3))
    #expect(f.oriented(.west) == f.oriented(.east))
    #expect(Set(f.tiles(at: Tile(x: 4, y: 7))).count == 6)
    #expect(f.center(at: Tile(x: 4, y: 7)) == WorldPoint(x: -80, y: -200))
    #expect(f.oriented(.east).center(at: Tile(x: 4, y: 7)) == WorldPoint(x: -112, y: -200))
    #expect(BuildingFootprint(width: 2, height: 2).center(at: Tile(x: 4, y: 7)) == WorldPoint(x: -96, y: -192))
}

@Test func rotatedConstructionUsesExactOccupancyAndChargesOnce() throws {
    var g = try GameEngine(configuration: rectangleConfiguration(), now: geometryEpoch)
    let tile = try geometrySite(g, .hut, .east)
    let before = g.state
    try g.build(.hut, at: tile, orientation: .east)
    let b = try #require(g.state.buildings.last)
    #expect(b.footprint == BuildingFootprint(width: 3, height: 2))
    #expect(b.resolvedOrientation == .east)
    #expect(b.occupiedFootprint(in: g.configuration) == BuildingFootprint(width: 2, height: 3))
    for covered in b.tiles(in: g.configuration) { #expect(g.building(at: covered)?.id == b.id) }
    #expect(g.building(at: Tile(x: tile.x + 2, y: tile.y + 2))?.id != b.id)
    #expect(g.state.resources.wood == before.resources.wood - g.configuration.definition(.hut).cost.wood)
    let paid = g.state
    #expect(throws: GameError.self) { try g.build(.hut, at: tile, orientation: .north) }
    #expect(g.state == paid)
    for invalid in [Tile(x: -1,y: 0), Tile(x: 31,y: 23), Tile(x: Int.max,y: Int.min)] {
        #expect(throws: GameError.self) { try g.build(.hut, at: invalid, orientation: .west) }
        #expect(g.state == paid)
    }
}

@Test func rectangularRelocationRotationPreservesProgressAndIsAtomic() throws {
    var g = try GameEngine(configuration: rectangleConfiguration(), now: geometryEpoch)
    let tile = try geometrySite(g, .hut)
    try g.build(.hut, at: tile)
    let id = g.state.buildings.last!.id
    let target = try #require((0..<24).flatMap { y in (0..<32).map { Tile(x: $0,y:y) } }.first { g.relocationIssue(buildingID:id,at:$0,orientation:.east) == nil })
    let before = g.state
    try g.relocate(buildingID:id,to:target,orientation:.east)
    var expected = before; expected.buildings[1].origin = target; expected.buildings[1].orientation = .east
    #expect(g.state == expected)
    let rotated = g.state
    #expect(throws: GameError.self) { try g.relocate(buildingID:id,to:Tile(x:31,y:23),orientation:.north) }
    #expect(g.state == rotated)
    try g.relocate(buildingID:id,to:target)
    #expect(g.state == rotated)
    #expect(throws: GameError.self) { try g.relocate(buildingID:0,to:g.configuration.map.campfire,orientation:.east) }
    #expect(g.state == rotated)
}

@Test func capturedFootprintSurvivesCatalogEditReloadAndRelocation() throws {
    var c = try rectangleConfiguration()
    var g = try GameEngine(configuration:c,now:geometryEpoch)
    let tile = try geometrySite(g,.hut,.east)
    try g.build(.hut,at:tile,orientation:.east)
    let before = g.state
    let i = c.buildings.firstIndex { $0.kind == .hut }!
    c.buildings[i].width = 4; c.buildings[i].height = 4
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at:url) }
    let store = SaveStore(url:url); try store.save(before)
    let loaded = try #require(try store.load(configuration:c))
    #expect(loaded == before)
    g = try GameEngine(state:loaded,configuration:c)
    #expect(g.state.buildings[1].occupiedFootprint(in:c) == BuildingFootprint(width:2,height:3))
    try g.relocate(buildingID:1,to:tile)
    #expect(g.state == before)
    let envelope = try #require(JSONSerialization.jsonObject(with:Data(contentsOf:url)) as? [String:Any])
    #expect(envelope["version"] as? Int == 6)
}

@Test func legacyMissingGeometryKeepsOriginalLayoutAndState() throws {
    var c = try rectangleConfiguration(); let i = c.buildings.firstIndex { $0.kind == .hut }!
    c.buildings[i].width = 2; c.buildings[i].height = 2
    var g = try GameEngine(configuration:c,now:geometryEpoch)
    try g.build(.hut,at:geometrySite(g,.hut))
    var old = g.state; old.buildings[1].footprint = nil; old.buildings[1].orientation = nil
    let decoded = try JSONDecoder().decode(GameState.self,from:JSONEncoder().encode(old))
    #expect(decoded == old)
    g = try GameEngine(state:decoded,configuration:c)
    #expect(g.state == old)
    #expect(g.state.buildings[1].occupiedFootprint(in:c) == BuildingFootprint(width:2,height:2))
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at:url) }
    let store = SaveStore(url:url); try store.save(old)
    #expect(try store.load(configuration:c) == old)
}

@Test func corruptCapturedGeometryIsRejectedBeforeTileEnumeration() throws {
    let c = try rectangleConfiguration()
    var g = try GameEngine(configuration:c,now:geometryEpoch)
    try g.build(.hut,at:geometrySite(g,.hut))
    for size in [BuildingFootprint(width:0,height:2), .init(width:-1,height:2), .init(width:Int.max,height:Int.max), .init(width:33,height:2)] {
        var bad = g.state; bad.buildings[1].footprint = size
        #expect(throws: GameError.self) { try GameEngine(state:bad,configuration:c) }
    }
    var bad = g.state; bad.buildings[0].orientation = .east
    #expect(throws: GameError.self) { try GameEngine(state:bad,configuration:c) }
    bad = g.state; bad.buildings[0].footprint = .init(width:2,height:1)
    #expect(throws: GameError.self) { try GameEngine(state:bad,configuration:c) }
}

@Test func orientationCatalogDefaultsAndRestrictionsAreValidated() throws {
    var c = try GameConfiguration.bundled()
    #expect(c.definition(.hut).resolvedOrientations == [.north])
    var g = try GameEngine(configuration:c,now:geometryEpoch)
    let before = g.state
    #expect(throws: GameError.self) { try g.build(.hut,at:Tile(x:12,y:12),orientation:.east) }
    #expect(g.state == before)
    let i = c.buildings.firstIndex { $0.kind == .hut }!
    for list: [BuildingOrientation] in [[], [.east], [.north,.north]] {
        c.buildings[i].allowedOrientations = list
        #expect(throws: GameError.self) { try c.validate() }
    }
    c.buildings[i].allowedOrientations = nil
    c.buildings[c.buildings.firstIndex { $0.kind == .campfire }!].allowedOrientations = [.north,.east]
    #expect(throws: GameError.self) { try c.validate() }
}

@MainActor @Test func relocationPreviewUsesCapturedOrientedGeometry() throws {
    var c = try rectangleConfiguration()
    var g = try GameEngine(configuration:c,now:geometryEpoch)
    try g.build(.hut,at:geometrySite(g,.hut,.east),orientation:.east)
    let i = c.buildings.firstIndex { $0.kind == .hut }!
    c.buildings[i].width = 4; c.buildings[i].height = 4
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at:folder) }
    let url = folder.appendingPathComponent("save.json"); try SaveStore(url:url).save(g.state)
    let session = try GameSession(clock:{geometryEpoch},saveURL:url,configuration:c)
    #expect(session.previewFootprint == nil)
    session.beginRelocation(buildingID:1)
    #expect(session.previewFootprint == BuildingFootprint(width:2,height:3))
    #expect(session.state == g.state)
    session.cancel()
    #expect(session.previewFootprint == nil)
    session.choose(.hut)
    #expect(session.previewFootprint == BuildingFootprint(width:4,height:4))
    session.cancel()
    #expect(session.state == g.state)
}

@Test func rectangularTurnRejectsOnlyNewlyCoveredUndiscoveredEdge() throws {
    let c = try rectangleConfiguration()
    var g = try GameEngine(configuration:c,now:geometryEpoch)
    let origin = try #require((0..<24).flatMap { y in (0..<32).map { Tile(x:$0,y:y) } }.first {
        g.placementIssue(.hut,at:$0,orientation:.north) == nil && g.placementIssue(.hut,at:$0,orientation:.east) == nil
    })
    try g.build(.hut,at:origin)
    let b = g.state.buildings[1]
    let north = Set(b.tiles(in:c))
    let east = Set(b.resolvedFootprint(in:c).oriented(.east).tiles(at:origin))
    let hidden = try #require(east.subtracting(north).first)
    var s = g.state
    s.discoveredTiles = Set((0..<24).flatMap { y in (0..<32).map { Tile(x:$0,y:y) } }).subtracting([hidden])
    g = try GameEngine(state:s,configuration:c)
    let before = g.state
    #expect(g.relocationIssue(buildingID:b.id,at:origin,orientation:.east)?.localizedDescription.contains("Explore") == true)
    #expect(throws:GameError.self) { try g.relocate(buildingID:b.id,to:origin,orientation:.east) }
    #expect(g.state == before)
    s.discoveredTiles?.insert(hidden)
    g = try GameEngine(state:s,configuration:c)
    try g.relocate(buildingID:b.id,to:origin,orientation:.east)
    #expect(Set(g.state.buildings[1].tiles(in:c)) == east)
}
