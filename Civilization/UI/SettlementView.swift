import UIKit
import GameApplication
import SwiftUI
import GameCore

let parchment = Color(red: 0.94, green: 0.89, blue: 0.76)
let panelColor = Color(red: 0.16, green: 0.17, blue: 0.165)

struct SettlementView: View {
    @Environment(\.scenePhase) private var phase
    let session: GameSession
    let openGames: (() -> Void)?
    let managesLifecycle: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pendingCompletionCues: Set<CompletionDestination> = []
    @State private var pulsingCompletionCues: Set<CompletionDestination> = []
    @State private var completionPulseOpacity = 0.0
    @State private var completionPulseTask: Task<Void, Never>?
    @State private var scene: SettlementScene? = nil
    @State private var inspectedResource: ResourceInspection?
    @State private var showPopulation = false
    @State private var worldReady = false
    @State private var goals = SettlementGoalsDisclosure(eraID: "stoneAge")
    @State private var category = "All"
    @State private var playerCatalogMemory = PlayerCatalogMemory()
    @State private var researchPillar: DevelopmentPillar = .science
    @State private var showResearch = false
    @State private var civicResearchID: String?
    @State private var researchReturnLabel = "Return to civic center"
    @State private var focusedBuildingKind: BuildingKind?
    @State private var returnToJourney = false
    @State private var showCatalog = false
    @State private var showJourney = false
    @State private var pendingGuidanceAction: GuidanceAction?
    #if DEBUG
    @State private var showDeveloperTools = false
    #endif
    private struct ResourceInspection: Identifiable { let resource: Resource; var id: String { resource.rawValue } }
    @State private var panel: Panel?
    enum Panel { case build, explore }
    init(session: GameSession, openGames: (() -> Void)? = nil, managesLifecycle: Bool = true) {
        self.session = session
        self.openGames = openGames; self.managesLifecycle = managesLifecycle
    }
    private var worldIsObscured: Bool {
        #if DEBUG
        showResearch || showCatalog || showJourney || showDeveloperTools
        #else
        showResearch || showCatalog || showJourney
        #endif
    }
    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 500
            ZStack {
                if let scene {
                    WorldView(scene: scene, session: session, onReady: { worldReady = true }, isObscured: worldIsObscured, onMapFind: { session.inspectedBuilding = nil; panel = .explore }).ignoresSafeArea()
                }
                if session.configuration.isRiverbendPlayer {
                    playerHUD(size: geometry.size)
                } else {
                VStack(spacing: compact ? 8 : 14) {
                    resourceBar(compact: compact)
                    HStack(alignment: .top, spacing: 14) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("RIVERBEND").font(.system(size: compact ? 17 : 23, weight: .bold, design: .serif)).tracking(2)
                                    Text("STONE AGE").font(.system(size: 10, weight: .semibold)).tracking(1.5).foregroundStyle(parchment.opacity(0.65))
                                }
                                Button { session.centerRequest += 1 } label: { Image(systemName: "scope").frame(width: 44, height: 44) }
                                    .accessibilityLabel("Center on settlement").buttonStyle(.plain).background(panelColor.opacity(0.8), in: RoundedRectangle(cornerRadius: 10))
                                settlementBuildingPicker
                                #if DEBUG
                                if !session.configuration.isRiverbendPlayer { Button { showDeveloperTools = true } label: { Image(systemName: "wrench.and.screwdriver").frame(width: 44, height: 44) }
                                    .buttonStyle(.plain).background(panelColor.opacity(0.8), in: RoundedRectangle(cornerRadius: 10)).accessibilityLabel("Developer tools").accessibilityIdentifier("developerTools") }
                                #endif
                            }
                            #if DEBUG
                            if session.isDeveloperMode {
                                Text("\(session.isGameplayReview ? "REVIEW COPY" : "DEVELOPER") · \(session.developerPaused ? "PAUSED" : "\(Int(session.developerSpeed))×") · isolated save")
                                    .font(.caption.weight(.bold)).padding(8).background(.orange.opacity(0.22), in: Capsule()).accessibilityIdentifier("developerModeBanner")
                                if session.configuration.map.width == 64 {
                                    Button("64×48 · Map overview") { scene?.showMapOverview() }
                                        .font(.caption.weight(.semibold)).padding(8)
                                        .background(panelColor, in: Capsule())
                                        .accessibilityIdentifier("largeMapOverview")
                                }
                            }
                            #endif
                            if session.isDragMode {
                                Label(session.movingBuildingID == nil ? "Drag mode · new building" : "Drag mode · move building", systemImage: "hand.draw.fill")
                                    .font(.subheadline.bold()).foregroundStyle(.yellow).padding(10)
                                    .background(panelColor, in: RoundedRectangle(cornerRadius: 12))
                                    .accessibilityIdentifier("dragModeIndicator")
                            }
                            if let building = session.constructionQueue.first { constructionCard(building, compact: compact) }
                            Spacer(minLength: 0)
                            if let warning = session.persistenceWarning {
                                Text(warning).font(.caption).foregroundStyle(.yellow).padding(10).background(panelColor, in: RoundedRectangle(cornerRadius: 12))
                            }
                            goalsPanel(compact: compact)
                            if !session.isDragMode {
                            Text(session.message).font(.system(size: 12)).lineLimit(2).foregroundStyle(parchment.opacity(0.85))
                                .padding(9).background(panelColor.opacity(0.94), in: RoundedRectangle(cornerRadius: 10))
                                .accessibilityIdentifier("settlementMessage")
                            }
                        }
                        .frame(maxWidth: compact ? 290 : 340, maxHeight: .infinity, alignment: .leading)
                        Spacer(minLength: 0)
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                panelButton("Build", icon: "hammer", value: .build)
                                Button { session.cancel(); session.inspectedBuilding = nil; showResearch = true } label: {
                                    VStack(spacing: 3) { Image(systemName: "sparkles"); Text("Research").font(.system(size: 11, weight: .semibold)) }
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                }.background(panelColor.opacity(0.95), in: RoundedRectangle(cornerRadius: 12)).accessibilityIdentifier("openResearch")
                                    .overlay { completionDecoration(.research) }.accessibilityValue(completionAccessibilityValue(.research))
                            }
                            contextualPanel
                        }
                        .frame(width: compact ? 250 : min(340, geometry.size.width * 0.3))
                    }

                }
                .padding(.horizontal, compact ? 12 : 22)
                .padding(.vertical, compact ? 8 : 18)
                .accessibilityHidden(!worldReady)
                }
            }
            .overlay {
                if let scene { CandidateControls(session: session, scene: scene).ignoresSafeArea() }
            }
            .foregroundStyle(parchment)
            .tint(StonePalette.accent)
            .overlay {
                if !worldReady { SettlementLoadingView(stage: "Preparing the valley…", reviewPresentation: session.configuration.isRiverbendPlayer).ignoresSafeArea() }
            }
        }
        .onChange(of: session.completionSequence) { _, _ in
            guard phase == .active else { return }
            let destinations = Set(session.latestCompletions.map(\.destination))
            pendingCompletionCues.formUnion(destinations)
            let announcement = [destinations.contains(.research) ? "Research complete." : nil,
                                destinations.contains(.goals) ? "Goals updated." : nil].compactMap { $0 }.joined(separator: " ")
            UIAccessibility.post(notification: .announcement, argument: announcement)
            presentCompletionCues()
        }
        .onChange(of: reduceMotion) { _, enabled in if enabled { clearCompletionPulses() } }
        .onDisappear { clearCompletionPulses() }
        .onChange(of: hasContextPanel) { _, active in if active && session.configuration.isRiverbendPlayer { goals.isExpanded = false } }
        .onChange(of: session.isDragMode) { _, active in if active { goals.isExpanded = false } }
        .onChange(of: session.roadTool != nil) { _, active in if active { goals.isExpanded = false } }
        .onChange(of: session.eraID) { _, id in goals.observeEra(id) }
        .fullScreenCover(isPresented: $showJourney, onDismiss: {
            if let action = pendingGuidanceAction {
                pendingGuidanceAction = nil
                navigateGuidance(action)
            }
            presentCompletionCues()
        }) {
            NavigationStack {
                ScrollView { goalCard(compact: false).padding() }.accessibilityIdentifier("journeyContent")
                    .background(panelColor).foregroundStyle(parchment).tint(.yellow)
                    .navigationTitle("Stone Age journey")
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showJourney = false }.frame(minHeight: 44) } }
            }
        }
        .fullScreenCover(isPresented: $showCatalog, onDismiss: {
            focusedBuildingKind = nil
            if returnToJourney { returnToJourney = false; if !session.isDragMode && session.roadTool == nil { showJourney = true } }
            presentCompletionCues()
        }) {
            BuildingCatalogView(session: session, selectedCategory: $category, focusedBuildingKind: focusedBuildingKind, playerMemory: playerCatalogMemory)
        }
        .fullScreenCover(isPresented: $showResearch, onDismiss: {
            civicResearchID = nil
            if returnToJourney { returnToJourney = false; showJourney = true }
            presentCompletionCues()
        }) {
            ResearchView(session: session, selectedPillar: $researchPillar, focusedTechnologyID: civicResearchID, returnLabel: researchReturnLabel)
        }
        #if DEBUG
        .sheet(isPresented: $showDeveloperTools) { DeveloperToolsView(session: session) }
        #endif
        .popover(item: $inspectedResource) { selection in
            resourceDetails(selection.resource).presentationCompactAdaptation(.popover)
        }
        .popover(isPresented: $showPopulation) {
            populationDetails.presentationCompactAdaptation(.popover)
        }
        .onChange(of: phase, initial: true) { _, newPhase in
            if newPhase != .active { clearCompletionPulses() }
            if managesLifecycle { session.setActive(newPhase == .active) }
        }
        .task {
            // Defer expensive scene creation until this identity is mounted.
            // State(initialValue: Scene(...)) evaluated a disposable terrain on parent updates.
            if scene == nil { scene = SettlementScene(configuration: session.configuration) }
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(1)) } catch { break }
                if phase == .active { session.tick() }
            }
        }
    }
    /// Ordinary campaign presentation. Navigation owns no gameplay or save state.
    private func playerHUD(size: CGSize) -> some View {
        let phone = size.width < 1000
        let editing = session.isDragMode || session.roadTool != nil
        return VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                resourceBar(compact: phone).frame(maxWidth: phone ? 470 : 650).stoneSurface()
                Spacer(minLength: 0)
                playerSettlementMenu
            }
            Spacer(minLength: 0)
            HStack(alignment: .bottom, spacing: 12) {
                if hasContextPanel {
                    Button {
                        session.cancel(); session.inspectedBuilding = nil; panel = nil; goals.isExpanded = true
                    } label: {
                        Label("Goals", systemImage: "flag.checkered").font(.caption.weight(.semibold))
                            .padding(.horizontal, 12).frame(minHeight: 44)
                    }.buttonStyle(.plain).stoneSurface().accessibilityIdentifier("toggleGoals")
                        .accessibilityLabel("Goals, " + session.nextGuidance.title)
                        .overlay { completionDecoration(.goals) }.accessibilityValue(completionAccessibilityValue(.goals))
                } else {
                    playerGoals(compact: phone).frame(width: phone ? 280 : 330)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 6) {
                    if hasContextPanel {
                        VStack(spacing: 4) {
                            contextualPanel
                            Text(session.message).font(.caption).lineLimit(2).frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 10).padding(.bottom, 6).accessibilityIdentifier("settlementMessage")
                        }
                            .frame(width: phone ? min(380, size.width * 0.55) : 340,
                                   height: phone ? min(190, size.height * 0.49) : min(480, size.height * 0.68))
                            .stoneSurface()
                            .accessibilityElement(children: .contain).accessibilityIdentifier("playerWorldInspector")
                    } else if let building = session.constructionQueue.first {
                        constructionCard(building, compact: phone).frame(width: phone ? 240 : 300).stoneSurface()
                    }
                    if !hasContextPanel {
                        Text(session.message).font(.caption).lineLimit(2).frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8).frame(width: phone ? 220 : 300).stoneSurface()
                            .accessibilityIdentifier("settlementMessage")
                    }
                    if !editing { playerActionDock }
                }
            }
            if let warning = session.persistenceWarning {
                Text(warning).font(.caption).foregroundStyle(.yellow).padding(8).stoneSurface()
            }
        }
        .padding(.horizontal, phone ? 12 : 22).padding(.vertical, phone ? 8 : 18)
        .accessibilityHidden(!worldReady)
    }
    private var playerSettlementMenu: some View {
        Menu {
            Button { session.centerRequest += 1 } label: { Label("Center on settlement", systemImage: "scope") }
            Section("Settlement buildings") {
                ForEach(session.state.buildings.sorted { $0.id < $1.id }) { building in
                    Button { goals.isExpanded = false; panel = nil; session.inspect(buildingID: building.id) } label: {
                        Text("\(session.buildingName(building)) #\(building.id) · \(building.origin.x), \(building.origin.y)")
                    }.accessibilityIdentifier("inspectBuilding-" + String(building.id))
                }
            }
            if let openGames {
                Button { session.cancel(); session.inspectedBuilding = nil; openGames() } label: { Label("Games", systemImage: "square.stack") }
                    .accessibilityIdentifier("openGames")
            }
        } label: {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Settlement").font(.caption.weight(.semibold))
                    Text("STONE AGE").font(.caption2).foregroundStyle(StonePalette.accent)
                }
                Image(systemName: "ellipsis.circle")
            }.padding(.horizontal, 12).frame(minHeight: 44)
        }.buttonStyle(.plain).stoneSurface().accessibilityLabel("Settlement menu")
            .accessibilityIdentifier("settlementMenu")
    }
    private var playerActionDock: some View {
        HStack(spacing: 2) {
            Button { session.cancel(); session.inspectedBuilding = nil; panel = nil; goals.isExpanded = false; showCatalog = true } label: {
                playerDockLabel("Build", symbol: "hammer")
            }.accessibilityIdentifier("openBuild")
            Button { session.cancel(); session.inspectedBuilding = nil; goals.isExpanded = false; showResearch = true } label: {
                playerDockLabel("Research", symbol: "sparkles")
            }.accessibilityIdentifier("openResearch")
                .overlay { completionDecoration(.research) }.accessibilityValue(completionAccessibilityValue(.research))
            Button {
                let visible = panel == .explore && !hasInspectionOrPlacement
                session.cancel(); session.inspectedBuilding = nil; goals.isExpanded = false; panel = visible ? nil : .explore
            } label: { playerDockLabel("Explore", symbol: "map") }
                .accessibilityIdentifier("openExplore").accessibilityAddTraits(panel == .explore ? .isSelected : [])
        }.buttonStyle(.plain).padding(4).stoneSurface().accessibilityElement(children: .contain).accessibilityIdentifier("playerActionDock")
    }
    private var hasInspectionOrPlacement: Bool { session.currentInspection != nil || session.previewKind != nil || session.roadTool != nil }
    private func playerDockLabel(_ title: String, symbol: String) -> some View {
        VStack(spacing: 3) { Image(systemName: symbol).font(.system(size: 18, weight: .semibold)); Text(title).font(.caption2.weight(.semibold)) }
            .frame(minWidth: 68, minHeight: 44).contentShape(Rectangle())
    }
    private func playerGoals(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if goals.isExpanded {
                ScrollView { VStack(alignment: .leading, spacing: 4) {
                    guidanceDetail(compact: false)
                    Button("All seven chapters", systemImage: "list.bullet") { session.cancel(); showJourney = true }
                        .frame(minHeight: 44).accessibilityIdentifier("openJourney")
                }.padding(12) }.frame(maxHeight: compact ? 140 : 220).accessibilityIdentifier("goalProgress")
                Divider().overlay(StonePalette.accent.opacity(0.35))
            }
            Button {
                session.cancel(); session.inspectedBuilding = nil; panel = nil; goals.isExpanded.toggle()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "flag.checkered").foregroundStyle(StonePalette.accent).frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Goals · \(session.journeyChapters.filter(\.isComplete).count)/7").font(.caption.weight(.semibold)).foregroundStyle(StonePalette.accent)
                        Text(session.nextGuidance.title).font(.subheadline.weight(.semibold)).lineLimit(2).multilineTextAlignment(.leading)
                            .accessibilityIdentifier("nextStepSummary")
                    }
                    Spacer(minLength: 0)
                    Image(systemName: goals.isExpanded ? "chevron.down" : "chevron.up").font(.caption)
                }.padding(.horizontal, 12).padding(.vertical, 8).frame(minHeight: 56).contentShape(Rectangle())
            }.buttonStyle(.plain).accessibilityIdentifier("toggleGoals")
                .accessibilityLabel("Goals, \(session.journeyChapters.filter(\.isComplete).count)/7 chapters, \(session.nextGuidance.title)")
                .accessibilityValue(goals.state.rawValue + (session.unreadCompletions(for: .goals).isEmpty ? "" : ", " + completionAccessibilityValue(.goals)))
        }.stoneSurface().overlay { completionDecoration(.goals) }
    }
    private func completionAccessibilityValue(_ destination: CompletionDestination) -> String {
        let count = session.unreadCompletions(for: destination).count
        guard count > 0 else { return "" }
        return (pulsingCompletionCues.contains(destination) ? "New completion, " : "") + "\(count) unread completed results"
    }
    private func completionDecoration(_ destination: CompletionDestination) -> some View {
        let unread = !session.unreadCompletions(for: destination).isEmpty
        let pulsing = pulsingCompletionCues.contains(destination)
        return ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 12).stroke(StonePalette.accent, lineWidth: 2)
                .opacity(pulsing ? completionPulseOpacity : 0)
            if unread {
                Image(systemName: pulsing && destination == .goals ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: 13, weight: .bold)).foregroundStyle(panelColor, StonePalette.accent)
                    .background(StonePalette.accent, in: Circle()).padding(2)
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
    private func clearCompletionPulses() {
        completionPulseTask?.cancel(); completionPulseTask = nil
        pendingCompletionCues = []; pulsingCompletionCues = []; completionPulseOpacity = 0
    }
    private func presentCompletionCues() {
        guard !worldIsObscured, phase == .active, !pendingCompletionCues.isEmpty else { return }
        let destinations = pendingCompletionCues.filter { !session.unreadCompletions(for: $0).isEmpty }
        pendingCompletionCues = []
        guard !reduceMotion, !destinations.isEmpty else { return }
        completionPulseTask?.cancel()
        pulsingCompletionCues.formUnion(destinations); completionPulseOpacity = 1
        completionPulseTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .milliseconds(50))
                withAnimation(.easeOut(duration: 0.75)) { completionPulseOpacity = 0 }
                try await Task.sleep(for: .milliseconds(750))
                pulsingCompletionCues = []
            } catch { }
        }
    }
    private var hasContextPanel: Bool { session.roadTool != nil || session.previewKind != nil || session.currentInspection != nil || panel == .explore }
    @ViewBuilder private var contextualPanel: some View {
    if session.roadTool != nil { RoadControlsView(session: session) }
    else if session.previewKind != nil { placementPanel }
    else if let building = session.currentInspection { inspectionPanel(building) }
    else if panel == .explore {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Exploration").font(.headline)
                    Spacer()
                    Button { self.panel = nil } label: { Image(systemName: "xmark").frame(width: 44, height: 44) }.accessibilityLabel("Close panel")
                }
                explorationPanel
            }.padding(14)
        }
        .background(panelColor.opacity(0.97), in: RoundedRectangle(cornerRadius: 18))
        .accessibilityIdentifier("riverbendExploreContent")
    }
    }
    private var settlementBuildingPicker: some View {
        Menu {
            ForEach(session.state.buildings.sorted { $0.id < $1.id }) { building in
                Button {
                    session.inspect(buildingID: building.id)
                } label: {
                    Text("\(session.buildingName(building)) #\(building.id) · \(building.origin.x), \(building.origin.y)")
                }.accessibilityIdentifier("inspectBuilding-\(building.id)")
            }
        } label: {
            Image(systemName: "building.2.crop.circle").frame(width: 44, height: 44)
        }.buttonStyle(.plain).background(panelColor.opacity(0.8), in: RoundedRectangle(cornerRadius: 10)).accessibilityLabel("Inspect settlement buildings")
            .accessibilityIdentifier("settlementBuildings")
    }
    private func resourceBar(compact: Bool) -> some View {
        HStack(spacing: 6) {
            ScrollView(.horizontal) {
                HStack(spacing: compact ? 6 : 12) {
                    ForEach(session.visibleResources, id: \.self) { resource in resourceButton(resource, compact: compact) }
                }.padding(.horizontal, 8)
            }.scrollIndicators(.visible)
            Button { showPopulation = true } label: {
                Label("\(session.state.population)/\(session.housingCapacity)", systemImage: "person.2.fill")
                    .font(.system(size: 14, weight: .semibold)).monospacedDigit().frame(minWidth: 80, minHeight: 44)
            }.buttonStyle(.plain).padding(.trailing, 8)
                .accessibilityLabel("Population \(session.state.population), housing capacity \(session.housingCapacity)")
        }.background(panelColor.opacity(0.96), in: RoundedRectangle(cornerRadius: 12))
    }
    private func resourceButton(_ resource: Resource, compact: Bool) -> some View {
        Button { inspectedResource = ResourceInspection(resource: resource) } label: {
            HStack(spacing: 5) {
                EraIcon(domain: .resource, id: resource.rawValue, size: 23).font(.system(size: 17))
                Text("\(Int(session.state.resources[resource].rounded(.down)))")
                    .font(.system(size: 14, weight: .semibold, design: .rounded)).monospacedDigit()
            }.frame(minWidth: 52, minHeight: 44).contentShape(Rectangle())
        }.buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(resource.title), \(Int(session.state.resources[resource])), net production \(signed(session.rates[resource])) per minute")
            .accessibilityIdentifier("resource-" + resource.rawValue)
    }
    private func panelButton(_ title: String, icon: String, value: Panel) -> some View {
        Button {
            session.cancel(); session.inspectedBuilding = nil
            if value == .build { panel = nil; showCatalog = true }
            else { panel = panel == value ? nil : value }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                Text(title).font(.system(size: 11, weight: .semibold))
            }.frame(maxWidth: .infinity, minHeight: 44)
        }
        .background(panel == value ? Color.white.opacity(0.13) : panelColor.opacity(0.95), in: RoundedRectangle(cornerRadius: 12))
    }
    private var placementPanel: some View {
        ScrollView { VStack(alignment: .leading, spacing: 10) {
            if let kind = session.previewKind {
                let definition = session.configuration.definition(kind)
                Label(definition.name, systemImage: "hand.draw.fill").font(.headline)
                if session.configuration.isRiverbendPlayer && kind == .storehouse && session.movingBuildingID == nil {
                    Picker("Storage role", selection: Binding(get: { session.storageSpecialization }, set: { session.storageSpecialization = $0; session.choose(.storehouse) })) {
                        Text("Granary").tag(StorageSpecialization.granary)
                        Text("Stockyard").tag(StorageSpecialization.stockyard)
                    }.pickerStyle(.segmented).accessibilityIdentifier("storageSpecialization")
                    Text(session.storageSpecialization == .granary ? "+60 Food capacity only" : "+60 Wood/Stone; +24 Flint/Tools capacity").font(.caption)
                }
                Text(session.movingBuildingID == nil ? cost(session.configuration.isRiverbendPlayer && kind == .storehouse ? session.storageSpecialization.cost : definition.cost) : "Move building · no cost").font(.caption).foregroundStyle(parchment.opacity(0.7))
                Text("Orientation: " + session.previewOrientation.rawValue.capitalized).font(.caption).accessibilityIdentifier("previewOrientation")
                Text(session.placementIssue?.localizedDescription ?? "Valid location · \(session.previewFootprint?.width ?? definition.width)×\(session.previewFootprint?.height ?? definition.height) tiles")
                    .font(.caption).foregroundStyle(session.placementIssue == nil ? Color.mint : Color.orange)
                    .fixedSize(horizontal: false, vertical: true)
                if let tile = session.selectedTile { Text("Tile \(tile.x), \(tile.y) · drag to move · green check confirms").accessibilityIdentifier("placementTile").font(.system(size: 10)).foregroundStyle(parchment.opacity(0.6)) }

            }
        }.padding(14) }.background(panelColor.opacity(0.97), in: RoundedRectangle(cornerRadius: 18))
    }

    private var riverbendActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RIVERBEND").font(.headline)
            Text("Free recovery fills only a small reserve. Connected producers sustain the village.").font(.caption)
            Button("Forage · restore Food up to 12") { session.recoverRiverbendFood() }
                .frame(minHeight: 44).accessibilityIdentifier("riverbendRecoverFood")
            Button("Collect fallen branches · restore opening Wood") { session.recoverRiverbendWood() }
                .frame(minHeight: 44).accessibilityIdentifier("riverbendRecoverWood")
            ForEach(session.availableRiverbendFinds) { find in
                VStack(alignment: .leading) {
                    Text(find.id == .berries ? "Wild berries · optional · +3 Food once" : "Deer tracks · optional observation, no reward").font(.subheadline)
                    Text("Revealed site \(find.tile.x), \(find.tile.y)").font(.caption)
                    Button(find.id == .berries ? "Gather berries" : "Observe tracks") { session.resolveRiverbendFind(find.id, at: find.tile) }
                        .frame(minHeight: 44).accessibilityIdentifier("riverbendFind-" + find.id.rawValue)
                }
            }
            if session.riverbendCraftAvailable {
                Text("ONE USEFUL CRAFT").font(.headline)
                Text("Stone gatherer: Stone 5/min or Flint 4/min, using the same worker. Craft 2 Wood + 2 Flint → 1 Tool in 60 seconds.").font(.caption)
                if let stone = session.state.buildings.first(where: { $0.kind == .stoneGatherer }) {
                    Button("Inspect Stone / Flint production") { panel = nil; session.inspect(buildingID: stone.id) }.frame(minHeight: 44)
                }
                if let remaining = session.riverbendProgress?.craftRemainingSeconds {
                    Text("Tool batch · \(Int(ceil(remaining)))s remaining").accessibilityIdentifier("riverbendToolTimer")
                } else {
                    Button("Make 1 Tool · 2 Wood + 2 Flint · 60s") { session.startRiverbendTools() }
                        .frame(minHeight: 44).disabled(!session.researchedIDs.contains("stoneTools"))
                        .accessibilityIdentifier("riverbendMakeTool")
                }
                Text(session.riverbendProgress?.woodcutterImproved == true ? "Woodcutter improved · 8 Wood/min base · no Tool upkeep" : "Spend 3 Tools once: Woodcutter 6 → 8 Wood/min permanently.").font(.caption)
                Button("Improve Woodcutter · spend 3 Tools") { session.improveRiverbendWoodcutter() }
                    .frame(minHeight: 44).disabled(session.state.resources[.stoneTools] < 3 || session.riverbendProgress?.woodcutterImproved == true)
                    .accessibilityIdentifier("riverbendImproveWood")
            }
            if session.researchedIDs.contains("fortification") {
                Text("CLIFF AND PALISADE").font(.headline)
                if session.riverbendProgress?.enclosed == true {
                    Text(session.riverbendProgress?.gateOpen == true ? "Gate open · entrance passable" : "Gate closed · entrance blocked").font(.caption)
                    Button(session.riverbendProgress?.gateOpen == true ? "Close gate" : "Open gate") { session.setRiverbendGate(open: session.riverbendProgress?.gateOpen != true) }
                        .frame(minHeight: 44).accessibilityIdentifier("riverbendGate")
                } else {
                    Text("36 Wood · joins both cliff ends and adds one connected gate. Reveal and clear the route before building.").font(.caption)
                    Button("Build enclosure · 36 Wood") { session.purchaseRiverbendEnclosure() }
                        .frame(minHeight: 44).accessibilityIdentifier("riverbendEnclosure")
                }
            }
            Divider()
        }
    }
    private var explorationPanel: some View {
        Group {
            if session.configuration.isRiverbendPlayer { riverbendActions }
            Text("EXPLORE THE VALLEY").font(.system(size: 10, weight: .bold)).tracking(1)
            Text("\(session.discoveredTileCount) / \(session.configuration.map.width * session.configuration.map.height) tiles discovered")
                .font(.subheadline).accessibilityIdentifier("explorationCoverage")
            Text("Unexplored land stays hidden. Buildings need a fully revealed footprint; deposits must also be identified before extraction.")
                .font(.caption).foregroundStyle(parchment.opacity(0.7))
            if let rules = session.configuration.explorationRules {
                if let remaining = session.state.explorationRemainingSeconds {
                    ProgressView(value: min(1, max(0, 1 - remaining / rules.durationSeconds)))
                    Text("Expedition returns in \(Int(ceil(remaining)))s").font(.caption).foregroundStyle(.yellow)
                        .accessibilityIdentifier("explorationTimer")
                } else {
                    Text("Expedition: " + cost(rules.cost) + " · \(Int(rules.durationSeconds))s").font(.caption).foregroundStyle(.yellow)
                }
                Text(session.configuration.isRiverbendPlayer ? "Reveals the whole nearby forest and its work faces. Further expeditions expand the known area; distant journeys require a connected Scout Camp." : "Explores a wider ring around camp. An operational scout camp is needed for journeys beyond radius \(rules.requiresScoutAfterRadius).")
                    .font(.caption).foregroundStyle(parchment.opacity(0.65))
                if let issue = session.explorationIssue {
                    Text(issue.localizedDescription).font(.caption).foregroundStyle(.orange)
                    if min(session.configuration.maximumExplorationRadius, (session.state.explorationRadius ?? rules.initialRadius) + rules.revealRadiusStep) > rules.requiresScoutAfterRadius && !session.state.buildings.contains(where: { $0.kind == .scoutCamp && $0.isOperational }) {
                        Button("Show Scout Camp") { navigateGuidance(.build(.scoutCamp)) }.frame(minHeight: 44).accessibilityIdentifier("explorationScoutLink")
                    }
                }
                Button("Send expedition") { session.startExploration() }
                    .frame(maxWidth: .infinity, minHeight: 44).buttonStyle(StonePrimaryActionStyle())
                    .disabled(session.explorationIssue != nil).accessibilityIdentifier("startExploration")
                if session.configuration.isRiverbendPlayer,
                   let technology = session.visibleTechnologies.first(where: { $0.id == "exploration" }) {
                    Button {
                        civicResearchID = technology.id; researchPillar = technology.pillar
                        researchReturnLabel = "Return to Explore"; showResearch = true
                    } label: { Label("Expedition research", systemImage: "sparkles").frame(minHeight: 44) }
                        .accessibilityIdentifier("explorationResearch")
                }
            }
            Text("DISCOVERED DEPOSITS").font(.system(size: 10, weight: .bold)).tracking(1).padding(.top, 8)
            if session.discoveredDeposits.isEmpty { Text("No deposits discovered yet.").font(.caption) }
            ForEach(session.discoveredDeposits, id: \.id) { deposit in
                depositDetails(deposit)
            }
        }
    }
    private func depositDetails(_ deposit: NaturalDeposit) -> some View {
        let identified = session.isIdentified(deposit)
        return VStack(alignment: .leading, spacing: 5) {
            Text(identified ? deposit.kind.replacingOccurrences(of: "_", with: " ").capitalized : "Unidentified deposit")
                .font(.subheadline).fontWeight(.semibold)
            ForEach(([deposit.origin] + (deposit.accessSites ?? [])).filter { session.isDiscovered($0) }, id: \.self) { site in
                Text("\(site == deposit.origin ? "Tile" : "Quarry access") \(site.x), \(site.y) · reach \(deposit.radius) tiles").font(.caption)
            }
            if identified {
                if let resource = deposit.resource {
                    Text(resource.title + " · " + (deposit.renewable ? "Renewable" : "\(Int(max(0, session.state.depositRemaining?[deposit.id] ?? deposit.capacity))) units remaining"))
                        .font(.caption).foregroundStyle(parchment.opacity(0.7))
                } else { Text("No extraction available in this age.").font(.caption) }
            } else {
                if let id = deposit.requiredTechnology, let technology = session.configuration.technologyDefinitions.first(where: { $0.id == id }) {
                    Button("Research " + technology.name + " to identify") {
                        civicResearchID = id; researchReturnLabel = "Return to Explore"; researchPillar = technology.pillar; showResearch = true
                    }.frame(minHeight: 44).accessibilityIdentifier("depositResearch-" + deposit.id)
                } else { Text("Requires future knowledge to identify. Cannot be extracted.").font(.caption).foregroundStyle(parchment.opacity(0.65)) }
            }
        }.padding(10).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
    }
    private var completedPillarCount: Int { session.pillarGoals.filter { session.isPillarGoalComplete($0.id) }.count }
    private func unlockRequirement(_ kind: BuildingKind) -> String {
        let technologies = session.configuration.technologyDefinitions.filter { $0.effects.unlockedBuildings.contains(kind) }.map(\.name)
        return "Requires: " + technologies.joined(separator: " or ")
    }
    private func constructionCard(_ building: PlacedBuilding, compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("BUILDING · " + session.configuration.definition(building.kind).name).font(.system(size: compact ? 11 : 14, weight: .semibold))
            ProgressView(value: constructionProgress(building)).tint(.yellow)
            Text("\(Int(ceil(building.constructionRemainingSeconds ?? 0)))s remaining" + (session.constructionQueue.count > 1 ? " · \(session.constructionQueue.count) in progress" : ""))
                .font(.system(size: 10)).foregroundStyle(parchment.opacity(0.7))
        }.padding(10).background(panelColor.opacity(0.94), in: RoundedRectangle(cornerRadius: 12))
            .accessibilityIdentifier("constructionProgress")
    }
    private func constructionProgress(_ building: PlacedBuilding) -> Double {
        guard let remaining = building.constructionRemainingSeconds, let duration = building.constructionDurationSeconds, duration > 0 else { return 1 }
        return min(1, max(0, 1 - remaining / duration))
    }
    private func resourceDetails(_ resource: Resource) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Label { Text(resource.title) } icon: { EraIcon(domain: .resource, id: resource.rawValue, size: 24) }.font(.headline)
                Text("Stored: \(Int(session.state.resources[resource])) / \(Int(session.capacities[resource]))")
                if session.state.resources[resource] > session.capacities[resource] {
                    Text("Stored materials remain spendable. Connect storage to make room for new production.").font(.caption)
                }
                Text("Gross: \(signed(session.grossRates[resource])) / min")
                Text("Consumption: \(String(format: "%.1f", session.consumption[resource])) / min")
                Text("Net: \(signed(session.rates[resource])) / min").foregroundStyle(session.rates[resource] < 0 ? .orange : .mint)
                Text("Producing now: \(session.producingBuildingCount(for: resource)) buildings").font(.subheadline.bold())
                    .accessibilityIdentifier("resourceProducerCount")
                if resource == .knowledge {
                    Text("Upgrade the civic center for knowledge and culture. Optional storytelling circles can speed research. Natural Knowledge improves output; inhabitants and balanced worker priorities keep knowledge and materials flowing.").font(.caption)
                }
                Text("WHERE TO GATHER OR MAKE").font(.caption.bold())
                ForEach(session.productionSources(for: resource), id: \.kind) { definition in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(definition.name).font(.subheadline.bold())
                        ForEach((definition.recipes ?? []).filter { $0.outputsPerMinute[resource] > 0 }, id: \.id) { recipe in
                            Text(recipe.name + (amounts(recipe.inputsPerMinute).isEmpty ? "" : " · uses " + amounts(recipe.inputsPerMinute) + " / min"))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        if definition.kind == .campfire, resource == .knowledge || resource == .culture {
                            ForEach(session.configuration.civicLevels?.filter { $0.culturalOutputPerMinute[resource] > 0 } ?? [], id: \.level) { level in
                                Text(level.name + " · " + amounts(level.culturalOutputPerMinute) + " / min · workers \(workforceNumber(level.workersRequired))").font(.caption)
                            }
                        }
                        if definition.requiresResearch { Text(unlockRequirement(definition.kind)).font(.caption).foregroundStyle(.secondary) }
                    }
                }
                let deposits = session.discoveredDeposits.filter { $0.resource == resource && session.isIdentified($0) }
                if !deposits.isEmpty {
                    Text("Known sources: " + deposits.map { "\($0.kind.capitalized) (\($0.origin.x), \($0.origin.y))" }.joined(separator: ", "))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Text("Counts reflect current recipes, staffing and input availability. Construction and stopped production are excluded.")
                    .font(.caption).foregroundStyle(.secondary)
            }.font(.subheadline).padding(20)
        }.frame(width: 310, height: 290).accessibilityIdentifier("resourceBreakdown")
    }
    private var populationDetails: some View {
        ScrollView {
        VStack(alignment: .leading, spacing: 10) {
            Text("Population \(session.state.population) / \(session.housingCapacity)").font(.headline)
            Text(session.growthStatus.description).font(.subheadline).fixedSize(horizontal: false, vertical: true)
            ProgressView(value: session.growthIntervalSeconds > 0 ? min(1, (session.state.populationGrowthSeconds ?? 0) / session.growthIntervalSeconds) : 0)
            Text("\(Int(ceil(session.growthRemainingSeconds))) eligible seconds until growth").font(.caption)
            if session.configuration.workforceRules != nil {
                Text("Workforce: \(workforceNumber(session.workforceAvailable)) available · \(workforceNumber(session.workforceRequired)) required")
                    .font(.subheadline).accessibilityIdentifier("workforceSummary")
                Text("Allocated: \(workforceNumber(session.workforceAllocated)) workers").font(.caption)
                Text("Workers are allocated automatically. Partial staffing reduces output. A protected share goes to basic food and water before other priorities.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if let rules = session.configuration.populationRules {
                Text("Needs free housing, at least \(Int(rules.minimumFoodForGrowth)) food and positive net food. Progress pauses when requirements are unmet.").font(.caption).foregroundStyle(.secondary)
            }
            if !session.configuration.isRiverbendPlayer, let rules = session.configuration.workforceRules {
                Text("Also needs at least \(Int(rules.minimumWaterForGrowth)) water and positive net water. Water use: \(String(format: "%g", rules.waterPerPersonPerMinute)) per person/min. No deaths during shortages.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }.padding(20)
        }.frame(width: 300, height: 310).accessibilityIdentifier("populationDetails")
    }
    private func signed(_ number: Double) -> String { String(format: "%+.1f", number) }
    private func goalsPanel(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            let rail = session.configuration.isRiverbendPlayer ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4)) : AnyLayout(HStackLayout(alignment: .top, spacing: 4))
            rail {
                Button {
                    if session.configuration.isRiverbendPlayer {
                        session.cancel(); session.inspectedBuilding = nil; panel = nil; goals.isExpanded.toggle()
                    } else { goals.cycle() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "flag.checkered").frame(minWidth: 24)
                        if goals.state != .minimal {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Chapters \(session.journeyChapters.filter(\.isComplete).count)/\(session.journeyChapters.count)").font(.subheadline.bold())
                                Text(session.nextGuidance.title).font(.caption).lineLimit(2)
                                    .accessibilityIdentifier("nextStepSummary")
                            }
                            Spacer(minLength: 0)
                            Image(systemName: goals.isExpanded ? "chevron.up" : "chevron.down")
                        }
                    }.padding(.horizontal, 10).frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityIdentifier("toggleGoals")
                    .accessibilityLabel("Chapters \(session.journeyChapters.filter(\.isComplete).count)/\(session.journeyChapters.count), goals")
                    .accessibilityValue(goals.state.rawValue + (session.unreadCompletions(for: .goals).isEmpty ? "" : ", " + completionAccessibilityValue(.goals)))
                    .overlay { completionDecoration(.goals) }
                Button {
                    let wasVisible = panel == .explore && session.roadTool == nil && !session.isDragMode && session.currentInspection == nil
                    session.cancel(); session.inspectedBuilding = nil
                    panel = wasVisible ? nil : .explore
                } label: {
                    Image(systemName: "map").frame(width: 44, height: 44).contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityLabel("Explore").accessibilityIdentifier("openExplore")
                if let openGames {
                    Button { session.cancel(); session.inspectedBuilding = nil; openGames() } label: {
                        Image(systemName: "square.stack").frame(width: 44, height: 44).contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityLabel("Games").accessibilityIdentifier("openGames")
                }
            }
            if goals.isExpanded {
                VStack(alignment: .leading, spacing: 5) {
                    guidanceDetail(compact: compact)
                    Button("All seven chapters", systemImage: "list.bullet") { session.cancel(); showJourney = true }.frame(minHeight: 44)
                        .accessibilityIdentifier("openJourney")
                }.padding(.horizontal, 12).padding(.bottom, 8).frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .contain).accessibilityIdentifier("goalProgress")
            }
        }.background(panelColor.opacity(0.96), in: RoundedRectangle(cornerRadius: 12))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    private func guidanceDetail(compact: Bool = false, showAction: Bool = true) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(session.nextGuidance.explanation).font(.caption).lineLimit(compact ? 3 : nil).fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("nextStepExplanation")
            if showAction {
                Button(guidanceActionTitle) { openGuidance() }.frame(minHeight: 44)
                    .accessibilityIdentifier("nextStepAction")
            }
        }
    }
    private var guidanceActionTitle: String {
        switch session.nextGuidance.action {
        case .build: "Open Buildings"
        case .research: "Open Research"
        case .recipe, .priority, .inspect, .upgrade: "Inspect building"
        case .explore: "Open Explore"
        case .resource: "Resource help"
        case .population: "Population and workers"
        case .journey, .complete: "View era requirements"
        }
    }
    private func openGuidance() {
        let action = session.nextGuidance.action
        if showJourney {
            if action != .journey && action != .complete {
                switch action { case .build, .research: returnToJourney = true; default: returnToJourney = false }
                pendingGuidanceAction = action; showJourney = false
            }
            return
        }
        navigateGuidance(action)
    }
    private func navigateGuidance(_ action: GuidanceAction) {
        session.cancel(); session.inspectedBuilding = nil
        switch action {
        case .build(let kind):
            focusedBuildingKind = kind
            category = session.configuration.definition(kind).category ?? "Other"
            showJourney = false; showCatalog = true
        case .research(let id):
            civicResearchID = id; researchReturnLabel = returnToJourney ? "Return to journey" : "Return to settlement"
            researchPillar = session.configuration.technologyDefinitions.first { $0.id == id }?.pillar ?? .science
            showJourney = false; showResearch = true
        case .recipe(let id, _), .priority(let id, _), .inspect(let id), .upgrade(let id):
            showJourney = false; panel = nil; session.inspect(buildingID: id)
        case .explore: showJourney = false; panel = .explore
        case .resource(let resource): showJourney = false; inspectedResource = ResourceInspection(resource: resource)
        case .population: showJourney = false; showPopulation = true
        case .journey, .complete: showJourney = true
        }
    }
    private func goalCard(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if session.state.stoneAgeCompleted == true {
                Label("Bronze Age unlocked · readiness earned", systemImage: "checkmark.seal.fill").foregroundStyle(.mint).accessibilityIdentifier("bronzeAgeReadiness")
                if !session.fullStoneAgeRequirementsMet { Text("Your historical readiness is preserved. Finish the expanded checklist at your own pace.").font(.caption) }
            }
            Text(session.nextGuidance.title).font(.headline).accessibilityIdentifier("journeyNextStepTitle")
            guidanceDetail(showAction: session.nextGuidance.action != .complete && session.nextGuidance.action != .journey)
            Text("Every chapter credits work completed ahead of time. Original construction rewards remain one-time awards.").font(.caption)
            ForEach(session.journeyChapters) { chapter in
                VStack(alignment: .leading, spacing: 6) {
                    Label("\(chapter.id). " + chapter.title, systemImage: chapter.isComplete ? "checkmark.circle.fill" : "circle").font(.subheadline.bold())
                        .modifier(ViewedCompletion(session: session, ids: ["chapter:\(chapter.id)"], earned: chapter.isComplete, active: showJourney && !showResearch && !showCatalog && phase == .active))
                    ProgressView(value: Double(chapter.completedCount), total: Double(max(1, chapter.objectives.count)))
                    ForEach(chapter.objectives) { objective in
                        HStack(alignment: .top) {
                            Image(systemName: objective.isComplete ? "checkmark.circle.fill" : "circle").foregroundStyle(objective.isComplete ? .mint : parchment)
                            Text(objective.title)
                            Spacer()
                            Text(objective.progress).monospacedDigit()
                        }.font(.caption)
                            .modifier(ViewedCompletion(session: session, ids: ["objective:\(chapter.id):" + objective.id], earned: objective.isComplete, active: showJourney && !showResearch && !showCatalog && phase == .active))
                    }
                }
            }
            Text("Five development pillars").font(.subheadline.bold())
            ForEach(session.pillarGoals) { goal in
                VStack(alignment: .leading, spacing: 4) {
                    Label(goal.title, systemImage: session.isPillarGoalComplete(goal.id) ? "checkmark.circle.fill" : "circle")
                    Text(session.pillarGoalProgress(id: goal.id)).foregroundStyle(.secondary)
                }.font(.caption)
                    .modifier(ViewedCompletion(session: session, ids: ["pillar:" + goal.id], earned: session.isPillarGoalComplete(goal.id), active: showJourney && !showResearch && !showCatalog && phase == .active))
            }
            if !session.missingDiscoveryResourceNames.isEmpty {
                Text("Resource territories still needed: " + session.missingDiscoveryResourceNames.joined(separator: ", ")).font(.caption)
            }
            Text("Goal: complete all Stone Age building types and technologies, required resource territories and all five pillars to unlock Bronze Age readiness. Full-map exploration is optional. Bronze Age gameplay is not available yet.").font(.caption)
        }.padding(12).frame(maxWidth: .infinity, alignment: .leading).accessibilityElement(children: .contain).accessibilityIdentifier("goalProgress")
    }
    private func inspectionPanel(_ building: PlacedBuilding) -> some View {
        let definition = session.configuration.definition(building.kind)
        return VStack(spacing: 0) {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(session.buildingName(building) + " · Lv \(building.level)").font(.headline).accessibilityIdentifier("civicLevelName")
                    Spacer()
                    Button { session.inspectedBuilding = nil } label: { Image(systemName: "xmark").frame(width: 44, height: 44) }.accessibilityLabel("Close inspection").accessibilityIdentifier("closeBuildingInspection")
                }
                if session.configuration.isRiverbendPlayer && building.kind == .campfire, let price = session.upgradeCost(for: building) {
                    Text("Upgrade: " + cost(price)).font(.caption).foregroundStyle(.yellow)
                    Button(building.level == 1 ? "Found Founder’s Lodge" : "Establish Council Circle") { session.upgrade(buildingID: building.id) }
                        .frame(maxWidth: .infinity, minHeight: 44).buttonStyle(StonePrimaryActionStyle())
                        .disabled(session.upgradeIssue(buildingID: building.id) != nil).accessibilityIdentifier("upgradeBuilding")
                    if let issue = session.upgradeIssue(buildingID: building.id) {
                        Text(issue.localizedDescription).font(.caption).foregroundStyle(.orange)
                        if let id = session.upgradeResearch(for: building) {
                            Button("Open required research") {
                                researchReturnLabel = "Return to civic center"; civicResearchID = id
                                researchPillar = session.configuration.technologyDefinitions.first { $0.id == id }?.pillar ?? .science
                                showResearch = true
                            }.frame(minHeight: 44)
                        }
                    }
                }
                if building.isOperational {
                    Text(session.operatingStatus(building)).font(.subheadline).foregroundStyle(session.productivity(building) < 0.999 ? .orange : .mint)
                        .accessibilityIdentifier("buildingOperatingStatus")
                    if !session.isServiceOperational(building) {
                        Text("Connect any footprint side to paths leading to the civic center, or move this building to reachable land.").font(.caption)
                        Button("Connect paths") { if session.configuration.isRiverbendPlayer { session.suggestRiverbendConnection(buildingID: building.id) } else { session.chooseRoadTool(.draw(.trodden)) } }
                            .frame(minHeight: 44).buttonStyle(.bordered).accessibilityIdentifier("connectBuildingPaths")
                    }
                    if session.configuration.isRiverbendPlayer && building.kind == .stoneGatherer {
                        Text("PRODUCTION MODE").font(.caption.bold())
                        ForEach(session.visibleProductionRecipes(for: building.kind), id: \.id) { recipe in
                            recipeButton(recipe, building: building, selected: building.productionModeID == recipe.id || (building.productionModeID == nil && recipe.id == "stone"))
                        }
                    }
                    Text("Productivity: \(Int((session.productivity(building) * 100).rounded()))%")
                        .font(.caption).accessibilityIdentifier("buildingProductivity")
                    if !effect(definition).isEmpty { Text("Base configuration: " + effect(definition)).font(.caption) }
                    if session.configuration.workforceRules != nil { workforceControls(building, definition: definition) }
                    if let civic = session.civicDefinition(for: building) {
                        Text("Founding provisions / min: " + amounts(definition.recipes?.first?.outputsPerMinute ?? definition.ratesPerMinute) + " · Housing \(definition.housing). Cultural staffing does not affect these provisions.").font(.caption)
                        Text("Base cultural output / min: " + amounts(civic.culturalOutputPerMinute)).font(.caption).accessibilityIdentifier("civicCulturalOutput")
                    }
                    if session.civicDefinition(for: building) == nil, !(session.configuration.isRiverbendPlayer && building.kind == .stoneGatherer), let recipes = definition.recipes, !recipes.isEmpty {
                        Text("PRODUCTION MODE").font(.system(size: 10, weight: .bold)).tracking(1)
                        ForEach(recipes, id: \.id) { recipe in
                            recipeButton(recipe, building: building, selected: building.productionModeID == recipe.id || (building.productionModeID == nil && recipes.first?.id == recipe.id))
                        }
                    }
                    if let maintenance = definition.maintenancePerMinute, !amounts(maintenance).isEmpty {
                        Text("Maintenance / min: " + amounts(maintenance)).font(.caption).foregroundStyle(.orange)
                        Text("Missing supplies reduce output. Production recovers when supplies return.")
                            .font(.caption).foregroundStyle(parchment.opacity(0.65))
                    }
                    if let role = session.riverbendProgress?.storage[building.id] {
                        Text(role == .granary ? "Granary · +60 Food capacity only" : "Stockyard · +60 Wood/Stone and +24 Flint/Tools capacity").font(.caption)
                    } else if let storage = definition.storageBonus, !amounts(storage).isEmpty {
                        Text("Storage per level: " + amounts(storage)).font(.caption)
                    }
                    if let bonus = definition.geographicBonus {
                        Text("Nearby terrain can improve output by \(Int(bonus.outputBonus * 100))% within \(bonus.radius) tiles.")
                            .font(.caption).foregroundStyle(parchment.opacity(0.7))
                    }
                    if !(session.configuration.isRiverbendPlayer && building.kind == .campfire), let upgradeCost = session.upgradeCost(for: building) {
                        Text("Upgrade: " + cost(upgradeCost)).font(.caption).foregroundStyle(.yellow)
                        Button("Upgrade to level \(building.level + 1)") { session.upgrade(buildingID: building.id) }
                            .frame(maxWidth: .infinity, minHeight: 44).buttonStyle(StonePrimaryActionStyle())
                            .disabled(session.upgradeIssue(buildingID: building.id) != nil).accessibilityIdentifier("upgradeBuilding")
                        if let researchID = session.upgradeResearch(for: building), !session.researchedIDs.contains(researchID),
                           let technology = session.configuration.technologyDefinitions.first(where: { $0.id == researchID }) {
                            Button("Research " + technology.name + " to unlock") {
                                researchReturnLabel = "Return to civic center"
                                civicResearchID = technology.id; researchPillar = technology.pillar; showResearch = true
                            }.frame(minHeight: 44).buttonStyle(.bordered).accessibilityIdentifier("civicPrerequisiteResearch")
                        }
                        if let issue = session.upgradeIssue(buildingID: building.id) {
                            Text(issue.localizedDescription).font(.caption).foregroundStyle(.orange)
                        }
                    } else if session.configuration.economyRules != nil {
                        Text("No further upgrades available.").font(.caption).foregroundStyle(parchment.opacity(0.65))
                    }
                } else {
                    Text("Under construction · benefits activate at completion").font(.caption).foregroundStyle(.yellow)
                    ProgressView(value: constructionProgress(building))
                    Text("\(Int(ceil(building.constructionRemainingSeconds ?? 0)))s remaining").font(.caption)
                }
                Text("Tile \(building.origin.x), \(building.origin.y) · \(building.occupiedFootprint(in: session.configuration).width)×\(building.occupiedFootprint(in: session.configuration).height) footprint · facing \(building.resolvedOrientation.rawValue)").font(.caption).accessibilityIdentifier("inspectedBuildingPosition")
                if !session.configuration.isRiverbendPlayer && (building.kind != .campfire || session.configuration.civicLevels != nil) {
                    Button("Move building") { session.beginRelocation(buildingID: building.id) }
                        .frame(maxWidth: .infinity, minHeight: 44).buttonStyle(.bordered).accessibilityIdentifier("moveBuilding")
                }
                Button("Close inspection") { session.inspectedBuilding = nil }.frame(minHeight: 44)
            }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
        }.accessibilityIdentifier("buildingInspection")
        if session.configuration.isRiverbendPlayer && building.kind != .campfire {
            Button { session.beginRelocation(buildingID: building.id) } label: {
                Text("Move building").frame(maxWidth: .infinity, minHeight: 48).contentShape(Rectangle())
            }.buttonStyle(.bordered)
                .padding(.horizontal, 12).padding(.bottom, 8).accessibilityIdentifier("moveBuilding")
        }
        }.background(panelColor, in: RoundedRectangle(cornerRadius: 18))
    }
    private func workforceControls(_ building: PlacedBuilding, definition: BuildingDefinition) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            let required = session.workersRequired(for: building)
            Text("Workers: \(workforceNumber(session.workersAllocated(to: building))) / \(workforceNumber(required))")
                .font(.subheadline).accessibilityIdentifier("buildingWorkers")
            if required > 0 {
                Text("Staffing: \(Int((session.workforceProductivity(building) * 100).rounded()))% · automatically assigned")
                    .font(.caption).foregroundStyle(parchment.opacity(0.7))
                Text("WORKFORCE PRIORITY").font(.system(size: 10, weight: .bold)).tracking(1)
                HStack(spacing: 4) {
                    ForEach(0...2, id: \.self) { priority in
                        Button {
                            session.setWorkerPriority(buildingID: building.id, priority: priority)
                        } label: {
                            Text(["Low", "Normal", "High"][priority]).font(.caption)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background((building.workerPriority ?? 1) == priority ? Color.white.opacity(0.18) : .clear, in: RoundedRectangle(cornerRadius: 8))
                        }.buttonStyle(.plain)
                            .accessibilityLabel("\(["Low", "Normal", "High"][priority]) workforce priority")
                            .accessibilityAddTraits((building.workerPriority ?? 1) == priority ? .isSelected : [])
                            .accessibilityIdentifier("workerPriority-\(priority)")
                    }
                }
                Text(definition.survivalProduction == true ? "Basic food and water receive a protected workforce share even at low priority." : "Basic food and water receive workers first; other jobs share the remainder by priority.")
                    .font(.caption).foregroundStyle(parchment.opacity(0.65))
            } else {
                Text("Operates without assigned workers.").font(.caption).foregroundStyle(parchment.opacity(0.65))
            }
        }
    }
    private func workforceNumber(_ value: Double) -> String { String(format: "%g", (value * 100).rounded() / 100) }
    @ViewBuilder private func recipeButton(_ recipe: ProductionRecipe, building: PlacedBuilding, selected: Bool) -> some View {
        if session.configuration.isRiverbendPlayer && building.kind == .stoneGatherer {
            Button { session.setProductionMode(buildingID: building.id, recipeID: recipe.id) } label: {
                Label(recipe.name + " · " + amounts(recipe.outputsPerMinute) + "/min base", systemImage: selected ? "checkmark.circle.fill" : "circle")
                    .font(.caption).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }.buttonStyle(.bordered).accessibilityIdentifier("productionMode-" + recipe.id)
        } else {
        Button { session.setProductionMode(buildingID: building.id, recipeID: recipe.id) } label: {
            VStack(alignment: .leading, spacing: 5) {
                Label(recipe.name, systemImage: selected ? "checkmark.circle.fill" : "circle").font(.subheadline)
                if !amounts(recipe.inputsPerMinute).isEmpty {
                    Text("In / min: " + amounts(recipe.inputsPerMinute)).font(.caption)
                }
                Text("Out / min: " + amounts(recipe.outputsPerMinute)).font(.caption)
                if recipe.depositResource != nil { Text("Requires a deposit in reach").font(.caption).foregroundStyle(parchment.opacity(0.6)) }
            }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).padding(8)
                .background(Color.white.opacity(selected ? 0.12 : 0.04), in: RoundedRectangle(cornerRadius: 10))
        }.buttonStyle(.plain).accessibilityIdentifier("productionMode-" + recipe.id)
        }
    }
    private func effect(_ definition: BuildingDefinition) -> String {
        let output = definition.recipes?.first?.outputsPerMinute ?? definition.ratesPerMinute
        var effects = Resource.allCases.filter { output[$0] > 0 }.map { "+\(String(format: "%g", output[$0])) \($0.title.lowercased())/min" }
        if definition.housing > 0 { effects.append("+\(definition.housing) housing") }
        let modes = session.visibleProductionRecipes(for: definition.kind)
        if modes.count > 1 { effects.append("\(modes.count) production modes") }
        if let storage = definition.storageBonus, !amounts(storage).isEmpty { effects.append("Storage: " + amounts(storage)) }
        return effects.joined(separator: " · ")
    }
    private func amounts(_ values: ResourceAmounts) -> String {
        Resource.allCases.filter { values[$0] > 0 }.map { "\(String(format: "%g", values[$0])) \($0.title.lowercased())" }.joined(separator: " · ")
    }
    private func cost(_ values: ResourceAmounts) -> String {
        let description = amounts(values)
        return description.isEmpty ? "No resource cost" : description
    }
}
extension Resource {
    var title: String {
        switch self {
        case .animalHides: "Animal hides"
        case .stoneTools: "Stone tools"
        default: rawValue.capitalized
        }
    }
    var symbol: String {
        switch self {
        case .food: "leaf.fill"
        case .wood: "tree.fill"
        case .stone: "mountain.2.fill"
        case .water: "drop.fill"
        case .flint: "diamond.fill"
        case .clay: "square.stack.3d.up.fill"
        case .animalHides: "pawprint.fill"
        case .stoneTools: "hammer.fill"
        case .leather: "square.fill"
        case .pottery: "cup.and.saucer.fill"
        case .knowledge: "sparkles"
        case .culture: "theatermasks.fill"
        }
    }
    var color: Color {
        switch self {
        case .food, .clay, .pottery: .orange
        case .wood: .mint
        case .stone, .flint, .stoneTools: .gray
        case .water: .cyan
        case .animalHides, .leather: .brown
        case .knowledge: .yellow
        case .culture: .pink
        }
    }
}

/// Scroll visibility, earned state and frontmost presentation must all agree.
/// A lazy row being created or a menu opening is not an acknowledgement.
struct ViewedCompletion: ViewModifier {
    let session: GameSession
    let ids: Set<String>
    let earned: Bool
    let active: Bool
    @State private var visible = false
    func body(content: Content) -> some View {
        content
            .onScrollVisibilityChange(threshold: 0.7) { value in visible = value; acknowledge() }
            .onChange(of: earned) { _, _ in acknowledge() }
            .onChange(of: active) { _, _ in acknowledge() }
            .onChange(of: session.state.completionInbox?.unread) { _, _ in acknowledge() }
            .onDisappear { visible = false }
    }
    private func acknowledge() {
        if active && visible && earned { session.acknowledgeCompletions(ids) }
    }
}
