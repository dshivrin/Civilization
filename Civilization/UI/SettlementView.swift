import GameApplication
import SwiftUI
import GameCore

let parchment = Color(red: 0.94, green: 0.89, blue: 0.76)
let panelColor = Color(red: 0.105, green: 0.155, blue: 0.125)

struct SettlementView: View {
    @Environment(\.scenePhase) private var phase
    let session: GameSession
    let openGames: (() -> Void)?
    let managesLifecycle: Bool
    @State private var scene: SettlementScene? = nil
    @State private var inspectedResource: ResourceInspection?
    @State private var showPopulation = false
    @State private var worldReady = false
    @State private var goals = SettlementGoalsDisclosure(eraID: "stoneAge")
    @State private var category = "All"
    @State private var researchPillar: DevelopmentPillar = .science
    @State private var showResearch = false
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
    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 500
            ZStack {
                if let scene {
                    WorldView(scene: scene, session: session, onReady: { worldReady = true }, isObscured: showResearch || showCatalog || showJourney).ignoresSafeArea()
                }
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
                                Button { showDeveloperTools = true } label: { Image(systemName: "wrench.and.screwdriver").frame(width: 44, height: 44) }
                                    .buttonStyle(.plain).background(panelColor.opacity(0.8), in: RoundedRectangle(cornerRadius: 10)).accessibilityLabel("Developer tools").accessibilityIdentifier("developerTools")
                                #endif
                            }
                            #if DEBUG
                            if session.isDeveloperMode {
                                Text("DEVELOPER · \(session.developerPaused ? "PAUSED" : "\(Int(session.developerSpeed))×") · isolated save")
                                    .font(.caption.weight(.bold)).padding(8).background(.orange.opacity(0.22), in: Capsule())
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
                            Text(session.message).font(.system(size: 12)).lineLimit(2).foregroundStyle(parchment.opacity(0.85))
                                .padding(9).background(panelColor.opacity(0.94), in: RoundedRectangle(cornerRadius: 10))
                                .accessibilityIdentifier("settlementMessage")
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
                            }
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
                            }
                        }
                        .frame(width: compact ? 250 : min(340, geometry.size.width * 0.3))
                    }

                }
                .padding(.horizontal, compact ? 12 : 22)
                .padding(.vertical, compact ? 8 : 18)
                .accessibilityHidden(!worldReady)
            }
            .overlay(alignment: .bottom) {
                if session.movingBuildingID != nil {
                    Button { session.cancel() } label: {
                        Image(systemName: "xmark").font(.headline).frame(width: 48, height: 48)
                    }
                    .background(panelColor, in: Circle()).overlay(Circle().stroke(parchment.opacity(0.7)))
                    .padding(.bottom, 10).accessibilityLabel("Cancel move").accessibilityIdentifier("cancelRelocation")
                }
            }
            .foregroundStyle(parchment)
            .tint(Color(red: 0.91, green: 0.73, blue: 0.39))
            .overlay {
                if !worldReady { SettlementLoadingView(stage: "Preparing the valley…").ignoresSafeArea() }
            }
        }
        .onChange(of: session.isDragMode) { _, active in if active { goals.isExpanded = false } }
        .onChange(of: session.roadTool != nil) { _, active in if active { goals.isExpanded = false } }
        .onChange(of: session.eraID) { _, id in goals.observeEra(id) }
        .fullScreenCover(isPresented: $showJourney, onDismiss: {
            if let action = pendingGuidanceAction {
                pendingGuidanceAction = nil
                navigateGuidance(action)
            }
        }) {
            NavigationStack {
                ScrollView { goalCard(compact: false).padding() }.accessibilityIdentifier("journeyContent")
                    .background(panelColor).foregroundStyle(parchment).tint(.yellow)
                    .navigationTitle("Stone Age journey")
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showJourney = false }.frame(minHeight: 44) } }
            }
        }
        .fullScreenCover(isPresented: $showCatalog) {
            BuildingCatalogView(session: session, selectedCategory: $category)
        }
        .fullScreenCover(isPresented: $showResearch) {
            ResearchView(session: session, selectedPillar: $researchPillar)
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
    private var settlementBuildingPicker: some View {
        Menu {
            ForEach(session.state.buildings.sorted { $0.id < $1.id }) { building in
                Button {
                    session.inspect(buildingID: building.id)
                } label: {
                    Text("\(session.configuration.definition(building.kind).name) #\(building.id) · \(building.origin.x), \(building.origin.y)")
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
                    ForEach(Resource.allCases, id: \.self) { resource in resourceButton(resource, compact: compact) }
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
                Text(session.movingBuildingID == nil ? cost(definition.cost) : "Move building · no cost").font(.caption).foregroundStyle(parchment.opacity(0.7))
                Text(session.placementIssue?.localizedDescription ?? "Valid location · \(session.previewFootprint?.width ?? definition.width)×\(session.previewFootprint?.height ?? definition.height) tiles")
                    .font(.caption).foregroundStyle(session.placementIssue == nil ? Color.mint : Color.orange)
                    .fixedSize(horizontal: false, vertical: true)
                if let tile = session.selectedTile { Text("Tile \(tile.x), \(tile.y) · drag to move, release to place").accessibilityIdentifier("placementTile").font(.system(size: 10)).foregroundStyle(parchment.opacity(0.6)) }
                HStack {
                    if session.movingBuildingID == nil {
                        Button("Cancel", action: session.cancel).frame(maxWidth: .infinity, minHeight: 44).buttonStyle(.bordered)
                    }
                    Button("Confirm", action: session.confirm).frame(maxWidth: .infinity, minHeight: 44).buttonStyle(.borderedProminent).disabled(session.placementIssue != nil).accessibilityIdentifier("confirmPlacement")
                }
            }
        }.padding(14) }.background(panelColor.opacity(0.97), in: RoundedRectangle(cornerRadius: 18))
    }
    private var explorationPanel: some View {
        Group {
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
                Text("Explores a wider ring around camp. An operational scout camp is needed for journeys beyond radius \(rules.requiresScoutAfterRadius).")
                    .font(.caption).foregroundStyle(parchment.opacity(0.65))
                if let issue = session.explorationIssue { Text(issue.localizedDescription).font(.caption).foregroundStyle(.orange) }
                Button("Send expedition") { session.startExploration() }
                    .frame(maxWidth: .infinity, minHeight: 44).buttonStyle(.borderedProminent)
                    .disabled(session.explorationIssue != nil).accessibilityIdentifier("startExploration")
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
                Text("Requires future knowledge to identify. Cannot be extracted.").font(.caption).foregroundStyle(parchment.opacity(0.65))
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
                Text("Gross: \(signed(session.grossRates[resource])) / min")
                Text("Consumption: \(String(format: "%.1f", session.consumption[resource])) / min")
                Text("Net: \(signed(session.rates[resource])) / min").foregroundStyle(session.rates[resource] < 0 ? .orange : .mint)
                Text("Producing now: \(session.producingBuildingCount(for: resource)) buildings").font(.subheadline.bold())
                    .accessibilityIdentifier("resourceProducerCount")
                if resource == .knowledge {
                    Text("Another storytelling circle can speed research. Natural Knowledge improves output; enough inhabitants and balanced worker priorities keep both knowledge and materials flowing.").font(.caption)
                }
                Text("WHERE TO GATHER OR MAKE").font(.caption.bold())
                ForEach(session.productionSources(for: resource), id: \.kind) { definition in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(definition.name).font(.subheadline.bold())
                        ForEach((definition.recipes ?? []).filter { $0.outputsPerMinute[resource] > 0 }, id: \.id) { recipe in
                            Text(recipe.name + (amounts(recipe.inputsPerMinute).isEmpty ? "" : " · uses " + amounts(recipe.inputsPerMinute) + " / min"))
                                .font(.caption).foregroundStyle(.secondary)
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
            if let rules = session.configuration.workforceRules {
                Text("Also needs at least \(Int(rules.minimumWaterForGrowth)) water and positive net water. Water use: \(String(format: "%g", rules.waterPerPersonPerMinute)) per person/min. No deaths during shortages.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }.padding(20)
        }.frame(width: 300, height: 310).accessibilityIdentifier("populationDetails")
    }
    private func signed(_ number: Double) -> String { String(format: "%+.1f", number) }
    private func goalsPanel(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 4) {
                Button { goals.cycle() } label: {
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
                    .accessibilityValue(goals.state.rawValue)
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
        case .recipe, .priority, .inspect: "Inspect building"
        case .explore: "Open Explore"
        case .resource: "Resource help"
        case .population: "Population and workers"
        case .journey, .complete: "View era requirements"
        }
    }
    private func openGuidance() {
        let action = session.nextGuidance.action
        if showJourney {
            if action != .journey && action != .complete { pendingGuidanceAction = action; showJourney = false }
            return
        }
        navigateGuidance(action)
    }
    private func navigateGuidance(_ action: GuidanceAction) {
        session.cancel(); session.inspectedBuilding = nil
        switch action {
        case .build(let kind):
            category = session.configuration.definition(kind).category ?? "Other"
            showJourney = false; showCatalog = true
        case .research(let id):
            researchPillar = session.configuration.technologyDefinitions.first { $0.id == id }?.pillar ?? .science
            showJourney = false; showResearch = true
        case .recipe(let id, _), .priority(let id, _), .inspect(let id):
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
                Label("Stone Age readiness earned", systemImage: "checkmark.seal.fill").foregroundStyle(.mint)
                if !session.fullStoneAgeRequirementsMet { Text("Your historical readiness is preserved. Finish the expanded checklist at your own pace.").font(.caption) }
            }
            Text(session.nextGuidance.title).font(.headline).accessibilityIdentifier("journeyNextStepTitle")
            guidanceDetail(showAction: session.nextGuidance.action != .complete && session.nextGuidance.action != .journey)
            Text("Every chapter credits work completed ahead of time. Original construction rewards remain one-time awards.").font(.caption)
            ForEach(session.journeyChapters) { chapter in
                VStack(alignment: .leading, spacing: 6) {
                    Label("\(chapter.id). " + chapter.title, systemImage: chapter.isComplete ? "checkmark.circle.fill" : "circle").font(.subheadline.bold())
                    ProgressView(value: Double(chapter.completedCount), total: Double(max(1, chapter.objectives.count)))
                    ForEach(chapter.objectives) { objective in
                        HStack(alignment: .top) {
                            Image(systemName: objective.isComplete ? "checkmark.circle.fill" : "circle").foregroundStyle(objective.isComplete ? .mint : parchment)
                            Text(objective.title)
                            Spacer()
                            Text(objective.progress).monospacedDigit()
                        }.font(.caption)
                    }
                }
            }
            Text("Complete all catalog entries, required resource discoveries and all five pillars. Advancing into a new age is not yet available.").font(.caption)
        }.padding(12).frame(maxWidth: .infinity, alignment: .leading).accessibilityElement(children: .contain).accessibilityIdentifier("goalProgress")
    }
    private func inspectionPanel(_ building: PlacedBuilding) -> some View {
        let definition = session.configuration.definition(building.kind)
        return ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(definition.name + " · Lv \(building.level)").font(.headline)
                    Spacer()
                    Button { session.inspectedBuilding = nil } label: { Image(systemName: "xmark").frame(width: 44, height: 44) }.accessibilityLabel("Close inspection")
                }
                if building.isOperational {
                    Text(session.operatingStatus(building)).font(.subheadline).foregroundStyle(session.productivity(building) < 0.999 ? .orange : .mint)
                    Text("Productivity: \(Int((session.productivity(building) * 100).rounded()))%")
                        .font(.caption).accessibilityIdentifier("buildingProductivity")
                    if !effect(definition).isEmpty { Text("Base configuration: " + effect(definition)).font(.caption) }
                    if session.configuration.workforceRules != nil { workforceControls(building, definition: definition) }
                    if let recipes = definition.recipes, !recipes.isEmpty {
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
                    if let storage = definition.storageBonus, !amounts(storage).isEmpty {
                        Text("Storage per level: " + amounts(storage)).font(.caption)
                    }
                    if let bonus = definition.geographicBonus {
                        Text("Nearby terrain can improve output by \(Int(bonus.outputBonus * 100))% within \(bonus.radius) tiles.")
                            .font(.caption).foregroundStyle(parchment.opacity(0.7))
                    }
                    if let upgradeCost = session.upgradeCost(for: building) {
                        Text("Upgrade: " + cost(upgradeCost)).font(.caption).foregroundStyle(.yellow)
                        Button("Upgrade to level \(building.level + 1)") { session.upgrade(buildingID: building.id) }
                            .frame(maxWidth: .infinity, minHeight: 44).buttonStyle(.borderedProminent)
                            .disabled(session.upgradeIssue(buildingID: building.id) != nil).accessibilityIdentifier("upgradeBuilding")
                        if let issue = session.bootstrapSpendIssue(for: upgradeCost) {
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
                Text("Tile \(building.origin.x), \(building.origin.y) · \(building.occupiedFootprint(in: session.configuration).width)×\(building.occupiedFootprint(in: session.configuration).height) footprint").font(.caption).accessibilityIdentifier("inspectedBuildingPosition")
                if building.kind != .campfire {
                    Button("Move building") { session.beginRelocation(buildingID: building.id) }
                        .frame(maxWidth: .infinity, minHeight: 44).buttonStyle(.bordered).accessibilityIdentifier("moveBuilding")
                }
                Button("Close inspection") { session.inspectedBuilding = nil }.frame(minHeight: 44)
            }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
        }.background(panelColor, in: RoundedRectangle(cornerRadius: 18))
    }
    private func workforceControls(_ building: PlacedBuilding, definition: BuildingDefinition) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            let required = definition.workersRequired ?? 0
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
    private func recipeButton(_ recipe: ProductionRecipe, building: PlacedBuilding, selected: Bool) -> some View {
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
    private func effect(_ definition: BuildingDefinition) -> String {
        let output = definition.recipes?.first?.outputsPerMinute ?? definition.ratesPerMinute
        var effects = Resource.allCases.filter { output[$0] > 0 }.map { "+\(String(format: "%g", output[$0])) \($0.title.lowercased())/min" }
        if definition.housing > 0 { effects.append("+\(definition.housing) housing") }
        if let recipes = definition.recipes, recipes.count > 1 { effects.append("\(recipes.count) production modes") }
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
