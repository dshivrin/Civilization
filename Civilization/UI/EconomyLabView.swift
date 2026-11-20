#if DEBUG
import SwiftUI
import SpriteKit
import GameCore
import GameApplication

struct EconomyLabView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var phase
    @State private var store: RiverbendEconomyLabStore?
    @State private var scene: SettlementScene?
    @State private var error = ""
    @State private var paused = false
    @State private var kind: BuildingKind?
    @State private var tile: Tile?
    var body: some View {
        ZStack(alignment: .trailing) {
            if let scene, let lab = store?.lab {
                WalkthroughMapSurface(scene: scene, isPaused: phase != .active, civicTile: lab.engine.configuration.map.campfire,
                    candidateAt: { point in isCandidate(point, scene: scene, lab: lab) ? tile : nil },
                    onTap: { point in guard kind != nil, !isCandidate(point, scene: scene, lab: lab) else { return }; tile = IsometricProjection.tile(point); refresh() },
                    onCandidateMove: { value in tile = value; refresh() }, mapLabel: "Persistent Riverbend Economy Lab map").ignoresSafeArea()
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Riverbend Economy Lab").font(.headline)
                    Spacer()
                    Button("Close") { dismiss() }.accessibilityIdentifier("closeEconomyLab")
                }
                Text("Debug v1 · separate save · terrain survey fixture").font(.caption2)
                if let lab = store?.lab {
                    Text(status(lab)).font(.subheadline.monospacedDigit())
                        .accessibilityIdentifier("economyLabStatus").accessibilityValue(machineStatus(lab))
                    ScrollView {
                        VStack(alignment: .leading, spacing: 9) {
                            Text(guide(lab)).font(.subheadline.bold()).accessibilityIdentifier("economyLabGuide")
                            ForEach([BuildingKind.hut, .gatheringShelter, .woodcutter], id: \.self) { value in
                                let definition = lab.engine.configuration.definition(value)
                                Button("\(definition.name) · \(Int(definition.cost.wood)) Wood · \(Int(definition.constructionSeconds ?? 0))s") {
                                    kind = value; tile = lab.sites(for: value).first
                                    error = tile == nil ? "No affordable legal site. Use recovery if needed; complete the survey for Woodcutter." : ""
                                    refresh(); focusSelection()
                                }.disabled(lab.engine.state.buildings.contains { $0.kind == value })
                                    .accessibilityIdentifier("labBuild-" + value.rawValue)
                            }
                            if let kind {
                                Text("\(lab.engine.configuration.definition(kind).name) at \(tile.map { "\($0.x),\($0.y)" } ?? "no site") · tap map or drag preview")
                                    .font(.caption).accessibilityIdentifier("labPlacement")
                                HStack {
                                    Button("Next site") {
                                        let sites = lab.sites(for: kind)
                                        if let tile, let index = sites.firstIndex(of: tile), !sites.isEmpty { self.tile = sites[(index + 1) % sites.count] }
                                        else { tile = sites.first }
                                        refresh()
                                    }.accessibilityIdentifier("labNextSite")
                                    Button("Confirm") {
                                        guard let tile else { return }
                                        if transact({ try $0.build(kind, at: tile) }) { self.kind = nil; self.tile = nil; refresh() }
                                    }.disabled(tile == nil || lab.issue(for: kind, at: tile!) != nil).accessibilityIdentifier("labConfirmBuild")
                                    Button("Cancel") { self.kind = nil; tile = nil; refresh() }
                                }
                                if let tile, let issue = lab.issue(for: kind, at: tile) { Text(issue.localizedDescription).font(.caption) }
                            }
                            if let remaining = lab.surveyRemaining {
                                Text("Forest survey · \(Int(ceil(remaining)))s left · 8 Food already paid").accessibilityIdentifier("labSurveyTimer")
                            } else if lab.surveyComplete {
                                Text("Whole forest surveyed · +6 Knowledge recorded once").font(.caption)
                            } else {
                                Button("Survey nearby forest · 8 Food · 60s") { _ = transact { try $0.startSurvey() } }
                                    .disabled(!lab.hutComplete || lab.engine.state.resources.food < 8).accessibilityIdentifier("labSurvey")
                                Text("Survey keeps both field workers available. Gathering Shelter is optional alongside it.").font(.caption2)
                            }
                            ForEach(lab.engine.state.buildings.filter { !$0.isOperational }) { building in
                                Text("\(lab.engine.configuration.definition(building.kind).name): \(Int(ceil(building.constructionRemainingSeconds ?? 0)))s to finish").font(.caption)
                            }
                            HStack {
                                Button("Forage to 12 Food") { _ = transact { try $0.recover(.food) } }.accessibilityIdentifier("labRecoverFood")
                                Button("Branches to \(lab.engine.state.buildings.contains { $0.kind == .hut } ? 8 : 12) Wood") { _ = transact { try $0.recover(.wood) } }.accessibilityIdentifier("labRecoverWood")
                            }.font(.caption)
                            Text("Recovery adds only the missing amount to the stated floor. No cost or reward above it.").font(.caption2)
                            HStack {
                                Button(paused ? "Resume" : "Pause") { paused.toggle() }.accessibilityIdentifier("labPause")
                                Button("+10s") { _ = transact { try $0.advance(by: 10) } }.accessibilityIdentifier("labAdvance10")
                                Button("+1 minute") { _ = transact { try $0.advance(by: 60) } }.accessibilityIdentifier("labAdvance60")
                            }
                            Text("Review time: 1×. Pauses while closed; no offline catch-up. Actions save before publication.").font(.caption2)
                            if !error.isEmpty { Text(error).foregroundStyle(.red).font(.caption).accessibilityIdentifier("labError") }
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    Text(error.isEmpty ? "Opening separate lab…" : error).accessibilityIdentifier("labOpenError")
                    Text("No existing game was loaded or changed. Close and resolve this lab's file before retrying.").font(.caption)
                }
            }.padding(12).frame(width: 320).background(.regularMaterial)
        }.task {
            open()
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
                if phase == .active && !paused && store != nil { _ = transact { try $0.advance(by: 1) } }
            }
        }
    }
    private func open() {
        do {
            let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("RiverbendDebugLabs", isDirectory: true)
            // Existing Debug UITest identity isolates this lab too; never changes the production root.
            let identifier = ProcessInfo.processInfo.environment["CIVILIZATION_UI_LIBRARY_ID"]
            let directory = identifier.map { root.appendingPathComponent($0) } ?? root
            store = try RiverbendEconomyLabStore(directory: directory, now: Date())
            let world = SettlementScene(configuration: store!.lab.engine.configuration)
            world.reviewContinuousFog = true
            scene = world; refresh(); focusSelection()
        } catch { self.error = error.localizedDescription; paused = true }
    }
    @discardableResult private func transact(_ command: (inout RiverbendEconomyLab) throws -> Void) -> Bool {
        guard var value = store else { return false }
        do { try value.perform(command); store = value; error = ""; refresh(); return true }
        catch { self.error = error.localizedDescription; paused = true; return false }
    }
    private func refresh() {
        guard let lab = store?.lab, let scene else { return }
        scene.display(state: lab.engine.state, kind: kind, tile: tile, valid: tile.map { lab.issue(for: kind ?? .hut, at: $0) == nil } ?? false,
            inspected: nil, movingBuildingID: nil, centerRequest: 0, deposits: [], identifiedDepositIDs: [])
    }
    private func isCandidate(_ point: CGPoint, scene: SettlementScene, lab: RiverbendEconomyLab) -> Bool {
        guard let kind, let tile else { return false }
        return lab.engine.configuration.definition(kind).footprint.tiles(at: tile).contains(IsometricProjection.tile(point)) || scene.previewContains(point)
    }
    private func focusSelection() {
        guard let lab = store?.lab, let scene else { return }
        scene.reviewReservedRightWidth = 320
        scene.reviewFocusTiles = lab.engine.configuration.tiles(within: 5).union(tile.map { [$0] } ?? [])
    }
    private func status(_ lab: RiverbendEconomyLab) -> String {
        let e = lab.engine
        return String(format: "Food %.1f /60  (%+.1f/min)\nWood %.1f /60  (%+.1f/min)\nPeople %d /%d · field staff %.0f /%.0f\n%@", e.state.resources.food, e.rates.food, e.state.resources.wood, e.rates.wood,
            e.state.population, e.housingCapacity, e.workforceRequired, e.workforceAvailable, e.growthStatus.description)
    }
    private func machineStatus(_ lab: RiverbendEconomyLab) -> String {
        let e = lab.engine
        return "food=\(Int(e.state.resources.food)) wood=\(Int(e.state.resources.wood)) foodNet=\(e.rates.food) woodNet=\(e.rates.wood) knowledge=\(Int(e.state.resources.knowledge)) survey=\(lab.surveyComplete) checkpoint=\(lab.checkpointReached) buildings=\(e.state.buildings.count)"
    }
    private func guide(_ lab: RiverbendEconomyLab) -> String {
        if lab.checkpointReached { return "Lab checkpoint reached · Food and Wood are growing. Stop here for review." }
        if !lab.hutComplete { return "First: build a Hut for 12 Wood and wait for completion." }
        if !lab.surveyComplete { return "Survey the nearby forest. Gathering Shelter (+8 Food/min) can be built alongside it." }
        if lab.engine.rates.wood <= 0 { return "Place Woodcutter at the surveyed forest edge (+6 Wood/min)." }
        return "Build Gathering Shelter for a Food surplus (+8 Food/min)."
    }
}
#endif
