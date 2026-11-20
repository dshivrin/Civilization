import GameApplication
import SwiftUI

struct SettlementLoadingView: View {
    let stage: String
    var reviewPresentation = false
    var context: LoadingPresentation.Context = .settlement
    var branding = LoadingBranding()
    var scenery: LoadingScenery = .founding
    var measurement: LoadingProgress?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var scenerySkipped = false
    @State private var lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled

    private var presentation: LoadingPresentation {
        var value = LoadingPresentation(stage: stage, context: context, measurement: measurement)
        if scenerySkipped { value.skipScenery() }
        return value
    }

    @ViewBuilder var body: some View {
        if reviewPresentation { nativeReviewBody }
        else { LegacySettlementLoadingView(stage: stage) }
    }

    private var nativeReviewBody: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 500
            ZStack {
                Color(red: 0.055, green: 0.10, blue: 0.11).ignoresSafeArea()
                if presentation.showsScenery {
                    LoadingSceneryView(scene: scenery, animates: presentation.animatesScenery(
                        isActive: scenePhase == .active, reduceMotion: reduceMotion, lowPower: lowPower))
                        .ignoresSafeArea().accessibilityHidden(true)
                    LinearGradient(colors: [.black.opacity(0.14), .clear, .black.opacity(0.86)],
                                   startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                }
                VStack(spacing: compact ? 12 : 24) {
                    if context == .brand { Spacer(minLength: 0) }
                    brandLockup(compact: compact)
                    if presentation.showsEra {
                        Text(branding.era).font(.system(.caption, design: .serif, weight: .semibold))
                            .tracking(4).accessibilityIdentifier("loadingEra")
                    }
                    Spacer(minLength: compact ? 8 : 24)
                    loadingStatus
                    if presentation.showsScenery {
                        Button("Skip scenery") { scenerySkipped = true }
                            .font(.caption.weight(.semibold)).frame(minHeight: 44)
                            .accessibilityHint("Hides decorative animation. Loading continues until your settlement is ready.")
                            .accessibilityIdentifier("skipLoadingScenery")
                    }
                    if context == .brand { Spacer(minLength: 0) }
                }
                .frame(maxWidth: 540).padding(.horizontal, 28)
                .padding(.vertical, compact ? 18 : 40)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundStyle(Color(red: 0.97, green: 0.93, blue: 0.82))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settlementLoading")
        .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { _ in
            lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
    }

    private func brandLockup(compact: Bool) -> some View {
        VStack(spacing: compact ? 8 : 14) {
            if branding.mark == .sunrise {
                SunriseLoadingMark().stroke(style: StrokeStyle(lineWidth: 1.7, lineCap: .round))
                    .frame(width: compact ? 64 : 88, height: compact ? 32 : 44)
                    .accessibilityHidden(true)
            }
            Text(branding.title).font(.system(compact ? .title2 : .largeTitle, design: .serif, weight: .medium))
                .tracking(4).multilineTextAlignment(.center).minimumScaleFactor(0.65)
                .accessibilityAddTraits(.isHeader).accessibilityIdentifier("loadingBrand")
        }
        .padding(.horizontal, 18).padding(.vertical, 10)
        .background(.black.opacity(presentation.showsScenery ? 0.28 : 0), in: RoundedRectangle(cornerRadius: 16))
    }

    private var loadingStatus: some View {
        VStack(spacing: 12) {
            if let fraction = presentation.progress {
                ProgressView(value: fraction).tint(.white).frame(maxWidth: 280)
                    .accessibilityLabel(stage)
            } else {
                // No timer-derived fill: the current native operation has no measured units.
                ProgressView().tint(.white).accessibilityLabel(stage)
            }
            Text(stage).font(.subheadline.weight(.medium)).multilineTextAlignment(.center)
                .accessibilityIdentifier("loadingStage")
            if presentation.showsEra && !branding.tip.isEmpty {
                Text(branding.tip).font(.caption).multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.82)).padding(.top, 2)
            }
        }
        .padding(18).frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.52), in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct SunriseLoadingMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.height * 0.85)
        let radius = rect.height * 0.53
        path.addArc(center: center, radius: radius, startAngle: .degrees(180), endAngle: .zero, clockwise: false)
        path.move(to: CGPoint(x: 0, y: center.y)); path.addLine(to: CGPoint(x: rect.width, y: center.y))
        for degrees in [210.0, 240, 270, 300, 330] {
            let angle = degrees * .pi / 180
            path.move(to: CGPoint(x: center.x + cos(angle) * radius * 1.24, y: center.y + sin(angle) * radius * 1.24))
            path.addLine(to: CGPoint(x: center.x + cos(angle) * radius * 1.52, y: center.y + sin(angle) * radius * 1.52))
        }
        return path
    }
}

// Original runtime fallback retained until appearance review accepts the new scenes.

private struct LegacySettlementLoadingView: View {
    let stage: String
    var body: some View {
        ZStack {
            panelColor.ignoresSafeArea()
            if let image = EraArt.image("loading-valley.png", maximumPixels: 1600) {
                GeometryReader { geometry in
                    Image(uiImage: image).resizable().scaledToFill().frame(width: geometry.size.width, height: geometry.size.height).clipped()
                }.ignoresSafeArea().accessibilityHidden(true)
                LinearGradient(colors: [.black.opacity(0.20), panelColor.opacity(0.90)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            }
            VStack(spacing: 18) {
                Text("CIVILIZATION").font(.system(size: 28, weight: .semibold, design: .serif)).tracking(4)
                Text("Every civilization has a beginning.").font(.subheadline).foregroundStyle(parchment.opacity(0.75))
                ProgressView().tint(parchment)
                Text(stage).font(.caption).foregroundStyle(parchment.opacity(0.75))
            }.foregroundStyle(parchment).padding(32).background(panelColor.opacity(0.72), in: RoundedRectangle(cornerRadius: 24)).padding(24)
        }.accessibilityElement(children: .combine).accessibilityIdentifier("settlementLoading")
    }
}
