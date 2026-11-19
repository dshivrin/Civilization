import GameApplication
import SwiftUI

@main
struct CivilizationApp: App {
    @Environment(\.scenePhase) private var phase
    @State private var library: GameLibrary?
    @State private var benchmarkSession: GameSession?
    @State private var startupError: String?
    @State private var showGames = false
    @State private var sceneIsActive = false
    var body: some Scene {
        WindowGroup {
            Group {
                if let library {
                    SettlementView(session: library.session, openGames: { showGames = true }, managesLifecycle: false)
                        .id(library.activeGameID)
                } else if let benchmarkSession { SettlementView(session: benchmarkSession) }
                else if let startupError { ContentUnavailableView("Unable to open settlement", systemImage: "exclamationmark.triangle", description: Text(startupError)) }
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
                    } else if ProcessInfo.processInfo.environment["CIVILIZATION_RENDER_SCENARIO"] == "late" {
                        benchmarkSession = try GameSession.renderBenchmark(in: FileManager.default.temporaryDirectory)
                        return
                    }
                    #endif
                    library = try await GameLibrary.load(rootURL: root)
                    library?.setActive(sceneIsActive)
                }
                catch is CancellationError {}
                catch { startupError = error.localizedDescription }
            }
            .preferredColorScheme(.dark)
        }
    }
}
