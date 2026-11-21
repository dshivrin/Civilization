#if DEBUG
import GameCore

/// A lateral opening site for the unchanged temporary walkthrough. Never consults the retained save.
public enum ReviewForestPresentation {
    public static func hutOrigin(in temporary: OnboardingReviewWalkthrough) throws -> Tile? {
        try RiverbendFoundingReview(state: temporary.engine.state).hutSites.first ?? temporary.suggestedOrigin(for: .hut)
    }
}
#endif
