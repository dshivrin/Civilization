import SwiftUI
import Observation
import GameCore
import GameApplication

struct BuildingCatalogView: View {
    let session: GameSession
    @Binding var selectedCategory: String
    var focusedBuildingKind: BuildingKind? = nil
    var playerMemory: PlayerCatalogMemory? = nil
    @State private var fallbackPlayerMemory = PlayerCatalogMemory()
    @State private var highlightedKind: BuildingKind?
    private struct CatalogLocation { var kind: BuildingKind; var category: String; var search: String }
    @State private var focusHistory: [CatalogLocation] = []
    @State private var focusRequest = 0
    @State private var researchTarget: String?
    @State private var researchSource = "buildings"
    @State private var researchPillar: DevelopmentPillar = .science
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    @FocusState private var searchFocused: Bool
    @State private var expanded: Set<BuildingKind> = []
    @Environment(\.dynamicTypeSize) private var typeSize
    private var categories: [String] { ["All"] + Set(session.visibleBuildingDefinitions.map { $0.category ?? "Other" }).sorted() + ["Roads"] }
    private func definitions(_ category: String) -> [BuildingDefinition] {
        session.visibleBuildingDefinitions.filter { category == "All" || ($0.category ?? "Other") == category }
    }
    private func constructed(_ kind: BuildingKind) -> Int { session.state.buildings.filter { $0.kind == kind && $0.isOperational }.count }
    var body: some View {
        if session.configuration.isRiverbendPlayer {
            PlayerBuildingCatalog(session: session, memory: playerMemory ?? fallbackPlayerMemory, focusedKind: focusedBuildingKind)
        } else { legacyBody }
    }
    private var legacyBody: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width > 1000
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Buildings").font(.system(.title, design: .serif).bold())
                        Text("Stone Age · \(definitions("All").filter { constructed($0.kind) > 0 }.count)/\(session.visibleBuildingDefinitions.count) types constructed").font(.caption)
                    }
                    Spacer()
                    if let previous = focusHistory.last {
                        Button("Back to " + session.configuration.definition(previous.kind).name) {
                            guard let location = focusHistory.popLast() else { return }
                            searchFocused = false; search = location.search; selectedCategory = location.category
                            expanded.insert(location.kind); highlightedKind = location.kind; focusRequest += 1
                        }.frame(minHeight: 44).buttonStyle(.bordered).accessibilityIdentifier("returnToBuildingItem")
                    }
                    TextField("Find building", text: $search, prompt: Text("Find building").foregroundStyle(parchment.opacity(0.65)))
                        .foregroundStyle(parchment).padding(10).background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                        .frame(maxWidth: 220).frame(minHeight: 44).accessibilityLabel("Find building").accessibilityIdentifier("catalogSearch")
                        .focused($searchFocused).submitLabel(.done).onSubmit { searchFocused = false }
                    Button("Done", systemImage: "xmark") { dismiss() }.frame(minWidth: 80, minHeight: 44).buttonStyle(.bordered)
                        .accessibilityIdentifier("closeBuildingCatalog")
                }
                HStack(alignment: .top, spacing: 20) {
                    if wide { VStack(spacing: 8) { ForEach(categories, id: \.self) { category($0) }; Spacer() }.frame(width: 220) }
                    VStack(spacing: 8) {
                        if !wide { ScrollView(.horizontal) { HStack(spacing: 8) { ForEach(categories, id: \.self) { category($0) } } }.fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("buildingCategories") }
                        ScrollViewReader { proxy in
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: typeSize.isAccessibilitySize ? 420 : 280), alignment: .top)], alignment: .leading, spacing: 10) {
                                if selectedCategory == "Roads" {
                                    ForEach(RoadStyle.allCases, id: \.self) { style in roadCard(style) }
                                }
                                ForEach(definitions(selectedCategory).filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) }, id: \.kind) { card($0).id($0.kind) }
                            }.scrollTargetLayout().padding(.bottom, 20)
                            if selectedCategory != "Roads" && definitions(selectedCategory).filter({ search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) }).isEmpty { Text("No matching buildings.").padding() }
                        }.frame(maxHeight: .infinity).clipped().accessibilityIdentifier("buildingCatalog")
                        .task(id: focusRequest) {
                            guard let kind = highlightedKind else { return }
                            await Task.yield()
                            proxy.scrollTo(kind, anchor: .top)
                        }
                        }
                    }
                }
            }.padding(12)
        }.background(panelColor).foregroundStyle(parchment).tint(StonePalette.accent)
        .onAppear { if let focusedBuildingKind { focus(focusedBuildingKind) } }
        .sheet(isPresented: Binding(get: { researchTarget != nil }, set: { if !$0 { researchTarget = nil } })) {
            ResearchView(session: session, selectedPillar: $researchPillar, focusedTechnologyID: researchTarget, returnLabel: "Return to " + researchSource)
        }

    }
    private func focus(_ kind: BuildingKind) {
        searchFocused = false; search = ""; selectedCategory = session.configuration.definition(kind).category ?? "Other"
        expanded.insert(kind); highlightedKind = kind; focusRequest += 1
    }
    private func category(_ title: String) -> some View {
        let entries = definitions(title)
        let count = entries.filter { constructed($0.kind) > 0 }.count
        return DevelopmentCategoryButton(title: title, detail: title == "Roads" ? "Three free surfaces" : "\(count)/\(entries.count) constructed", completed: count, total: entries.count, selected: selectedCategory == title) { selectedCategory = title }
            .accessibilityIdentifier("buildingCategory-" + title)
    }
    private func roadCard(_ style: RoadStyle) -> some View {
        Button {
            session.chooseRoadTool(.draw(style))
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath").font(.title2).frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 4) {
                    Text(style.title).font(.headline)
                    Text(session.usesConnectedPaths ? "Free · connects services · drag to preview" : "Free · decorative · drag to preview").font(.caption)
                }
                Spacer()
                Image(systemName: "chevron.right")
            }.padding(12).frame(minHeight: 64)
        }.buttonStyle(.plain).modifier(DevelopmentCardStyle(color: .yellow))
            .accessibilityIdentifier("roadCatalog-" + style.rawValue)
    }
    private func amounts(_ values: ResourceAmounts) -> String {
        let items = Resource.allCases.filter { values[$0] > 0 }.map { "\(String(format: "%g", values[$0])) \($0.title)" }
        return items.isEmpty ? "None" : items.joined(separator: " · ")
    }
    private func card(_ definition: BuildingDefinition) -> some View {
        let locked = !session.isUnlocked(definition.kind)
        let count = constructed(definition.kind)
        let campfire = definition.kind == .campfire
        let affordable = session.canAfford(definition.cost)
        let supplier = locked || campfire ? nil : session.bootstrapRequirement(for: definition.cost, constructing: definition.kind)
        let supplierName = supplier.map { session.configuration.definition($0).name }
        let status = locked ? "Research required" : supplierName.map { "Build " + $0 + " first" } ?? (campfire ? "Permanent civic center" : count > 0 ? "Constructed · \(count)" : affordable ? "Available" : "Need resources")
        let actionLabel = campfire ? "Campfire already placed" : locked ? definition.name + ": research required" : supplierName.map { definition.name + ": build " + $0 + " first" } ?? ("Build " + definition.name)
        let blocked = locked || campfire || supplier != nil
        let color: Color = supplier != nil ? .orange : locked ? parchment.opacity(0.6) : count > 0 ? .mint : .yellow
        let prerequisites = session.configuration.technologyDefinitions.filter { $0.effects.unlockedBuildings.contains(definition.kind) }
        let isExpanded = Binding(get: { expanded.contains(definition.kind) }, set: { if $0 { expanded.insert(definition.kind) } else { expanded.remove(definition.kind) } })
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                DevelopmentSummary(title: definition.name, status: status, symbol: locked ? "lock.fill" : count > 0 ? "checkmark.seal.fill" : "hammer.fill", color: color) {
                    BuildingThumbnail(kind: definition.kind, size: 44)
                }
                DevelopmentDetailsButton(title: definition.name, id: "building-" + definition.kind.rawValue, expanded: isExpanded)
            }
            HStack(spacing: 6) {
                DevelopmentCosts(cost: definition.cost, stored: session.state.resources, id: "building-" + definition.kind.rawValue)
                Button(campfire ? "Placed" : locked ? "Locked" : supplier != nil ? "Reserved" : "Build") {
                    session.choose(definition.kind)
                    dismiss()
                }.font(.caption.bold()).padding(.horizontal, 10).frame(minWidth: 64, minHeight: 44).buttonStyle(.plain)
                    .background(blocked ? Color.white.opacity(0.08) : .yellow, in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(blocked ? parchment.opacity(0.6) : panelColor).disabled(blocked)
                    .accessibilityLabel(actionLabel)
                    .accessibilityIdentifier("build-" + definition.kind.rawValue)
            }
            if isExpanded.wrappedValue {
                Divider().overlay(parchment.opacity(0.2))
                if let supplier, let issue = session.bootstrapSpendIssue(for: definition.cost, constructing: definition.kind) {
                    Text(issue.localizedDescription).font(.caption).foregroundStyle(.orange)
                        .accessibilityIdentifier("building-reserve-" + definition.kind.rawValue)
                    Button("Show " + session.configuration.definition(supplier).name) {
                        focusHistory.append(CatalogLocation(kind: definition.kind, category: selectedCategory, search: search))
                        focus(supplier)
                    }.frame(minHeight: 44).buttonStyle(.bordered)
                        .accessibilityIdentifier("showBootstrapSupplier-" + definition.kind.rawValue)
                }
                Text(definition.description ?? definition.name).font(.subheadline).fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("building-description-" + definition.kind.rawValue)
                DevelopmentCosts(cost: definition.cost, stored: session.state.resources, id: "building-detail-" + definition.kind.rawValue, detailed: true)
                if locked, let prerequisite = prerequisites.first(where: { !session.researchedIDs.contains($0.id) }) {
                    Button("Research " + prerequisite.name) {
                        researchSource = definition.name; researchTarget = prerequisite.id
                    }.frame(minHeight: 44).buttonStyle(.bordered).accessibilityIdentifier("buildingResearch-" + definition.kind.rawValue)
                }
                Text("Research: " + (prerequisites.isEmpty ? "None" : prerequisites.map { $0.name + (session.researchedIDs.contains($0.id) ? " ✓" : "") }.joined(separator: ", "))).font(.caption)
                ForEach(definition.recipes ?? [], id: \.id) { recipe in
                    Text(recipe.name + ": " + amounts(recipe.outputsPerMinute) + "/min" + (Resource.allCases.contains { recipe.inputsPerMinute[$0] > 0 } ? " · uses " + amounts(recipe.inputsPerMinute) + "/min" : ""))
                        .font(.caption).foregroundStyle(.mint)
                }
                if definition.housing > 0 { Text("+\(definition.housing) housing").font(.caption) }
                if let storage = definition.storageBonus { Text("Storage: " + amounts(storage)).font(.caption) }
                Text("\(definition.width)×\(definition.height) tiles · \(Int(ceil(session.constructionDuration(for: definition.kind))))s · \(String(format: "%g", definition.workersRequired ?? 0)) workers").font(.caption).foregroundStyle(parchment.opacity(0.7))
                if definition.requiredNearbyTerrain != nil { Text("Requires revealed nearby water.").font(.caption) }
            }
        }.modifier(DevelopmentCardStyle(color: color))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(highlightedKind == definition.kind ? Color.yellow : .clear, lineWidth: 2))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(highlightedKind == definition.kind ? "focusedBuilding-" + definition.kind.rawValue : "buildingCard-" + definition.kind.rawValue)
    }
}

