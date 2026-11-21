import Foundation

public enum CompletionDestination: String, Codable, Sendable { case research, goals }
public struct EarnedCompletion: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let destination: CompletionDestination
}
/// Seen includes the silent historical baseline. Unread is a subset, retained until
/// the exact result is actually viewed. Neither field changes progression or rewards.
public struct CompletionInbox: Codable, Equatable, Sendable {
    public internal(set) var seen: Set<String> = []
    public internal(set) var unread: Set<String> = []
    public init() {}
}
public extension GameEngine {
    var earnedCompletions: [EarnedCompletion] {
        var result = configuration.technologyDefinitions.filter { researchedIDs.contains($0.id) }.map {
            EarnedCompletion(id: "research:" + $0.id, title: $0.name, destination: .research)
        }
        for chapter in journeyChapters {
            for objective in chapter.objectives where objective.isComplete {
                result.append(EarnedCompletion(id: "objective:\(chapter.id):" + objective.id, title: objective.title, destination: .goals))
            }
            if chapter.isComplete { result.append(EarnedCompletion(id: "chapter:\(chapter.id)", title: chapter.title, destination: .goals)) }
        }
        for goal in pillarGoals where isPillarGoalComplete(id: goal.id) {
            result.append(EarnedCompletion(id: "pillar:" + goal.id, title: goal.title, destination: .goals))
        }
        return result
    }
    /// Called once by ordinary session restoration, before any gameplay commands.
    /// Existing predicates/history establish a baseline, never new unread results.
    mutating func prepareCompletionInbox() {
        guard state.completionInbox == nil else { return }
        let baseline = Set(earnedCompletions.map(\.id))
        state.completionInbox = CompletionInbox()
        state.completionInbox?.seen = baseline
    }
    mutating func acknowledgeCompletions(_ ids: Set<String>) {
        state.completionInbox?.unread.subtract(ids)
    }
}
extension GameEngine {
    mutating func recordCompletionInbox() {
        guard let inbox = state.completionInbox else { return }
        let earned = Set(earnedCompletions.map(\.id))
        state.completionInbox?.unread.formUnion(earned.subtracting(inbox.seen))
        state.completionInbox?.seen.formUnion(earned)
    }
}
