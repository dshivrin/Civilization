import SwiftUI
import GameCore
import GameApplication

struct BuildingCatalogView: View {
    let session: GameSession
    @Binding var selectedCategory: String
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
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
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), alignment: .top)], alignment: .leading, spacing: 14) {
                                ForEach(definitions(selectedCategory).filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) }, id: \.kind) { card($0) }
                            }.padding(.bottom, 20)
                            if definitions(selectedCategory).filter({ search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) }).isEmpty { Text("No matching buildings.").padding() }
                        }.accessibilityIdentifier("buildingCatalog")
                    }
                }
            }.padding(20)
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
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: symbol(definition)).font(.title2).frame(width: 34, height: 34)
                Text(definition.name).font(.title3.bold())
                Spacer()
                if count > 0 { Label("\(count)", systemImage: "checkmark.seal.fill").foregroundStyle(.mint) }
            }
            Label(locked ? "Research required" : campfire ? "Fixed settlement anchor" : affordable ? "Available" : "Need resources", systemImage: locked ? "lock.fill" : campfire ? "flame.fill" : affordable ? "hammer.fill" : "hourglass").font(.caption.bold()).foregroundStyle(color)
            Text(definition.description ?? definition.name).font(.subheadline).fixedSize(horizontal: false, vertical: true)
            Text("Research: " + (prerequisites.isEmpty ? "None" : prerequisites.map { $0.name + (session.researchedIDs.contains($0.id) ? " ✓" : "") }.joined(separator: ", "))).font(.caption)
            Text("Cost: " + amounts(definition.cost)).font(.caption).foregroundStyle(.yellow)
            ForEach(definition.recipes ?? [], id: \.id) { recipe in
                Text(recipe.name + ": " + amounts(recipe.outputsPerMinute) + "/min" + (Resource.allCases.contains { recipe.inputsPerMinute[$0] > 0 } ? " · uses " + amounts(recipe.inputsPerMinute) + "/min" : ""))
                    .font(.caption).foregroundStyle(.mint)
            }
            if definition.housing > 0 { Text("+\(definition.housing) housing").font(.caption) }
            if let storage = definition.storageBonus { Text("Storage: " + amounts(storage)).font(.caption) }
            Text("\(definition.width)×\(definition.height) tiles · \(Int(ceil(session.constructionDuration(for: definition.kind))))s · \(String(format: "%g", definition.workersRequired ?? 0)) workers").font(.caption).foregroundStyle(parchment.opacity(0.7))
            if definition.requiredNearbyTerrain != nil { Text("Requires revealed nearby water.").font(.caption) }
            Button(campfire ? "Already placed" : locked ? "Research required" : "Build " + definition.name) {
                session.choose(definition.kind)
                dismiss()
            }.frame(maxWidth: .infinity, minHeight: 44).buttonStyle(.borderedProminent).foregroundStyle(panelColor).disabled(locked || campfire)
                .accessibilityIdentifier("build-" + definition.kind.rawValue)
        }.modifier(DevelopmentCardStyle(color: color))
    }
    /// Replaceable SF Symbol placeholders, independent of renderer asset keys.
    private func symbol(_ definition: BuildingDefinition) -> String {
        if definition.kind == .campfire { return "flame.fill" }
        switch definition.category {
        case "Settlement": return "house.fill"
        case "Food and water": return "leaf.fill"
        case "Extraction": return "mountain.2.fill"
        case "Crafting": return "hammer.fill"
        case "Culture and knowledge": return "sparkles"
        case "Community": return "person.3.fill"
        default: return "shield.fill"
        }
    }
}