/// Presentation memory belongs to the mounted game, not to the sheet's lifetime or save schema.
@Observable final class PlayerCatalogMemory {
    var selected: BuildingKind = .hut
    var category = "All"
    var search = ""
    var scrollID: BuildingKind?
}

private struct PlayerBuildingCatalog: View {
    let session: GameSession
    @Bindable var memory: PlayerCatalogMemory
    let focusedKind: BuildingKind?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var textSize
    @FocusState private var searching: Bool
    @State private var appliedInitialFocus = false
    @State private var material: Resource?
    @State private var history: [(BuildingKind, String, String, BuildingKind?)] = []
    @State private var researchID: String?
    @State private var researchPillar: DevelopmentPillar = .science
    private var definition: BuildingDefinition { session.configuration.definition(memory.selected) }
    private var price: ResourceAmounts { memory.selected == .storehouse ? session.storageSpecialization.cost : definition.cost }
    private var missing: Resource? { Resource.allCases.first { session.state.resources[$0] < price[$0] } }
    private var civicLevel: Int { session.state.buildings.first { $0.kind == .campfire }?.level ?? 1 }
    private var prerequisite: TechnologyDefinition? {
        guard !session.isUnlocked(memory.selected) else { return nil }
        return session.visibleTechnologies.first { $0.effects.unlockedBuildings.contains(memory.selected) && !session.researchedIDs.contains($0.id) }
    }
    private var sourceBlocked: Bool {
        switch memory.selected {
        case .woodcutter: return (session.state.explorationRadius ?? 0) <= (session.configuration.explorationRules?.initialRadius ?? 0)
        case .stoneGatherer: return !session.riverbendOpeningComplete
        case .storehouse: return !session.riverbendCraftAvailable
        default: return false
        }
    }
    private var alreadyStored: Bool { memory.selected == .storehouse && session.riverbendProgress?.storage.values.contains(session.storageSpecialization) == true }
    private var actionTitle: String {
        if memory.selected == .campfire { return "Inspect civic center" }
        if civicLevel < 2 { return "Found Lodge first" }
        if prerequisite != nil { return "Open required research" }
        if alreadyStored { return "This storage role is already built" }
        if missing != nil || sourceBlocked { return "Find materials" }
        return "Build"
    }
    private var matches: [BuildingDefinition] {
        session.visibleBuildingDefinitions.filter { (memory.category == "All" || $0.category == memory.category) && (memory.search.isEmpty || $0.name.localizedCaseInsensitiveContains(memory.search)) }
    }
    var body: some View {
        GeometryReader { geometry in
            let pad = geometry.size.width > 1000
            VStack(spacing: 6) {
                HStack(spacing: 10) {
                    Label("Buildings", systemImage: "hammer").font(.system(.title3, design: .serif).bold())
                    Spacer(minLength: 4)
                    TextField("Find building", text: $memory.search).focused($searching)
                        .submitLabel(.done).onSubmit { searching = false }
                        .padding(8).background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                        .frame(maxWidth: 220).frame(minHeight: 44).accessibilityLabel("Find building").accessibilityIdentifier("catalogSearch")
                    Button("Done") { searching = false; dismiss() }.frame(minWidth: 56, minHeight: 44).accessibilityIdentifier("closeCatalog")
                }
                ScrollView(.horizontal) {
                    HStack(spacing: 6) {
                        ForEach(["All"] + Set(session.visibleBuildingDefinitions.compactMap(\.category)).sorted() + ["Roads"], id: \.self) { category in
                            Button(category) { searching = false; memory.category = category }
                                .font(.caption.bold()).frame(minHeight: 44).padding(.horizontal, 10)
                                .background(memory.category == category ? Color.white.opacity(0.16) : panelColor, in: RoundedRectangle(cornerRadius: 8))
                                .accessibilityIdentifier("buildingCategory-" + category)
                        }
                    }
                }.fixedSize(horizontal: false, vertical: true)
                if pad {
                    HStack(alignment: .top, spacing: 12) { grid; inspector.frame(width: 330) }
                } else {
                    VStack(spacing: 6) {
                        grid
                        if !searching { inspector.frame(height: textSize.isAccessibilitySize ? 200 : 156) }
                    }
                }
            }.padding(10)
        }
        .background(panelColor).foregroundStyle(parchment).tint(StonePalette.accent)
        .onChange(of: memory.search) { _, _ in if searching { memory.scrollID = matches.first?.kind } }
        .onAppear {
            if !appliedInitialFocus { appliedInitialFocus = true; if let focusedKind { focus(focusedKind) } }
        }
        .sheet(isPresented: Binding(get: { researchID != nil }, set: { if !$0 { researchID = nil } })) {
            ResearchView(session: session, selectedPillar: $researchPillar, focusedTechnologyID: researchID, returnLabel: "Return to " + definition.name)
        }
    }
    private var grid: some View {
        ScrollView {
            if memory.category == "Roads" {
                ForEach(RoadStyle.allCases, id: \.self) { style in
                    Button { session.chooseRoadTool(.draw(style)); dismiss() } label: {
                        Label(style.title + " · free connected surface", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading).padding(.horizontal, 12)
                    }.buttonStyle(.bordered).accessibilityIdentifier("roadCatalog-" + style.rawValue)
                }
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
                    ForEach(matches, id: \.kind) { item in
                        Button { searching = false; memory.selected = item.kind; material = nil } label: {
                            HStack(spacing: 8) {
                                BuildingThumbnail(kind: item.kind, size: 38)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name).font(.subheadline.bold()).lineLimit(2)
                                    Text(session.isUnlocked(item.kind) ? "Select to inspect" : "Research required").font(.caption).lineLimit(2)
                                }
                                Spacer(minLength: 0)
                            }.padding(8).frame(maxWidth: .infinity).frame(minHeight: textSize.isAccessibilitySize ? 128 : 92)
                                .background(memory.selected == item.kind ? .white.opacity(0.13) : .white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                        }.buttonStyle(.plain).accessibilityIdentifier("selectBuilding-" + item.kind.rawValue).id(item.kind)
                    }
                }.scrollTargetLayout()
                if matches.isEmpty { Text("No matching buildings. Your selection is retained below.").font(.caption).padding() }
            }
        }.scrollPosition(id: $memory.scrollID).accessibilityIdentifier("buildingCatalog")
    }
    private var inspector: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(definition.name).font(.subheadline.bold()).accessibilityIdentifier("playerCatalogSelection")
                Spacer()
                if !history.isEmpty { Button("Back") { back() }.frame(minHeight: 44).accessibilityIdentifier("returnToBuildingItem") }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if memory.selected == .storehouse {
                        Picker("Storage role", selection: Binding(get: { session.storageSpecialization }, set: { session.storageSpecialization = $0 })) {
                            Text("Granary").tag(StorageSpecialization.granary); Text("Stockyard").tag(StorageSpecialization.stockyard)
                        }.pickerStyle(.segmented).accessibilityIdentifier("storageSpecialization")
                    }
                    DevelopmentCosts(cost: price, stored: session.state.resources, id: "playerCatalogCost-" + memory.selected.rawValue, detailed: true)
                    if let material { materialRequirement(material) }
                    else {
                        Text(definition.description ?? definition.name).font(.caption).fixedSize(horizontal: false, vertical: true)
                        if memory.selected == .storehouse {
                            Text(session.storageSpecialization == .granary ? "+60 Food capacity only after completion and connection." : "+60 Wood/Stone and +24 Flint/Tools capacity after completion and connection.").font(.caption)
                        } else {
                            ForEach(session.visibleProductionRecipes(for: memory.selected), id: \.id) { recipe in
                                Text(recipe.name + " · " + amounts(recipe.outputsPerMinute) + "/min base").font(.caption)
                            }
                            if definition.housing > 0 { Text("+\(definition.housing) housing after completion and connection.").font(.caption) }
                        }
                        Text("\(definition.width)×\(definition.height) · \(Int(ceil(session.constructionDuration(for: memory.selected))))s paid construction").font(.caption)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }.accessibilityIdentifier("playerCatalogDetails")
            if material != nil {
                Button("Back to " + definition.name) { material = nil }.frame(maxWidth: .infinity, minHeight: 44).buttonStyle(.bordered).accessibilityIdentifier("playerCatalogBack")
            } else {
                Button(actionTitle) { act() }.frame(maxWidth: .infinity, minHeight: 44).buttonStyle(.borderedProminent)
                    .disabled(alreadyStored).accessibilityLabel(actionTitle + " · " + definition.name)
                    .accessibilityIdentifier("build-" + memory.selected.rawValue)
            }
        }.padding(10).stoneSurface()
            .accessibilityElement(children: .contain).accessibilityIdentifier("playerCatalogInspector")
    }
    private func act() {
        searching = false
        if memory.selected == .campfire || civicLevel < 2 {
            session.cancel(); session.inspect(buildingID: 0); dismiss()
        } else if let prerequisite {
            researchPillar = prerequisite.pillar; researchID = prerequisite.id
        } else if let missing { material = missing }
        else if sourceBlocked { material = memory.selected == .woodcutter ? .wood : .stone }
        else { session.choose(memory.selected); dismiss() }
    }
    @ViewBuilder private func materialRequirement(_ resource: Resource) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(resource.title + " · stored \(Int(session.state.resources[resource])) / \(Int(session.capacities[resource])) · net \(String(format: "%+.1f", session.rates[resource]))/min").font(.caption)
            if resource == .food { Button("Forage · Food reserve up to 12") { session.recoverRiverbendFood() }.frame(minHeight: 44) }
            if resource == .wood {
                Button("Collect fallen branches · bounded Wood reserve") { session.recoverRiverbendWood() }.frame(minHeight: 44)
                if (session.state.explorationRadius ?? 0) <= (session.configuration.explorationRules?.initialRadius ?? 0) {
                    Text("Reveal the whole forest before placing the Woodcutter beside its work face.").font(.caption)
                    Button("Survey whole forest · 8 Food · 60s") { session.startExploration() }.frame(minHeight: 44).disabled(session.explorationIssue != nil)
                }
            }
            if !session.riverbendOpeningComplete && resource == .stone {
                Text("Complete and connect the Gathering Shelter and Woodcutter before the free nearby Stone discovery.").font(.caption)
            }
            if let remaining = session.state.explorationRemainingSeconds { Text("Expedition · \(Int(ceil(remaining)))s remaining").font(.caption) }
            if resource == .stone && !session.riverbendOpeningComplete {
                Button("Open Gathering Shelter") { follow(.gatheringShelter) }.frame(minHeight: 44)
                Button("Open Woodcutter") { follow(.woodcutter) }.frame(minHeight: 44)
            } else if !(resource == .wood && memory.selected == .woodcutter && sourceBlocked) {
                sourceButton(resource)
            }
        }.accessibilityElement(children: .contain).accessibilityIdentifier("playerCatalogRequirement")
    }
    private func sourceButton(_ resource: Resource) -> some View {
        let kind: BuildingKind = resource == .food ? .gatheringShelter : resource == .wood ? .woodcutter : resource == .knowledge ? .campfire : .stoneGatherer
        return Button("Open " + session.configuration.definition(kind).name) {
            if let building = session.state.buildings.first(where: { $0.kind == kind }) {
                session.cancel(); session.inspect(buildingID: building.id); dismiss()
            } else {
                follow(kind)
            }
        }.frame(minHeight: 44).accessibilityIdentifier("playerCatalogSource")
    }
    private func follow(_ kind: BuildingKind) {
        history.append((memory.selected, memory.category, memory.search, memory.scrollID)); material = nil; focus(kind)
    }
    private func focus(_ kind: BuildingKind) {
        memory.selected = kind; memory.category = session.configuration.definition(kind).category ?? "All"
        memory.search = ""; memory.scrollID = kind
    }
    private func back() {
        guard let previous = history.popLast() else { return }
        memory.selected = previous.0; memory.category = previous.1; memory.search = previous.2; memory.scrollID = previous.3; material = nil
    }
    private func amounts(_ values: ResourceAmounts) -> String {
        Resource.allCases.filter { values[$0] > 0 }.map { "\(String(format: "%g", values[$0])) \($0.title)" }.joined(separator: " · ")
    }
}
