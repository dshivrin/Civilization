import Foundation
import Testing
@testable import GameCore
import GamePersistence

private let roadEpoch = Date(timeIntervalSince1970:50_000_000)
private func roadGame() throws -> GameEngine {
    var c = try GameConfiguration.bundled(); c.explorationRules = nil; c.progressionGoals = nil
    return try GameEngine(configuration:c,now:roadEpoch)
}
private func roadSites(_ g:GameEngine) -> [Tile] {
    (0..<g.configuration.map.height).flatMap { y in (0..<g.configuration.map.width).map { Tile(x:$0,y:y) } }.filter { g.roadIssue(at:$0) == nil }
}

@Test func roadMasksCoverAllSixteenLogicalCombinations() {
    let center = Tile(x:10,y:10)
    let neighbors = RoadGeometry.neighbors(of:center)
    #expect(neighbors.map(\.bit) == [1,2,4,8])
    for mask in UInt8(0)...15 {
        let occupied = Set([center] + neighbors.filter { mask & $0.bit != 0 }.map(\.tile))
        #expect(RoadGeometry.connectionMask(at:center,occupied:occupied) == mask)
    }
    #expect(RoadGeometry.connectionMask(at:center,occupied:[center,Tile(x:11,y:11)]) == 0)
}

@Test func roadStrokeFillsFourConnectedGapsAndBoundsBeforeTraversal() {
    for end in [Tile(x:31,y:23),Tile(x:0,y:23),Tile(x:31,y:0),Tile(x:0,y:0)] {
        let start = Tile(x:15,y:12)
        let path = RoadGeometry.path(from:start,to:end,width:32,height:24)
        #expect(path.first == start && path.last == end)
        #expect(path.count == abs(start.x-end.x)+abs(start.y-end.y)+1)
        #expect(Set(path).count == path.count)
        for (a,b) in zip(path,path.dropFirst()) { #expect(abs(a.x-b.x)+abs(a.y-b.y) == 1) }
    }
    #expect(RoadGeometry.path(from:.init(x:Int.max,y:Int.min),to:.init(x:0,y:0),width:32,height:24).isEmpty)
    #expect(RoadGeometry.path(from:.init(x:0,y:0),to:.init(x:-1,y:0),width:32,height:24).isEmpty)
}

@Test func roadCommandsAreFreeAtomicAndIdempotent() throws {
    var g = try roadGame(); let sites = roadSites(g); let before = g.state
    try g.editRoads(at:Array(sites.prefix(3)),style:.trodden)
    var expected = before; expected.roads = g.state.roads
    #expect(g.state == expected)
    let painted = g.state
    try g.editRoads(at:[sites[0],sites[0],sites[1]],style:.trodden)
    #expect(g.state == painted)
    for invalid in [Tile(x:-1,y:0),Tile(x:Int.max,y:Int.min),g.configuration.map.campfire] {
        #expect(throws:GameError.self) { try g.editRoads(at:[sites[3],invalid],style:.stone) }
        #expect(g.state == painted)
    }
    try g.editRoads(at:[sites[0]],style:.stone)
    #expect(g.state.roads?.first { $0.tile == sites[0] }?.style == .stone)
    try g.editRoads(at:[sites[0]],style:nil)
    #expect(g.state.roads?.contains { $0.tile == sites[0] } == false)
    let erased = g.state; try g.editRoads(at:[sites[0]],style:nil); #expect(g.state == erased)
    try g.editRoads(at:[],style:nil); #expect(g.state == erased)
}

@Test func roadsRejectFogAndProtectedTerrainWithoutChangingState() throws {
    var g = try GameEngine(configuration:.bundled(),now:roadEpoch)
    let all = (0..<24).flatMap { y in (0..<32).map { Tile(x:$0,y:y) } }
    let hidden = try #require(all.first { !g.isDiscovered($0) })
    let protected = try #require(all.first { g.isDiscovered($0) && [.water,.hill,.forest].contains(g.configuration.map.terrain(at:$0)) })
    let valid = try #require(roadSites(g).first); let before = g.state
    for tile in [hidden,protected] {
        #expect(throws:GameError.self) { try g.editRoads(at:[valid,tile],style:.dirt) }
        #expect(g.state == before)
    }
}

@Test func mixedRoadStylesReconnectAfterRemovalAndReload() throws {
    var g = try roadGame()
    let a = try #require(roadSites(g).first { p in RoadGeometry.neighbors(of:p).contains { g.roadIssue(at:$0.tile) == nil } })
    let b = try #require(RoadGeometry.neighbors(of:a).first { g.roadIssue(at:$0.tile) == nil })
    try g.editRoads(at:[a],style:.trodden); try g.editRoads(at:[b.tile],style:.stone)
    #expect(g.roadMask(at:a) == b.bit)
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at:url) }
    let store = SaveStore(url:url);try store.save(g.state)
    let state = try #require(try store.load(configuration:g.configuration))
    #expect(state == g.state)
    g = try GameEngine(state:state,configuration:g.configuration)
    #expect(g.roadMask(at:a) == b.bit)
    try g.editRoads(at:[b.tile],style:nil)
    #expect(g.roadMask(at:a) == 0)
}

