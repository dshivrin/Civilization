import SwiftUI
import GameCore
import GameApplication

/// Research is separate from the map HUD so descriptions and costs have room on every device.
struct ResearchView: View {
    let session: GameSession
    @Binding var selectedPillar: DevelopmentPillar
    var focusedTechnologyID: String? = nil
    var returnLabel = "Return to civic center"
    @State private var highlightedID: String?
    @Environment(\.dismiss) private var dismiss
    @State private var showReadiness = false
    @State private var expanded: Set<String> = []
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var focusRequest = 0
    private let pillars: [DevelopmentPillar] = [.economy, .science, .population, .culture, .militarySecurity]
    private var completedRequirements: Int { session.stoneAgeRequirements.filter(\.isComplete).count }
    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width > 1000
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Research").font(.system(.title, design: .serif).bold())
                        Text("Stone Age · develop your settlement").font(.caption).foregroundStyle(parchment.opacity(0.7))
                    }
                    Spacer()
                    if focusedTechnologyID != nil {
                        Button(returnLabel) { dismiss() }.frame(minHeight: 44).buttonStyle(.bordered)
                            .accessibilityIdentifier(returnLabel == "Return to civic center" ? "returnToCivicCenter" : "returnToSource")
                    }
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
                    VStack(spacing: 8) {
                        if !wide {
                            ScrollView(.horizontal) { HStack(spacing: 8) { ForEach(pillars, id: \.self) { category($0) } } }.fixedSize(horizontal: false, vertical: true)
                        }
                        ScrollViewReader { proxy in
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: typeSize.isAccessibilitySize ? 420 : 280), alignment: .top)], alignment: .leading, spacing: 10) {
                                ForEach(session.configuration.technologyDefinitions.filter { $0.pillar == selectedPillar }) { technology in
                                    technologyCard(technology).id(technology.id)
                                }
                            }.scrollTargetLayout().padding(.bottom, 20)
                        }.frame(maxHeight: .infinity).clipped()
                        .task(id: focusRequest) {
                            guard let id = highlightedID else { return }
                            await Task.yield()
                            proxy.scrollTo(id, anchor: .top)
                        }
                        }
                    }
                }
            }.padding(12)
        }
        .background(panelColor).foregroundStyle(parchment).tint(.yellow)
        .onAppear {
            if let id = focusedTechnologyID, let technology = session.configuration.technologyDefinitions.first(where: { $0.id == id }) {
                focus(technology.id)
            }
        }
        .sheet(isPresented: $showReadiness) {
            NavigationStack {
                List {
                    Section {
                        Text("Upgrade your civic center to Council Circle, construct every required Stone Age building type, research every technology, discover required resource territories, and finish all five pillars. Storytelling Circles are optional. Keep playing in this settlement when ready.")
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
    private func focus(_ id: String) {
        guard let technology = session.configuration.technologyDefinitions.first(where: { $0.id == id }) else { return }
        selectedPillar = technology.pillar; expanded.insert(id); highlightedID = id
        focusRequest += 1
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
        let supplier = complete || missing ? nil : session.bootstrapRequirement(for: technology.cost)
        let reserved = supplier.map { "Build " + session.configuration.definition($0).name + " first" }
        let status = complete ? "Researched" : missing ? "Prerequisites needed" : reserved ?? (!affordable ? "Need resources" : "Available")
        let actionLabel = complete ? technology.name + ": researched" : missing ? technology.name + ": prerequisites needed" : reserved.map { technology.name + ": " + $0 } ?? ("Research " + technology.name)
        let color: Color = complete ? .mint : missing ? parchment.opacity(0.65) : !affordable || supplier != nil ? .orange : .yellow
        let isExpanded = Binding(get: { expanded.contains(technology.id) }, set: { if $0 { expanded.insert(technology.id) } else { expanded.remove(technology.id) } })
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                DevelopmentSummary(title: technology.name, status: status, symbol: complete ? "checkmark.seal.fill" : missing ? "lock.fill" : "sparkles", color: color) {
                    EraIcon(domain: .research, id: technology.id, size: 44)
                }
                DevelopmentDetailsButton(title: technology.name, id: "research-" + technology.id, expanded: isExpanded)
            }
            HStack(spacing: 6) {
                DevelopmentCosts(cost: technology.cost, stored: session.state.resources, id: "research-" + technology.id, paid: complete)
                Button(complete ? "Done ✓" : missing ? "Locked" : supplier != nil ? "Reserved" : "Research") { session.research(technology.id) }
                    .font(.caption.bold()).padding(.horizontal, 8).frame(minWidth: 70, minHeight: 44).buttonStyle(.plain)
                    .background(complete || session.researchIssue(technology.id) != nil ? Color.white.opacity(0.08) : .yellow, in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(complete || session.researchIssue(technology.id) != nil ? parchment.opacity(0.6) : panelColor)
                    .disabled(complete || session.researchIssue(technology.id) != nil)
                    .accessibilityLabel(actionLabel)
                    .accessibilityIdentifier("research-" + technology.id)
            }
            if isExpanded.wrappedValue {
                Divider().overlay(parchment.opacity(0.2))
                if supplier != nil, let issue = session.bootstrapSpendIssue(for: technology.cost) {
                    Text(issue.localizedDescription).font(.caption).foregroundStyle(.orange)
                        .accessibilityIdentifier("research-reserve-" + technology.id)
                }
                Text(technology.summary).font(.subheadline).foregroundStyle(parchment.opacity(0.85)).fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("research-description-" + technology.id)
                DevelopmentCosts(cost: technology.cost, stored: session.state.resources, id: "research-detail-" + technology.id, paid: complete, detailed: true)
                Text("Prerequisites: " + (technology.prerequisites.isEmpty ? "None" : technology.prerequisites.map { id in
                    (session.configuration.technologyDefinitions.first { $0.id == id }?.name ?? id) + (session.researchedIDs.contains(id) ? " ✓" : "")
                }.joined(separator: ", "))).font(.caption).foregroundStyle(parchment.opacity(0.75))
                ForEach(technology.prerequisites, id: \.self) { id in
                    Button("Show " + (session.configuration.technologyDefinitions.first { $0.id == id }?.name ?? id)) { focus(id) }
                        .frame(minHeight: 44).buttonStyle(.bordered).accessibilityIdentifier("researchPrerequisite-" + id)
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text("BENEFITS").font(.caption2.bold()).tracking(1)
                    ForEach(effects(technology), id: \.self) { Text($0).font(.subheadline) }
                }.foregroundStyle(.mint)
            }
        }.modifier(DevelopmentCardStyle(color: color))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(highlightedID == technology.id ? Color.yellow : .clear, lineWidth: 2))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(highlightedID == technology.id ? "focusedResearch-" + technology.id : "researchCard-" + technology.id)
    }
    private func effects(_ technology: TechnologyDefinition) -> [String] {
        var values: [String] = []
        for level in session.configuration.civicLevels ?? [] where level.requiredTechnology == technology.id {
            values.append("Civic center upgrade: " + level.name)
        }
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
