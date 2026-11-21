#if DEBUG
import Foundation
import Testing
import GameCore
import GameApplication

private func stoneRoute() throws -> RiverbendEconomyLab {
    var lab = try RiverbendEconomyLab(now: Date(timeIntervalSince1970: 40_000_000))
    for kind in [BuildingKind.hut, .woodcutter, .gatheringShelter] {
        if kind == .woodcutter { try lab.startSurvey(); try lab.advance(by: 60) }
        try lab.build(kind, at: #require(lab.sites(for: kind).first)); try lab.advance(by: 30)
    }
    try lab.advance(by: 600)
    return lab
}
@Test func stoneStorageFreeRevealDoesNotRequireGathererFunds() throws {
    var lab = try RiverbendEconomyLab(now: Date(timeIntervalSince1970: 40_000_000))
    for kind in [BuildingKind.hut, .gatheringShelter] {
        try lab.build(kind, at: #require(lab.sites(for: kind).first))
        try lab.advance(by: lab.engine.configuration.definition(kind).constructionSeconds ?? 0)
    }
    try lab.startSurvey(); try lab.advance(by: 60)
    try lab.build(.woodcutter, at: #require(lab.sites(for: .woodcutter).first))
    try lab.advance(by: lab.engine.configuration.definition(.woodcutter).constructionSeconds ?? 0)
    #expect(lab.checkpointReached && lab.engine.state.resources.wood < 10)
    let stock = lab.engine.state.resources
    try lab.revealStone()
    #expect(lab.stoneSource != nil && lab.engine.state.resources == stock)
    #expect(lab.sites(for: .stoneGatherer).isEmpty)
}
@Test func stoneStorageHiddenSourceAndOpeningRemainIndependent() throws {
    var lab = try RiverbendEconomyLab(now: Date())
    #expect(throws: (any Error).self) { try lab.revealStone() }
    #expect(lab.sites(for: .stoneGatherer).isEmpty)
    lab = try stoneRoute()
    #expect(lab.checkpointReached && lab.engine.state.resources.stone == 0)
    #expect(lab.availableFinds.count == 2)
    try lab.revealStone()
    let source = try #require(lab.stoneSource)
    #expect(lab.legalFindSites.contains(source))
    #expect(lab.engine.isDiscovered(source))
    let before = lab.engine.state
    #expect(throws: (any Error).self) { try lab.revealStone() }
    #expect(lab.engine.state == before)
}
@Test func stoneStorageDistinctCapsCollectSpendAndReload() throws {
    for role in RiverbendStorageRole.allCases {
        var lab = try stoneRoute(); try lab.revealStone()
        let wood = lab.engine.state.resources.wood
        try lab.build(.stoneGatherer, at: #require(lab.sites(for: .stoneGatherer).first))
        #expect(lab.engine.state.resources.wood == wood - 10)
        try lab.advance(by: 20)
        #expect(lab.engine.rates.stone == 5)
        try lab.advance(by: 600)
        #expect(lab.engine.state.resources.stone == 40)
        try lab.advance(by: 60)
        #expect(lab.engine.state.resources.stone == 40)
        let before = lab.engine.state.resources
        try lab.buildStorage(role, at: #require(lab.storageSites(for: role).first))
        #expect(lab.engine.state.resources.wood == before.wood - (role == .granary ? 14 : 18))
        #expect(lab.engine.state.resources.stone == before.stone - (role == .granary ? 4 : 6))
        #expect(lab.engine.capacities.food == 60 && lab.engine.capacities.stone == 40)
        lab = try RiverbendEconomyLab(data: lab.encoded())
        try lab.advance(by: 120)
        #expect(lab.engine.capacities.food == (role == .granary ? 120 : 60))
        #expect(lab.engine.capacities.wood == (role == .stockyard ? 120 : 60))
        #expect(lab.engine.capacities.stone == (role == .stockyard ? 100 : 40))
        try lab.advance(by: 1200)
        #expect(lab.engine.state.resources.food == (role == .granary ? 120 : 60))
        #expect(lab.engine.state.resources.wood == (role == .stockyard ? 120 : 60))
        #expect(lab.engine.state.resources.stone == (role == .stockyard ? 100 : 40))
        let reloaded = try RiverbendEconomyLab(data: lab.encoded())
        #expect(reloaded.engine.state == lab.engine.state)
        #expect(reloaded.engine.capacities == lab.engine.capacities)
        #expect(throws: (any Error).self) { try lab.buildStorage(role, at: Tile(x: 1,y: 1)) }
    }
}
@Test func stoneStorageAtomicFailureRetryAndBothRoles() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    var store = try RiverbendEconomyLabStore(directory: root, now: Date())
    try store.perform { $0 = try stoneRoute() }
    func blocked(_ action: (inout RiverbendEconomyLab) throws -> Void) throws {
        let bytes = try Data(contentsOf: store.url), before = store.lab.engine.state
        try FileManager.default.removeItem(at: store.url)
        try FileManager.default.createDirectory(at: store.url, withIntermediateDirectories: false)
        #expect(throws: (any Error).self) { try store.perform(action) }
        #expect(store.lab.engine.state == before)
        try FileManager.default.removeItem(at: store.url); try bytes.write(to: store.url)
    }
    try blocked { try $0.revealStone() }
    #expect(store.lab.stoneSource == nil)
    try store.perform { try $0.revealStone() }
    let site = try #require(store.lab.sites(for: .stoneGatherer).first)
    try blocked { try $0.build(.stoneGatherer, at: site) }
    try store.perform { try $0.build(.stoneGatherer, at: site); try $0.advance(by: 600) }
    for role in RiverbendStorageRole.allCases {
        let site = try #require(store.lab.storageSites(for: role).first)
        try blocked { try $0.buildStorage(role, at: site) }
        try store.perform { try $0.buildStorage(role, at: site) }
        let mid = store.lab
        try blocked { try $0.advance(by: 120) }
        try store.perform { try $0.advance(by: 120) }
        var split = mid
        for _ in 0..<120 { try split.advance(by: 1) }
        #expect(abs(split.engine.state.resources.stone - store.lab.engine.state.resources.stone) < 1e-7)
        #expect(abs(split.engine.state.resources.food - store.lab.engine.state.resources.food) < 1e-7)
        store = try RiverbendEconomyLabStore(directory: root, now: Date().addingTimeInterval(90000))
    }
    #expect(store.lab.engine.capacities.food == 120)
    #expect(store.lab.engine.capacities.wood == 120)
    #expect(store.lab.engine.capacities.stone == 100)
    #expect(store.lab.storage.count == 2)
    #expect(store.lab.mapFinds.allSatisfy { !$0.resolved })
    #expect(store.lab.engine.state.resources.knowledge == 6)
}
@Test func stoneStorageRejectsMetadataLossHiddenSourceAndOverCapWithoutReset() throws {
    var lab = try stoneRoute(); try lab.revealStone()
    try lab.build(.stoneGatherer, at: #require(lab.sites(for: .stoneGatherer).first)); try lab.advance(by: 600)
    try lab.buildStorage(.stockyard, at: #require(lab.storageSites(for: .stockyard).first)); try lab.advance(by: 1200)
    let data = try lab.encoded()
    for key in ["storage", "stoneSource"] {
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object.removeValue(forKey: key)
        #expect(throws: (any Error).self) { _ = try RiverbendEconomyLab(data: JSONSerialization.data(withJSONObject: object)) }
    }
    var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    object["stoneSource"] = ["x": -1, "y": -1]
    #expect(throws: (any Error).self) { _ = try RiverbendEconomyLab(data: JSONSerialization.data(withJSONObject: object)) }
    var old = try #require(JSONSerialization.jsonObject(with: stoneRoute().encoded()) as? [String: Any])
    old.removeValue(forKey: "stoneSource"); old.removeValue(forKey: "storage")
    let upgraded = try RiverbendEconomyLab(data: JSONSerialization.data(withJSONObject: old))
    #expect(upgraded.checkpointReached && upgraded.stoneSource == nil && upgraded.storage.isEmpty)
    #expect(upgraded.availableFinds.count == 2)
}
#endif
