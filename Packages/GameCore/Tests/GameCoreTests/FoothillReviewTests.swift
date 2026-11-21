#if DEBUG
import Foundation
import Testing
import GameCore
import GameApplication

@Test func foothillProfileAndFullMapCollision() throws {
    let original = try GameConfiguration.riverbendFoundingReview()
    let c = try GameConfiguration.riverbendFoothillReview()
    #expect(c.map.id != original.map.id && c.isRiverbendFoundingReview)
    #expect(c.map.width == 64 && c.map.height == 48)
    #expect(c.map.campfire == original.map.campfire)
    let terrain = FoothillBoundary(configuration: c, buildings: [], enclosed: false, gateOpen: true)
    #expect(terrain.walkable(FoothillBoundary.slope))
    #expect(!terrain.walkable(Tile(x: 16, y: 7)))
    #expect(!terrain.path(from: FoothillBoundary.outside, to: c.map.campfire).isEmpty)
    #expect(terrain.reachable(from: FoothillBoundary.outside).count > 96)
    for target in FoothillBoundary.earlyResources {
        #expect(!terrain.path(from: c.map.campfire, to: target).isEmpty)
        #expect(target.x < 30)
    }
    #expect(!terrain.path(from: c.map.campfire, to: FoothillBoundary.expansion).isEmpty)
    let closed = FoothillBoundary(configuration: c, buildings: [], enclosed: true, gateOpen: false)
    let open = FoothillBoundary(configuration: c, buildings: [], enclosed: true, gateOpen: true)
    #expect(!open.path(from: FoothillBoundary.outside, to: c.map.campfire).isEmpty)
    #expect(open.path(from: FoothillBoundary.outside, to: c.map.campfire).contains(FoothillBoundary.gate))
    #expect(closed.path(from: FoothillBoundary.outside, to: c.map.campfire).isEmpty)
    let exterior = closed.reachable(from: FoothillBoundary.outside)
    #expect(FoothillBoundary.interior.isDisjoint(with: exterior))
    #expect(FoothillBoundary.wall.count == 36)
    #expect(FoothillBoundary.freestandingWall.count == 50)
    #expect(FoothillBoundary.cliffCost == 36 && FoothillBoundary.freestandingCost == 50)
    let freeClosed = FoothillBoundary(configuration: c, buildings: [], enclosed: true, gateOpen: false, freestanding: true)
    let freeOpen = FoothillBoundary(configuration: c, buildings: [], enclosed: true, gateOpen: true, freestanding: true)
    #expect(freeClosed.path(from: FoothillBoundary.outside, to: c.map.campfire).isEmpty)
    #expect(FoothillBoundary.interior.isDisjoint(with: freeClosed.reachable(from: FoothillBoundary.outside)))
    #expect(freeOpen.path(from: FoothillBoundary.outside, to: c.map.campfire).contains(FoothillBoundary.gate))
    // Remove each join cell: a real bypass must become possible (negative control).
    for join in [Tile(x: 10, y: 8), Tile(x: 23, y: 8)] {
        let broken = FoothillBoundary(configuration: c, buildings: [], enclosed: true, gateOpen: false, omittedWall: [join])
        #expect(!broken.path(from: FoothillBoundary.outside, to: c.map.campfire).isEmpty)
    }
}

