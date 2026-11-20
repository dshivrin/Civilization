#if DEBUG
import SwiftUI
import SpriteKit
import GameApplication
import GameCore

/// Disposable render snapshots. No library, store, session commands or elapsed production.
struct NativeVisualReviewView: View {
    let configuration: GameConfiguration
    @Environment(\.scenePhase) private var appPhase
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scene: SettlementScene?
    @State private var fixture: GameEngine?
    @State private var phase = LivingWorldLayer.Phase.day
    @State private var weather = LivingWorldLayer.Weather.clear
    @State private var loading = false
    @State private var onboarding = false
    @State private var onboardingSnapshot: OnboardingReviewSnapshot?
    @State private var forestRevealed = false
    @State private var revealSettled = false
    @State private var reviewFrameReady = false
    @State private var previousDrag = CGSize.zero
    @State private var previousZoom: CGFloat = 1
    @State private var cameraRevision = 0
    var body: some View {
        ZStack(alignment: .top) {
            if let scene {
                SpriteView(scene: scene, isPaused: appPhase != .active || loading).id(ObjectIdentifier(scene)).ignoresSafeArea()
                    .accessibilityElement(children: .ignore).accessibilityLabel("Visual review map")
                    .accessibilityIdentifier("nativeVisualReviewMap")
                    .accessibilityValue(scene.cameraAccessibilityValue + " revision=\(cameraRevision)")
                    .gesture(DragGesture(minimumDistance: 3).onChanged { value in
                        scene.pan(dx: value.translation.width - previousDrag.width, dy: value.translation.height - previousDrag.height)
                        previousDrag = value.translation
                    }.onEnded { _ in previousDrag = .zero; cameraRevision += 1 })
                    .simultaneousGesture(MagnificationGesture().onChanged { value in
                        scene.zoom(factor: value / previousZoom); previousZoom = value
                    }.onEnded { _ in previousZoom = 1; cameraRevision += 1 })
            }
            VStack(spacing: 8) {
                Text("VISUAL REVIEW · disposable snapshot · provisional people / shared-yard details")
                    .font(.caption).accessibilityIdentifier("visualReviewNotice")
                HStack {
                    ForEach([LivingWorldLayer.Phase.day, .dusk, .night], id: \.self) { value in
                        Button(String(describing: value).capitalized) { phase = value; refresh() }
                            .accessibilityIdentifier("visualReview-" + String(describing: value))
                    }
                    ForEach([LivingWorldLayer.Weather.clear, .rain, .fog], id: \.self) { value in
                        Button(String(describing: value).capitalized) { weather = value; refresh() }
                    }
                    Button("Center") { scene?.recenter(); cameraRevision += 1 }
                    Button("Overview") { scene?.showMapOverview(); cameraRevision += 1 }
                    Button("Onboarding") { prepareOnboarding() }.accessibilityIdentifier("visualReviewOnboarding")
                    Button("Loading scenes") { loading = true }
                    Button("Done") { dismiss() }.accessibilityIdentifier("closeNativeVisualReview")
                }.buttonStyle(.bordered).font(.caption)
                Text("Routes avoid water/structures; bridges and gates are not enabled. No player save or economy changes.")
                    .font(.caption2)
                if onboarding {
                    HStack {
                        Text(forestRevealed ? (revealSettled ? "Forest area revealed · valid woodcutter preview · no build charged" : "Revealing forest area…") : "First goal: Build → Hut. Place your hut freely near the campfire.")
                            .font(.caption).frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("onboardingReviewCard")
                        Button("Reveal forest area (preview)") {
                            guard !forestRevealed else { return }
                            print("VISUAL_REVEAL begin paused=\(scene?.isPaused ?? true) viewPaused=\(scene?.view?.isPaused ?? true)")
                            forestRevealed = true; revealSettled = reduceMotion; refreshOnboarding()
                        }
                            .disabled(!reviewFrameReady || forestRevealed)
                            .font(.caption).frame(maxWidth: 180, minHeight: 44)
                            .accessibilityIdentifier("onboardingReviewForest")
                    }
                    Text(expeditionDescription).font(.caption2)
                }
            }.padding(10).foregroundStyle(parchment).background(panelColor.opacity(0.96))
        }.task {
            do {
                let engine = try DeveloperScenario.grouped.makeEngine(configuration: configuration, now: Date(timeIntervalSince1970: 0))
                fixture = engine
                let world = SettlementScene(configuration: engine.configuration)
                let ready = $reviewFrameReady
                world.onReady = { ready.wrappedValue = true }
                scene = world; refresh()
            } catch { scene = nil }
        }.onChange(of: reduceMotion) { _, value in if value && forestRevealed { revealSettled = true }; refresh() }
        .onChange(of: appPhase) { _, value in scene?.isPaused = value != .active || loading; refresh() }
        .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { _ in refresh() }
        .onChange(of: loading) { _, value in scene?.isPaused = value || appPhase != .active; refresh() }

        .fullScreenCover(isPresented: $loading) {
            VStack(spacing: 0) {
                HStack {
                    ForEach(LoadingScenery.allCases, id: \.self) { value in
                        Button(value.rawValue.capitalized) { scenery = value }
                    }
                    Button("Back to scene") { loading = false }.accessibilityIdentifier("closeLoadingReview")
                }.buttonStyle(.bordered).padding()
                SettlementLoadingView(stage: "Preview only · no game is loading", reviewPresentation: true, scenery: scenery)
            }.background(panelColor)
        }
    }
    @State private var scenery = LoadingScenery.founding
    private var expeditionDescription: String {
        guard let rules = configuration.explorationRules else { return "No expedition in this ruleset." }
        let costs = Resource.allCases.filter { rules.cost[$0] > 0 }.map { "\(Int(rules.cost[$0])) \($0.rawValue)" }.joined(separator: ", ")
        return "Existing expedition: \(costs) / \(Int(rules.durationSeconds)) s. Preview charges nothing."
    }
    private func prepareOnboarding() {
        do {
            let engine = try GameEngine(configuration: configuration, now: Date(timeIntervalSince1970: 0))
            onboardingSnapshot = try OnboardingReviewSnapshot.make(configuration: configuration, state: engine.state, includeWholeForest: true)
            fixture = engine; onboarding = true; forestRevealed = false
            reviewFrameReady = false
            let world = SettlementScene(configuration: configuration)
            let ready = $reviewFrameReady
            world.onReady = { ready.wrappedValue = true }
            scene = world; refreshOnboarding()
        } catch { onboarding = false }
    }
    private func refreshOnboarding() {
        guard let snapshot = onboardingSnapshot, let fixture else { return }
        var state = fixture.state
        state.discoveredTiles = forestRevealed ? snapshot.revealedDiscoveredTiles : snapshot.initialDiscoveredTiles
        if let preview = try? GameEngine(state: state, configuration: fixture.configuration) { self.fixture = preview }
        let settled = $revealSettled
        scene?.onReviewRevealComplete = { print("VISUAL_REVEAL finished"); settled.wrappedValue = true }
        scene?.reviewContinuousFog = true
        scene?.reviewFocusTiles = snapshot.initialDiscoveredTiles.union(snapshot.region.tiles)
        refresh()
    }
    private func refresh() {
        guard let scene, let fixture else { return }
        scene.isPaused = appPhase != .active || loading
        scene.reviewVisualsEnabled = true; scene.reviewPhase = phase; scene.reviewWeather = weather
        scene.reduceMotion = reduceMotion
        scene.activeProductionIDs = fixture.operatingProductionBuildingIDs
        scene.display(state: fixture.state, kind: onboarding && forestRevealed ? .woodcutter : nil,
                      tile: onboarding && forestRevealed ? onboardingSnapshot?.region.woodcutterOrigins.first : nil, valid: true, inspected: nil,
                      movingBuildingID: nil, centerRequest: 0, deposits: fixture.discoveredDeposits,
                      identifiedDepositIDs: Set(fixture.discoveredDeposits.filter { fixture.isIdentified($0) }.map(\.id)))
    }
}
#endif
