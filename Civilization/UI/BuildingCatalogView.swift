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
    private var categories: [String] { ["All"] + Set(session.configuration.buildings.map { $0.category ?? "Other" }).sorted() }
    private func definitions(_ category: String) -> [BuildingDefinition] {
        session.configuration.buildings.filter { category == "All" || ($0.category ?? "Other") == category }
    }
    private func constructed(_ kind: BuildingKind) -> Int { session.state.buildings.filter { $0.kind == kind && $0.isOperational }.count }
    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width > 1000
            VStack(spacing: 12) {
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
                    VStack(spacing: 12) {
                        if !wide { ScrollView(.horizontal) { HStack(spacing: 8) { ForEach(categories, id: \.self) { category($0) } } }.fixedSize(horizontal: false, vertical: true) }
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: typeSize.isAccessibilitySize ? 420 : 248), alignment: .top)], alignment: .leading, spacing: 10) {
                                ForEach(definitions(selectedCategory).filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) }, id: \.kind) { card($0) }
                            }.padding(.bottom, 20)
                            if definitions(selectedCategory).filter({ search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) }).isEmpty { Text("No matching buildings.").padding() }
                        }.frame(maxHeight: .infinity).clipped().accessibilityIdentifier("buildingCatalog")
                    }
                }
            }.padding(16)
        }.background(panelColor).foregroundStyle(parchment).tint(.yellow)
    }
    private func category(_ title: String) -> some View {
        let entries = definitions(title)
        let count = entries.filter { constructed($0.kind) > 0 }.count
        return DevelopmentCategoryButton(title: title, detail: "\(count)/\(entries.count) constructed", completed: count, total: entries.count, selected: selectedCategory == title) { selectedCategory = title }
            .accessibilityIdentifier("buildingCategory-" + title)
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
        let color: Color = locked ? parchment.opacity(0.6) : count > 0 ? .mint : .yellow
        let prerequisites = session.configuration.technologyDefinitions.filter { $0.effects.unlockedBuildings.contains(definition.kind) }
        let isExpanded = Binding(get: { expanded.contains(definition.kind) }, set: { if $0 { expanded.insert(definition.kind) } else { expanded.remove(definition.kind) } })
        return VStack(alignment: .leading, spacing: 8) {
            DevelopmentSummary(title: definition.name, status: locked ? "Research required" : campfire ? "Fixed anchor" : count > 0 ? "Constructed · \(count)" : affordable ? "Available" : "Need resources", symbol: locked ? "lock.fill" : count > 0 ? "checkmark.seal.fill" : "hammer.fill", color: color) {
                BuildingThumbnail(kind: definition.kind, size: 48)
            }
            DevelopmentCosts(cost: definition.cost, stored: session.state.resources, id: "building-" + definition.kind.rawValue)
            HStack(spacing: 8) {
                Button(campfire ? "Already placed" : locked ? "Locked" : "Build") {
                    session.choose(definition.kind)
                    dismiss()
                }.frame(maxWidth: .infinity, minHeight: 44).buttonStyle(.borderedProminent).foregroundStyle(panelColor).disabled(locked || campfire)
                    .accessibilityLabel(campfire ? "Campfire already placed" : locked ? definition.name + ": research required" : "Build " + definition.name)
                    .accessibilityIdentifier("build-" + definition.kind.rawValue)
                DevelopmentDetailsButton(title: definition.name, id: "building-" + definition.kind.rawValue, expanded: isExpanded)
            }
            if isExpanded.wrappedValue {
                Divider().overlay(parchment.opacity(0.2))
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
