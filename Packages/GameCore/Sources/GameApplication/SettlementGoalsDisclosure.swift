/// UI disclosure state. Readiness and repeated notifications are not era advancement.
public struct SettlementGoalsDisclosure: Sendable {
    public enum DisplayState: String, CaseIterable, Sendable {
        case minimal = "Minimal", compact = "Compact", expanded = "Expanded"
    }
    public var state: DisplayState = .minimal
    public var isExpanded: Bool {
        get { state == .expanded }
        set { state = newValue ? .expanded : .minimal }
    }
    private var eraID: String
    public init(eraID: String) { self.eraID = eraID }
    public mutating func cycle() {
        switch state {
        case .minimal: state = .compact
        case .compact: state = .expanded
        case .expanded: state = .minimal
        }
    }
    public mutating func observeEra(_ id: String) {
        guard id != eraID else { return }
        eraID = id
        state = .expanded
    }
}
