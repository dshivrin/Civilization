/// Appearance only. The owner of the actual loading operation controls dismissal.
public struct LoadingPresentation: Equatable, Sendable {
    public enum Context: Equatable, Sendable { case brand, settlement }
    public let stage: String
    public let context: Context
    public let measurement: LoadingProgress?
    public private(set) var scenerySkipped = false

    public init(stage: String, context: Context = .settlement, measurement: LoadingProgress? = nil) {
        self.stage = stage
        self.context = context
        self.measurement = measurement
    }

    public var progress: Double? { measurement?.fraction }
    public var showsEra: Bool { context == .settlement }
    public var showsScenery: Bool { showsEra && !scenerySkipped }
    public mutating func skipScenery() { scenerySkipped = true }

    public func animatesScenery(isActive: Bool, reduceMotion: Bool, lowPower: Bool) -> Bool {
        showsScenery && isActive && !reduceMotion && !lowPower
    }
}

/// Supply only actual measured units of work. Invalid or unavailable measurements
/// remain indeterminate; elapsed animation time is never used as loading progress.
public struct LoadingProgress: Equatable, Sendable {
    public let completed: Double
    public let total: Double
    public init(completed: Double, total: Double) {
        self.completed = completed
        self.total = total
    }
    public var fraction: Double? {
        guard completed.isFinite, total.isFinite, total > 0, completed >= 0 else { return nil }
        return min(1, completed / total)
    }
}

public enum LoadingScenery: String, CaseIterable, Sendable {
    case founding, river, mountain
}

/// Temporary title, mark, era and advice are independent of scene artwork.
public struct LoadingBranding: Equatable, Sendable {
    public enum Mark: Equatable, Sendable { case sunrise, none }
    public var title: String
    public var mark: Mark
    public var era: String
    public var tip: String
    public init(title: String = "CIVILIZATION", mark: Mark = .sunrise,
                era: String = "STONE AGE", tip: String = "A small beginning. A world of possibilities.") {
        self.title = title
        self.mark = mark
        self.era = era
        self.tip = tip
    }
}
