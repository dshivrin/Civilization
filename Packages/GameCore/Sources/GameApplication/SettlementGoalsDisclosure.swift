/// UI disclosure state. Readiness and repeated notifications are not era advancement.
public struct SettlementGoalsDisclosure: Sendable {
    public var isExpanded = false
    private var eraID: String
    public init(eraID: String) { self.eraID = eraID }
    public mutating func observeEra(_ id: String) {
        guard id != eraID else { return }
        eraID = id
        isExpanded = true
    }
}
