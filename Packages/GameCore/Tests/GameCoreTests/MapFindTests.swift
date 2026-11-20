#if DEBUG
import Foundation
import Testing
import GameCore
import GameApplication

private let findEpoch = Date(timeIntervalSince1970: 40_000_000)
private func waitingFindLab() throws -> RiverbendEconomyLab {
    var lab = try RiverbendEconomyLab(now: findEpoch)
    try lab.build(.hut, at: #require(lab.sites(for: .hut).first))
    return lab
}
private func editFindLab(_ lab: RiverbendEconomyLab, _ edit: (inout [String: Any]) throws -> Void) throws -> Data {
    var object = try #require(JSONSerialization.jsonObject(with: lab.encoded()) as? [String: Any])
    try edit(&object)
    return try JSONSerialization.data(withJSONObject: object)
}

@Test func mapFindsOverlappingTargetsSelectNearestNotFirst() throws {
    let lab = try waitingFindLab()
    let berry = MapGeometry.point(for: try #require(lab.availableFinds.first { $0.id == .berries }?.tile))
    let track = MapGeometry.point(for: try #require(lab.availableFinds.first { $0.id == .tracks }?.tile))
    let separation = hypot(berry.x - track.x, berry.y - track.y)
    #expect(lab.find(near: track, radius: separation + 1) == .tracks)
    #expect(lab.find(near: berry, radius: separation + 1) == .berries)
    #expect(lab.find(near: WorldPoint(x: -10000, y: -10000), radius: 22) == nil)
}

@Test func mapFindsAppearDuringRealWaitAtDeterministicReachableDistinctSites() throws {
    let fresh = try RiverbendEconomyLab(now: findEpoch)
    #expect(fresh.mapFinds.isEmpty)
    let lab = try waitingFindLab(), other = try waitingFindLab()
    #expect(lab.engine.state.buildings.contains { !$0.isOperational })
    #expect(lab.mapFinds == other.mapFinds)
    #expect(Set(lab.availableFinds.map(\.id)) == Set(RiverbendMapFindID.allCases))
    #expect(Set(lab.availableFinds.compactMap(\.tile)).count == 2)
    for find in lab.availableFinds {
        let tile = try #require(find.tile)
        #expect(lab.engine.isDiscovered(tile))
        #expect(lab.engine.building(at: tile) == nil)
        #expect(lab.legalFindSites.contains(tile))
    }
    #expect(try RiverbendEconomyLab(data: lab.encoded()).mapFinds == lab.mapFinds)
}

@Test func mapFindsGatherObserveAndDuplicatesPersistWithoutProgressOrReveal() throws {
    var lab = try waitingFindLab()
    let berry = try #require(lab.availableFinds.first { $0.id == .berries })
    let track = try #require(lab.availableFinds.first { $0.id == .tracks })
    let before = lab.engine.state
    try lab.resolveFind(.berries, at: #require(berry.tile))
    #expect(lab.engine.state.resources.food == before.resources.food + 3)
    #expect(throws: (any Error).self) { try lab.resolveFind(.berries, at: #require(berry.tile)) }
    let gathered = lab.engine.state
    lab = try RiverbendEconomyLab(data: lab.encoded())
    #expect(throws: (any Error).self) { try lab.resolveFind(.berries, at: #require(berry.tile)) }
    try lab.resolveFind(.tracks, at: #require(track.tile))
    #expect(lab.engine.state == gathered)
    #expect(lab.engine.state.discoveredTiles == before.discoveredTiles)
    #expect(lab.engine.state.researchedTechnologies == before.researchedTechnologies)
    #expect(lab.engine.state.resources[.animalHides] == 0)
    lab = try RiverbendEconomyLab(data: lab.encoded())
    #expect(lab.availableFinds.isEmpty)
    #expect(lab.mapFinds.allSatisfy { $0.resolved })
    #expect(throws: (any Error).self) { try lab.resolveFind(.tracks, at: #require(track.tile)) }
}

@Test func mapFindsFullCapacityRejectsWholeRewardAndAllowsLaterRetry() throws {
    var lab = try waitingFindLab()
    let berry = try #require(lab.availableFinds.first { $0.id == .berries })
    for amount in [60.0, 58.0] {
        lab = try RiverbendEconomyLab(data: editFindLab(lab) { object in
            var state = try #require(object["state"] as? [String: Any])
            var resources = try #require(state["resources"] as? [String: Any])
            resources["food"] = amount; state["resources"] = resources; object["state"] = state
        })
        let before = try lab.encoded()
        #expect(throws: (any Error).self) { try lab.resolveFind(.berries, at: #require(berry.tile)) }
        #expect(lab.engine.state.resources.food == amount)
        #expect(lab.availableFinds.contains { $0.id == .berries })
        #expect(try RiverbendEconomyLab(data: before).mapFinds == lab.mapFinds)
    }
    try lab.advance(by: 120)
    let food = lab.engine.state.resources.food
    try lab.resolveFind(.berries, at: #require(berry.tile))
    #expect(lab.engine.state.resources.food == food + 3)
}

@Test func mapFindsOccupiedFallbackAndInvalidHiddenStaleActions() throws {
    var lab = try waitingFindLab()
    let berry = try #require(lab.availableFinds.first { $0.id == .berries })
    let oldTile = try #require(berry.tile)
    let blocker = try #require(lab.sites(for: .gatheringShelter).first {
        lab.engine.configuration.definition(.gatheringShelter).footprint.tiles(at: $0).contains(oldTile)
    })
    try lab.build(.gatheringShelter, at: blocker)
    let moved = try #require(lab.availableFinds.first { $0.id == .berries })
    #expect(moved.tile != oldTile)
    #expect(lab.legalFindSites.contains(try #require(moved.tile)))
    #expect(throws: (any Error).self) { try lab.resolveFind(.berries, at: oldTile) }
    #expect(throws: (any Error).self) { try lab.resolveFind(.berries, at: Tile(x: -1, y: -1)) }
    let hidden = try #require((0..<lab.engine.configuration.map.width).map { Tile(x: $0, y: 0) }.first { !lab.engine.isDiscovered($0) })
    #expect(throws: (any Error).self) { try lab.resolveFind(.tracks, at: hidden) }
    #expect(lab.mapFinds.count == 2)
    #expect(try RiverbendEconomyLab(data: lab.encoded()).mapFinds == lab.mapFinds)
}

@Test func mapFindsFailedWriteRetryAndRelaunchAreExactlyOnce() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    var store = try RiverbendEconomyLabStore(directory: root, now: findEpoch)
    try store.perform { lab in try lab.build(.hut, at: #require(lab.sites(for: .hut).first)) }
    for id in RiverbendMapFindID.allCases {
        let tile = try #require(store.lab.availableFinds.first { $0.id == id }?.tile)
        let state = store.lab.engine.state, finds = store.lab.mapFinds
        let bytes = try Data(contentsOf: store.url)
        try FileManager.default.removeItem(at: store.url)
        try FileManager.default.createDirectory(at: store.url, withIntermediateDirectories: false)
        #expect(throws: (any Error).self) { try store.perform { try $0.resolveFind(id, at: tile) } }
        #expect(store.lab.engine.state == state && store.lab.mapFinds == finds)
        try FileManager.default.removeItem(at: store.url); try bytes.write(to: store.url)
        store = try RiverbendEconomyLabStore(directory: root, now: findEpoch.addingTimeInterval(10000))
        try store.perform { try $0.resolveFind(id, at: tile) }
        #expect(store.lab.engine.state.resources.food == state.resources.food + (id == .berries ? 3 : 0))
        let committed = try Data(contentsOf: store.url)
        #expect(throws: (any Error).self) { try store.perform { try $0.resolveFind(id, at: tile) } }
        #expect(try Data(contentsOf: store.url) == committed)
        store = try RiverbendEconomyLabStore(directory: root, now: findEpoch)
        #expect(store.lab.mapFinds.first { $0.id == id }?.resolved == true)
    }
}

@Test func mapFindsOldLabEnvelopeUpgradesAndIgnoringBothCompletesRoute() throws {
    var lab = try waitingFindLab()
    let old = try editFindLab(lab) { $0.removeValue(forKey: "mapFinds") }
    lab = try RiverbendEconomyLab(data: old)
    #expect(lab.availableFinds.count == 2)
    try lab.advance(by: 15); try lab.startSurvey(); try lab.advance(by: 60)
    for kind in [BuildingKind.woodcutter, .gatheringShelter] {
        try lab.build(kind, at: #require(lab.sites(for: kind).first)); try lab.advance(by: 30)
    }
    #expect(lab.checkpointReached)
    #expect(lab.availableFinds.count == 2)
    #expect(lab.mapFinds.allSatisfy { !$0.resolved })
    #expect(lab.engine.state.resources.knowledge == 6)
}
#endif
