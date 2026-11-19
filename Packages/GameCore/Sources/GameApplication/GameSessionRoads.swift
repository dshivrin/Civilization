import Foundation
import GameCore

public extension GameSession {
    var roadPreviewIssue: GameError? {
        guard !roadDraft.isEmpty else { return nil }
        if roadDraft.count > configuration.map.width * configuration.map.height { return .placement("This stroke is too large. Clear it and draw a shorter road.") }
        return roadDraft.lazy.compactMap { self.roadIssue(at:$0) }.first
    }
    func chooseRoadTool(_ tool: RoadTool) {
        cancel(); inspectedBuilding = nil;roadTool = tool
        message = "Road mode · drag or tap to preview; Confirm applies the stroke. Roads are free decoration."
    }
    func extendRoadStroke(to tile: Tile) {
        guard roadTool != nil else { return }
        // A sparse pointer sample landing on the retained route is an exact retrace,
        // not a new staircase that can invent off-route cells on a diagonal.
        if let index = roadDraft.firstIndex(of: tile) {
            roadDraft.removeSubrange((index + 1)..<roadDraft.count)
            roadLastSample = tile
            return
        }
        guard roadDraft.count <= configuration.map.width * configuration.map.height else { return }
        let samples = roadLastSample.map { RoadGeometry.path(from:$0,to:tile,width:configuration.map.width,height:configuration.map.height) } ?? [tile]
        roadLastSample = tile
        for p in samples.isEmpty ? [tile] : samples {
            if let index = roadDraft.firstIndex(of: p) {
                roadDraft.removeSubrange((index + 1)..<roadDraft.count)
            } else {
                guard roadDraft.count <= configuration.map.width * configuration.map.height else { break }
                roadDraft.append(p)
            }
        }
    }
    func clearRoadStroke() { roadDraft = [];roadLastSample = nil }
    func exitRoadMode() { roadTool = nil;clearRoadStroke() }
    func confirmRoadStroke() {
        guard let tool = roadTool, !roadDraft.isEmpty else { return }
        if let issue = roadPreviewIssue { message = issue.localizedDescription;return }
        let existing = Set((state.roads ?? []).map(\.tile))
        let edited = roadDraft.filter { tile in
            switch tool { case .draw: !existing.contains(tile);case .replace, .erase: existing.contains(tile) }
        }
        if commitRoadEdit(at:edited,style:tool.style) {
            clearRoadStroke();message = "Road stroke applied · free decoration, no effect on era progress."
        }
    }
}
