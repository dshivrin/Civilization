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
                do { session = try await GameSession.load() }
                catch is CancellationError {}
                catch { startupError = error.localizedDescription }
            }
            .preferredColorScheme(.dark)
        }
    }
}
