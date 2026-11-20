#if DEBUG
import Foundation
import Testing
import GameCore
import GameApplication

private func motionPlanner() throws -> VisualRoutePlanner {
    var config = try GameConfiguration.bundled()
    var state = try GameEngine(configuration: config, now: Date(timeIntervalSince1970: 0)).state
    config.map.rows = Array(repeating: String(repeating: ".", count: 12), count: 12)
    config.map.width = 12; config.map.height = 12
    state.buildings = []; state.discoveredTiles = nil; state.roads = nil
    return VisualRoutePlanner(configuration: config, state: state)
}

@Test func visualAgentPosesHaveDistinctReadableActivitiesAndFiniteJoints() {
    for activity in VisualAgentActivity.allCases {
        let pose = VisualAgentPose.sample(activity: activity, elapsed: 0.25)
        #expect([pose.bodyOffsetY, pose.bodyTilt, pose.leftLegAngle, pose.rightLegAngle,
                 pose.leftArmAngle, pose.rightArmAngle, pose.headTilt, pose.turnScale].allSatisfy { $0.isFinite })
        #expect(VisualAgentPose.sample(activity: activity, elapsed: .nan) == VisualAgentPose.sample(activity: activity, elapsed: 0))
    }
    let idle = VisualAgentPose.sample(activity: .idle, elapsed: 0.25)
    #expect(VisualAgentPose.sample(activity: .rest, elapsed: 0.25).bodyOffsetY < idle.bodyOffsetY)
    #expect(VisualAgentPose.sample(activity: .work, elapsed: 0.25).leftArmAngle != idle.leftArmAngle)
    #expect(VisualAgentPose.sample(activity: .gather, elapsed: 0.25).bodyTilt != idle.bodyTilt)
    #expect(VisualAgentPose.sample(activity: .socialize, elapsed: 0.25).rightArmAngle != idle.rightArmAngle)
    #expect(VisualAgentPose.sample(activity: .carry, elapsed: 0.25).cargoVisible)
    #expect(!VisualAgentPose.sample(activity: .walk, elapsed: 0.25).cargoVisible)
    #expect(VisualAgentPose.sample(activity: .walk, elapsed: 0.25) != VisualAgentPose.sample(activity: .walk, elapsed: 0.75))
    #expect(VisualAgentFacing.forVector(x: 32, y: -16) == .nearRight)
    #expect(VisualAgentFacing.forVector(x: -32, y: -16) == .nearLeft)
    #expect(VisualAgentFacing.forVector(x: 32, y: 16) == .awayRight)
    #expect(VisualAgentFacing.forVector(x: -32, y: 16) == .awayLeft)
}

@Test func visualAgentJourneysUseValidContactsAndReturnWithoutCargo() throws {
    let planner = try motionPlanner()
    var journey = try #require(VisualAgentJourney(tiles: [.init(x: 0, y: 0), .init(x: 1, y: 0)], planner: planner,
        source: .woodcutter, destination: .storehouse, sourceActive: true, purpose: .carryWood))
    #expect(journey.activity == .gather)
    var seen: Set<VisualAgentActivity> = []; var sawEmptyReturn = false
    for _ in 0..<200 {
        journey.advance(by: 0.1, animates: true); seen.insert(journey.activity)
        #expect((0...32).contains(journey.position.x) && (-16...0).contains(journey.position.y))
        #expect(abs(journey.position.x + 2 * journey.position.y) < 0.00001)
        if journey.activity == .idle { #expect(journey.position == WorldPoint(x: 32, y: -16)) }
        if journey.activity == .gather { #expect(journey.position == WorldPoint(x: 0, y: 0)) }
        if journey.activity == .walk && journey.facing == .awayLeft { sawEmptyReturn = true }
    }
    #expect(seen.isSuperset(of: [.gather, .turn, .carry, .walk, .idle]))
    #expect(sawEmptyReturn)
}

@Test func visualAgentJourneysGateWorkByExistingProductionAndUseGatheringDestinations() throws {
    let planner = try motionPlanner(), path = [Tile(x: 0, y: 0), Tile(x: 1, y: 0)]
    var inactive = try #require(VisualAgentJourney(tiles: path, planner: planner, source: .woodcutter,
        destination: .storehouse, sourceActive: false, purpose: .carryWood))
    var visit = try #require(VisualAgentJourney(tiles: path, planner: planner, source: .hut,
        destination: .storytellingCircle, sourceActive: false, purpose: .visitGathering))
    let worker = try #require(VisualAgentJourney(tiles: path, planner: planner, source: .toolmaker,
        destination: .storehouse, sourceActive: true, purpose: .visitStorage))
    #expect(worker.activity == .work)
    var seen: Set<VisualAgentActivity> = []
    for _ in 0..<150 {
        inactive.advance(by: 0.1, animates: true); visit.advance(by: 0.1, animates: true)
        #expect(![VisualAgentActivity.work, .gather, .carry].contains(inactive.activity))
        seen.insert(visit.activity)
    }
    #expect(seen.isSuperset(of: [.rest, .socialize, .walk, .turn]))
}

