import Foundation
import Testing
@testable import GameCore

private let reviewEpoch = Date(timeIntervalSince1970: 7_000_000)
private func reviewAmounts(_ values: [Resource: Double]) -> ResourceAmounts {
    var result = ResourceAmounts(); for (r,v) in values { result[r] = v }; return result
}
private func reviewFlows() throws -> GameEngine {
    var c = try economyConfiguration()
    c.populationRules = nil
    for i in c.buildings.indices {
        c.buildings[i].cost = .init()
        c.buildings[i].constructionSeconds = 0
    }
    let camp = c.buildings.firstIndex { $0.kind == .campfire }!
    c.buildings[camp].recipes = [ProductionRecipe(id:"source",name:"Source",inputsPerMinute:.init(),outputsPerMinute:reviewAmounts([.wood:12,.flint:6,.water:6]),allocationTier:0)]
    let tool = c.buildings.firstIndex { $0.kind == .toolmaker }!
    c.buildings[tool].recipes = [ProductionRecipe(id:"tools",name:"Tools",inputsPerMinute:reviewAmounts([.wood:3,.flint:12]),outputsPerMinute:reviewAmounts([.stoneTools:6]),allocationTier:1)]
    c.buildings[tool].maintenancePerMinute = .init()
    let tannery = c.buildings.firstIndex { $0.kind == .tannery }!
    c.buildings[tannery].recipes = [ProductionRecipe(id:"leather",name:"Leather",inputsPerMinute:reviewAmounts([.wood:9]),outputsPerMinute:reviewAmounts([.leather:6]),allocationTier:1)]
    c.buildings[tannery].maintenancePerMinute = .init()
    var g = try GameEngine(configuration:c,now:reviewEpoch)
    try g.build(.toolmaker,at:Tile(x:8,y:8))
    try g.build(.tannery,at:Tile(x:10,y:8))
    var s = g.state; s.resources = .init()
    return try GameEngine(state:s,configuration:c)
}
@Test func reviewUnevenMultiInputConsumersUseAvailableFlowWithoutOrderDependence() throws {
    var g = try reviewFlows()
    #expect(abs(g.productivity(g.state.buildings[1]) - 0.5) < 1e-9)
    #expect(abs(g.productivity(g.state.buildings[2]) - 1) < 1e-9)
    var reversed = g.state; reversed.buildings.reverse()
    var b = try GameEngine(state:reversed,configuration:g.configuration)
    g.advance(to:reviewEpoch.addingTimeInterval(600))
    b.advance(to:reviewEpoch.addingTimeInterval(600))
    for r in Resource.allCases { #expect(abs(g.state.resources[r] - b.state.resources[r]) < 1e-8) }
    #expect(abs(g.state.resources[.stoneTools] - 30) < 1e-8)
    #expect(abs(g.state.resources[.leather] - 60) < 1e-8)
    #expect(abs(g.state.resources.wood - 15) < 1e-8)
}
@Test func reviewUnevenFlowsRemainEquivalentAcrossIrregularPartitions() throws {
    var a = try reviewFlows(), b = a
    a.advance(to:reviewEpoch.addingTimeInterval(600))
    for second in [0.3,1.7,16.9,100.1,122.0,503.6,599.999,600] {
        b.advance(to:reviewEpoch.addingTimeInterval(second))
    }
    for r in Resource.allCases { #expect(abs(a.state.resources[r] - b.state.resources[r]) < 1e-8) }
}
@Test func reviewFiniteExtractionSplitsAtActualReserveBoundary() throws {
    var c = try economyConfiguration()
    c.populationRules = nil
    for i in c.buildings.indices { c.buildings[i].cost = .init(); c.buildings[i].constructionSeconds = 0 }
    var a = try GameEngine(configuration:c,now:reviewEpoch)
    try a.build(.stoneGatherer,at:Tile(x:8,y:8))
    try a.setProductionMode(buildingID:1,recipeID:"flint")
    var s = a.state
    for key in s.depositRemaining!.keys { s.depositRemaining![key] = 0 }
    let match = c.naturalDeposits!.first { $0.resource == .flint }!
    s.depositRemaining![match.id] = 1
    a = try GameEngine(state:s,configuration:c)
    var b = a
    a.advance(to:reviewEpoch.addingTimeInterval(600))
    for second in 1...600 { b.advance(to:reviewEpoch.addingTimeInterval(Double(second))) }
    #expect(abs(a.state.resources[.flint] - 1) < 1e-8)
    #expect(a.state.depositRemaining![match.id] == 0)
    for r in Resource.allCases { #expect(abs(a.state.resources[r] - b.state.resources[r]) < 1e-8) }
}
@Test func reviewEffectiveRecipeRatesRejectResearchOverflow() throws {
    var c = try economyConfiguration()
    c.technologies![0].effects.productionBonus[.flint] = Double.greatestFiniteMagnitude / 2
    #expect(throws:GameError.self) { try c.validate() }
}
@Test func reviewHistoricalRulesetRejectsUnsupportedBuildingBeforeLookingUpEffects() throws {
    let c = try foundationConfiguration()
    var s = try GameEngine(configuration:c,now:reviewEpoch).state
    s.buildings.append(PlacedBuilding(id:1,kind:.farm,origin:Tile(x:8,y:8)))
    s.nextBuildingID = 2
    #expect(throws:GameError.self) { try GameEngine(state:s,configuration:c) }
}
