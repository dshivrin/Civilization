import Foundation

/// Read-only presentation of actual remaining construction work; never advances time.
public struct ConstructionPresentation: Sendable {
    public enum Stage: Sendable { case foundation, frame, roof, finished }
    public let fraction: Double
    public var stage: Stage {
        if fraction >= 1 { return .finished }
        if fraction < 0.25 { return .foundation }
        return fraction < 0.65 ? .frame : .roof
    }
    public init(remaining: Double, duration: Double) {
        guard remaining.isFinite, duration.isFinite, duration > 0 else { fraction = 0; return }
        fraction = min(1, max(0, 1 - remaining / duration))
    }
}
