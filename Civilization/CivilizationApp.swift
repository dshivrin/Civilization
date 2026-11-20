import GameApplication
import GamePersistence
import SwiftUI

@main
struct CivilizationApp: App {
    @Environment(\.scenePhase) private var phase
    @State private var library: GameLibrary?
    @State private var benchmarkSession: GameSession?
    @State private var startupError: String?
    @State private var showGames = false
    @State private var sceneIsActive = false
    @State private var libraryRoot: URL?
    @State private var recoveryGames: [SavedGame] = []
    @State private var isRestoring = false
    var body: some Scene {
        WindowGroup {
            Group {
                if let library {
                    SettlementView(session: library.session, openGames: { showGames = true }, managesLifecycle: false)
                        .id(library.activeGameID)
                } else if let benchmarkSession { SettlementView(session: benchmarkSession) }
                else if isRestoring { SettlementLoadingView(stage: "Restoring settlement…") }
                else if let startupError {
                    if recoveryGames.isEmpty {
                        ContentUnavailableView("Unable to open settlement", systemImage: "exclamationmark.triangle", description: Text(startupError))
                    } else {
                        NavigationStack {
                            List {
                                Section { Text(startupError).accessibilityIdentifier("gameRecoveryError")
                                    Text("Existing game files have been preserved. Choose a saved game to open.") }
                                Section("Saved games") {
                                    ForEach(recoveryGames) { game in
                                        Button(game.name) { Task { await restoreLibrary(selectedGameID: game.id) } }
                                            .frame(minHeight: 44).accessibilityIdentifier("recoverGame-" + game.id)
                                    }
                                }
                            }.navigationTitle("Open a saved game")
                        }
                    }
                }
                else { SettlementLoadingView(stage: "Restoring settlement…") }
            }
            .sheet(isPresented: $showGames) {
                if let library { SavedGamesView(library: library) }
            }
            .onChange(of: phase, initial: true) { _, phase in
                sceneIsActive = phase == .active
                library?.setActive(sceneIsActive)
            }
            .task {
                guard library == nil && benchmarkSession == nil && startupError == nil else { return }
                do {
                    var root: URL?
                    #if DEBUG
                    if ProcessInfo.processInfo.environment["CIVILIZATION_UI_FRESH_SAVE"] == "1" {
                        // A validated UUID allows a single UI test to relaunch its isolated library.
                        // Ordinary fresh tests get a new root, and no environment value supplies a path.
                        let requestedID = ProcessInfo.processInfo.environment["CIVILIZATION_UI_LIBRARY_ID"]
                        let id = requestedID.flatMap(UUID.init(uuidString:))?.uuidString ?? UUID().uuidString
                        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("ui-library-" + id)
                        root = folder
                        let url = folder.appendingPathComponent("settlement-v1.json")
                        if !FileManager.default.fileExists(atPath: url.path),
                           let encoded = ProcessInfo.processInfo.environment["CIVILIZATION_UI_EARNED_SAVE"] {
                            guard let data = Data(base64Encoded: encoded) else { throw CocoaError(.fileReadCorruptFile) }
                            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                            try data.write(to: url, options: .atomic)
                        }
                        if ProcessInfo.processInfo.environment["CIVILIZATION_UI_MISSING_SELECTED_SAVE"] == "1",
                           !FileManager.default.fileExists(atPath: folder.appendingPathComponent("games-index.json").path) {
                            // A missing registered slot fixture lives only in this fresh temporary Debug library.
                            let prepared = try await GameLibrary.load(rootURL: folder)
                            var index = prepared.index
                            let missing = SavedGame(id: UUID().uuidString, name: "Unavailable test game", createdAt: Date(), mapID: prepared.session.state.mapID)
                            index.games.append(missing); index.activeGameID = missing.id
                            try GameLibraryStore(rootURL: folder).save(index)
                        }
                    } else if ProcessInfo.processInfo.environment["CIVILIZATION_RENDER_SCENARIO"] == "late" {
                        benchmarkSession = try GameSession.renderBenchmark(in: FileManager.default.temporaryDirectory)
                        return
                    }
                    #endif
                    libraryRoot = root
                    await restoreLibrary()
                }
                catch is CancellationError {}
                catch { startupError = error.localizedDescription }
            }
            .preferredColorScheme(.dark)
        }
    }
    @MainActor private func restoreLibrary(selectedGameID: String? = nil) async {
        guard !isRestoring else { return }
        isRestoring = true
        defer { isRestoring = false }
        do {
            library = try await GameLibrary.load(rootURL: libraryRoot, selectedGameID: selectedGameID)
            library?.setActive(sceneIsActive)
            startupError = nil; recoveryGames = []
        } catch is CancellationError {} catch {
            startupError = error.localizedDescription
            recoveryGames = (try? GameLibrary.availableGames(rootURL: libraryRoot)) ?? []
        }
    }
}
