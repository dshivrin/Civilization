#if DEBUG
import SwiftUI
import SpriteKit
import UIKit
import GameApplication

/// Magnified motion examples, independent of all settlements/stores.
struct VillagerMotionReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var appPhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scene: VillagerPoseScene?
    @State private var powerObservation: VisualAgentPowerObservation?
    @State private var activity = VisualAgentActivity.idle
    @State private var facing = VisualAgentFacing.nearRight
    @State private var staticPreview = false
    @State private var powerPreview = false
    @State private var closeRequests = 0
    var body: some View {
        ZStack {
            if let scene { SpriteView(scene: scene, isPaused: appPhase != .active).ignoresSafeArea() }
            VStack(spacing: 8) {
                HStack {
                    Text("PEOPLE MOTION · REVIEW ONLY").font(.headline)
                    Spacer()
                    Button { closeRequests += 1; dismiss() } label: {
                        Text("Done").frame(minWidth: 60, minHeight: 44).contentShape(Rectangle())
                    }.buttonStyle(.bordered).accessibilityIdentifier("closeVillagerMotionReview")
                        .accessibilityValue("requests=\(closeRequests)")
                }
                Text("Enlarged provisional figure · shared map pose code · no worker or resource transactions")
                    .font(.caption).multilineTextAlignment(.center)
                Spacer()
                Text(activity.rawValue.capitalized).font(.title2.bold())
                Text("Eight pose examples. Map work/carry poses require an active production site; routes stay outside buildings.")
                    .font(.caption).multilineTextAlignment(.center)
                HStack {
                    Button("Next pose") {
                        let values = VisualAgentActivity.allCases
                        activity = values[((values.firstIndex(of: activity) ?? 0)+1)%values.count]; refresh()
                    }.accessibilityIdentifier("villagerNextPose")
                    Button("Facing: " + (facing.away ? "away " : "toward ") + (facing.left ? "left" : "right")) {
                        let values = VisualAgentFacing.allCases
                        facing = values[((values.firstIndex(of: facing) ?? 0)+1)%values.count]; refresh()
                    }.accessibilityIdentifier("villagerFacing")
                    Button(staticPreview ? "Static: on" : "Static") { staticPreview.toggle(); refresh() }
                        .accessibilityIdentifier("villagerStatic")
                    Button(powerPreview ? "Power: low" : "Power preview") { powerPreview.toggle(); refresh() }
                        .accessibilityIdentifier("villagerPower")
                }.font(.caption).buttonStyle(.bordered).controlSize(.large)
                if let scene {
                    VillagerPoseStatus(scene: scene).frame(height: 22)
                }
            }.padding(16).foregroundStyle(Color(red: 0.94, green: 0.91, blue: 0.81))
        }.background(Color(red: 0.08, green: 0.14, blue: 0.13))
        .task {
            if scene == nil { scene = VillagerPoseScene() }
            if powerObservation == nil { powerObservation = VisualAgentPowerObservation() }
            refresh()
        }
        .onChange(of: powerObservation?.lowPower) { _,_ in refresh() }
        .onChange(of: reduceMotion) { _,_ in refresh() }
        .onChange(of: appPhase) { _,_ in refresh() }
        .onDisappear { scene?.suspend() }
    }
    private func refresh() {
        scene?.select(activity: activity, facing: facing,
            animates: appPhase == .active && !reduceMotion && !staticPreview && !powerPreview && !(powerObservation?.lowPower ?? ProcessInfo.processInfo.isLowPowerModeEnabled))
    }
}

/// Read actual retained joints on accessibility demand without polling SwiftUI at animation frequency.
private struct VillagerPoseStatus: UIViewRepresentable {
    let scene: VillagerPoseScene
    func makeUIView(context: Context) -> PoseLabel {
        let label = PoseLabel()
        label.text = "Provisional source geometry · 6× inspection scale"
        label.textAlignment = .center; label.font = .preferredFont(forTextStyle: .caption2)
        label.textColor = UIColor(red: 0.94, green: 0.91, blue: 0.81, alpha: 1)
        label.accessibilityIdentifier = "villagerPoseStatus"
        label.poseScene = scene; return label
    }
    func updateUIView(_ label: PoseLabel, context: Context) { label.poseScene = scene }
    final class PoseLabel: UILabel {
        weak var poseScene: VillagerPoseScene?
        override var accessibilityValue: String? {
            get { poseScene?.summary }
            set { }
        }
    }
}

@MainActor private final class VillagerPoseScene: SKScene {
    private let figure = VillagerFigure(profile: 0)
    private var activity = VisualAgentActivity.idle, facing = VisualAgentFacing.nearRight
    private var elapsed = 0.25, previousTime: Double?, debt = 0.0
    private var animates = true
    var summary: String {
        func count(_ node: SKNode) -> Int { 1 + node.children.reduce(0) { $0+count($1) } }
        return "activity=\(figure.activity.rawValue) facing=\(figure.facing.rawValue) moving=\(animates) figures=\(children.filter { $0 is VillagerFigure }.count) actorID=\(figure.reviewIdentity) nodes=\(count(figure)) " +
            String(format: "elapsed=%.4f ", elapsed) + figure.jointSummary
    }
    override init() {
        super.init(size: CGSize(width: 960, height: 440)); scaleMode = .resizeFill
        backgroundColor = UIColor(red: 0.08, green: 0.14, blue: 0.13, alpha: 1)
        figure.setScale(6); addChild(figure); layoutFigure(); paint()
    }
    required init?(coder: NSCoder) { fatalError("Programmatic pose comparison") }
    override func didChangeSize(_ oldSize: CGSize) { layoutFigure() }
    private func layoutFigure() { figure.position = CGPoint(x: size.width/2, y: size.height*0.48) }
    func select(activity: VisualAgentActivity, facing: VisualAgentFacing, animates: Bool) {
        if self.activity != activity { elapsed = 0.25 }
        self.activity = activity; self.facing = facing; self.animates = animates
        previousTime = nil; debt = 0; paint()
    }
    func suspend() { previousTime = nil; debt = 0; animates = false }
    override func update(_ currentTime: TimeInterval) {
        guard animates, currentTime.isFinite else { previousTime = nil; debt = 0; return }
        let delta = min(0.1, max(0, currentTime-(previousTime ?? currentTime))); previousTime = currentTime
        debt += delta
        guard debt >= 1.0/15 else { return }
        elapsed = (elapsed+debt).truncatingRemainder(dividingBy: 120); debt = 0; paint()
    }
    private func paint() { figure.display(.sample(activity: activity, elapsed: elapsed), activity: activity, facing: facing) }
}
#endif
