import SwiftUI
import GameApplication

struct SavedGamesView: View {
    let library: GameLibrary
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var error: String?
    @FocusState private var naming: Bool
    private var canManage: Bool {
        #if DEBUG
        !library.session.isDeveloperMode
        #else
        true
        #endif
    }
    var body: some View {
        NavigationStack {
            Form {
                Section("Current game") {
                    Text(library.games.first { $0.id == library.activeGameID }?.name ?? "Settlement")
                        .font(.headline).accessibilityIdentifier("activeGameName")
                    Text("Each game has its own settlement and progress.").font(.subheadline).foregroundStyle(.secondary)
                }
                if !canManage {
                    Text("Return to the normal settlement in Developer tools before managing games.")
                        .accessibilityIdentifier("gamesDeveloperWarning")
                }
                Section("Other games") {
                    ForEach(library.games.filter { $0.id != library.activeGameID }) { game in
                        Button { run { try await library.openGame(id: game.id) } } label: {
                            HStack { Text(game.name); Spacer(); Image(systemName: "play.fill").accessibilityHidden(true) }
                                .frame(minHeight: 44)
                        }.accessibilityIdentifier("resumeGame-" + game.id)
                    }
                    if library.games.count == 1 { Text("Your other games will appear here.").foregroundStyle(.secondary) }
                }.disabled(library.isBusy || !canManage)
                Section("New game") {
                    TextField("Name (optional)", text: $name).accessibilityIdentifier("newGameName")
                        .focused($naming).submitLabel(.done).onSubmit { naming = false }
                    Button { naming = false; run { _ = try await library.createGame(name: name) } } label: {
                        Label("Start new game", systemImage: "plus.circle.fill").frame(minHeight: 44)
                    }.accessibilityIdentifier("createGame")
                }.disabled(library.isBusy || !canManage)
                if library.isBusy { ProgressView("Opening game…") }
                if let error { Text(error).foregroundStyle(.red).accessibilityIdentifier("gamesError") }
            }
            .navigationTitle("Games")
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }.frame(minHeight: 44).disabled(library.isBusy)
            } }
            .interactiveDismissDisabled(library.isBusy)
        }
    }
    private func run(_ operation: @escaping @MainActor () async throws -> Void) {
        error = nil
        Task { @MainActor in
            do { try await operation(); dismiss() }
            catch { self.error = error.localizedDescription }
        }
    }
}
