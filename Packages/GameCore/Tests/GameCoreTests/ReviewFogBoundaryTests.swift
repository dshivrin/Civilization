#if DEBUG
import Testing
import GameCore
@testable import GameApplication

struct ReviewFogBoundaryTests {
    @Test func edgesAreDeterministicAndOnlyOnDiscoveryBoundary() {
        let known: Set<Tile> = [Tile(x: 1, y: 1), Tile(x: 2, y: 1)]
        let edges = ReviewFogBoundary.edges(known: known, width: 4, height: 3)
        #expect(edges.count == 6)
        #expect(edges == ReviewFogBoundary.edges(known: known, width: 4, height: 3))
        #expect(edges.allSatisfy { known.contains($0.known) && !known.contains($0.unknown) })
        #expect(Set(edges.map(\.radius)).count > 1)
    }
    @Test func holesAndNarrowRoutesHaveOpaqueBoundaryWithoutChangingDiscovery() {
        let all = Set((0..<5).flatMap { y in (0..<5).map { Tile(x: $0, y: y) } })
        let hole = Tile(x: 2, y: 2)
        let edges = ReviewFogBoundary.edges(known: all.subtracting([hole]), width: 5, height: 5)
        #expect(edges.count == 4)
        #expect(edges.allSatisfy { $0.unknown == hole })
        #expect(ReviewFogBoundary.edges(known: [], width: 5, height: 5).isEmpty)
        #expect(ReviewFogBoundary.edges(known: all, width: 5, height: 5).isEmpty)
        let route = Set((0..<5).map { Tile(x: $0, y: 2) })
        #expect(ReviewFogBoundary.edges(known: route, width: 5, height: 5).count == 10)
        #expect(route.count == 5)
    }
}
#endif

#if DEBUG
import Foundation
@Test func temporaryForestHutSuggestionIsIndependentOfRetainedPoorSave() throws {
    var retained = try RiverbendFoundingReview(now: Date(timeIntervalSince1970: 0))
    var state = retained.engine.state; state.resources.wood = 0
    retained = try RiverbendFoundingReview(state: state)
    #expect(retained.hutSites.isEmpty)
    let temporary = try OnboardingReviewWalkthrough(configuration: retained.engine.configuration, now: Date(timeIntervalSince1970: 0))
    let site = try #require(try ReviewForestPresentation.hutOrigin(in: temporary))
    #expect(temporary.engine.placementIssue(.hut, at: site) == nil)
    let civic = temporary.engine.configuration.map.campfire
    #expect(abs(site.x-civic.x)+abs(site.y-civic.y) >= 3)
    #expect(retained.engine.state.resources.wood == 0)
    #expect(temporary.engine.state.resources.wood == 100)
}
#endif
