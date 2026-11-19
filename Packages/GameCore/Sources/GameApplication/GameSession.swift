import Foundation
import Observation
import GameCore
import GamePersistence

@MainActor @Observable
public final class GameSession {
    private var engine: GameEngine
    @ObservationIgnored private let store: SaveStore
    #if DEBUG
    private struct DeveloperEnvelope: Encodable {
        let version = 5
        let state: GameState
        let developerScenario: DeveloperScenario
        let originalScenarioState: GameState?
    }
    private struct DeveloperMetadata: Decodable { let developerScenario: DeveloperScenario?; let originalScenarioState: GameState? }
    @ObservationIgnored private let developerStore: SaveStore
    @ObservationIgnored private var normalSnapshot: (engine: GameEngine, savesEnabled: Bool, warning: String?)?
    public private(set) var isDeveloperMode = false
    public private(set) var developerPaused = false
    public private(set) var developerSpeed: Double = 1
    public private(set) var developerFastConstruction = false
    @ObservationIgnored private var originalScenarioState: GameState?
    public func isSelectedDeveloperScenario(_ scenario: DeveloperScenario) -> Bool { isDeveloperMode && developerScenario == scenario }
    public var developerStateDescription: String {
        guard isDeveloperMode else { return "Normal settlement" }
        guard var original = originalScenarioState else { return "Saved developer state · original comparison unavailable" }
        original.lastUpdated = state.lastUpdated
        return original == state ? "Original scenario" : "Modified developer state"
    }
    public private(set) var developerScenario: DeveloperScenario = .early
    #endif
    @ObservationIgnored private let clock: () -> Date
    @ObservationIgnored private var savesEnabled = true
    @ObservationIgnored private var isActive = true
    @ObservationIgnored private var lastSaved = Date.distantPast
    public var message = "Welcome to Riverbend. Build your first gathering shelter."
    public var persistenceWarning: String?
    public var selectedKind: BuildingKind?
    public private(set) var movingBuildingID: Int?
    public var eraID: String { "stoneAge" }
    public var isDragMode: Bool { previewKind != nil }
    public var previewKind: BuildingKind? {
        if let id = movingBuildingID { return state.buildings.first { $0.id == id }?.kind }
        return selectedKind
    }
    public func producingBuildingCount(for resource: Resource) -> Int { engine.producingBuildingCount(for: resource) }
    public func productionSources(for resource: Resource) -> [BuildingDefinition] {
        configuration.buildings.filter { definition in
            definition.ratesPerMinute[resource] > 0 || (definition.recipes?.contains { $0.outputsPerMinute[resource] > 0 } ?? false)
        }
    }
    public var selectedTile: Tile?
    public var inspectedBuilding: PlacedBuilding?
    public var currentInspection: PlacedBuilding? { state.buildings.first { $0.id == inspectedBuilding?.id } }
    public var centerRequest = 0
    public var state: GameState { engine.state }
    public var configuration: GameConfiguration { engine.configuration }
    public var rates: ResourceAmounts { engine.rates }
    public var grossRates: ResourceAmounts { engine.grossRates }
    public var consumption: ResourceAmounts { engine.consumption }
    public var capacities: ResourceAmounts { engine.capacities }
    public var growthStatus: GrowthStatus { engine.growthStatus }
    public var growthIntervalSeconds: Double { engine.growthIntervalSeconds }
    public var researchedIDs: Set<String> { engine.researchedIDs }
    public var constructionQueue: [PlacedBuilding] { state.buildings.filter { !$0.isOperational } }
    public var growthRemainingSeconds: Double { max(0, engine.growthIntervalSeconds - (state.populationGrowthSeconds ?? 0)) }
    public func constructionDuration(for kind: BuildingKind) -> Double { engine.constructionDuration(for: kind) }
    public func isUnlocked(_ kind: BuildingKind) -> Bool { engine.isUnlocked(kind) }
    public func researchIssue(_ id: String) -> GameError? { engine.researchIssue(id) }
    public var explorationIssue: GameError? { engine.explorationIssue }
    public var discoveredTileCount: Int { engine.discoveredTileCount }
    public var discoveredDeposits: [NaturalDeposit] { engine.discoveredDeposits }
    public func isDiscovered(_ tile: Tile) -> Bool { engine.isDiscovered(tile) }
    public func isIdentified(_ deposit: NaturalDeposit) -> Bool { engine.isIdentified(deposit) }
    public func startExploration() {
        perform {
            try engine.startExploration()
            message = "Exploration started. New terrain will be revealed when the expedition returns."
        }
    }
    public var workforceAvailable: Double { engine.workforceAvailable }
    public var workforceRequired: Double { engine.workforceRequired }
    public var workforceAllocated: Double { state.buildings.reduce(0) { $0 + engine.workersAllocated(to: $1) } }
    public func workersAllocated(to building: PlacedBuilding) -> Double { engine.workersAllocated(to: building) }
    public func workforceProductivity(_ building: PlacedBuilding) -> Double { engine.workforceProductivity(building) }
    public func setWorkerPriority(buildingID: Int, priority: Int) {
        perform {
            try engine.setWorkerPriority(buildingID: buildingID, priority: priority)
            message = "Workforce priority changed. Basic food and water keep a protected share."
        }
    }
    public func inspect(buildingID: Int) {
        guard let building = state.buildings.first(where: { $0.id == buildingID }) else { return }
        cancelRelocationPreview()
        selectedKind = nil
        selectedTile = nil
        inspectedBuilding = building
        message = configuration.definition(building.kind).name
    }
    public func productivity(_ building: PlacedBuilding) -> Double { engine.productivity(building) }
    public func operatingStatus(_ building: PlacedBuilding) -> String { engine.operatingStatus(building) }
    public func upgradeCost(for building: PlacedBuilding) -> ResourceAmounts? { engine.upgradeCost(for: building) }
    public func setProductionMode(buildingID: Int, recipeID: String) {
        perform {
            try engine.setProductionMode(buildingID: buildingID, recipeID: recipeID)
            message = "Production mode changed."
        }
    }
    public func upgrade(buildingID: Int) {
        perform {
            try engine.upgrade(buildingID: buildingID)
            message = "Building upgraded."
        }
    }
    public var housingCapacity: Int { engine.housingCapacity }
    public var journeyChapters: [JourneyChapter] { engine.journeyChapters }
    public var stoneAgeRequirements: [JourneyObjective] { engine.stoneAgeRequirements }
    public var missingDiscoveryResourceNames: [String] { engine.missingDiscoveryResourceNames }
    public var fullStoneAgeRequirementsMet: Bool { engine.fullStoneAgeRequirementsMet }
    public var currentGoal: Goal? { engine.currentGoal }
    public var pillarGoals: [PillarGoalDefinition] { engine.pillarGoals }
    public func pillarGoalProgress(id: String) -> String { engine.pillarGoalProgress(id: id) }
    public func isPillarGoalComplete(_ id: String) -> Bool { engine.isPillarGoalComplete(id: id) }
    public var placementIssue: GameError? {
        if let id = movingBuildingID, let tile = selectedTile { return engine.relocationIssue(buildingID: id, at: tile) }
        guard let kind = selectedKind, let tile = selectedTile else { return .placement("Tap open land to choose a location.") }
        return engine.placementIssue(kind, at: tile)
    }
    private struct Restoration: Sendable {
        var engine: GameEngine
        var url: URL
        var message: String
        var warning: String?
    }
    /// Read and simulate off the UI thread. Invalid save bytes remain untouched.
    nonisolated private static func restore(now: Date, saveURL: URL?, configuration providedConfiguration: GameConfiguration?) throws -> Restoration {
        let configuration = try providedConfiguration ?? GameConfiguration.bundled()
        let url = try saveURL ?? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Civilization/settlement-v1.json")
        var engine = try GameEngine(configuration: configuration, now: now)
        var message = "Welcome to Riverbend. Build your first gathering shelter."
        var warning: String?
        do {
            if let saved = try SaveStore(url: url).load(configuration: configuration) {
                engine = try GameEngine(state: saved, configuration: configuration)
                engine.advance(to: now, offline: true)
                message = "Welcome back. Your settlement kept producing (up to \(Int(configuration.offlineCapSeconds / 3600)) hours)."
            }
        } catch {
            warning = "Your existing save could not be loaded and has been preserved. This temporary settlement will not overwrite it. \(error.localizedDescription)"
        }
        return Restoration(engine: engine, url: url, message: message, warning: warning)
    }
    public convenience init(clock: @escaping () -> Date = Date.init, saveURL: URL? = nil, configuration: GameConfiguration? = nil) throws {
        self.init(restoration: try Self.restore(now: clock(), saveURL: saveURL, configuration: configuration), clock: clock)
    }
    private init(restoration: Restoration, clock: @escaping () -> Date) {
        self.clock = clock
        store = SaveStore(url: restoration.url)
        #if DEBUG
        developerStore = SaveStore(url: restoration.url.appendingPathExtension("developer"))
        #endif
        engine = restoration.engine
        message = restoration.message
        persistenceWarning = restoration.warning
        savesEnabled = restoration.warning == nil
        if savesEnabled { save() }
    }
    public static func load(clock: @escaping () -> Date = Date.init, saveURL: URL? = nil, configuration: GameConfiguration? = nil) async throws -> GameSession {
        let now = clock()
        let restored = try await Task.detached(priority: .userInitiated) {
            try restore(now: now, saveURL: saveURL, configuration: configuration)
        }.value
        try Task.checkCancellation()
        let session = GameSession(restoration: restored, clock: clock)
        // Activation belongs to the presenting scene; a suspension during startup must use capped catch-up.
        session.isActive = false
        return session
    }
    public func tick() {
        guard isActive else { return }
        advance(to: clock())
        if clock().timeIntervalSince(lastSaved) >= 15 { save() }
    }
    public func setActive(_ active: Bool) {
        guard active != isActive else { return }
        if active { resume() } else { background() }
        isActive = active
    }
    public func resume() { advance(to: clock(), offline: true); save() }
    public func background() { cancelRelocationPreview(); advance(to: clock()); save() }
    public func save() {
        guard savesEnabled else { return }
        do {
            #if DEBUG
            if isDeveloperMode {
                let data = try JSONEncoder().encode(DeveloperEnvelope(state: engine.state, developerScenario: developerScenario, originalScenarioState: originalScenarioState))
                try FileManager.default.createDirectory(at: developerStore.url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try data.write(to: developerStore.url, options: .atomic)
            }
            else { try store.save(engine.state) }
            #else
            try store.save(engine.state)
            #endif
            lastSaved = clock(); persistenceWarning = nil
        }
        catch { persistenceWarning = "Progress could not be saved: \(error.localizedDescription)" }
    }
    public func choose(_ kind: BuildingKind) {
        cancelRelocationPreview()
        selectedKind = kind; inspectedBuilding = nil
        // Offer a valid initial ghost near the campfire; map taps can reposition it.
        let map = configuration.map
        let candidates = (0..<map.height).flatMap { y in (0..<map.width).map { Tile(x: $0, y: y) } }
            .sorted { abs($0.x - map.campfire.x) + abs($0.y - map.campfire.y) < abs($1.x - map.campfire.x) + abs($1.y - map.campfire.y) }
        selectedTile = candidates.first { engine.placementIssue(kind, at: $0) == nil } ?? Tile(x: 13, y: 12)
        message = "Drag mode · drag on the map and release to build, or tap and Confirm."
    }
    public func tap(_ tile: Tile) {
        if selectedKind != nil || movingBuildingID != nil { selectedTile = tile }
        else {
            inspectedBuilding = engine.building(at: tile)
            if let building = inspectedBuilding { message = configuration.definition(building.kind).name }
            else if !isDiscovered(tile) { message = "Unexplored terrain · send an expedition to reveal it." }
            else if let terrain = configuration.map.terrain(at: tile) { message = "\(String(describing: terrain).capitalized) · tile \(tile.x), \(tile.y)" }
        }
    }
    private func cancelRelocationPreview() {
        if movingBuildingID != nil { selectedTile = nil }
        movingBuildingID = nil
    }
    public func beginRelocation(buildingID: Int) {
        guard let building = state.buildings.first(where: { $0.id == buildingID }) else { return }
        if building.kind == .campfire { message = "The campfire is the fixed settlement anchor."; return }
        selectedKind = nil; inspectedBuilding = nil; movingBuildingID = buildingID; selectedTile = building.origin
        message = "Drag to move · release on valid land. Relocation is free."
    }
    /// A release commits only the active preview; repeated release callbacks cannot charge twice.
    public func finishDragging() {
        if movingBuildingID != nil { finishRelocation() }
        else if selectedKind != nil { confirm() }
    }
    public func finishRelocation() {
        guard let id = movingBuildingID, let tile = selectedTile else { return }
        if let issue = engine.relocationIssue(buildingID: id, at: tile) {
            cancelRelocationPreview()
            message = "Move cancelled. " + issue.localizedDescription
            return
        }
        perform {
            try engine.relocate(buildingID: id, to: tile)
            cancelRelocationPreview()
            inspectedBuilding = state.buildings.first { $0.id == id }
            message = "Building moved."
        }
    }
    public func cancel() {
        cancelRelocationPreview(); selectedKind = nil; selectedTile = nil
        message = "Drag to explore · pinch to zoom · long-press a building to move it"
    }
    public func confirm() {
        if movingBuildingID != nil { finishRelocation(); return }
        guard let kind = selectedKind, let tile = selectedTile else { return }
        perform {
            try engine.build(kind, at: tile)
            message = "\(configuration.definition(kind).name) construction started."
            selectedKind = nil; selectedTile = nil
        }
    }
    public func research(_ id: String = "oralTradition") {
        perform {
            try engine.research(id)
            let name = configuration.technologyDefinitions.first { $0.id == id }!.name
            message = "\(name) research complete."
        }
    }
    private func advance(to date: Date, offline: Bool = false) {
        let previouslyBuilding = Set(constructionQueue.map(\.id))
        let population = state.population
        let discovered = discoveredTileCount
        let goals = state.completedGoals
        let stoneAgeWasComplete = state.stoneAgeCompleted == true
        #if DEBUG
        if isDeveloperMode {
            let previousWallTime = engine.state.lastUpdated
            let elapsed = max(0, date.timeIntervalSince(previousWallTime))
            let seconds = offline || developerPaused ? 0 : min(elapsed, configuration.offlineCapSeconds) * developerSpeed
            engine.advance(to: engine.state.lastUpdated.addingTimeInterval(seconds))
            engine.developerRebaseClock(to: max(date, previousWallTime))
        } else { engine.advance(to: date, offline: offline) }
        #else
        engine.advance(to: date, offline: offline)
        #endif
        let completed = state.buildings.filter { previouslyBuilding.contains($0.id) && $0.isOperational }
        if !completed.isEmpty { message = completed.map { configuration.definition($0.kind).name }.joined(separator: ", ") + " construction complete." }
        if state.population > population { message = "Settlement grew to \(state.population) inhabitants." }
        if discoveredTileCount > discovered { message = "Exploration complete. \(discoveredTileCount - discovered) new tiles discovered." }
        if state.completedGoals != goals && engine.currentGoal == nil { message = "Onboarding complete. Continue developing the five pillars." }
        if !stoneAgeWasComplete && state.stoneAgeCompleted == true { message = "Stone Age ready. Continue building and researching in your settlement sandbox." }
    }
    public func canAfford(_ costs: ResourceAmounts) -> Bool { engine.canAfford(costs) }
    private func perform(_ action: () throws -> Void) {
        advance(to: clock())
        do { try action(); save() } catch { message = error.localizedDescription }
    }
    #if DEBUG
    private func enterDeveloperMode() {
        guard !isDeveloperMode else { return }
        // Commands already save their state. Avoid rewriting a normal save when no wall time elapsed.
        if clock() > engine.state.lastUpdated { background() }
        normalSnapshot = (engine, savesEnabled, persistenceWarning)
        isDeveloperMode = true; savesEnabled = true; persistenceWarning = nil
        resetDeveloperControls()
    }
    private func resetDeveloperControls() {
        developerPaused = false; developerSpeed = 1; developerFastConstruction = false
        engine.developerFastConstruction = false
        cancelRelocationPreview()
        selectedKind = nil; selectedTile = nil; inspectedBuilding = nil
        centerRequest += 1
    }
    public func loadDeveloperScenario(_ scenario: DeveloperScenario) {
        do {
            let replacement = try scenario.makeEngine(configuration: configuration, now: clock())
            // An explicit scenario reset can recover a damaged developer file while preserving its bytes.
            do { _ = try developerStore.load(configuration: configuration) }
            catch {
                let backup = developerStore.url.appendingPathExtension("invalid-\(UUID().uuidString).bak")
                try FileManager.default.moveItem(at: developerStore.url, to: backup)
            }
            enterDeveloperMode()
            engine = replacement; developerScenario = scenario; originalScenarioState = replacement.state
            resetDeveloperControls()
            message = "Developer · " + scenario.title + ". Normal progress is isolated."
            save()
        } catch { message = error.localizedDescription }
    }
    public func resumeDeveloperSettlement() {
        do {
            guard let state = try developerStore.load(configuration: configuration) else { loadDeveloperScenario(.early); return }
            let replacement = try GameEngine(state: state, configuration: configuration)
            let metadata = try JSONDecoder().decode(DeveloperMetadata.self, from: Data(contentsOf: developerStore.url))
            enterDeveloperMode(); engine = replacement
            developerScenario = metadata.developerScenario ?? .early
            originalScenarioState = metadata.originalScenarioState
            engine.developerRebaseClock(to: clock()); resetDeveloperControls()
            message = "Developer save resumed. Offline simulation is disabled here."
        } catch { message = "Developer save preserved: " + error.localizedDescription }
    }
    public func returnToNormalGame() {
        guard let snapshot = normalSnapshot else { return }
        save()
        engine = snapshot.engine; savesEnabled = snapshot.savesEnabled; persistenceWarning = snapshot.warning
        normalSnapshot = nil; isDeveloperMode = false; resetDeveloperControls()
        message = "Returned to normal settlement."
        resume()
    }
    public func setDeveloperPaused(_ paused: Bool) {
        guard isDeveloperMode else { return }
        advance(to: clock()); developerPaused = paused; save()
    }
    public func setDeveloperSpeed(_ speed: Double) {
        guard isDeveloperMode, [1.0, 2, 5, 10].contains(speed) else { return }
        advance(to: clock()); developerSpeed = speed
    }
    public func setDeveloperFastConstruction(_ enabled: Bool) {
        guard isDeveloperMode else { return }
        developerFastConstruction = enabled; engine.developerFastConstruction = enabled
    }
    public func addDeveloperResources() {
        guard isDeveloperMode else { return }
        perform { engine.developerAddResources(250); message = "Added up to 250 of each resource, within storage limits." }
    }
    public func addDeveloperPopulation() {
        guard isDeveloperMode else { return }
        perform { engine.developerAddPopulation(5); message = "Added up to 5 inhabitants, within housing limits." }
    }
    public func unlockDeveloperTechnology(_ id: String? = nil) {
        guard isDeveloperMode else { return }
        perform {
            for technology in configuration.technologyDefinitions where id == nil || technology.id == id {
                try engine.developerUnlockTechnology(technology.id)
            }
            message = "Developer research granted with prerequisites."
        }
    }
    public func revealDeveloperTerritory() {
        guard isDeveloperMode else { return }
        perform { engine.developerRevealTerritory(); message = "Developer territory revealed." }
    }
    public func advanceDeveloperTime(seconds: Double) {
        guard isDeveloperMode, seconds.isFinite, seconds > 0, seconds <= configuration.offlineCapSeconds else { return }
        advance(to: clock())
        engine.advance(to: engine.state.lastUpdated.addingTimeInterval(seconds))
        engine.developerRebaseClock(to: clock())
        message = "Developer advanced \(Int(seconds)) simulation seconds."
        save()
    }
    #endif

}
