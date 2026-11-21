#if DEBUG
import Foundation
import Testing
import GameCore
import GameApplication

private func craftRoute(unlock: Bool = true) throws -> RiverbendEconomyLab {
    var lab = try RiverbendEconomyLab(now: Date(timeIntervalSince1970: 40_000_000))
    for kind in [BuildingKind.hut, .woodcutter, .gatheringShelter] {
        if kind == .woodcutter { try lab.startSurvey(); try lab.advance(by: 60) }
        try lab.build(kind, at: #require(lab.sites(for: kind).first)); try lab.advance(by: 30)
    }
    try lab.advance(by: 600); try lab.revealStone()
    try lab.build(.stoneGatherer, at: #require(lab.sites(for: .stoneGatherer).first)); try lab.advance(by: 60)
    if unlock { try lab.unlockCraft() }
    return lab
}
private func craftStocks(_ lab: RiverbendEconomyLab, wood: Double? = nil, flint: Double? = nil, tools: Double? = nil) throws -> RiverbendEconomyLab {
    var object = try #require(JSONSerialization.jsonObject(with: lab.encoded()) as? [String: Any])
    var state = try #require(object["state"] as? [String: Any])
    var stocks = try #require(state["resources"] as? [String: Any])
    if let wood { stocks["wood"] = wood }; if let flint { stocks["flint"] = flint }; if let tools { stocks["stoneTools"] = tools }
    state["resources"] = stocks; object["state"] = state
    return try RiverbendEconomyLab(data: JSONSerialization.data(withJSONObject: object))
}
@Test func firstCraftUnlockIsLaterFreeAndModesExclusive() throws {
    var fresh = try RiverbendEconomyLab(now: Date())
    #expect(fresh.craft == nil)
    #expect(throws: (any Error).self) { try fresh.unlockCraft() }
    var lab = try craftRoute(unlock: false)
    #expect(lab.engine.capacities[.flint] == 24 && lab.engine.capacities[.stoneTools] == 24)
    let stocks = lab.engine.state.resources
    try lab.unlockCraft()
    #expect(lab.engine.state.resources == stocks)
    #expect(lab.engine.capacities[.flint] == 24 && lab.engine.capacities[.stoneTools] == 24)
    #expect(throws: (any Error).self) { try lab.unlockCraft() }
    try lab.setGatheringMode(.flint)
    #expect(lab.engine.rates[.flint] == 4 && lab.engine.rates.stone == 0)
    let stone = lab.engine.state.resources.stone
    try lab.advance(by: 60)
    #expect(lab.engine.state.resources[.flint] == 4 && lab.engine.state.resources.stone == stone)
    try lab.setGatheringMode(.stone)
    #expect(lab.engine.rates[.flint] == 0 && lab.engine.rates.stone == 5)
    let reloaded = try RiverbendEconomyLab(data: lab.encoded())
    #expect(reloaded.craft == lab.craft)
    #expect(lab.mapFinds.allSatisfy { !$0.resolved })
}
@Test func firstCraftFullAndInsufficientRejectBeforeAnyDebit() throws {
    let ready = try craftRoute()
    for (wood, flint, tools) in [(1.0, 2.0, 0.0), (2, 1, 0), (2, 2, 24), (2, 2, 23.5)] {
        var lab = try craftStocks(ready, wood: wood, flint: flint, tools: tools)
        let state = lab.engine.state, craft = lab.craft
        #expect(throws: (any Error).self) { try lab.startToolBatch() }
        #expect(lab.engine.state == state && lab.craft == craft)
    }
    var lab = try craftStocks(ready, wood: 2, flint: 2)
    try lab.startToolBatch()
    #expect(lab.engine.state.resources.wood == 0 && lab.engine.state.resources[.flint] == 0)
    let paid = lab.engine.state
    #expect(throws: (any Error).self) { try lab.startToolBatch() }
    #expect(lab.engine.state == paid)
    try lab.advance(by: 59)
    #expect(lab.engine.state.resources[.stoneTools] == 0)
    lab = try RiverbendEconomyLab(data: lab.encoded())
    try lab.advance(by: 1)
    #expect(lab.engine.state.resources[.stoneTools] == 1 && lab.craft?.batchRemaining == nil)
    try lab.advance(by: 600)
    #expect(lab.engine.state.resources[.stoneTools] == 1)
}
@Test func firstCraftSpendLastingBenefitExactlyOnceAndNoUpkeep() throws {
    var lab = try craftRoute()
    #expect(throws: (any Error).self) { try lab.improveWoodcutter() }
    try lab.setGatheringMode(.flint); try lab.advance(by: 90)
    try lab.setGatheringMode(.stone)
    for _ in 0..<3 { try lab.startToolBatch(); try lab.advance(by: 60) }
    #expect(lab.engine.state.resources[.stoneTools] == 3)
    let before = lab.engine.state.resources, rate = lab.engine.rates.wood
    try lab.improveWoodcutter()
    #expect(lab.engine.state.resources[.stoneTools] == 0)
    #expect(lab.engine.state.resources.wood == before.wood && lab.engine.state.resources[.flint] == before[.flint])
    #expect(lab.engine.rates.wood == rate + 2 && lab.craft?.woodcutterImproved == true)
    let improved = lab.engine.state
    #expect(throws: (any Error).self) { try lab.improveWoodcutter() }
    #expect(lab.engine.state == improved)
    lab = try RiverbendEconomyLab(data: lab.encoded())
    #expect(lab.engine.rates.wood == 8)
    try lab.advance(by: 3600)
    #expect(lab.engine.state.resources[.stoneTools] == 0 && lab.engine.rates.wood == 8)
}
@Test func firstCraftStockyardOnlyAddsUnlockedCapsAndSplitTimeMatches() throws {
    var lab = try craftRoute(unlock: false)
    try lab.advance(by: 600)
    try lab.buildStorage(.stockyard, at: #require(lab.storageSites(for: .stockyard).first)); try lab.advance(by: 120)
    #expect(lab.engine.capacities[.flint] == 24)
    let food = lab.engine.capacities.food, knowledge = lab.engine.capacities.knowledge, culture = lab.engine.capacities[.culture]
    try lab.unlockCraft()
    #expect(lab.engine.capacities[.flint] == 48 && lab.engine.capacities[.stoneTools] == 48)
    try lab.setGatheringMode(.flint); try lab.advance(by: 1200)
    #expect(lab.engine.state.resources[.flint] == 48)
    let flint = lab.engine.state.resources[.flint]
    try lab.advance(by: 60); #expect(lab.engine.state.resources[.flint] == flint)
    try lab.startToolBatch()
    var split = lab
    try lab.advance(by: 120)
    for _ in 0..<120 { try split.advance(by: 1) }
    for resource in Resource.allCases { #expect(abs(split.engine.state.resources[resource] - lab.engine.state.resources[resource]) < 1e-7) }
    #expect(lab.craft == split.craft)
    #expect(lab.engine.capacities.food == food && lab.engine.capacities.knowledge == knowledge && lab.engine.capacities[.culture] == culture)
}
@Test func firstCraftAtomicFailureRetryReloadAtEveryCommit() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    var store = try RiverbendEconomyLabStore(directory: root, now: Date())
    try store.perform { $0 = try craftRoute(unlock: false) }
    func failThenRetry(_ action: (inout RiverbendEconomyLab) throws -> Void) throws {
        let bytes = try Data(contentsOf: store.url), state = store.lab.engine.state, craft = store.lab.craft
        try FileManager.default.removeItem(at: store.url)
        try FileManager.default.createDirectory(at: store.url, withIntermediateDirectories: false)
        #expect(throws: (any Error).self) { try store.perform(action) }
        #expect(store.lab.engine.state == state && store.lab.craft == craft)
        try FileManager.default.removeItem(at: store.url); try bytes.write(to: store.url)
        store = try RiverbendEconomyLabStore(directory: root, now: Date().addingTimeInterval(99999))
        #expect(store.lab.engine.state == state && store.lab.craft == craft)
        try store.perform(action)
        store = try RiverbendEconomyLabStore(directory: root, now: Date().addingTimeInterval(99999))
    }
    try failThenRetry { try $0.unlockCraft() }
    try failThenRetry { try $0.setGatheringMode(.flint) }
    try failThenRetry { try $0.advance(by: 90) }
    try store.perform { try $0.setGatheringMode(.stone) }
    for index in 1...3 {
        let wood = store.lab.engine.state.resources.wood, flint = store.lab.engine.state.resources[.flint]
        try failThenRetry { try $0.startToolBatch() }
        #expect(store.lab.engine.state.resources.wood == wood - 2 && store.lab.engine.state.resources[.flint] == flint - 2)
        try failThenRetry { try $0.advance(by: 60) }
        #expect(store.lab.engine.state.resources[.stoneTools] == Double(index))
    }
    try failThenRetry { try $0.improveWoodcutter() }
    #expect(store.lab.craft?.woodcutterImproved == true && store.lab.engine.rates.wood == 8)
    #expect(store.lab.engine.state.resources[.stoneTools] == 0)
    #expect(throws: (any Error).self) { try store.perform { try $0.improveWoodcutter() } }
}
@Test func firstCraftOldEnvelopeAndMalformedMetadata() throws {
    let old = try craftRoute(unlock: false)
    var object = try #require(JSONSerialization.jsonObject(with: old.encoded()) as? [String: Any])
    object.removeValue(forKey: "craft")
    let restored = try RiverbendEconomyLab(data: JSONSerialization.data(withJSONObject: object))
    #expect(restored.craft == nil && restored.engine.state == old.engine.state)
    let ready = try craftRoute()
    for time in [-1.0, 0, 61] {
        var o = try #require(JSONSerialization.jsonObject(with: ready.encoded()) as? [String: Any])
        var craft = try #require(o["craft"] as? [String: Any]); craft["batchRemaining"] = time; o["craft"] = craft
        #expect(throws: (any Error).self) { _ = try RiverbendEconomyLab(data: JSONSerialization.data(withJSONObject: o)) }
    }
    var bad = try #require(JSONSerialization.jsonObject(with: ready.encoded()) as? [String: Any])
    bad.removeValue(forKey: "stoneSource")
    #expect(throws: (any Error).self) { _ = try RiverbendEconomyLab(data: JSONSerialization.data(withJSONObject: bad)) }
}
@Test func firstCraftModeSwitchDuringPaidBatchAndMidStorageCompletion() throws {
    var lab = try craftRoute()
    try lab.advance(by: 600)
    try lab.setGatheringMode(.flint); try lab.advance(by: 90)
    try lab.startToolBatch()
    try lab.advance(by: 20)
    let flint = lab.engine.state.resources[.flint], stone = lab.engine.state.resources.stone
    try lab.setGatheringMode(.stone)
    lab = try RiverbendEconomyLab(data: lab.encoded())
    try lab.advance(by: 40)
    #expect(lab.engine.state.resources[.flint] == flint)
    #expect(lab.engine.state.resources.stone >= stone && lab.engine.state.resources[.stoneTools] == 1)
    try lab.buildStorage(.granary, at: #require(lab.storageSites(for: .granary).first)); try lab.advance(by: 120)
    #expect(lab.engine.capacities[.flint] == 24 && lab.engine.capacities[.stoneTools] == 24)
    try lab.setGatheringMode(.flint); try lab.advance(by: 600)
    #expect(lab.engine.state.resources[.flint] == 24)
    try lab.buildStorage(.stockyard, at: #require(lab.storageSites(for: .stockyard).first))
    let remaining = try #require(lab.engine.state.buildings.first { $0.kind == .storehouse && !$0.isOperational }?.constructionRemainingSeconds)
    var split = try RiverbendEconomyLab(data: lab.encoded())
    try lab.advance(by: remaining + 60)
    try split.advance(by: remaining); try split.advance(by: 60)
    #expect(abs(lab.engine.state.resources[.flint] - 28) < 1e-7)
    #expect(lab.engine.state == split.engine.state)
    #expect(lab.engine.capacities[.flint] == 48 && lab.engine.capacities[.stoneTools] == 48)
    var full = try craftStocks(lab, wood: 2, flint: 2, tools: 48)
    let before = full.engine.state
    #expect(throws: (any Error).self) { try full.startToolBatch() }
    #expect(full.engine.state == before)
}

@Test func firstCraftDeterministicBalanceTrace() throws {
    var lab = try craftRoute(unlock: false)
    let epoch = Date(timeIntervalSince1970: 40_000_000)
    func trace(_ label: String) {
        let r = lab.engine.state.resources
        print("CRAFT_TRACE \(label) seconds=\(lab.engine.state.lastUpdated.timeIntervalSince(epoch)) food=\(r.food) wood=\(r.wood) stone=\(r.stone) flint=\(r[.flint]) tools=\(r[.stoneTools]) woodNet=\(lab.engine.rates.wood) batch=\(lab.craft?.batchRemaining ?? 0) improved=\(lab.craft?.woodcutterImproved == true)")
    }
    trace("opening-and-stone")
    try lab.unlockCraft(); trace("opportunity-free")
    try lab.setGatheringMode(.flint); try lab.advance(by: 90); trace("six-flint")
    #expect(lab.engine.state.resources[.flint] == 6)
    try lab.setGatheringMode(.stone)
    for index in 1...3 {
        try lab.startToolBatch(); trace("batch-\(index)-paid")
        try lab.advance(by: 60); trace("batch-\(index)-complete")
    }
    #expect(lab.engine.state.resources[.flint] == 0 && lab.engine.state.resources[.stoneTools] == 3)
    try lab.improveWoodcutter(); trace("three-tools-spent")
    lab = try RiverbendEconomyLab(data: lab.encoded()); trace("reloaded")
    #expect(lab.engine.rates.wood == 8 && lab.engine.state.resources[.stoneTools] == 0)
    try lab.buildStorage(.stockyard, at: #require(lab.storageSites(for: .stockyard).first))
    try lab.advance(by: 120); trace("stockyard-headroom")
    let before = lab.engine.state.resources.wood
    try lab.advance(by: 60); trace("improved-one-minute-output")
    #expect(abs(lab.engine.state.resources.wood - before - 8) < 1e-7)
}
#endif
