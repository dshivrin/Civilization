import Foundation

/// Read-only presentation of actual remaining construction work; never advances time.
public struct ConstructionPresentation: Sendable {
    public enum Stage: Sendable { case foundation, frame, roof, finished }
    public let fraction: Double
    private let reviewWorkIsValid: Bool
    public var stage: Stage {
        if fraction >= 1 { return .finished }
        if fraction < 0.25 { return .foundation }
        return fraction < 0.65 ? .frame : .roof
    }
    public init(remaining: Double, duration: Double) {
        reviewWorkIsValid = remaining.isFinite && remaining >= 0 && duration.isFinite && duration > 0
        guard remaining.isFinite, duration.isFinite, duration > 0 else { fraction = 0; return }
        fraction = min(1, max(0, 1 - remaining / duration))
    }
    public enum WorkStage: String, Sendable { case foundation, frame, walls, roof, finished }
    public var workStage: WorkStage {
        guard reviewWorkIsValid else { return .foundation }
        if fraction >= 1 { return .finished }
        if fraction < 0.15 { return .foundation }
        if fraction < 0.40 { return .frame }
        return fraction < 0.75 ? .walls : .roof
    }
    #if DEBUG
    public typealias ReviewStage = WorkStage
    public var reviewStage: WorkStage { workStage }
    #endif
}
