import Foundation

/// Read-only presentation of actual remaining construction work; never advances time.
public struct ConstructionPresentation: Sendable {
    public enum Stage: Sendable { case foundation, frame, roof, finished }
    public let fraction: Double
    #if DEBUG
    private let reviewWorkIsValid: Bool
    #endif
    public var stage: Stage {
        if fraction >= 1 { return .finished }
        if fraction < 0.25 { return .foundation }
        return fraction < 0.65 ? .frame : .roof
    }
    public init(remaining: Double, duration: Double) {
        #if DEBUG
        reviewWorkIsValid = remaining.isFinite && remaining >= 0 && duration.isFinite && duration > 0
        #endif
        guard remaining.isFinite, duration.isFinite, duration > 0 else { fraction = 0; return }
        fraction = min(1, max(0, 1 - remaining / duration))
    }
    #if DEBUG
    /// Five-stage comparison for the disposable walkthrough; normal stage stays unchanged.
    public enum ReviewStage: String, Sendable { case foundation, frame, walls, roof, finished }
    public var reviewStage: ReviewStage {
        guard reviewWorkIsValid else { return .foundation }
        if fraction >= 1 { return .finished }
        if fraction < 0.15 { return .foundation }
        if fraction < 0.40 { return .frame }
        return fraction < 0.75 ? .walls : .roof
    }
    #endif
}
