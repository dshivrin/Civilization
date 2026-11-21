import GameCore

/// Ephemeral HUD state only. Durable unread state belongs to GameSession's save.
public struct CompletionCuePresentation: Equatable, Sendable {
    public private(set) var pending: Set<CompletionDestination> = []
    public private(set) var pulsing: Set<CompletionDestination> = []
    public init() {}
    public mutating func enqueue(_ destinations: Set<CompletionDestination>) { pending.formUnion(destinations) }
    @discardableResult public mutating func begin(visible: Bool, active: Bool, reduceMotion: Bool, unread: Set<CompletionDestination>) -> Bool {
        guard visible && active else { return false }
        let destinations = pending.intersection(unread)
        pending = []
        guard !reduceMotion && !destinations.isEmpty else { return false }
        pulsing.formUnion(destinations); return true
    }
    public mutating func finish() { pulsing = [] }
    public mutating func clear() { pending = []; pulsing = [] }
}
