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
    @State private var menu: String?
    @State private var tools = false
    @State private var category = "All"
    @State private var search = ""
    @FocusState private var searchFocused: Bool
    @State private var selected: BuildingKind = .hut
    @State private var scrollID: BuildingKind?
    @State private var requirement: FoundingCatalogAction?
    @State private var sourceHistory: [(kind: BuildingKind, requirement: FoundingCatalogAction?)] = []
    @State private var chapters = false
    @State private var placementKind: BuildingKind = .hut
    @Environment(\.dynamicTypeSize) private var textSize
    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Color(red: 0.10, green: 0.16, blue: 0.13).ignoresSafeArea()
                if let scene, let r = store?.review {
                    WalkthroughMapSurface(scene: scene, isPaused: phase != .active,
                        civicTile: r.engine.configuration.map.campfire,
                        candidateAt: { point in placing && scene.previewContains(point) ? tile : nil },
                        onTap: { point in mapTap(point) },
                        onCandidateMove: { tile = $0; refresh() }, mapLabel: "Riverbend founding review map").ignoresSafeArea()
                }
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Text("RIVERBEND").font(.headline)
                        if let r = store?.review {
                            Text("Wood \(Int(r.engine.state.resources.wood)) · Stone \(Int(r.engine.state.resources.stone)) · Food \(Int(r.engine.state.resources.food))")
                                .font(.caption.monospacedDigit()).accessibilityIdentifier("foundingStatus").accessibilityValue(machine(r))
                        }
                        Spacer(minLength: 0)
                        Button("Build") { menu = "Build"; tools = false }.accessibilityIdentifier("foundingCatalog")
                        Button("Close") { dismiss() }.accessibilityIdentifier("closeFoundingReview")
                    }.padding(.horizontal, 8).background(panelColor.opacity(0.97)).opacity(menu == "Build" ? 0 : 1).accessibilityHidden(menu == "Build")
                    HStack(alignment: .top, spacing: 8) {
                        VStack(spacing: 4) {
                            ForEach(["Goals", "Explore", "Games"], id: \.self) { title in
                                Button { menu = menu == title ? nil : title; tools = false } label: {
                                    VStack(spacing: 2) {
                                        Image(systemName: title == "Goals" ? "flag" : title == "Explore" ? "map" : "square.grid.2x2")
                                        Text(title).font(.caption)
                                    }.frame(minWidth: 64, minHeight: 44)
                                }.accessibilityIdentifier("foundingRail-" + title)
                                    .accessibilityLabel(title).accessibilityValue(menu == title ? "Selected" : "Closed")
                            }
                        }.padding(4).background(panelColor.opacity(0.97), in: RoundedRectangle(cornerRadius: 12))
                        Spacer(minLength: 0)
                        if let r = store?.review, menu != "Build" {
                            if tools || placing || drawing { reviewPanel(r).frame(width: min(290, geometry.size.width * 0.38)) }
                            else if let menu { menuPanel(menu, r).frame(width: min(isPad ? 350 : 300, geometry.size.width * 0.43)) }
                        }
                    }
                    Spacer(minLength: 0)
                }
                if let r = store?.review, menu == "Build" {
                    catalog(r, height: max(44, geometry.size.height - 8))
                        .padding(.leading, 82)
                        .onDisappear { endSearch() }
                }
            }.buttonStyle(FoundingReviewButtonStyle()).controlSize(.regular)
                .foregroundStyle(parchment).tint(.yellow)
        }.task { open() }
            .onChange(of: menu) { _, _ in endSearch() }
            .onChange(of: requirement) { _, _ in endSearch() }
            .onReceive(timer) { _ in if !paused && phase == .active { transact { try $0.advance(seconds: 1) } } }
    }
    private func menuPanel(_ title: String, _ r: RiverbendFoundingReview) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack { Text(title).font(.headline); Spacer(); Button("Done") { menu = nil }.accessibilityIdentifier("foundingMenuDone") }
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if title == "Goals" {
                        Text(r.objective).font(.headline).accessibilityIdentifier("foundingObjective")
                        Text(!r.founded ? "Shelter the camp in place. Founding needs no road or research." : r.hut == nil ? "Choose a hut site outside the Lodge yard; connect it after building." : !r.hut!.isOperational ? "Paid construction continues while disconnected. Resume time to finish." : "Ordinary buildings need a cardinal path to any full Lodge edge.")
                            .font(.subheadline).fixedSize(horizontal: false, vertical: true)
                        Button(!r.founded ? "Found Founder’s Lodge" : r.hut == nil ? "Choose hut" : !r.hut!.isOperational ? "Resume construction" : "Open Roads") {
                            if !r.founded { transact { try $0.found() }; focus() }
                            else if r.hut == nil { selected = .hut; menu = "Build" }
                            else if !r.hut!.isOperational { paused = false; menu = nil }
                            else { drawing = true; draft = []; menu = nil; refresh() }
                        }.accessibilityIdentifier("foundingGoalAction")
                        if !r.founded { Text("12 Wood + 4 Stone").font(.caption) }
                        Button { chapters.toggle() } label: {
                            HStack { Text("All chapters"); Spacer(); Image(systemName: chapters ? "chevron.down" : "chevron.right") }
                        }.accessibilityIdentifier("foundingChapters").accessibilityValue(chapters ? "Expanded" : "Collapsed")
                        if chapters {
                            ForEach(r.engine.journeyChapters, id: \.id) { chapter in Text(chapter.title).font(.caption).frame(maxWidth: .infinity, alignment: .leading) }
                        }
                    } else if title == "Explore" {
                        Text("Pan open map with one finger; pinch to zoom. Building and path previews use map taps. Close those tools to pan freely.")
                            .fixedSize(horizontal: false, vertical: true)
                        Button("Return to map") { menu = nil }.accessibilityIdentifier("foundingExploreMap")
                    } else {
                        Text("Isolated founding review · separate save. Reopening grants no offline time.").font(.subheadline)
                        Button("Review controls") { tools = true; menu = nil }.accessibilityIdentifier("foundingTools")
                        Button("Return to your game") { dismiss() }
                    }
                }
            }
        }.padding(10).background(panelColor.opacity(0.97), in: RoundedRectangle(cornerRadius: 12))
    }
    private func reviewPanel(_ r: RiverbendFoundingReview) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack { Text(drawing ? "Roads" : placing ? "Place" : "Review").font(.headline); Spacer()
                Button("Done") { tools = false; placing = false; drawing = false; draft = []; refresh() }.accessibilityIdentifier("foundingToolsDone") }
            Text(r.objective).font(.caption).accessibilityIdentifier("foundingObjective")
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if placing {
                        let definition = r.engine.configuration.definition(placementKind)
                        Text(definition.name + " · " + amounts(definition.cost)).font(.subheadline)
                        Text("Tap open land or drag the outline. Keep the civic yard clear. A path is required for service.").font(.caption).fixedSize(horizontal: false, vertical: true)
                        if placementKind == .hut {
                            Button("Next legal plot · fallback") {
                                let sites = r.hutSites
                                if let tile, let i = sites.firstIndex(of: tile), !sites.isEmpty { self.tile = sites[(i + 1) % sites.count] }
                                refresh()
                            }.accessibilityIdentifier("foundingNextSite")
                        }
                    } else if drawing {
                        Text("Tap each bend; free cardinal strokes join the samples. Yellow is a preview. Confirm to connect. Close Roads to pan; pinch to zoom. Terrain remains protected.")
                            .font(.caption).fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("foundingRoadHelp")
                        Text("\(draft.count) preview tiles · free").font(.caption)
                    } else { controls(r) }
                    if !inspection.isEmpty { Text(inspection).font(.caption).accessibilityIdentifier("foundingInspection") }
                    if !error.isEmpty { Text(error).foregroundStyle(.yellow).accessibilityIdentifier("foundingError") }
                    if !placing && !drawing {
                        Divider()
                        Button(paused ? "Resume 1× time" : "Pause time") { paused.toggle() }.accessibilityIdentifier("foundingPause")
                        Button("Review step · advance 60 seconds") { transact { try $0.advance(seconds: 60) } }.accessibilityIdentifier("foundingAdvance60")
                        Text("Separate simulation · paused on reopen · no offline time.").font(.caption2)
                    }
                }
            }.accessibilityIdentifier("foundingControls")
            if placing {
                Button(placementKind == .hut ? "Build hut" : "Confirm building") {
                    if let tile, transact({ try $0.build(placementKind, at: tile) }) { placing = false; self.tile = nil; refresh() }
                }.disabled(tile == nil || (placementKind == .hut ? r.hutIssue(at: tile!) : r.catalogPlacementIssue(placementKind, at: tile!)) != nil)
                    .accessibilityIdentifier(placementKind == .hut ? "foundingConfirmHut" : "foundingConfirmBuilding")
            }
            if drawing {
                HStack {
                    Button("Confirm path") { if transact({ try $0.editPath(draft) }) { drawing = false; draft = []; refresh() } }
                        .disabled(draft.isEmpty).accessibilityIdentifier("foundingConfirmPath")
                    Button("Cancel") { drawing = false; draft = []; refresh() }.accessibilityIdentifier("foundingCancelPath")
                }
            }
        }.padding(10).background(panelColor.opacity(0.97), in: RoundedRectangle(cornerRadius: 12))
    }
    private func catalog(_ r: RiverbendFoundingReview, height: CGFloat) -> some View {
        ZStack(alignment: .top) {
        VStack(spacing: 4) {
            HStack {
                Text("Build").font(.headline)
                TextField("Search buildings", text: $search).textFieldStyle(.plain).padding(.horizontal, 8).frame(minHeight: 44).background(.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 8)).accessibilityLabel("Search buildings").focused($searchFocused).submitLabel(.done).onSubmit { endSearch() }.accessibilityIdentifier("foundingSearch")
                Button("Done") { endSearch(); menu = nil }.accessibilityIdentifier("foundingCatalogDone")
            }
            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    ForEach(["All", "Roads"] + Array(Set(r.engine.configuration.buildings.compactMap(\.category))).sorted(), id: \.self) { name in
                        Button(name) { category = name }.accessibilityIdentifier("foundingCategory-" + name)
                            .accessibilityValue(category == name ? "Selected" : "Not selected")
                    }
                }
            }.fixedSize(horizontal: false, vertical: true)
            if category == "Roads" {
                VStack(alignment: .leading, spacing: 8) {
                    ScrollView { Text("Free paths connect services to any full Lodge edge. Tap each bend on clear land; a cardinal stroke joins the samples. Yellow shows the preview. Confirm commits the whole stroke. Terrain stays protected. Close Roads to pan; pinch to zoom.")
                        .fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("foundingCatalogRoadHelp") }.accessibilityIdentifier("foundingRoadInstructions")
                    Button("Draw free path") { menu = nil; drawing = true; placing = false; draft = []; refresh() }.disabled(!r.founded).accessibilityIdentifier("foundingCatalogRoads")
                }
            } else {
                if isPad {
                    HStack(alignment: .top, spacing: 10) { catalogGrid(r); inspector(r).frame(width: 310) }
                } else {
                    VStack(spacing: 4) { catalogGrid(r); inspector(r).frame(height: textSize.isAccessibilitySize ? 140 : 152) }
                }
            }
        }.padding(8).frame(maxWidth: .infinity).frame(height: height, alignment: .top)
            .background(panelColor.opacity(0.99), in: RoundedRectangle(cornerRadius: 12)).padding(.trailing, 4)
            .accessibilityHidden(requirement != nil)
            .allowsHitTesting(requirement == nil)
            if let requirement { requirementPanel(requirement, r).padding(.trailing, 4) }
        }.frame(height: height, alignment: .top)
    }
    private func catalogGrid(_ r: RiverbendFoundingReview) -> some View {
        let matches = r.engine.configuration.buildings.filter { $0.kind != .campfire && (category == "All" || $0.category == category) && (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)) }
        return ScrollViewReader { proxy in
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 180))], spacing: 8) {
                ForEach(matches, id: \.kind) { definition in
                    Button { selected = definition.kind; sourceHistory = []; endSearch() } label: {
                        VStack(spacing: 3) {
                            BuildingThumbnail(kind: definition.kind, size: 36)
                            Text(definition.name).font(.subheadline).lineLimit(2)
                        }.frame(maxWidth: .infinity).frame(height: textSize.isAccessibilitySize ? (isPad ? 140 : 110) : 92)
                    }.overlay(RoundedRectangle(cornerRadius: 8).stroke(selected == definition.kind ? .yellow : .clear, lineWidth: 2))
                        .accessibilityIdentifier("foundingCard-" + definition.kind.rawValue)
                        .accessibilityValue(selected == definition.kind ? "Selected" : "Not selected").id(definition.kind)
                }
            }.scrollTargetLayout()
            if matches.isEmpty { Text("No matching buildings. Your selected building is retained in the inspector.").font(.caption).accessibilityIdentifier("foundingNoMatches") }
        }.scrollPosition(id: $scrollID, anchor: .top).accessibilityIdentifier("foundingCatalogGrid").accessibilityValue(scrollID?.rawValue ?? "top")
        .onAppear { if let scrollID { proxy.scrollTo(scrollID, anchor: .top) } }
        }
    }
    private func inspector(_ r: RiverbendFoundingReview) -> some View {
        let definition = r.engine.configuration.definition(selected)
        let action = r.catalogAction(selected)
        return VStack(alignment: .leading, spacing: 4) {
            ScrollView {
                VStack(alignment: .leading, spacing: 3) {
                    if let previous = sourceHistory.last {
                        Button("Return to " + r.engine.configuration.definition(previous.kind).name) {
                            if let context = sourceHistory.popLast() { selected = context.kind; requirement = context.requirement }
                        }.accessibilityIdentifier("foundingSourceBack")
                    }
                    Text(definition.name).font(.headline).accessibilityIdentifier("foundingSelectedName")
                    Text(definition.description ?? definition.name).font(.subheadline).fixedSize(horizontal: false, vertical: true)
                    Text("Price: " + amounts(definition.cost)).font(.caption).accessibilityIdentifier("foundingPrice")
                    let needs = r.materialNeeds(for: definition.cost)
                    if !needs.isEmpty { Text("Short: " + needs.map { "\(String(format: "%g", $0.amount)) \($0.resource.title)" }.joined(separator: " · ")).font(.caption).foregroundStyle(.orange) }
                    if let issue = r.engine.bootstrapSpendIssue(for: definition.cost, constructing: selected) { Text(issue.localizedDescription).font(.caption).foregroundStyle(.orange) }
                    if definition.housing > 0 { Text("Output: +\(definition.housing) housing").font(.caption) }
                    ForEach(definition.recipes ?? [], id: \.id) { recipe in Text(recipe.name + ": " + amounts(recipe.outputsPerMinute) + "/min" + (Resource.allCases.contains { recipe.inputsPerMinute[$0] > 0 } ? " · uses " + amounts(recipe.inputsPerMinute) + "/min" : "")).font(.caption) }
                    if let bonus = definition.storageBonus { Text("Storage: " + amounts(bonus)).font(.caption) }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }.accessibilityIdentifier("foundingInspectorDetails")
            Button(action == .build ? "Build" : action == .materials ? "Find materials" : "Open required research") {
                endSearch()
                if action == .build {
                    placementKind = selected; placing = true; drawing = false; menu = nil; tools = false
                    tile = selected == .hut ? r.hutSites.first : r.engine.configuration.tiles(within: 6).first { candidate in
                        let center = r.engine.configuration.map.campfire
                        return r.engine.configuration.definition(selected).footprint.tiles(at: candidate).allSatisfy { abs($0.x - center.x) + abs($0.y - center.y) >= 3 } && r.catalogPlacementIssue(selected, at: candidate) == nil
                    }; refresh(); focus()
                } else { requirement = action }
            }.frame(maxWidth: .infinity, minHeight: 44).disabled(!r.founded || (selected == .hut && r.hut != nil))
                .accessibilityIdentifier("foundingCatalogAction")
                .accessibilityHint("For " + definition.name)
        }.padding(8).background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
            .accessibilityElement(children: .contain)
    }
    private func requirementPanel(_ action: FoundingCatalogAction, _ r: RiverbendFoundingReview) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button("Back to " + r.engine.configuration.definition(selected).name) { requirement = nil }.accessibilityIdentifier("foundingRequirementBack")
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if case .research(let id) = action, let tech = r.engine.configuration.technologyDefinitions.first(where: { $0.id == id }) {
                        Text(tech.name).font(.headline).accessibilityIdentifier("foundingRequiredTechnology")
                        Text("Required for " + r.engine.configuration.definition(selected).name + ". Earlier prerequisites are shown first.").font(.subheadline)
                        Text("Price: " + amounts(tech.cost)).font(.caption)
                        if let issue = r.engine.researchIssue(id) {
                            Text(issue.localizedDescription).font(.caption)
                            materialSources(r.materialNeeds(for: tech.cost), r)
                            if let supplier = r.researchSupplier(id) {
                                Button("Show " + r.engine.configuration.definition(supplier).name) { showSource(supplier) }.accessibilityIdentifier("foundingResearchSupplier")
                            }
                        }
                        Button("Research " + tech.name) { if transact({ try $0.research(id) }) { requirement = r.catalogAction(selected) == .build ? nil : r.catalogAction(selected) } }
                            .disabled(r.engine.researchIssue(id) != nil).accessibilityIdentifier("foundingResearchCommit")
                    } else {
                        Text("Materials for " + r.engine.configuration.definition(selected).name).font(.headline).accessibilityIdentifier("foundingRequiredMaterials")
                        materialSources(r.materialNeeds(for: r.engine.configuration.definition(selected).cost), r)
                        if let supplier = r.engine.bootstrapRequirement(for: r.engine.configuration.definition(selected).cost, constructing: selected) {
                            Text("Preserve starter supplies: establish " + r.engine.configuration.definition(supplier).name + " first.")
                            Button("Show " + r.engine.configuration.definition(supplier).name) { showSource(supplier) }.accessibilityIdentifier("foundingReservedSupplier")
                        }
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
        }.padding(12).frame(maxWidth: .infinity, maxHeight: .infinity).background(panelColor)
    }
    private func materialSources(_ needs: [FoundingMaterialNeed], _ r: RiverbendFoundingReview) -> some View {
        ForEach(needs, id: \.resource) { need in
            VStack(alignment: .leading, spacing: 4) {
                Text("Need \(String(format: "%g", need.amount)) more \(need.resource.title)").font(.headline)
                ForEach(need.suppliers, id: \.self) { kind in
                    let existing = r.engine.state.buildings.filter { $0.kind == kind }
                    Button(r.engine.configuration.definition(kind).name + (existing.isEmpty ? " · view source" : " · check workers, path and production")) {
                        showSource(kind)
                    }.disabled(kind == .campfire).accessibilityIdentifier("foundingSource-" + kind.rawValue)
                }
                Text("Select a source to check its full cost and required research before commitment. Return preserves your original selection.").font(.caption)
            }
        }
    }
    private func endSearch() {
        searchFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    private func showSource(_ kind: BuildingKind) {
        sourceHistory.append((selected, requirement)); selected = kind; requirement = nil; endSearch()
    }
    private func amounts(_ value: ResourceAmounts) -> String {
        let values = Resource.allCases.filter { value[$0] > 0 }.map { "\(String(format: "%g", value[$0])) \($0.title)" }
        return values.isEmpty ? "Free" : values.joined(separator: " · ")
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
                    placementKind = .hut; placing = true; drawing = false; tile = r.hutSites.first; refresh(); focus()
                }.accessibilityIdentifier("foundingChooseHut")
            }
            if let hut = r.hut {
                Text(hut.isOperational ? (r.engine.isServiceOperational(hut) ? "Hut active · housing is available." : "Inactive · needs a path to the Lodge. Reserves and completed work are preserved.") : "Hut construction is paid. It completes even while disconnected; housing activates only with a path.")
                    .font(.subheadline).accessibilityIdentifier("foundingConnectionExplanation")
                Button("Draw path · tap map tiles") { drawing = true; placing = false; draft = []; refresh() }
                    .accessibilityIdentifier("foundingDrawPath")
                Button("Preview suggested free route") {
                    drawing = true; placing = false; draft = r.route(to: hut.origin); refresh()
                }.accessibilityIdentifier("foundingSuggestPath")
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
            placementKind = .hut; placing = true; tile = hit; refresh()
        }
        else if let id = scene.buildingID(at: point), let b = r.engine.state.buildings.first(where: { $0.id == id }) {
            inspection = r.engine.buildingName(b) + " · civic/building ID \(id) · " + (r.engine.isServiceOperational(b) ? "active" : "path required")
        }
    }
    private func refresh() {
        guard let r = store?.review, let scene else { return }
        scene.display(state: r.engine.state, kind: placing ? placementKind : nil, tile: tile,
            valid: tile.map { (placementKind == .hut ? r.hutIssue(at: $0) : r.catalogPlacementIssue(placementKind, at: $0)) == nil } ?? false,
            inspected: nil, movingBuildingID: nil, roadTool: drawing ? .draw(.trodden) : nil, roadDraft: draft,
            roadInvalid: draft.contains { r.engine.roadIssue(at: $0) != nil }, centerRequest: 0,
            deposits: [], identifiedDepositIDs: [])
        let hints = r.hut == nil ? Array(r.hutSites.prefix(2)) : []
        scene.reviewMapTargets = Dictionary(uniqueKeysWithValues: hints.enumerated().map { ("plot\($0.offset)", $0.element) })
        if let tile, placing { scene.reviewMapTargets["candidate"] = tile }
        if let hut = r.hut {
            for (index, tile) in r.route(to: hut.origin).enumerated() { scene.reviewMapTargets["route\(index)"] = tile }
        }
        scene.displayFoundingHints(sites: hints, entrance: r.founded && r.engine.state.roads?.contains { $0.tile == r.entrance } == true ? r.entrance : nil)
    }
    private func focus() {
        guard let r = store?.review, let scene else { return }
        scene.reviewReservedRightWidth = isPad ? 370 : 325
        scene.reviewFocusTiles = Set([r.engine.configuration.map.campfire] + Array(r.hutSites.prefix(2)) + (tile.map { [$0] } ?? []) + (r.hut.map { [$0.origin] } ?? []))
    }
    private func machine(_ r: RiverbendFoundingReview) -> String {
        let s = r.engine.state
        return "civic=\(r.engine.civicCenter?.id ?? -1) level=\(r.engine.civicLevel) wood=\(Int(s.resources.wood)) stone=\(Int(s.resources.stone)) food=\(Int(s.resources.food)) roads=\(s.roads?.count ?? 0) story=\(s.completedGoals.contains(.storytellingCircle) ? 1 : 0) civicHistory=\(s.civicProgress?.reachedLevels.count ?? 0) goals=\(s.completedGoals.count) active=\(r.hut.map { r.engine.isServiceOperational($0) ? 1 : 0 } ?? 0) sites=\(r.hutSites.count)"
    }
}
private struct FoundingReviewButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.padding(.horizontal, 8).frame(minWidth: 44, minHeight: 44)
            .background(.white.opacity(configuration.isPressed ? 0.18 : 0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}
#endif
