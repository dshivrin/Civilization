#if DEBUG
import Foundation

public extension GameConfiguration {
    static let riverbendFoundingID = "riverbend-ui2-founding-v1"
    var isRiverbendFoundingReview: Bool { map.id == Self.riverbendFoundingID }
    static func riverbendFoundingReview() throws -> Self {
        var c = try bundled()
        c.map.id = riverbendFoundingID
        c.constructionGoalWoodReward = 0
        c.civicLevels![1].name = "Founder’s Lodge"
        c.civicLevels![1].requiredTechnology = nil
        c.civicLevels![1].cost = ResourceAmounts(wood: 12, stone: 4)
        // Founding shelter has no new cultural/worker effect in this bounded opening.
        c.civicLevels![1].culturalOutputPerMinute = .init()
        c.civicLevels![1].workersRequired = 0
        try c.validate()
        return c
    }
}
#endif
