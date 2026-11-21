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
    @State private var storageRole: RiverbendStorageRole?
    @State private var tile: Tile?
    @State private var selectedFind: RiverbendMapFindID?
    var body: some View {
        ZStack(alignment: .trailing) {
            if let scene, let lab = store?.lab {
                WalkthroughMapSurface(scene: scene, isPaused: phase != .active, civicTile: lab.engine.configuration.map.campfire,
                    candidateAt: { point in isCandidate(point, scene: scene, lab: lab) ? tile : nil },
                    onTap: { point in
                        if kind != nil {
                            guard !isCandidate(point, scene: scene, lab: lab) else { return }
                            tile = IsometricProjection.tile(point); refresh()
                        } else {
                            selectedFind = lab.find(near: WorldPoint(x: point.x, y: point.y), radius: 22 * (scene.camera?.xScale ?? 1))
                            error = ""
                        }
                    },
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
                            if !lab.checkpointReached {
                            ForEach([BuildingKind.hut, .gatheringShelter, .woodcutter], id: \.self) { value in
                                let definition = lab.engine.configuration.definition(value)
                                Button("\(definition.name) · \(Int(definition.cost.wood)) Wood · \(Int(definition.constructionSeconds ?? 0))s") {
                                    selectedFind = nil; storageRole = nil; kind = value; tile = lab.sites(for: value).first
                                    error = tile == nil ? "No affordable legal site. Use recovery if needed; complete the survey for Woodcutter." : ""
                                    refresh(); focusSelection()
                                }.disabled(lab.engine.state.buildings.contains { $0.kind == value })
                                    .accessibilityIdentifier("labBuild-" + value.rawValue)
                            }
                            }
                            if let kind {
                                Text("\(kind == .storehouse ? (storageRole == .granary ? "Granary" : "Stockyard") : lab.engine.configuration.definition(kind).name) at \(tile.map { "\($0.x),\($0.y)" } ?? "no site") · tap map or drag preview")
                                    .font(.caption).accessibilityIdentifier("labPlacement")
                                HStack {
                                    Button("Next site") {
                                        let sites = storageRole.map { lab.storageSites(for: $0) } ?? lab.sites(for: kind)
                                        if let tile, let index = sites.firstIndex(of: tile), !sites.isEmpty { self.tile = sites[(index + 1) % sites.count] }
                                        else { tile = sites.first }
                                        refresh()
                                    }.accessibilityIdentifier("labNextSite")
                                    Button("Confirm") {
                                        guard let tile else { return }
                                        if transact({ lab in
                                            if let storageRole { try lab.buildStorage(storageRole, at: tile) }
                                            else { try lab.build(kind, at: tile) }
                                        }) { self.kind = nil; self.tile = nil; refresh() }
                                    }.disabled(tile == nil || placementIssue(lab, kind: kind, tile: tile!) != nil).accessibilityIdentifier("labConfirmBuild")
                                    Button("Cancel") { self.kind = nil; tile = nil; refresh() }
                                }
                                if let tile, let issue = placementIssue(lab, kind: kind, tile: tile) { Text(issue.localizedDescription).font(.caption) }
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
                            if lab.checkpointReached {
                                if let source = lab.stoneSource {
                                    Text("Stone outcrop · \(source.x),\(source.y) · revealed reachable-land fixture; no depletion in this review").font(.caption).accessibilityIdentifier("labStoneSource")
                                    Button("Stone gatherer · 10 Wood · +5 Stone/min · 1 worker") {
                                        selectedFind = nil; storageRole = nil; kind = .stoneGatherer
                                        tile = lab.sites(for: .stoneGatherer).first
                                        error = tile == nil ? "Need 10 Wood and an open reachable outcrop site." : ""
                                        refresh(); focusSelection()
                                    }.disabled(lab.engine.state.buildings.contains { $0.kind == .stoneGatherer }).accessibilityIdentifier("labBuild-stoneGatherer")
                                    Text("Storage family · choose specialization. No workers or hauling bonus.").font(.caption.bold())
                                    ForEach(RiverbendStorageRole.allCases, id: \.self) { role in
                                        Button(role == .granary ? "Granary · 14 Wood + 4 Stone · +60 Food only" : "Stockyard · 18 Wood + 6 Stone · +60 Wood/Stone; never Food") {
                                            selectedFind = nil; storageRole = role; kind = .storehouse
                                            tile = lab.storageSites(for: role).first
                                            error = tile == nil ? "Need \(Int(role.cost.wood)) Wood + \(Int(role.cost.stone)) Stone and a clear site." : ""
                                            refresh(); focusSelection()
                                        }.disabled(lab.storage.contains { $0.role == role }).accessibilityIdentifier("labStorage-" + role.rawValue)
                                    }
                                    Text("Craft goods stay locked. Future Stockyard contract: +24 per unlocked craft material; never Knowledge/Culture.").font(.caption2)
                                    ForEach(lab.engine.state.buildings.filter { $0.kind == .stoneGatherer }) { building in
                                        Text("Stone: " + (lab.engine.state.resources.stone >= lab.engine.capacities.stone ? "Storage full · spend Stone or add Stockyard" : lab.engine.operatingStatus(building))).font(.caption)
                                    }
                                    Text("Third producer needs a third field slot for full output: population 5. Food keeps priority; growth supplies the slot.").font(.caption2)
                                } else {
                                    Button("Reveal nearby Stone outcrop · free") { _ = transact { try $0.revealStone() } }.accessibilityIdentifier("labRevealStone")
                                }
                            }
                            ForEach(lab.engine.state.buildings.filter { !$0.isOperational }) { building in
                                Text("\(lab.storage.first(where: { $0.buildingID == building.id }).map { $0.role == .granary ? "Granary" : "Stockyard" } ?? lab.engine.configuration.definition(building.kind).name): \(Int(ceil(building.constructionRemainingSeconds ?? 0)))s to finish").font(.caption)
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
                            Text(lab.engine.growthStatus.description).font(.caption)
                            Text("Review time: 1×. Pauses while closed; no offline catch-up. Actions save before publication.").font(.caption2)
                            if !error.isEmpty { Text(error).foregroundStyle(.red).font(.caption).accessibilityIdentifier("labError") }
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    Text(error.isEmpty ? "Opening separate lab…" : error).accessibilityIdentifier("labOpenError")
                    Text("No existing game was loaded or changed. Close and resolve this lab's file before retrying.").font(.caption)
                }
            }.padding(12).frame(width: 320).background(.regularMaterial)
        }.overlay(alignment: .bottomLeading) {
            if let id = selectedFind, let lab = store?.lab,
               let find = lab.availableFinds.first(where: { $0.id == id }), let site = find.tile {
                VStack(alignment: .leading, spacing: 8) {
                    Text(id == .berries ? "Wild berries" : "Fresh deer tracks").font(.headline)
                        .accessibilityIdentifier("labFindTitle")
                    Text(id == .berries ? "Gather +3 Food · once. Needs room for all 3." : "Observe this reachable wildlife clue. No reward, hunting, unlock or new territory.")
                        .font(.caption)
                    HStack {
                        Button(id == .berries ? "Gather +3 Food" : "Observe") {
                            if transact({ try $0.resolveFind(id, at: site) }) { selectedFind = nil }
                        }.accessibilityIdentifier("labResolveFind")
                        Button("Dismiss") { selectedFind = nil; error = "" }.accessibilityIdentifier("labDismissFind")
                    }
                    if !error.isEmpty { Text(error).font(.caption).foregroundStyle(.red).accessibilityIdentifier("labFindError") }
                }.padding(12).frame(width: 250).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12)).padding(12)
            }
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
        var deposits: [NaturalDeposit] = []
        if let source = lab.stoneSource, var outcrop = lab.engine.configuration.naturalDeposits?.first(where: { $0.resource == .stone }) {
            outcrop.origin = source; outcrop.accessSites = nil; outcrop.renewable = true
            deposits = [outcrop]
        }
        scene.display(state: lab.engine.state, kind: kind, tile: tile, valid: tile.map { placementIssue(lab, kind: kind ?? .hut, tile: $0) == nil } ?? false,
            inspected: nil, movingBuildingID: nil, centerRequest: 0, deposits: deposits, identifiedDepositIDs: Set(deposits.map(\.id)))
        scene.displayLabFinds(lab.mapFinds.filter { find in
            guard let tile = find.tile else { return false }
            return lab.legalFindSites.contains(tile) && (find.id == .tracks || !find.resolved)
        }, hidden: kind != nil)
        if let selectedFind, !lab.availableFinds.contains(where: { $0.id == selectedFind }) { self.selectedFind = nil }
    }
    private func placementIssue(_ lab: RiverbendEconomyLab, kind: BuildingKind, tile: Tile) -> GameError? {
        if let storageRole, kind == .storehouse { return lab.storageIssue(storageRole, at: tile) }
        return lab.issue(for: kind, at: tile)
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
        let foodBonus = Int(e.capacities.food - 60), woodBonus = Int(e.capacities.wood - 60), stoneBonus = Int(e.capacities.stone - 40)
        var text = String(format: "Food %.1f /%.0f (%+.1f/min) · cache60 +%d\nWood %.1f /%.0f (%+.1f/min) · cache60 +%d", e.state.resources.food, e.capacities.food, e.rates.food, foodBonus, e.state.resources.wood, e.capacities.wood, e.rates.wood, woodBonus)
        if lab.stoneSource != nil { text += String(format: "\nStone %.1f /%.0f (%+.1f/min) · cache40 +%d", e.state.resources.stone, e.capacities.stone, e.rates.stone, stoneBonus) }
        text += "\nPeople \(e.state.population) /\(e.housingCapacity) · field staff \(Int(e.workforceRequired)) /\(Int(e.workforceAvailable))"
        return text

    }
    private func machineStatus(_ lab: RiverbendEconomyLab) -> String {
        let e = lab.engine
        return "food=\(Int(e.state.resources.food)) wood=\(Int(e.state.resources.wood)) foodNet=\(e.rates.food) woodNet=\(e.rates.wood) knowledge=\(Int(e.state.resources.knowledge)) survey=\(lab.surveyComplete) checkpoint=\(lab.checkpointReached) buildings=\(e.state.buildings.count) stone=\(Int(e.state.resources.stone)) foodCap=\(Int(e.capacities.food)) woodCap=\(Int(e.capacities.wood)) stoneCap=\(Int(e.capacities.stone)) source=\(lab.stoneSource != nil) storage=\(lab.storage.count) " + lab.mapFinds.map { "\($0.id.rawValue)=\($0.tile.map { "\($0.x),\($0.y)" } ?? "none"),\($0.resolved ? "resolved" : "pending")" }.joined(separator: " ")
    }
    private func guide(_ lab: RiverbendEconomyLab) -> String {
        if lab.storage.count == 2 { return "Storage checkpoint: Granary holds Food; Stockyard holds materials. Review ends here." }
        if lab.stoneSource != nil { return "Gather Stone → choose Granary or Stockyard. Capacity starts when construction finishes." }
        if lab.checkpointReached { return "Food/Wood checkpoint. Optional next: reveal nearby Stone." }
        if !lab.hutComplete { return "First: build a Hut for 12 Wood and wait for completion." }
        if !lab.surveyComplete { return "Survey the nearby forest. Gathering Shelter (+8 Food/min) can be built alongside it." }
        if lab.engine.rates.wood <= 0 { return "Place Woodcutter at the surveyed forest edge (+6 Wood/min)." }
        return "Build Gathering Shelter for a Food surplus (+8 Food/min)."
    }
}

@MainActor private extension SettlementScene {
    func displayLabFinds(_ finds: [RiverbendMapFind], hidden: Bool) {
        childNode(withName: "riverbendMapFinds")?.removeFromParent()
        guard !hidden else { return }
        let layer = SKNode(); layer.name = "riverbendMapFinds"; layer.zPosition = 50_000
        for find in finds {
            guard let tile = find.tile else { continue }
            let marker = SKShapeNode(ellipseOf: CGSize(width: 36, height: 30))
            marker.position = IsometricProjection.point(tile)
            marker.fillColor = find.resolved ? .darkGray : find.id == .berries ? .systemPurple : .brown
            marker.strokeColor = .white; marker.lineWidth = 2
            let icon = SKLabelNode(fontNamed: "AvenirNext-Bold")
            icon.text = find.id == .berries ? "●●" : find.resolved ? "✓" : "⋮"
            icon.fontSize = 17; icon.verticalAlignmentMode = .center; marker.addChild(icon)
            let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
            label.text = find.id == .berries ? "Berries" : find.resolved ? "Observed" : "Tracks"
            label.fontSize = 12; label.position.y = 22; marker.addChild(label)
            layer.addChild(marker)
        }
        addChild(layer)
    }
}
#endif
