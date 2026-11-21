#if DEBUG
import SwiftUI
import SpriteKit
import GameCore
import GameApplication

/// Integrated native review, opened only from Debug tools with its own save root.
struct FoundingReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var phase
    @State private var store: RiverbendFoundingStore?
    @State private var scene: SettlementScene?
    @State private var tile: Tile?
    @State private var placing = false
    @State private var drawing = false
    @State private var draft: [Tile] = []
    @State private var error = ""
    @State private var paused = true
    @State private var inspection = ""
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                Color(red: 0.10, green: 0.16, blue: 0.13).ignoresSafeArea()
                if let scene, let r = store?.review {
                    WalkthroughMapSurface(scene: scene, isPaused: phase != .active,
                        civicTile: r.engine.configuration.map.campfire,
                        candidateAt: { point in placing && scene.previewContains(point) ? tile : nil },
                        onTap: { point in mapTap(point) },
                        onCandidateMove: { tile = $0; refresh() }, mapLabel: "Riverbend founding review map").ignoresSafeArea()
                }
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("RIVERBEND · FOUNDING").font(.headline)
                        Spacer()
                        Button("Close") { dismiss() }.accessibilityIdentifier("closeFoundingReview")
                    }
                    Text("Debug review · separate save · \(paused ? "paused" : "1×")")
                        .font(.caption)
                    if let r = store?.review {
                        Text("Wood \(Int(r.engine.state.resources.wood)) · Stone \(Int(r.engine.state.resources.stone)) · Food \(Int(r.engine.state.resources.food))")
                            .font(.subheadline.monospacedDigit()).accessibilityIdentifier("foundingStatus").accessibilityValue(machine(r))
                        Text(r.objective).font(.headline).accessibilityIdentifier("foundingObjective")
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                controls(r)
                                if !inspection.isEmpty { Text(inspection).font(.caption).accessibilityIdentifier("foundingInspection") }
                                if !error.isEmpty { Text(error).foregroundStyle(.yellow).accessibilityIdentifier("foundingError") }
                                Divider()
                                Button(paused ? "Resume 1× time" : "Pause time") { paused.toggle() }.accessibilityIdentifier("foundingPause")
                                Button("Review step · advance 60 seconds") { transact { try $0.advance(seconds: 60) } }
                                    .accessibilityIdentifier("foundingAdvance60")
                                Text("Review steps advance this separate simulation. Reopening grants no offline time.").font(.caption2)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }.accessibilityIdentifier("foundingControls")
                    } else { Text(error.isEmpty ? "Opening review…" : error) }
                }
                .buttonStyle(.bordered).controlSize(.regular)
                .frame(width: min(290, geometry.size.width * 0.35))
                .padding(12).background(panelColor.opacity(0.97), in: RoundedRectangle(cornerRadius: 14))
                .padding(.trailing, 12).padding(.vertical, 8)
                .foregroundStyle(parchment).tint(.yellow)
            }
        }.task { open() }
            .onReceive(timer) { _ in if !paused && phase == .active { transact { try $0.advance(seconds: 1) } } }
    }
    @ViewBuilder private func controls(_ r: RiverbendFoundingReview) -> some View {
        if !r.founded {
            Text("Shelter the founding camp in place. 12 Wood + 4 Stone. No research or roads needed; no resource award. Civic identity and footprint stay fixed.").font(.subheadline)
            Button("Found Founder’s Lodge · 12 Wood + 4 Stone") { transact { try $0.found() }; focus() }
                .accessibilityIdentifier("foundingUpgrade")
        } else {
            Text(r.hut == nil ? "Free footpath at the door. Build a hut, then connect any hut edge to any full Lodge edge. The Lodge always works." : (r.engine.state.roads?.contains { $0.tile == r.entrance } == true ? "Paths are free. Any full civic edge connects." : "Path removed · draw or preview a free replacement." )).font(.subheadline)
            if r.hut == nil {
                Button("Choose recommended hut plot") {
                    placing = true; drawing = false; tile = r.hutSites.first; refresh(); focus()
                }.accessibilityIdentifier("foundingChooseHut")
                if placing {
                    Text("Hut · \(Int(r.engine.configuration.definition(.hut).cost.wood)) Wood · tap open land or drag the outline. Keep the civic yard clear.").font(.caption)
                    Button("Next legal plot · fallback") {
                        let sites = r.hutSites
                        if let tile, let i = sites.firstIndex(of: tile), !sites.isEmpty { self.tile = sites[(i + 1) % sites.count] }
                        refresh()
                    }.accessibilityIdentifier("foundingNextSite")
                    Button("Build hut") {
                        if let tile, transact({ try $0.buildHut(at: tile) }) { placing = false; self.tile = nil; refresh() }
                    }.disabled(tile == nil || r.hutIssue(at: tile!) != nil)
                        .accessibilityIdentifier("foundingConfirmHut")
                }
            }
            if let hut = r.hut {
                Text(hut.isOperational ? (r.engine.isServiceOperational(hut) ? "Hut active · housing is available." : "Inactive · needs a path to the Lodge. Reserves and completed work are preserved.") : "Hut construction is paid. It completes even while disconnected; housing activates only with a path.")
                    .font(.subheadline).accessibilityIdentifier("foundingConnectionExplanation")
                Button("Draw path · tap map tiles") { drawing = true; placing = false; draft = []; refresh() }
                    .accessibilityIdentifier("foundingDrawPath")
                Button("Preview suggested free route") {
                    drawing = true; placing = false; draft = r.route(to: hut.origin); refresh()
                }.accessibilityIdentifier("foundingSuggestPath")
                if drawing {
                    Text("Tap each bend; a free cardinal stroke joins the samples. Yellow is a preview. Confirm to connect; terrain remains protected.").font(.caption)
                    Button("Confirm free path") {
                        if transact({ try $0.editPath(draft) }) { drawing = false; draft = []; refresh() }
                    }.disabled(draft.isEmpty).accessibilityIdentifier("foundingConfirmPath")
                    Button("Cancel path") { drawing = false; draft = []; refresh() }
                }
                Button("Disconnect paths · retain progress") { transact { try $0.disconnect() } }
                    .accessibilityIdentifier("foundingDisconnect")
            }
        }
    }
    private func open() {
        guard store == nil else { return }
        do {
            let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("RiverbendFoundingReviews", isDirectory: true)
            let id = ProcessInfo.processInfo.environment["CIVILIZATION_UI_LIBRARY_ID"]
            store = try RiverbendFoundingStore(directory: id.map { root.appendingPathComponent($0) } ?? root, now: Date())
            scene = SettlementScene(configuration: store!.review.engine.configuration)
            refresh(); focus()
        } catch { self.error = error.localizedDescription }
    }
    @discardableResult private func transact(_ command: (inout RiverbendFoundingReview) throws -> Void) -> Bool {
        guard var value = store else { return false }
        do { try value.perform(command); store = value; error = ""; refresh(); return true }
        catch { self.error = error.localizedDescription; paused = true; return false }
    }
    private func mapTap(_ point: CGPoint) {
        guard let r = store?.review, let scene else { return }
        let hit = IsometricProjection.tile(point)
        if drawing {
            if let last = draft.last {
                draft += RoadGeometry.path(from: last, to: hit, width: r.engine.configuration.map.width, height: r.engine.configuration.map.height).dropFirst()
            } else { draft = [hit] }
            refresh()
        } else if placing { tile = hit; refresh() }
        else if r.founded && r.hut == nil && r.hutSites.prefix(2).contains(hit) {
            placing = true; tile = hit; refresh()
        }
        else if let id = scene.buildingID(at: point), let b = r.engine.state.buildings.first(where: { $0.id == id }) {
            inspection = r.engine.buildingName(b) + " · civic/building ID \(id) · " + (r.engine.isServiceOperational(b) ? "active" : "path required")
        }
    }
    private func refresh() {
        guard let r = store?.review, let scene else { return }
        scene.display(state: r.engine.state, kind: placing ? .hut : nil, tile: tile,
            valid: tile.map { r.hutIssue(at: $0) == nil } ?? false,
            inspected: nil, movingBuildingID: nil, roadTool: drawing ? .draw(.trodden) : nil, roadDraft: draft,
            roadInvalid: draft.contains { r.engine.roadIssue(at: $0) != nil }, centerRequest: 0,
            deposits: [], identifiedDepositIDs: [])
        let hints = r.hut == nil ? Array(r.hutSites.prefix(2)) : []
        scene.reviewMapTargets = Dictionary(uniqueKeysWithValues: hints.enumerated().map { ("plot\($0.offset)", $0.element) })
        if let hut = r.hut {
            for (index, tile) in r.route(to: hut.origin).enumerated() { scene.reviewMapTargets["route\(index)"] = tile }
        }
        scene.displayFoundingHints(sites: hints, entrance: r.founded && r.engine.state.roads?.contains { $0.tile == r.entrance } == true ? r.entrance : nil)
    }
    private func focus() {
        guard let r = store?.review, let scene else { return }
        scene.reviewReservedRightWidth = 325
        scene.reviewFocusTiles = Set([r.engine.configuration.map.campfire] + Array(r.hutSites.prefix(2)) + (tile.map { [$0] } ?? []) + (r.hut.map { [$0.origin] } ?? []))
    }
    private func machine(_ r: RiverbendFoundingReview) -> String {
        let s = r.engine.state
        return "civic=\(r.engine.civicCenter?.id ?? -1) level=\(r.engine.civicLevel) wood=\(Int(s.resources.wood)) stone=\(Int(s.resources.stone)) food=\(Int(s.resources.food)) roads=\(s.roads?.count ?? 0) story=\(s.completedGoals.contains(.storytellingCircle) ? 1 : 0) civicHistory=\(s.civicProgress?.reachedLevels.count ?? 0) goals=\(s.completedGoals.count) active=\(r.hut.map { r.engine.isServiceOperational($0) ? 1 : 0 } ?? 0) sites=\(r.hutSites.count)"
    }
}
#endif
