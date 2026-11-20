import Foundation

/// Presentation-only keyframes. They do not represent game time or production rates.
public enum VisualDayPhase: String, CaseIterable, Sendable {
    case day, dusk, night, dawn
    public var cycleFraction: Double {
        switch self { case .day: 0; case .dusk: 0.25; case .night: 0.5; case .dawn: 0.75 }
    }
}

public struct VisualLighting: Equatable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let opacity: Double

    /// A bounded tint preserves at least 80% of the untinted scene contribution.
    /// This is a review readability floor, not a measured accessibility certificate.
    public static func sample(cycleFraction: Double) -> Self {
        let fraction = cycleFraction.isFinite ? cycleFraction - floor(cycleFraction) : 0
        let frames: [Self] = [
            .init(red: 0.84, green: 0.42, blue: 0.15, opacity: 0),
            .init(red: 0.84, green: 0.42, blue: 0.15, opacity: 0.10),
            .init(red: 0.10, green: 0.20, blue: 0.40, opacity: 0.20),
            .init(red: 0.86, green: 0.56, blue: 0.35, opacity: 0.10),
            .init(red: 0.84, green: 0.42, blue: 0.15, opacity: 0)
        ]
        let segment = min(3, Int(fraction * 4))
        let amount = fraction * 4 - Double(segment)
        let a = frames[segment], b = frames[segment + 1]
        return .init(red: a.red + (b.red - a.red) * amount,
                     green: a.green + (b.green - a.green) * amount,
                     blue: a.blue + (b.blue - a.blue) * amount,
                     opacity: a.opacity + (b.opacity - a.opacity) * amount)
    }
}

/// Non-persistent visual clock. Call suspend whenever rendering is covered/inactive.
/// A fresh frame baseline on resume avoids replaying background time.
public struct VisualDayCycle: Sendable {
    public private(set) var fraction: Double = 0
    private var previousTimestamp: Double?
    private let duration: Double

    public init(duration: Double = 120) {
        self.duration = duration.isFinite && duration >= 1 ? duration : 120
    }
    public mutating func select(_ phase: VisualDayPhase) {
        fraction = phase.cycleFraction
        suspend()
    }
    public mutating func suspend() { previousTimestamp = nil }
    public mutating func tick(timestamp: Double, animates: Bool) {
        guard animates, timestamp.isFinite else { suspend(); return }
        guard let previous = previousTimestamp else { previousTimestamp = timestamp; return }
        guard timestamp >= previous else { suspend(); return }
        previousTimestamp = timestamp
        let increment = min(0.1, timestamp - previous) / duration
        // The remainder keeps the visual phase bounded across full cycles.
        let next = fraction + increment.truncatingRemainder(dividingBy: 1)
        fraction = next.truncatingRemainder(dividingBy: 1)
    }
}
