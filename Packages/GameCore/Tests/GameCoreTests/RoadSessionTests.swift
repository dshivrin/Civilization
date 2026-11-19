import Foundation
import Testing
import GameCore
import GameApplication
import GamePersistence

private let roadSessionEpoch = Date(timeIntervalSince1970:60_000_000)
@MainActor private func roadSession(_ url:URL) throws -> GameSession { try GameSession(clock:{roadSessionEpoch},saveURL:url,configuration:.bundled()) }
@MainActor private func openRoadSites(_ s:GameSession) -> [Tile] {
    (0..<24).flatMap { y in (0..<32).map { Tile(x:$0,y:y) } }.filter { s.roadIssue(at:$0) == nil }
}

@MainActor @Test func roadDraftCancelAndBackgroundNeverPersistPendingEdits() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at:folder) }
    let url = folder.appendingPathComponent("save.json"),s = try roadSession(url)
    let tile = try #require(openRoadSites(s).first);let before = s.state
    s.chooseRoadTool(.draw(.trodden));s.extendRoadStroke(to:tile)
    #expect(s.roadDraft == [tile] && s.state == before)
    s.save();#expect(try SaveStore(url:url).load(configuration:s.configuration) == before)
    s.clearRoadStroke();#expect(s.roadDraft.isEmpty && s.roadTool != nil && s.state == before)
    s.extendRoadStroke(to:tile);s.background()
    #expect(s.roadTool == nil && s.roadDraft.isEmpty && s.state == before)
    s.chooseRoadTool(.draw(.stone));s.extendRoadStroke(to:tile);s.choose(.hut)
    #expect(s.roadTool == nil && s.roadDraft.isEmpty && s.selectedKind == .hut)
    s.cancel();#expect(s.state == before)
}

@MainActor @Test func roadModesDrawReplaceAndEraseIndependently() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at:folder) }
    let url = folder.appendingPathComponent("save.json"),s = try roadSession(url)
    let tile = try #require(openRoadSites(s).first)
    s.chooseRoadTool(.draw(.dirt));s.extendRoadStroke(to:tile);s.confirmRoadStroke()
    #expect(s.state.roads == [RoadTile(tile:tile,style:.dirt)] && s.roadDraft.isEmpty)
    s.chooseRoadTool(.draw(.stone));s.extendRoadStroke(to:tile);s.confirmRoadStroke()
    #expect(s.state.roads?.first?.style == .dirt)
    s.chooseRoadTool(.replace(.stone));s.extendRoadStroke(to:tile);s.confirmRoadStroke()
    #expect(s.state.roads?.first?.style == .stone)
    s.chooseRoadTool(.erase);s.extendRoadStroke(to:tile);s.confirmRoadStroke()
    #expect(s.state.roads?.isEmpty == true)
    s.chooseRoadTool(.replace(.trodden));s.extendRoadStroke(to:tile);s.confirmRoadStroke()
    #expect(s.state.roads?.isEmpty == true)
    #expect(try SaveStore(url:url).load(configuration:s.configuration) == s.state)
}

@MainActor @Test func invalidRoadDraftAndPinchStyleClearAreBoundedAndAtomic() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at:folder) }
    let s = try roadSession(folder.appendingPathComponent("save.json"))
    let tile = try #require(openRoadSites(s).first);let before = s.state
    s.chooseRoadTool(.draw(.dirt));s.extendRoadStroke(to:tile)
    s.extendRoadStroke(to:.init(x:Int.max,y:Int.min))
    #expect(s.roadDraft.count <= 769 && s.roadPreviewIssue != nil)
    s.confirmRoadStroke();#expect(s.state == before)
    s.clearRoadStroke();#expect(s.roadTool == .draw(.dirt) && s.roadDraft.isEmpty)
    s.extendRoadStroke(to:tile);s.chooseRoadTool(.replace(.stone))
    #expect(s.roadDraft.isEmpty && s.state == before)
    s.exitRoadMode();#expect(s.roadTool == nil)
}

@MainActor @Test func backtrackedRoadPointerDoesNotInventOffRouteTiles() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at:folder) }
    let s = try roadSession(folder.appendingPathComponent("save.json"))
    let a = try #require(openRoadSites(s).first { p in
        (0..<2).allSatisfy { dy in (0..<3).allSatisfy { dx in s.roadIssue(at:Tile(x:p.x+dx,y:p.y+dy)) == nil } }
    })
    let b = Tile(x:a.x+1,y:a.y),c = Tile(x:a.x+2,y:a.y),d = Tile(x:a.x+1,y:a.y+1)
    s.chooseRoadTool(.draw(.dirt))
    for p in [a,b,c,b,d] { s.extendRoadStroke(to:p) }
    #expect(s.roadDraft == [a,b,d])
    s.clearRoadStroke();s.extendRoadStroke(to:d);#expect(s.roadDraft == [d])
}

@MainActor @Test func sparseRoadRetraceCanRemoveOneCommittedTileWithoutChangingOtherSurfaces() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = folder.appendingPathComponent("save.json"), s = try roadSession(url)
    let a = try #require(openRoadSites(s).first { p in
        (0..<4).allSatisfy { dx in s.roadIssue(at: Tile(x: p.x + dx, y: p.y)) == nil }
    })
    let b = Tile(x: a.x + 1, y: a.y), c = Tile(x: a.x + 2, y: a.y)
    s.chooseRoadTool(.draw(.dirt)); s.extendRoadStroke(to: a); s.extendRoadStroke(to: c)
    #expect(s.roadDraft == [a,b,c])
    s.confirmRoadStroke()
    let before = s.state
    s.chooseRoadTool(.erase); s.extendRoadStroke(to: a); s.extendRoadStroke(to: c)
    s.extendRoadStroke(to: a)
    #expect(s.roadDraft == [a])
    #expect(s.state == before)
    s.confirmRoadStroke()
    #expect(s.state.roads == [RoadTile(tile: b, style: .dirt), RoadTile(tile: c, style: .dirt)])
    #expect(try SaveStore(url: url).load(configuration: s.configuration) == s.state)
    s.chooseRoadTool(.draw(.stone)); s.extendRoadStroke(to: a); s.extendRoadStroke(to: c)
    s.extendRoadStroke(to: b)
    #expect(s.roadDraft == [a,b])
    s.cancel()
    #expect(s.state.roads?.count == 2)
}

@MainActor @Test func inspectionDiscardsRoadDraftAndShowsBuildingWithoutApplyingStroke() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let s = try roadSession(folder.appendingPathComponent("save.json"))
    let before = s.state
    let tile = try #require(openRoadSites(s).first)
    s.chooseRoadTool(.draw(.stone)); s.extendRoadStroke(to: tile)
    s.inspect(buildingID: 0)
    #expect(s.roadTool == nil && s.roadDraft.isEmpty)
    #expect(s.currentInspection?.id == 0)
    s.confirmRoadStroke(); #expect(s.state == before)
}
