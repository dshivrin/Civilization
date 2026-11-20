import SwiftUI
import GameCore
import GameApplication

struct BuildingCatalogView: View {
    let session: GameSession
    @Binding var selectedCategory: String
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    @State private var expanded: Set<BuildingKind> = []
    @Environment(\.dynamicTypeSize) private var typeSize
    private var categories: [String] { ["All"] + Set(session.configuration.buildings.map { $0.category ?? "Other" }).sorted() + ["Roads"] }
    private func definitions(_ category: String) -> [BuildingDefinition] {
        session.configuration.buildings.filter { category == "All" || ($0.category ?? "Other") == category }
    }
    private func constructed(_ kind: BuildingKind) -> Int { session.state.buildings.filter { $0.kind == kind && $0.isOperational }.count }
    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width > 1000
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Buildings").font(.system(.title, design: .serif).bold())
                        Text("Stone Age · \(definitions("All").filter { constructed($0.kind) > 0 }.count)/\(session.configuration.buildings.count) types constructed").font(.caption)
                    }
                    Spacer()
                    TextField("Find building", text: $search, prompt: Text("Find building").foregroundStyle(parchment.opacity(0.65)))
                        .foregroundStyle(parchment).padding(10).background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                        .frame(maxWidth: 220).accessibilityIdentifier("catalogSearch")
                    Button("Done", systemImage: "xmark") { dismiss() }.frame(minWidth: 80, minHeight: 44).buttonStyle(.bordered)
                        .accessibilityIdentifier("closeBuildingCatalog")
                }
                HStack(alignment: .top, spacing: 20) {
                    if wide { VStack(spacing: 8) { ForEach(categories, id: \.self) { category($0) }; Spacer() }.frame(width: 220) }
                    VStack(spacing: 8) {
                        if !wide { ScrollView(.horizontal) { HStack(spacing: 8) { ForEach(categories, id: \.self) { category($0) } } }.fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("buildingCategories") }
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: typeSize.isAccessibilitySize ? 420 : 280), alignment: .top)], alignment: .leading, spacing: 10) {
                                if selectedCategory == "Roads" {
                                    ForEach(RoadStyle.allCases, id: \.self) { style in roadCard(style) }
                                }
                                ForEach(definitions(selectedCategory).filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) }, id: \.kind) { card($0) }
                            }.padding(.bottom, 20)
                            if selectedCategory != "Roads" && definitions(selectedCategory).filter({ search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) }).isEmpty { Text("No matching buildings.").padding() }
                        }.frame(maxHeight: .infinity).clipped().accessibilityIdentifier("buildingCatalog")
                    }
                }
            }.padding(12)
        }.background(panelColor).foregroundStyle(parchment).tint(.yellow)
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
                    Text("Free · decorative · drag to preview").font(.caption)
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
                        search = ""
                        selectedCategory = session.configuration.definition(supplier).category ?? "Other"
                    }.frame(minHeight: 44).buttonStyle(.bordered)
                        .accessibilityIdentifier("showBootstrapSupplier-" + definition.kind.rawValue)
                }
                Text(definition.description ?? definition.name).font(.subheadline).fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("building-description-" + definition.kind.rawValue)
                DevelopmentCosts(cost: definition.cost, stored: session.state.resources, id: "building-detail-" + definition.kind.rawValue, detailed: true)
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
    }
}
