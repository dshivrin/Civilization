import SwiftUI
import GameCore
import GameApplication

/// Research is separate from the map HUD so descriptions and costs have room on every device.
struct ResearchView: View {
    let session: GameSession
    @Binding var selectedPillar: DevelopmentPillar
    @Environment(\.dismiss) private var dismiss
    @State private var showReadiness = false
    @State private var expanded: Set<String> = []
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var positions: [DevelopmentPillar: String] = [:]
    private let pillars: [DevelopmentPillar] = [.economy, .science, .population, .culture, .militarySecurity]
    private var completedRequirements: Int { session.stoneAgeRequirements.filter(\.isComplete).count }
    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width > 1000
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Research").font(.system(.title, design: .serif).bold())
                        Text("Stone Age · develop your settlement").font(.caption).foregroundStyle(parchment.opacity(0.7))
                    }
                    Spacer()
                    Button("Done", systemImage: "xmark") { dismiss() }.frame(minWidth: 80, minHeight: 44).buttonStyle(.bordered)
                        .accessibilityIdentifier("closeResearch")
                }
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Research · \(session.researchedIDs.count)/\(session.configuration.technologyDefinitions.count) technologies").font(.subheadline.bold())
                        ProgressView(value: Double(session.researchedIDs.count), total: Double(session.configuration.technologyDefinitions.count))
                    }
                    Button { showReadiness = true } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Label(session.state.stoneAgeCompleted == true ? "Stone Age Ready" : "Stone Age readiness · \(completedRequirements)/\(session.stoneAgeRequirements.count) checks", systemImage: "flag.checkered")
                                .font(.subheadline.bold())
                            ProgressView(value: Double(completedRequirements), total: Double(session.stoneAgeRequirements.count))
                        }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).contentShape(Rectangle())
                    }.buttonStyle(.plain).frame(minHeight: 44).accessibilityIdentifier("showReadiness")
                }
                HStack(alignment: .top, spacing: 20) {
                    if wide {
                        VStack(spacing: 8) { ForEach(pillars, id: \.self) { category($0) }; Spacer() }.frame(width: 220)
                    }
                    VStack(spacing: 12) {
                        if !wide {
                            ScrollView(.horizontal) { HStack(spacing: 8) { ForEach(pillars, id: \.self) { category($0) } } }.fixedSize(horizontal: false, vertical: true)
                        }
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: typeSize.isAccessibilitySize ? 420 : 248), alignment: .top)], alignment: .leading, spacing: 10) {
                                ForEach(session.configuration.technologyDefinitions.filter { $0.pillar == selectedPillar }) { technology in
                                    technologyCard(technology).id(technology.id)
                                }
                            }.scrollTargetLayout().padding(.bottom, 20)
                        }.frame(maxHeight: .infinity).clipped().scrollPosition(id: Binding(get: { positions[selectedPillar] }, set: { positions[selectedPillar] = $0 }))
                    }
                }
            }.padding(16)
        }
        .background(panelColor).foregroundStyle(parchment).tint(.yellow)
        .sheet(isPresented: $showReadiness) {
            NavigationStack {
                List {
                    Section {
                        Text("Complete every Stone Age building type and technology, discover required resource territories, and finish all five pillars. Keep playing in this settlement when ready.")
                        if session.state.stoneAgeCompleted == true && !session.fullStoneAgeRequirementsMet { Text("Previously earned readiness is preserved. The expanded checklist below remains available.") }
                        ForEach(session.stoneAgeRequirements) { requirement in
                            Label(requirement.title + " · " + requirement.progress, systemImage: requirement.isComplete ? "checkmark.circle.fill" : "circle")
                        }
                        if !session.missingDiscoveryResourceNames.isEmpty { Text("Find territories containing: " + session.missingDiscoveryResourceNames.map { Resource(rawValue: $0)?.title ?? $0 }.joined(separator: ", ")) }
                    }
                    ForEach(session.pillarGoals) { goal in
                        Section(goal.pillar.title) {
                            Label(goal.title, systemImage: session.isPillarGoalComplete(goal.id) ? "checkmark.seal.fill" : "circle")
                            Text(session.pillarGoalProgress(id: goal.id)).font(.subheadline)
                        }
                    }
                }.navigationTitle("Stone Age readiness")
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showReadiness = false }.frame(minHeight: 44) } }
            }
        }
    }
    private func category(_ pillar: DevelopmentPillar) -> some View {
        let technologies = session.configuration.technologyDefinitions.filter { $0.pillar == pillar }
        let completed = technologies.filter { session.researchedIDs.contains($0.id) }.count
        return DevelopmentCategoryButton(title: pillar.title, detail: "\(completed)/\(technologies.count) researched", completed: completed, total: technologies.count, selected: selectedPillar == pillar, pillarID: pillar.rawValue) { selectedPillar = pillar }
            .accessibilityIdentifier("pillarFilter-" + pillar.rawValue)
    }
    private func technologyCard(_ technology: TechnologyDefinition) -> some View {
        let complete = session.researchedIDs.contains(technology.id)
        let missing = technology.prerequisites.contains { !session.researchedIDs.contains($0) }
        let affordable = session.canAfford(technology.cost)
        let status = complete ? "Researched" : missing ? "Prerequisites needed" : !affordable ? "Need resources" : "Available"
        let color: Color = complete ? .mint : missing ? parchment.opacity(0.65) : !affordable ? .orange : .yellow
        let isExpanded = Binding(get: { expanded.contains(technology.id) }, set: { if $0 { expanded.insert(technology.id) } else { expanded.remove(technology.id) } })
        return VStack(alignment: .leading, spacing: 8) {
            DevelopmentSummary(title: technology.name, status: status, symbol: complete ? "checkmark.seal.fill" : missing ? "lock.fill" : "sparkles", color: color) {
                EraIcon(domain: .research, id: technology.id, size: 48)
            }
            DevelopmentCosts(cost: technology.cost, stored: session.state.resources, id: "research-" + technology.id, paid: complete)
            HStack(spacing: 8) {
                Button(complete ? "Researched ✓" : missing ? "Locked" : !affordable ? "Need resources" : "Research") { session.research(technology.id) }
                    .frame(maxWidth: .infinity, minHeight: 44).buttonStyle(.borderedProminent).foregroundStyle(panelColor)
                    .disabled(complete || session.researchIssue(technology.id) != nil)
                    .accessibilityLabel(complete ? technology.name + ": researched" : missing ? technology.name + ": prerequisites needed" : "Research " + technology.name)
                    .accessibilityIdentifier("research-" + technology.id)
                DevelopmentDetailsButton(title: technology.name, id: "research-" + technology.id, expanded: isExpanded)
            }
            if isExpanded.wrappedValue {
                Divider().overlay(parchment.opacity(0.2))
                Text(technology.summary).font(.subheadline).foregroundStyle(parchment.opacity(0.85)).fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("research-description-" + technology.id)
                DevelopmentCosts(cost: technology.cost, stored: session.state.resources, id: "research-detail-" + technology.id, paid: complete, detailed: true)
                Text("Prerequisites: " + (technology.prerequisites.isEmpty ? "None" : technology.prerequisites.map { id in
                    (session.configuration.technologyDefinitions.first { $0.id == id }?.name ?? id) + (session.researchedIDs.contains(id) ? " ✓" : "")
                }.joined(separator: ", "))).font(.caption).foregroundStyle(parchment.opacity(0.75))
                VStack(alignment: .leading, spacing: 5) {
                    Text("BENEFITS").font(.caption2.bold()).tracking(1)
                    ForEach(effects(technology), id: \.self) { Text($0).font(.subheadline) }
                }.foregroundStyle(.mint)
            }
        }.modifier(DevelopmentCardStyle(color: color))
    }
    private func effects(_ technology: TechnologyDefinition) -> [String] {
        var values: [String] = []
        if !technology.effects.unlockedBuildings.isEmpty {
            values.append("Unlocks: " + technology.effects.unlockedBuildings.map { session.configuration.definition($0).name }.joined(separator: ", "))
        }
        for resource in Resource.allCases {
            let bonus = technology.effects.productionBonus[resource], storage = technology.effects.storageBonus[resource]
            if bonus > 0 { values.append("\(resource.title) production +\(Int((bonus * 100).rounded()))%") }
            if storage > 0 { values.append("\(resource.title) storage +\(Int(storage))") }
        }
        if technology.effects.growthIntervalMultiplier != 1 { values.append("Growth time ×\(String(format: "%g", technology.effects.growthIntervalMultiplier))") }
        if technology.effects.constructionDurationMultiplier != 1 { values.append("Construction time ×\(String(format: "%g", technology.effects.constructionDurationMultiplier))") }
        return values.isEmpty ? ["Advances prerequisite knowledge."] : values
    }
}
