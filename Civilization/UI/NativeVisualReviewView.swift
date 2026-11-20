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
    @State private var phaseRevision = 0
    @State private var cyclesLighting = false
    @State private var cycleDuration: Double = 120
    @State private var staticPreview = false
    @State private var powerPreview = false
    private var effectiveReduceMotion: Bool {
        reduceMotion || staticPreview || powerPreview || ProcessInfo.processInfo.isLowPowerModeEnabled
    }
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
                    ForEach(LivingWorldLayer.Phase.allCases, id: \.self) { value in
                        Button(String(describing: value).capitalized) { phase = value; phaseRevision += 1; cyclesLighting = false; refresh() }
                            .accessibilityIdentifier("visualReview-" + String(describing: value))
                    }
                    ForEach([LivingWorldLayer.Weather.clear, .rain, .fog], id: \.self) { value in
                        Button(String(describing: value).capitalized) { weather = value; refresh() }
                            .accessibilityIdentifier("visualReviewWeather-" + value.rawValue)
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
        }.overlay(alignment: .bottomTrailing) {
            VStack(spacing: 4) {
                HStack {
                    Button(cyclesLighting ? "Pause cycle" : "Cycle light") { cyclesLighting.toggle(); refresh() }
                        .disabled(!reviewFrameReady).accessibilityIdentifier("visualReviewCycle")
                    Button(staticPreview ? "Static: on" : "Static world") { staticPreview.toggle(); refresh() }
                        .accessibilityIdentifier("visualReviewStatic")
                    Button(powerPreview ? "Power: low" : "Power preview") { powerPreview.toggle(); refresh() }
                        .accessibilityIdentifier("visualReviewPower")
                }.buttonStyle(.bordered).controlSize(.large).font(.caption)
                HStack {
                    Button(cycleDuration == 24 ? "120 s cycle" : "24 s preview") {
                        cycleDuration = cycleDuration == 24 ? 120 : 24
                        phase = .day; phaseRevision += 1; cyclesLighting = true; refresh()
                    }.buttonStyle(.bordered).font(.caption).frame(minHeight: 44)
                        .disabled(!reviewFrameReady).accessibilityIdentifier("visualReviewFastCycle")
                    if let scene {
                        TimelineView(.animation(minimumInterval: 0.25, paused: appPhase != .active || loading)) { _ in
                            Text(scene.reviewAtmosphereCaption).font(.caption2)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityLabel(scene.reviewAtmosphereCaption)
                                .accessibilityValue(scene.reviewAtmosphereSummary)
                                .accessibilityIdentifier("visualReviewAtmosphereStatus")
                        }
                    }
                }
            }.padding(8).frame(maxWidth: 380).foregroundStyle(parchment)
                .background(panelColor.opacity(0.96), in: RoundedRectangle(cornerRadius: 12)).padding(10)
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
                TimelineView(.animation(minimumInterval: 0.5, paused: appPhase != .active)) { _ in
                    Text("World preview paused").font(.caption2)
                        .accessibilityValue(scene?.reviewAtmosphereSummary ?? "Preparing")
                        .accessibilityIdentifier("visualReviewCoveredStatus")
                }
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
        scene.reviewLightingSelectionRevision = phaseRevision
        scene.reviewCyclesLighting = cyclesLighting; scene.reviewLowPowerPreview = powerPreview
        scene.reviewLightingCycleDuration = cycleDuration
        scene.reduceMotion = effectiveReduceMotion
        if effectiveReduceMotion && forestRevealed { revealSettled = true }
        scene.activeProductionIDs = fixture.operatingProductionBuildingIDs
        scene.display(state: fixture.state, kind: onboarding && forestRevealed ? .woodcutter : nil,
                      tile: onboarding && forestRevealed ? onboardingSnapshot?.region.woodcutterOrigins.first : nil, valid: true, inspected: nil,
                      movingBuildingID: nil, centerRequest: 0, deposits: fixture.discoveredDeposits,
                      identifiedDepositIDs: Set(fixture.discoveredDeposits.filter { fixture.isIdentified($0) }.map(\.id)))
    }
}
/// Complete guide rehearsal on a fresh, disposable engine. No GameSession or store.
struct OnboardingWalkthroughReviewView: View {
    let configuration: GameConfiguration
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var appPhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var walkthrough: OnboardingReviewWalkthrough?
    @State private var scene: SettlementScene?
    @State private var selectedKind: BuildingKind?
    @State private var selectedTile: Tile?
    @State private var errorMessage: String?
    @State private var revealSettled = true
    @State private var showGoals = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let scene {
                WalkthroughMapSurface(scene: scene, isPaused: appPhase != .active, civicTile: configuration.map.campfire,
                    candidateAt: { point in isCandidate(point, in: scene) ? selectedTile : nil },
                    onTap: { point in
                        guard selectedKind != nil, !isCandidate(point, in: scene) else { return }
                        selectedTile = IsometricProjection.tile(point); errorMessage = nil; refresh()
                    }, onCandidateMove: { tile in
                        guard selectedKind != nil else { return }
                        selectedTile = tile; errorMessage = nil; refresh()
                    }).ignoresSafeArea()
            }
            VStack(alignment: .trailing, spacing: 8) {
                HStack {
                    Text("ONBOARDING WALKTHROUGH · REVIEW ONLY").font(.caption.bold())
                    Spacer()
                    Button("Close") { dismiss() }.accessibilityIdentifier("closeOnboardingWalkthrough")
                }
                Text("Fresh temporary settlement. Your saved games are untouched. Area exploration is a proposal.")
                    .font(.caption2)
                Spacer()
                if let walkthrough {
                    if walkthrough.guide.isSkipped {
                        Button("Reopen onboarding guide") { self.walkthrough?.reopenGuide() }
                            .accessibilityIdentifier("reopenOnboardingWalkthroughGuide")
                            .padding(12).background(panelColor, in: RoundedRectangle(cornerRadius: 12))
                    } else { guidePanel(walkthrough) }
                } else if let errorMessage { Text(errorMessage).padding().background(panelColor) }
            }.padding(12).foregroundStyle(parchment)
        }.background(panelColor).buttonStyle(.bordered).controlSize(.large)
        .task {
            prepare()
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
                guard appPhase == .active else { continue }
                advance(by: 1)
            }
        }
        .onChange(of: reduceMotion) { _, value in if value { revealSettled = true }; refresh() }
        .onChange(of: appPhase) { _, value in scene?.isPaused = value != .active; refresh() }
    }

    @ViewBuilder private func guidePanel(_ review: OnboardingReviewWalkthrough) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top) {
                Text(guideTitle(review)).font(.subheadline.bold()).fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("onboardingWalkthroughStep")
                    .accessibilityValue(review.guide.nextStep.rawValue)
                Spacer()
                Button("Skip guide") { walkthrough?.skipGuide(); selectedKind = nil; selectedTile = nil; refresh() }
                    .font(.caption).accessibilityIdentifier("skipOnboardingWalkthroughGuide")
            }
            Text(guideDescription(review)).font(.caption).fixedSize(horizontal: false, vertical: true)
            if let kind = selectedKind, let tile = selectedTile {
                let issue = review.engine.placementIssue(kind, at: tile)
                Text("Drag the building or tap an open tile · tile \(tile.x), \(tile.y)").font(.caption)
                    .accessibilityIdentifier("walkthroughPlacementLocation")
                if let issue { Text(issue.localizedDescription).font(.caption).foregroundStyle(.orange) }
                HStack {
                    Button {
                        perform { try $0.build(kind, at: tile) }
                        if errorMessage == nil { selectedKind = nil; selectedTile = nil; refresh() }
                    } label: {
                        Text("Place \(configuration.definition(kind).name) · \(cost(configuration.definition(kind).cost))")
                            .font(.caption).fixedSize(horizontal: false, vertical: true).multilineTextAlignment(.center)
                    }.disabled(issue != nil).accessibilityIdentifier("walkthroughConfirmBuilding")
                    Button("Cancel") { selectedKind = nil; selectedTile = nil; refresh() }
                }
                Button("Next suggested site") { choose(kind, after: tile) }.font(.caption)
                    .accessibilityIdentifier("walkthroughSuggestedSite")
            } else if let remaining = remainingWork(review) {
                Text("\(review.engine.state.explorationRemainingSeconds == nil ? "Construction" : "Expedition") · \(Int(ceil(remaining))) s remaining")
                    .font(.subheadline.monospacedDigit()).accessibilityIdentifier("onboardingWorkRemaining")
                Button("Advance review time by \(Int(ceil(remaining))) s") { advance(by: remaining) }
                    .font(.caption).accessibilityIdentifier("walkthroughAdvanceTime")
            } else {
                switch review.guide.nextStep {
                case .hut:
                    Button("Build → Hut · \(cost(configuration.definition(.hut).cost))") { choose(.hut) }
                        .accessibilityIdentifier("walkthroughChooseHut")
                case .expedition:
                    Button("Explore forest · \(cost(configuration.explorationRules?.cost ?? ResourceAmounts()))") {
                        perform { try $0.startExpedition() }
                    }.disabled(review.engine.explorationIssue != nil).accessibilityIdentifier("walkthroughStartExpedition")
                case .woodcutter:
                    if revealSettled {
                        Button("Build → Woodcutter · \(cost(configuration.definition(.woodcutter).cost))") { choose(.woodcutter) }
                            .accessibilityIdentifier("walkthroughChooseWoodcutter")
                    } else { Text("Revealing the forest area…").font(.caption) }
                case .handoff:
                    Text("Roads are decorative under these rules; a connection is not required for production.").font(.caption)
                    Button(showGoals ? "Hide next goal" : "See existing chapter goal") { showGoals.toggle() }
                    if showGoals {
                        Text(review.engine.settlementGuidance.title).font(.subheadline.bold())
                        Text(review.engine.settlementGuidance.explanation).font(.caption)
                    }
                default: EmptyView()
                }
            }
            if let errorMessage { Text(errorMessage).font(.caption).foregroundStyle(.orange) }
            Text("Review stock: \(Int(review.engine.state.resources.food)) food · \(Int(review.engine.state.resources.wood)) wood · \(Int(review.engine.state.resources.stone)) stone")
                .font(.caption2.monospacedDigit()).accessibilityIdentifier("walkthroughResourceStock")
        }.padding(14).frame(maxWidth: 320, alignment: .leading)
            .background(panelColor.opacity(0.98), in: RoundedRectangle(cornerRadius: 16))
            .accessibilityElement(children: .contain).accessibilityIdentifier("onboardingGuidePanel")
    }

    private func guideTitle(_ review: OnboardingReviewWalkthrough) -> String {
        switch review.guide.nextStep {
        case .hut: "1 · Give your people a home"
        case .expedition: "2 · Discover a useful forest"
        case .forest: "3 · Your expedition is exploring"
        case .woodcutter: "4 · Put the forest to work"
        case .handoff: "5 · Your settlement is growing"
        default: "Your permanent civic campfire"
        }
    }
    private func guideDescription(_ review: OnboardingReviewWalkthrough) -> String {
        switch review.guide.nextStep {
        case .hut: "Your campfire is the civic heart of this settlement. Choose Build → Hut, then drag it or tap a valid nearby site. A completed hut adds housing."
        case .expedition: "Explore to uncover useful terrain. The current expedition costs \(cost(configuration.explorationRules?.cost ?? ResourceAmounts())) and takes \(Int(configuration.explorationRules?.durationSeconds ?? 0)) seconds. This review proposes revealing the whole western forest."
        case .forest: "The cost has been paid once. The countdown below reflects actual expedition work. You can continue looking around while it runs."
        case .woodcutter: "The forest and its existing wood source are now known. Place a Woodcutter on valid open ground nearby. Forest proximity improves output; completion and a worker are needed."
        case .handoff: "Your Woodcutter is complete. Existing staffing and production rules now apply. Continue through the current chapter goals; no tutorial reward is invented."
        default: "Build freely around your civic center."
        }
    }
    private func remainingWork(_ review: OnboardingReviewWalkthrough) -> Double? {
        review.engine.state.explorationRemainingSeconds ?? review.engine.state.buildings.compactMap(\.constructionRemainingSeconds).max()
    }
    private func cost(_ amounts: ResourceAmounts) -> String {
        Resource.allCases.filter { amounts[$0] > 0 }.map { "\(Int(amounts[$0])) \($0.rawValue)" }.joined(separator: ", ")
    }
    private func prepare() {
        do {
            let review = try OnboardingReviewWalkthrough(configuration: configuration, now: Date(timeIntervalSince1970: 0))
            walkthrough = review
            let world = SettlementScene(configuration: configuration)
            world.reviewContinuousFog = true
            world.reviewReservedRightWidth = 340
            world.reviewFocusTiles = review.snapshot.initialDiscoveredTiles
            let settled = $revealSettled
            world.onReviewRevealComplete = { settled.wrappedValue = true }
            scene = world; refresh()
        } catch { errorMessage = error.localizedDescription }
    }
    private func choose(_ kind: BuildingKind, after previous: Tile? = nil) {
        guard let review = walkthrough else { return }
        errorMessage = nil; selectedKind = kind; selectedTile = review.suggestedOrigin(for: kind, after: previous)
        if selectedTile == nil { selectedKind = nil; errorMessage = "No valid site is currently available." }
        else if let previous, selectedTile == previous { errorMessage = "Only one valid site is available right now." }
        refresh()
    }
    private func isCandidate(_ point: CGPoint, in scene: SettlementScene) -> Bool {
        guard let kind = selectedKind, let origin = selectedTile else { return false }
        return configuration.definition(kind).footprint.tiles(at: origin).contains(IsometricProjection.tile(point)) || scene.previewContains(point)
    }
    private func perform(_ action: (inout OnboardingReviewWalkthrough) throws -> Void) {
        guard var review = walkthrough else { return }
        do { try action(&review); walkthrough = review; errorMessage = nil; refresh() }
        catch { errorMessage = error.localizedDescription }
    }
    private func advance(by seconds: Double) {
        guard var review = walkthrough else { return }
        let known = review.guide.observedEvents.contains(.forestRevealed)
        do {
            try review.advanceReview(by: seconds)
            if !known && review.guide.observedEvents.contains(.forestRevealed) {
                revealSettled = reduceMotion
                scene?.reviewFocusTiles = review.snapshot.initialDiscoveredTiles.union(review.snapshot.region.tiles)
            }
            walkthrough = review; refresh()
        } catch { errorMessage = error.localizedDescription }
    }
    private func refresh() {
        guard let scene, let review = walkthrough else { return }
        scene.isPaused = appPhase != .active
        scene.reduceMotion = reduceMotion
        scene.activeProductionIDs = review.engine.operatingProductionBuildingIDs
        let valid = selectedKind.flatMap { kind in selectedTile.map { review.engine.placementIssue(kind, at: $0) == nil } } ?? false
        scene.display(state: review.engine.state, kind: selectedKind, tile: selectedTile, valid: valid,
            inspected: nil, movingBuildingID: nil, centerRequest: 0,
            deposits: review.engine.discoveredDeposits,
            identifiedDepositIDs: Set(review.engine.discoveredDeposits.filter(review.engine.isIdentified).map(\.id)))
    }
}
/// Same SKView-local coordinate path as normal WorldView. SwiftUI's safe-area
/// wrapper coordinates must never be passed directly into convertPoint(fromView:).
private struct WalkthroughMapSurface: UIViewRepresentable {
    let scene: SettlementScene
    let isPaused: Bool
    let civicTile: Tile
    let candidateAt: (CGPoint) -> Tile?
    let onTap: (CGPoint) -> Void
    let onCandidateMove: (Tile) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIView(context: Context) -> SKView {
        let view = SKView(); view.ignoresSiblingOrder = true; view.preferredFramesPerSecond = 60
        view.isAccessibilityElement = true; view.accessibilityLabel = "Disposable onboarding map"
        view.accessibilityIdentifier = "onboardingWalkthroughMap"
        view.presentScene(scene)
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tap(_:)))
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.pan(_:)))
        pan.maximumNumberOfTouches = 1; pan.delegate = context.coordinator
        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.pinch(_:)))
        pinch.delegate = context.coordinator
        tap.require(toFail: pan)
        for recognizer in [tap, pan, pinch] { view.addGestureRecognizer(recognizer) }
        return view
    }
    func updateUIView(_ view: SKView, context: Context) {
        context.coordinator.parent = self
        view.isPaused = isPaused
        if isPaused { context.coordinator.resetGestureOwnership() }
        if view.scene !== scene { view.presentScene(scene) }
        context.coordinator.updateAccessibility(view)
    }
    static func dismantleUIView(_ view: SKView, coordinator: Coordinator) {
        view.isPaused = true; view.presentScene(nil)
    }
    @MainActor final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: WalkthroughMapSurface
        private var grabOffset: Tile?
        private var previousTranslation = CGPoint.zero
        private var panAccepted = false
        private var isZooming = false
        init(_ parent: WalkthroughMapSurface) { self.parent = parent }
        func resetGestureOwnership() {
            grabOffset = nil; previousTranslation = .zero; panAccepted = false; isZooming = false
        }
        func updateAccessibility(_ view: SKView) {
            let civic = parent.scene.convertPoint(toView: IsometricProjection.point(parent.civicTile))
            view.accessibilityValue = "civicX=\(civic.x) civicY=\(civic.y) " + parent.scene.cameraAccessibilityValue
        }
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            if gestureRecognizer is UIPanGestureRecognizer {
                let point = parent.scene.convertPoint(fromView: touch.location(in: gestureRecognizer.view))
                if let origin = parent.candidateAt(point) {
                    let touched = IsometricProjection.tile(point)
                    grabOffset = Tile(x: touched.x - origin.x, y: touched.y - origin.y)
                } else { grabOffset = nil }
                previousTranslation = .zero; panAccepted = false
            }
            return true
        }
        func gestureRecognizer(_ first: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith second: UIGestureRecognizer) -> Bool {
            (first is UIPanGestureRecognizer && second is UIPinchGestureRecognizer) ||
            (first is UIPinchGestureRecognizer && second is UIPanGestureRecognizer)
        }
        @objc func tap(_ recognizer: UITapGestureRecognizer) {
            guard !isZooming, let view = recognizer.view as? SKView else { return }
            parent.onTap(parent.scene.convertPoint(fromView: recognizer.location(in: view)))
            updateAccessibility(view)
        }
        @objc func pan(_ recognizer: UIPanGestureRecognizer) {
            guard let view = recognizer.view as? SKView else { return }
            defer {
                if [.ended, .cancelled, .failed].contains(recognizer.state) {
                    grabOffset = nil; previousTranslation = .zero; panAccepted = false
                }
                updateAccessibility(view)
            }
            if recognizer.state == .began { panAccepted = !isZooming }
            guard panAccepted, !isZooming, [.began, .changed, .ended].contains(recognizer.state) else { return }
            let translation = recognizer.translation(in: view)
            if let offset = grabOffset {
                let touched = IsometricProjection.tile(parent.scene.convertPoint(fromView: recognizer.location(in: view)))
                parent.onCandidateMove(Tile(x: touched.x - offset.x, y: touched.y - offset.y))
            } else {
                parent.scene.pan(dx: translation.x - previousTranslation.x, dy: translation.y - previousTranslation.y)
            }
            previousTranslation = translation
        }
        @objc func pinch(_ recognizer: UIPinchGestureRecognizer) {
            guard let view = recognizer.view as? SKView else { return }
            if recognizer.state == .began { isZooming = true; grabOffset = nil; panAccepted = false }
            if [.began, .changed].contains(recognizer.state) {
                parent.scene.zoom(factor: recognizer.scale); recognizer.scale = 1
            }
            if [.ended, .cancelled, .failed].contains(recognizer.state) { isZooming = false; previousTranslation = .zero }
            updateAccessibility(view)
        }
    }
}
#endif
