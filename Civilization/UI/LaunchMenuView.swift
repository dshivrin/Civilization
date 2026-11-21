import SwiftUI

/// Player entry contains no developer scenario or accelerated-play controls.
struct LaunchMenuView: View {
    let canContinue: Bool
    let newGame: () -> Void
    let resume: () -> Void
    var body: some View {
        ZStack {
            Color(red: 0.10, green: 0.15, blue: 0.12).ignoresSafeArea()
            LoadingSceneryView(scene: .founding, animates: false).ignoresSafeArea().accessibilityHidden(true)
            Color.black.opacity(0.65).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    Text("Civilization").font(.largeTitle.bold())
                    Text("Build a settlement. Complete the Stone Age.")
                        .font(.headline).multilineTextAlignment(.center)
                    Button(action: resume) {
                        Label("Continue", systemImage: "play.fill").foregroundStyle(.black).frame(maxWidth: .infinity, minHeight: 48)
                    }.buttonStyle(.borderedProminent).disabled(!canContinue).accessibilityIdentifier("continueGame")
                    Button(action: newGame) {
                        Label("New Game", systemImage: "plus.circle").frame(maxWidth: .infinity, minHeight: 48)
                    }.buttonStyle(.bordered).accessibilityIdentifier("newNormalGame")
                    Text(canContinue ? "New Game starts a separate settlement. Your saved games are preserved." : "Start with one campfire in a 64×48 river valley.")
                        .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Text("Complete seven chapters to earn Bronze Age readiness. Bronze Age gameplay is coming later; you can keep building here.")
                        .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }.padding(24).frame(maxWidth: 500).frame(maxWidth: .infinity)
            }
        }.tint(.yellow)
    }
}
