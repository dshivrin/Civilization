import Foundation
import Observation
import GameCore

#if DEBUG

/// The comparison sheet responds to OS power changes without a control tap or polling timer.
@MainActor @Observable public final class VisualAgentPowerObservation {
    public private(set) var lowPower: Bool
    @ObservationIgnored private let readLowPower: @MainActor () -> Bool
    @ObservationIgnored private let lifetime: VisualPowerLifetime
    public init(center: NotificationCenter = .default,
                readLowPower: @escaping @MainActor () -> Bool = { ProcessInfo.processInfo.isLowPowerModeEnabled }) {
        self.readLowPower = readLowPower
        lowPower = readLowPower()
        lifetime = VisualPowerLifetime(center: center)
        lifetime.token = center.addObserver(forName: .NSProcessInfoPowerStateDidChange, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.lowPower = self.readLowPower()
            }
        }
    }
}

/// Installed once on the main actor; deinitialization may remove the Foundation token on any thread.
private final class VisualPowerLifetime: @unchecked Sendable {
    let center: NotificationCenter
    var token: NSObjectProtocol?
    init(center: NotificationCenter) { self.center = center }
    deinit { if let token { center.removeObserver(token) } }
}

#endif

/// Provisional pose vocabulary, never authoritative worker/economy state.
public enum VisualAgentActivity: String, CaseIterable, Sendable { case idle, walk, carry, gather, work, rest, socialize, turn }
public enum VisualAgentFacing: String, CaseIterable, Sendable {
    case nearRight, nearLeft, awayRight, awayLeft
    public static func forVector(x: Double, y: Double) -> Self {
        guard x.isFinite, y.isFinite else { return .nearRight }
        return y > 0 ? (x < 0 ? .awayLeft : .awayRight) : (x < 0 ? .nearLeft : .nearRight)
    }
    public var away: Bool { self == .awayRight || self == .awayLeft }
    public var left: Bool { self == .nearLeft || self == .awayLeft }
}

public struct VisualAgentPose: Equatable, Sendable {
    public let bodyOffsetY, bodyTilt, leftLegAngle, rightLegAngle: Double
    public let leftArmAngle, rightArmAngle, headTilt, turnScale: Double
    public let cargoVisible: Bool
    public static func sample(activity: VisualAgentActivity, elapsed: Double) -> Self {
        let time = elapsed.isFinite ? max(0, elapsed).truncatingRemainder(dividingBy: 2) : 0
        let wave = sin(time * 2 * .pi)
        var y = 0.12 * wave, tilt = 0.0, legs = (0.0, 0.0), arms = (0.08, -0.08), head = 0.0, width = 1.0
        switch activity {
        case .idle: break
        case .walk, .carry:
            legs = (0.40 * wave, -0.40 * wave); y = abs(wave) * 0.35
            arms = activity == .carry ? (0.90, -0.70) : (-0.30 * wave, 0.30 * wave)
        case .gather:
            y = -1.8; tilt = -0.23; legs = (0.20, -0.20); arms = (0.45 + 0.16 * wave, -0.32)
        case .work: arms = (1.25 + 0.35 * wave, -0.7); tilt = 0.06 * wave
        case .rest: y = -3.1; legs = (0.95, -0.95); arms = (0.48, -0.48)
        case .socialize: arms = (0.25, -0.95 - 0.30 * wave); head = 0.12 * wave
        case .turn: width = 0.65 + 0.35 * abs(cos(time * .pi)); head = 0.13 * wave
        }
        return .init(bodyOffsetY: y, bodyTilt: tilt, leftLegAngle: legs.0, rightLegAngle: legs.1,
            leftArmAngle: arms.0, rightArmAngle: arms.1, headTilt: head, turnScale: width, cargoVisible: activity == .carry)
    }
}