@Test func foothillFoundingPurchaseAtomicIsolationAndReload() throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: dir) }
    let now = Date(timeIntervalSince1970: 9_000_000)
    var original = try RiverbendFoundingStore(directory: dir, now: now)
    try original.perform { try $0.found() }
    let originalBytes = try Data(contentsOf: original.url)
    let originalURLs = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil).filter { $0.lastPathComponent.hasPrefix("ui2-founding-v1.json") }
    #expect(originalURLs.count == 2) // Main file and authentic pre-connectivity backup.
    let originalFiles = try originalURLs.map { ($0, try Data(contentsOf: $0)) }
    let originalState = original.review.engine.state
    var f = try RiverbendFoundingStore(directory: dir, now: now, foothill: true)
    #expect(f.url != original.url)
    #expect(f.review.hutSites.count >= 2)
    try f.perform { try $0.found() }
    let site = try #require(f.review.hutSites.first)
    try f.perform { try $0.buildHut(at: site); try $0.drawPath(to: site); try $0.advance(seconds: 60) }
    let wood = f.review.engine.state.resources.wood
    try f.perform { try $0.purchaseFoothillEnclosure() }
    #expect(f.review.engine.state.resources.wood == wood - 36)
    #expect(f.review.foothillEnclosed)
    #expect(f.review.foothillBoundary.path(from: FoothillBoundary.outside, to: FoothillBoundary.inside).contains(FoothillBoundary.gate))
    try f.perform { try $0.setFoothillGate(open: false) }
    #expect(f.review.foothillBoundary.path(from: FoothillBoundary.outside, to: FoothillBoundary.inside).isEmpty)
    let paid = try Data(contentsOf: f.url)
    #expect(throws: GameError.self) { try f.perform { try $0.purchaseFoothillEnclosure() } }
    #expect(try Data(contentsOf: f.url) == paid)
    let reopened = try RiverbendFoundingStore(directory: dir, now: now.addingTimeInterval(9999), foothill: true)
    #expect(reopened.review.engine.state == f.review.engine.state)
    #expect(reopened.review.foothillEnclosed && !reopened.review.foothillGateOpen)
    #expect(try Data(contentsOf: original.url) == originalBytes)
    let old = try RiverbendFoundingStore(directory: dir, now: now)
    #expect(old.review.engine.state == originalState)
    for (url, bytes) in originalFiles { #expect(try Data(contentsOf: url) == bytes) }
    var stale = reopened
    try f.perform { try $0.setFoothillGate(open: true) }
    #expect(throws: GameError.self) { try stale.perform { try $0.setFoothillGate(open: true) } }
}
@Test func foothillGateCorridorAndStoreIdentityAreProtected() throws {
    let now = Date(timeIntervalSince1970: 9_000_000)
    var r = try RiverbendFoundingReview(now: now, foothill: true)
    try r.found()
    #expect(r.hutIssue(at: Tile(x: 20, y: 13)) != nil)
    try r.purchaseFoothillEnclosure()
    #expect(r.hutIssue(at: Tile(x: 17, y: 20)) != nil)
    #expect(r.route(to: Tile(x: 17, y: 20)).isEmpty)
    let paid = r.engine.state
    #expect(throws: GameError.self) { try r.editPath([FoothillBoundary.gate], erase: true) }
    #expect(r.engine.state == paid)
    try r.disconnect()
    #expect(Set((r.engine.state.roads ?? []).map(\.tile)).contains(FoothillBoundary.gate))
    _ = try RiverbendFoundingReview(state: r.engine.state, enclosed: true, gateOpen: true)
    var bad = r.engine.state; bad.roads = []
    #expect(throws: GameError.self) { try RiverbendFoundingReview(state: bad, enclosed: true) }
    let fresh = try RiverbendFoundingReview(now: now, foothill: true)
    #expect(throws: GameError.self) { try RiverbendFoundingReview(state: fresh.engine.state, enclosed: true) }
    #expect(throws: GameError.self) { try RiverbendFoundingReview(state: fresh.engine.state, gateOpen: false) }
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: dir) }
    var original = try RiverbendFoundingStore(directory: dir, now: now)
    let bytes = try Data(contentsOf: original.url)
    #expect(throws: GameError.self) { try original.perform { $0 = fresh } }
    #expect(try Data(contentsOf: original.url) == bytes)
}
@Test func foothillRejectsCorruptEnvelopeWithoutResetAndSourcesAreReal() throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: dir) }
    let now = Date(timeIntervalSince1970: 9_000_000)
    let f = try RiverbendFoundingStore(directory: dir, now: now, foothill: true)
    let valid = try Data(contentsOf: f.url)
    let object = try #require(JSONSerialization.jsonObject(with: valid) as? [String: Any])
    for key in ["version", "enclosed", "gateOpen", "state"] {
        var bad = object
        switch key {
        case "version": bad[key] = 2
        case "enclosed": bad[key] = true
        case "gateOpen": bad[key] = false
        default:
            var state = try #require(bad[key] as? [String: Any]); state["mapID"] = GameConfiguration.riverbendFoundingID; bad[key] = state
        }
        let bytes = try JSONSerialization.data(withJSONObject: bad)
        try bytes.write(to: f.url)
        #expect(throws: (any Error).self) { try RiverbendFoundingStore(directory: dir, now: now, foothill: true) }
        #expect(try Data(contentsOf: f.url) == bytes)
    }
    let garbage = Data("invalid-json".utf8); try garbage.write(to: f.url)
    #expect(throws: (any Error).self) { try RiverbendFoundingStore(directory: dir, now: now, foothill: true) }
    #expect(try Data(contentsOf: f.url) == garbage)
    let c = f.review.engine.configuration
    let wood = try #require(c.naturalDeposits?.first { $0.resource == .wood })
    let stone = try #require(c.naturalDeposits?.first { $0.resource == .stone })
    let water = try #require(c.naturalDeposits?.first { $0.resource == .water })
    #expect(c.map.terrain(at: water.origin) == .water)
    #expect(c.map.terrain(at: wood.origin) == .forest)
    #expect(c.map.terrain(at: stone.origin) == .hill)
    #expect(wood.accessSites?.contains(FoothillBoundary.earlyResources[1]) == true)
    #expect(stone.accessSites?.contains(FoothillBoundary.earlyResources[2]) == true)
    #expect(c.definition(.gatheringShelter).recipes?.contains { $0.outputsPerMinute.food > 0 } == true)
    #expect(f.review.catalogPlacementIssue(.gatheringShelter, at: FoothillBoundary.earlyResources[0]) == nil)
}
#endif
