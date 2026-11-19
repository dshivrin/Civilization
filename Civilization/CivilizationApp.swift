import GameApplication
import SwiftUI

@main
struct CivilizationApp: App {
    @State private var session: GameSession?
    @State private var startupError: String?
    var body: some Scene {
        WindowGroup {
            Group {
                if let session { SettlementView(session: session) }
                else if let startupError { ContentUnavailableView("Unable to open settlement", systemImage: "exclamationmark.triangle", description: Text(startupError)) }
                else { SettlementLoadingView(stage: "Restoring settlement…") }
            }
            .task {
                guard session == nil && startupError == nil else { return }
                do {
                    #if DEBUG
                    if ProcessInfo.processInfo.environment["CIVILIZATION_UI_FRESH_SAVE"] == "1" {
                        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ui-fresh-" + UUID().uuidString + ".json")
                        // Synthetic earned UI fixtures use the same validated save loader and a unique temporary file.
                        if let encoded = ProcessInfo.processInfo.environment["CIVILIZATION_UI_EARNED_SAVE"] {
                            guard let data = Data(base64Encoded: encoded) else { throw CocoaError(.fileReadCorruptFile) }
                            try data.write(to: url, options: .atomic)
                        }
                        session = try await GameSession.load(saveURL: url)
                        return
                    }
                    if ProcessInfo.processInfo.environment["CIVILIZATION_RENDER_SCENARIO"] == "late" {
                        session = try GameSession.renderBenchmark(in: FileManager.default.temporaryDirectory)
                        return
                    }
                    #endif
                    session = try await GameSession.load()
                }
                catch is CancellationError {}
                catch { startupError = error.localizedDescription }
            }
            .preferredColorScheme(.dark)
        }
    }
}