/// Exterior-route presentation, with no worker allocation, materials or time-state writes.
public struct VisualAgentJourney: Equatable, Sendable {
    private enum Phase: Equatable, Sendable { case sourcePause, turnOut, outward, destinationPause, turnBack, inward }
    private let points: [WorldPoint]
    private let sourceActivity, destinationActivity: VisualAgentActivity
    private let carriesWood: Bool
    private var phase = Phase.sourcePause
    private var phaseElapsed = 0.0
    private var cursor = 0
    private var segmentFraction = 0.0
    public private(set) var position: WorldPoint
    public private(set) var facing: VisualAgentFacing
    public private(set) var elapsed = 0.0
    public var poseElapsed: Double {
        phase == .turnOut || phase == .turnBack ? phaseElapsed / 0.3 : elapsed
    }
    public var activity: VisualAgentActivity {
        switch phase {
        case .sourcePause: sourceActivity
        case .destinationPause: destinationActivity
        case .turnOut, .turnBack: .turn
        case .outward: carriesWood ? .carry : .walk
        case .inward: .walk
        }
    }
    public init?(tiles: [Tile], planner: VisualRoutePlanner, source: BuildingKind, destination: BuildingKind,
                 sourceActive: Bool, purpose: VisualAgentRoute.Purpose) {
        guard tiles.count > 1, planner.isValid(path: tiles) else { return nil }
        points = tiles.map(MapGeometry.point)
        position = points[0]
        facing = .forVector(x: points[1].x-points[0].x, y: points[1].y-points[0].y)
        carriesWood = source == .woodcutter && sourceActive && purpose == .carryWood
        let producers: Set<BuildingKind> = [.woodcutter, .stoneGatherer, .farm, .fishingShelter, .huntingLodge, .toolmaker, .potteryWorkshop]
        sourceActivity = source == .hut ? .rest : sourceActive && producers.contains(source) ? (source == .woodcutter ? .gather : .work) : .idle
        destinationActivity = [.campfire, .storytellingCircle, .gatheringShelter].contains(destination) ? .socialize : destination == .hut ? .rest : .idle
    }
    public mutating func advance(by delta: Double, animates: Bool) {
        guard animates, delta.isFinite, delta > 0 else { return }
        var budget = min(0.1, delta)
        elapsed = (elapsed + budget).truncatingRemainder(dividingBy: 120)
        while budget > 0.00000001 {
            switch phase {
            case .sourcePause, .destinationPause, .turnOut, .turnBack:
                let duration = phase == .sourcePause || phase == .destinationPause ? 1.6 : 0.3
                let used = min(budget, max(0, duration - phaseElapsed))
                phaseElapsed += used; budget -= used
                if (phase == .turnOut || phase == .turnBack), phaseElapsed >= 0.15 {
                    let step = phase == .turnOut ? 1 : -1
                    let a = points[cursor], b = points[cursor + step]
                    facing = .forVector(x: b.x-a.x, y: b.y-a.y)
                }
                guard phaseElapsed >= duration - 0.00000001 else { return }
                phaseElapsed = 0
                switch phase {
                case .sourcePause: phase = .turnOut
                case .turnOut: phase = .outward
                case .destinationPause: phase = .turnBack
                case .turnBack: phase = .inward
                default: break
                }
            case .outward, .inward:
                let step = phase == .outward ? 1 : -1
                let a = points[cursor], b = points[cursor + step]
                let length = hypot(b.x-a.x, b.y-a.y)
                facing = .forVector(x: b.x-a.x, y: b.y-a.y)
                let used = min(budget, max(0, (1-segmentFraction)*length/17))
                segmentFraction += used * 17 / length; budget -= used
                position = .init(x: a.x+(b.x-a.x)*segmentFraction, y: a.y+(b.y-a.y)*segmentFraction)
                if segmentFraction >= 1-0.00000001 {
                    position = b; cursor += step; segmentFraction = 0
                    if cursor == points.count-1 { phase = .destinationPause }
                    else if cursor == 0 { phase = .sourcePause }
                }
            }
        }
    }
}