@Test func visualAgentJourneyRejectsBadPathsAndSuspendsWithoutChangingPoseOrPosition() throws {
    let planner = try motionPlanner(), path = [Tile(x: 0, y: 0), Tile(x: 1, y: 0)]
    for invalid in [[], [path[0]], [path[0], Tile(x: 2, y: 0)], [path[0], Tile(x: Int.max, y: Int.min)]] {
        #expect(VisualAgentJourney(tiles: invalid, planner: planner, source: .hut,
            destination: .storehouse, sourceActive: false, purpose: .visitStorage) == nil)
    }
    var journey = try #require(VisualAgentJourney(tiles: path, planner: planner, source: .hut,
        destination: .storehouse, sourceActive: false, purpose: .visitStorage))
    for _ in 0..<22 { journey.advance(by: 0.1, animates: true) }
    let frozen = journey
    journey.advance(by: 100, animates: false)
    for invalid in [-1, Double.nan, .infinity] { journey.advance(by: invalid, animates: true) }
    #expect(journey == frozen)
    journey.advance(by: .greatestFiniteMagnitude, animates: true)
    #expect(hypot(journey.position.x-frozen.position.x, journey.position.y-frozen.position.y) <= 1.70001)
    var replay = frozen; replay.advance(by: 0.1, animates: true)
    #expect(journey == replay)
}

@Test func visualAgentTurnsFaceTheDepartureDirectionBeforeLeavingContact() throws {
    let planner = try motionPlanner()
    var journey = try #require(VisualAgentJourney(tiles: [.init(x: 0, y: 0), .init(x: 1, y: 0)], planner: planner,
        source: .woodcutter, destination: .storehouse, sourceActive: true, purpose: .carryWood))
    var turnedAtDestination = false, departed = false
    for _ in 0..<80 {
        journey.advance(by: 0.1, animates: true)
        if journey.activity == .turn && journey.position == WorldPoint(x: 32, y: -16), journey.facing == .awayLeft {
            turnedAtDestination = true
        }
        if journey.activity == .walk && journey.position.x < 32 {
            #expect(turnedAtDestination, "The actor must turn while stationary, before its first return step")
            departed = true; break
        }
    }
    #expect(turnedAtDestination && departed)
}

@Test @MainActor func visualAgentPowerObservationUpdatesWithoutInteractionAndReleasesObserver() {
    let center = NotificationCenter()
    var power = false, reads = 0
    var observer: VisualAgentPowerObservation? = VisualAgentPowerObservation(center: center, readLowPower: {
        reads += 1; return power
    })
    #expect(observer?.lowPower == false)
    power = true; center.post(name: .NSProcessInfoPowerStateDidChange, object: nil)
    #expect(observer?.lowPower == true)
    power = false; center.post(name: .NSProcessInfoPowerStateDidChange, object: nil)
    #expect(observer?.lowPower == false)
    weak var retained = observer; observer = nil
    #expect(retained == nil)
    let before = reads
    center.post(name: .NSProcessInfoPowerStateDidChange, object: nil)
    #expect(reads == before)
}
#endif
