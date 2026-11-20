#if DEBUG
import SwiftUI
import GameApplication

struct DeveloperToolsView: View {
    let session: GameSession
    @Environment(\.dismiss) private var dismiss
    @State private var preparation: Task<Void, Never>?
    var body: some View {
        NavigationStack {
            Form {
                Section("Isolated developer settlement") {
                    if session.isDeveloperMode {
                        Text("Source: " + session.developerScenario.title).font(.subheadline.bold())
                        Text(session.developerStateDescription).foregroundStyle(.orange).accessibilityIdentifier("developerStateDescription")
                    }
                    Text("Normal progress is isolated. The checkmark identifies the source scenario; Reset restores its original state. Debug settings reset on relaunch; no developer offline catch-up.").font(.subheadline)
                    ForEach(DeveloperScenario.allCases) { scenario in
                        Button { preparation = Task { await session.prepareDeveloperScenario(scenario); if !Task.isCancelled { dismiss() } } } label: {
                            HStack {
                                Text(scenario.title)
                                Spacer()
                                if session.isSelectedDeveloperScenario(scenario) { Image(systemName: "checkmark.circle.fill").foregroundStyle(.orange) }
                            }
                        }.frame(minHeight: 44)
                            .accessibilityAddTraits(session.isSelectedDeveloperScenario(scenario) ? .isSelected : [])
                            .accessibilityIdentifier("scenario-" + scenario.rawValue)
                    }
                    Button("Resume developer save") { preparation = Task { await session.prepareResumeDeveloperSettlement(); if !Task.isCancelled { dismiss() } } }.frame(minHeight: 44)
                }
                if session.isDeveloperMode {
                    Section("Simulation") {
                        Toggle("Pause simulation", isOn: Binding(get: { session.developerPaused }, set: session.setDeveloperPaused))
                        Picker("Simulation speed", selection: Binding(get: { session.developerSpeed }, set: session.setDeveloperSpeed)) {
                            ForEach([1.0, 2, 5, 10], id: \.self) { Text("\(Int($0))×").tag($0) }
                        }.pickerStyle(.segmented)
                        Toggle("Fast construction · 3 seconds", isOn: Binding(get: { session.developerFastConstruction }, set: session.setDeveloperFastConstruction))
                        Text("Applies to new buildings. At 1×, the three-second animation runs in real time; higher simulation speeds also accelerate construction.").font(.caption)
                        Button("Advance 1 minute") { session.advanceDeveloperTime(seconds: 60) }.frame(minHeight: 44)
                        Button("Advance 1 hour") { session.advanceDeveloperTime(seconds: 3600) }.frame(minHeight: 44)
                    }
                    Section("State controls") {
                        Button("Add 250 of each resource") { session.addDeveloperResources() }.frame(minHeight: 44)
                        Button("Add 5 inhabitants within housing") { session.addDeveloperPopulation() }.frame(minHeight: 44)
                        Menu("Unlock technology") {
                            ForEach(session.configuration.technologyDefinitions) { technology in
                                Button(technology.name) { session.unlockDeveloperTechnology(technology.id) }
                            }
                        }.frame(minHeight: 44)
                        Button("Unlock all technologies") { session.unlockDeveloperTechnology() }.frame(minHeight: 44)
                        Button("Reveal all territory") { session.revealDeveloperTerritory() }.frame(minHeight: 44)
                        Text(session.message).font(.caption).accessibilityIdentifier("developerMessage")
                    }
                    Section {
                        Button("Reset developer settlement", role: .destructive) { preparation = Task { await session.prepareDeveloperScenario(session.developerScenario); if !Task.isCancelled { dismiss() } } }.frame(minHeight: 44)
                        Button("Return to normal settlement") { session.returnToNormalGame(); dismiss() }.frame(minHeight: 44)
                    }
                }
            }.disabled(session.isPreparingDeveloperScenario)
                .overlay {
                    if session.isPreparingDeveloperScenario {
                        ProgressView("Preparing developer village…").padding(24)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .onDisappear { preparation?.cancel() }
                .navigationTitle("Developer tools")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { preparation?.cancel(); dismiss() }.frame(minHeight: 44) } }
        }
    }
}
#endif