@Test func roadSaveValidationAndLegacyNilRoundTrip() throws {
    let g = try roadGame();let tile = try #require(roadSites(g).first)
    #expect(g.state.roads == nil)
    let decoded = try JSONDecoder().decode(GameState.self,from:JSONEncoder().encode(g.state))
    #expect(decoded == g.state)
    for roads in [[RoadTile(tile:tile,style:.dirt),RoadTile(tile:tile,style:.stone)], [.init(tile:g.configuration.map.campfire,style:.dirt)], [.init(tile:.init(x:Int.max,y:Int.min),style:.stone)]] {
        var s = g.state;s.roads = roads
        #expect(throws:GameError.self) { try GameEngine(state:s,configuration:g.configuration) }
    }
}

@Test func buildingsRequireExplicitRoadRemovalBeforeConstructionOrMove() throws {
    var g = try roadGame()
    let site = try #require(roadSites(g).first { g.placementIssue(.hut,at:$0) == nil })
    try g.editRoads(at:[site],style:.dirt)
    let before = g.state
    #expect(throws:GameError.self) { try g.build(.hut,at:site) };#expect(g.state == before)
    try g.editRoads(at:[site],style:nil);try g.build(.hut,at:site)
    let other = try #require(roadSites(g).first { g.relocationIssue(buildingID:1,at:$0) == nil })
    try g.editRoads(at:[other],style:.stone);let placed = g.state
    #expect(throws:GameError.self) { try g.relocate(buildingID:1,to:other) };#expect(g.state == placed)
}

@Test func roadRendererInvalidationIsLocalAndIncludesNeighbors() {
    let a = Tile(x:10,y:10),b = Tile(x:11,y:10),far = Tile(x:20,y:20)
    let before = [RoadTile(tile:a,style:.dirt),RoadTile(tile:b,style:.trodden),RoadTile(tile:far,style:.stone)]
    let after = [RoadTile(tile:a,style:.stone),RoadTile(tile:b,style:.trodden),RoadTile(tile:far,style:.stone)]
    #expect(RoadGeometry.affectedTiles(before:before,after:before).isEmpty)
    let dirty = RoadGeometry.affectedTiles(before:before,after:after)
    #expect(dirty == Set([a]+RoadGeometry.neighbors(of:a).map(\.tile)))
    #expect(!dirty.contains(far))
}

@Test func ordinaryFirstEraStillCompletesAfterDecorativeRoadEdits() throws {
    var g = try GameEngine(configuration:.bundled(),now:roadEpoch)
    let tiles = Array(roadSites(g).suffix(2))
    try g.editRoads(at:tiles,style:.trodden)
    try g.editRoads(at:[tiles[0]],style:.stone)
    for _ in 0..<2000 {
        let hint = g.settlementGuidance
        if hint.action == .complete { break }
        if let seconds = hint.waitSeconds { g.advance(to:g.state.lastUpdated.addingTimeInterval(min(60,max(1,seconds))));continue }
        switch hint.action {
        case .build(let kind):
            let site = try #require((0..<24).flatMap { y in (0..<32).map { Tile(x:$0,y:y) } }.first { g.placementIssue(kind,at:$0) == nil })
            try g.build(kind,at:site)
        case .upgrade(let id):try g.upgrade(buildingID:id)
        case .research(let id):try g.research(id)
        case .recipe(let id,let mode):try g.setProductionMode(buildingID:id,recipeID:mode)
        case .priority(let id,let value):try g.setWorkerPriority(buildingID:id,priority:value)
        case .explore:try g.startExploration()
        default:Issue.record("Unusable guidance with decorative roads: \(hint.title)");return
        }
        g.advance(to:g.state.lastUpdated.addingTimeInterval(60))
    }
    #expect(g.fullStoneAgeRequirementsMet && g.journeyChapters.allSatisfy(\.isComplete))
    #expect(g.state.roads?.count == 2)
    print("ROADS_FULL_ERA seconds=\(g.state.lastUpdated.timeIntervalSince(roadEpoch)) roads=\(g.state.roads?.count ?? 0)")
}
