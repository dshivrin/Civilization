import Foundation
import Observation
import GameCore
import GamePersistence

@MainActor @Observable
public final class GameSession {
    private var engine: GameEngine
    /// Separate observation identity: resource ticks must not rebuild the scene-owning root.
    public private(set) var mapIdentity: String
    @ObservationIgnored private let store: SaveStore
    #if DEBUG
    private struct DeveloperEnvelope: Encodable {
        let version: Int
        let state: GameState
        let developerScenario: DeveloperScenario
        let originalScenarioState: GameState?
        let isGameplayReview: Bool
    }
    private struct DeveloperMetadata: Decodable, Sendable { let developerScenario: DeveloperScenario?; let originalScenarioState: GameState?; let isGameplayReview: Bool? }
    @ObservationIgnored private let developerStore: SaveStore
    @ObservationIgnored private let reviewStore: SaveStore
    @ObservationIgnored private var activeDeveloperStore: SaveStore { isGameplayReview ? reviewStore : developerStore }
    @ObservationIgnored private var normalSnapshot: (engine: GameEngine, savesEnabled: Bool, warning: String?)?
    public private(set) var isDeveloperMode = false
    public private(set) var isGameplayReview = false
    public var hasGameplayReview: Bool { FileManager.default.fileExists(atPath: reviewStore.url.path) }
    public var developerModeTitle: String { isGameplayReview ? "Review copy" : developerScenario.title }
    private func prepareNormalForGameplayReview() -> Bool {
        guard !isDeveloperMode && !isPreparingDeveloperScenario else {
            message = "Finish preparing or return to normal before opening a review copy."; return false
        }
        guard savesEnabled else { message = "Open a healthy saved game before creating a review copy."; return false }
        if clock() > engine.state.lastUpdated || persistenceWarning != nil { background() }
        guard persistenceWarning == nil else { message = "Save normal progress successfully before opening a review copy."; return false }
        return true
    }
    public func startGameplayReview() {
        if hasGameplayReview { resumeGameplayReview(); return }
        guard prepareNormalForGameplayReview() else { return }
        do {
            // Publish review mode only after the first durable write; failures leave normal mode intact.
            try writeDeveloperState(engine.state, to: reviewStore, review: true, original: nil)
            enterDeveloperMode(advanceNormal: false)
            isGameplayReview = true; originalScenarioState = nil
            lastSaved = clock()
            message = "Review copy created. Time controls and grants affect only this copy."
        } catch {
            persistenceWarning = "Review copy could not be saved: " + error.localizedDescription
            message = persistenceWarning!
        }
    }
    public func resumeGameplayReview() {
        guard prepareNormalForGameplayReview() else { return }
        do {
            guard let saved = try reviewStore.loadGameplayReview(configuration: configuration) else { throw GameError.invalidSave("Review copy is missing.") }
            let replacement = try GameEngine(state: saved, configuration: configuration)
            enterDeveloperMode(advanceNormal: false)
            engine = replacement; mapIdentity = replacement.state.mapID; isGameplayReview = true
            originalScenarioState = nil
            engine.developerRebaseClock(to: clock()); resetDeveloperControls()
            message = "Review copy resumed. Normal progress and developer scenarios stay separate."
        } catch { message = "Review copy preserved: " + error.localizedDescription }
    }
    private func writeDeveloperState(_ state: GameState, to destination: SaveStore, review: Bool, original: GameState?) throws {
        try destination.preservePreviousVersion(beforeSaving: state)
        let data = try JSONEncoder().encode(DeveloperEnvelope(version: state.civicProgress == nil ? 5 : 6, state: state,
            developerScenario: developerScenario, originalScenarioState: original, isGameplayReview: review))
        try FileManager.default.createDirectory(at: destination.url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: destination.url, options: .atomic)
    }
    public private(set) var developerPaused = false
    public private(set) var developerSpeed: Double = 1
    public private(set) var developerFastConstruction = false
    @ObservationIgnored private var originalScenarioState: GameState?
    public func isSelectedDeveloperScenario(_ scenario: DeveloperScenario) -> Bool { isDeveloperMode && !isGameplayReview && developerScenario == scenario }
    public var developerStateDescription: String {
        guard isDeveloperMode else { return "Normal settlement" }
        if isGameplayReview { return "Review copy · normal progress preserved" }
        guard var original = originalScenarioState else { return "Saved developer state · original comparison unavailable" }
        original.lastUpdated = state.lastUpdated
        return original == state ? "Original scenario" : "Modified developer state"
    }
    public private(set) var developerScenario: DeveloperScenario = .early
    public private(set) var isPreparingDeveloperScenario = false
    #endif
    private struct RelocationGridKey: Equatable {
        struct Occupancy: Equatable {
            var id: Int
            var origin: Tile
            var footprint: BuildingFootprint
        }
        var movingID: Int
        var occupied: [Occupancy]
        var roads: [Tile]
        var discovered: Set<Tile>?
    }
    @ObservationIgnored private var relocationGridKey: RelocationGridKey?
    @ObservationIgnored private var cachedRelocationGrid: [Tile: Bool]?
    @ObservationIgnored private var economicPresentationState: GameState?
    @ObservationIgnored private var economicPresentation: EconomicOverview?
    @ObservationIgnored private var guidanceState: GameState?
    @ObservationIgnored private var cachedGuidance: SettlementGuidance?
    @ObservationIgnored private let clock: () -> Date
    @ObservationIgnored private var savesEnabled = true
    @ObservationIgnored private var isActive = true
    @ObservationIgnored private var lastSaved = Date.distantPast
    public var message = "Welcome to Riverbend. Build your first gathering shelter."
    public var persistenceWarning: String?
    public var selectedKind: BuildingKind?
    public internal(set) var roadTool: RoadTool?
    public internal(set) var roadDraft: [Tile] = []
    @ObservationIgnored var roadLastSample: Tile?
    public func roadIssue(at tile: Tile) -> GameError? { engine.roadIssue(at: tile) }
    func commitRoadEdit(at tiles: [Tile], style: RoadStyle?) -> Bool {
        var success = false
        perform { try engine.editRoads(at: tiles, style: style); success = true }
        return success
    }
    public private(set) var movingBuildingID: Int?
    public private(set) var previewOrientation: BuildingOrientation = .north
    public var canRotatePreview: Bool { previewKind.map { configuration.definition($0).resolvedOrientations.count > 1 } ?? false }
    public func rotatePreview() {
        guard let kind = previewKind else { return }
        let choices = configuration.definition(kind).resolvedOrientations
        guard let index = choices.firstIndex(of: previewOrientation), choices.count > 1 else { return }
        previewOrientation = choices[(index + 1) % choices.count]
    }
    public var eraID: String { "stoneAge" }
    public var shouldPauseRendering: Bool { !isActive }
    public var shouldPauseAnimation: Bool {
        #if DEBUG
        return !isActive || (isDeveloperMode && developerPaused)
        #else
        return !isActive
        #endif
    }
    public var isDragMode: Bool { previewKind != nil }
    public var previewKind: BuildingKind? {
        if let id = movingBuildingID { return state.buildings.first { $0.id == id }?.kind }
        return selectedKind
    }
    public func producingBuildingCount(for resource: Resource) -> Int { engine.producingBuildingCount(for: resource) }
    public func productionSources(for resource: Resource) -> [BuildingDefinition] {
        configuration.buildings.filter { definition in
            definition.ratesPerMinute[resource] > 0 || (definition.recipes?.contains { $0.outputsPerMinute[resource] > 0 } ?? false) ||
                (definition.kind == .campfire && (configuration.civicLevels?.contains { $0.culturalOutputPerMinute[resource] > 0 } ?? false))
        }
    }
    public var selectedTile: Tile?
    public var inspectedBuilding: PlacedBuilding?
    public var currentInspection: PlacedBuilding? { state.buildings.first { $0.id == inspectedBuilding?.id && isVisible($0) } }
    public var centerRequest = 0
    public var state: GameState { engine.state }
    public var configuration: GameConfiguration { engine.configuration }
    public var economicOverview: EconomicOverview {
        // Shared across toolbar accessibility, resource details and world effects until state changes.
        if economicPresentationState != engine.state || economicPresentation == nil {
            economicPresentation = engine.economicOverview
            economicPresentationState = engine.state
        }
        return economicPresentation!
    }
    public var rates: ResourceAmounts { economicOverview.net }
    public var grossRates: ResourceAmounts { economicOverview.gross }
    public var consumption: ResourceAmounts { economicOverview.consumption }
    public var capacities: ResourceAmounts { engine.capacities }
    public var growthStatus: GrowthStatus { engine.growthStatus }
    public var growthIntervalSeconds: Double { engine.growthIntervalSeconds }
    public var researchedIDs: Set<String> { engine.researchedIDs }
    public var constructionQueue: [PlacedBuilding] { state.buildings.filter { !$0.isOperational } }
    public var growthRemainingSeconds: Double { max(0, engine.growthIntervalSeconds - (state.populationGrowthSeconds ?? 0)) }
    public func constructionDuration(for kind: BuildingKind) -> Double { engine.constructionDuration(for: kind) }
    public func isUnlocked(_ kind: BuildingKind) -> Bool { engine.isUnlocked(kind) }
    public func researchIssue(_ id: String) -> GameError? { engine.researchIssue(id) }
    public func bootstrapRequirement(for cost: ResourceAmounts, constructing kind: BuildingKind? = nil) -> BuildingKind? {
        engine.bootstrapRequirement(for: cost, constructing: kind)
    }
    public func bootstrapSpendIssue(for cost: ResourceAmounts, constructing kind: BuildingKind? = nil) -> GameError? {
        engine.bootstrapSpendIssue(for: cost, constructing: kind)
    }
    public func upgradeIssue(buildingID: Int) -> GameError? { engine.upgradeIssue(buildingID: buildingID) }

    public var explorationIssue: GameError? { engine.explorationIssue }
    public var discoveredTileCount: Int { engine.discoveredTileCount }
    public var discoveredDeposits: [NaturalDeposit] { engine.discoveredDeposits }
    public func isDiscovered(_ tile: Tile) -> Bool { engine.isDiscovered(tile) }
    public func isVisible(_ building: PlacedBuilding) -> Bool {
        DiscoveryVisibility.isVisible(building, in: configuration, discovered: state.discoveredTiles)
    }
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
        guard let building = state.buildings.first(where: { $0.id == buildingID }), isVisible(building) else { return }
        exitRoadMode()
        cancelRelocationPreview()
        selectedKind = nil
        selectedTile = nil
        inspectedBuilding = building
        message = engine.buildingName(building)
    }
    public var operatingProductionBuildingIDs: Set<Int> { economicOverview.productiveBuildingIDs }
    public func productivity(_ building: PlacedBuilding) -> Double { engine.productivity(building) }
    public func operatingStatus(_ building: PlacedBuilding) -> String { engine.operatingStatus(building) }
    public func buildingName(_ building: PlacedBuilding) -> String { engine.buildingName(building) }
    public func workersRequired(for building: PlacedBuilding) -> Double { engine.workersRequired(for: building) }
    public func civicDefinition(for building: PlacedBuilding) -> CivicLevelDefinition? { engine.civicDefinition(for: building) }
    public func upgradeResearch(for building: PlacedBuilding) -> String? { engine.upgradeResearch(for: building) }
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
    public var nextGuidance: SettlementGuidance {
        if guidanceState != engine.state || cachedGuidance == nil {
            cachedGuidance = engine.settlementGuidance
            guidanceState = engine.state
        }
        return cachedGuidance!
    }
    public var journeyChapters: [JourneyChapter] { engine.journeyChapters }
    public var stoneAgeRequirements: [JourneyObjective] { engine.stoneAgeRequirements }
    public var missingDiscoveryResourceNames: [String] { engine.missingDiscoveryResourceNames }
    public var fullStoneAgeRequirementsMet: Bool { engine.fullStoneAgeRequirementsMet }
    public var currentGoal: Goal? { engine.currentGoal }
    public var pillarGoals: [PillarGoalDefinition] { engine.pillarGoals }
    public func pillarGoalProgress(id: String) -> String { engine.pillarGoalProgress(id: id) }
    public func isPillarGoalComplete(_ id: String) -> Bool { engine.isPillarGoalComplete(id: id) }
    /// The same occupied dimensions used by core validation, including captured relocation geometry.
    public var previewFootprint: BuildingFootprint? {
        if let id = movingBuildingID, let building = state.buildings.first(where: { $0.id == id }) {
            return building.resolvedFootprint(in: configuration).oriented(previewOrientation)
        }
        return selectedKind.map { configuration.definition($0).footprint.oriented(previewOrientation) }
    }
    /// Only known terrain is exposed to the relocation grid; no fog contents leak.
    public var relocationGrid: [Tile: Bool]? {
        guard let id = movingBuildingID else {
            relocationGridKey = nil; cachedRelocationGrid = nil
            return nil
        }
        let key = RelocationGridKey(movingID: id, occupied: state.buildings.map {
            .init(id: $0.id, origin: $0.origin, footprint: $0.occupiedFootprint(in: configuration))
        }, roads: (state.roads ?? []).map(\.tile), discovered: state.discoveredTiles)
        if key == relocationGridKey { return cachedRelocationGrid }
        let tiles = state.discoveredTiles ?? Set((0..<configuration.map.height).flatMap { y in
            (0..<configuration.map.width).map { Tile(x: $0, y: y) }
        })
        let grid = Dictionary(uniqueKeysWithValues: tiles.map { ($0, engine.siteTileIssue(at: $0, excludingBuildingID: id) == nil) })
        relocationGridKey = key; cachedRelocationGrid = grid
        return grid
    }
    public func isPreviewTileAvailable(_ tile: Tile) -> Bool {
        engine.siteTileIssue(at: tile, excludingBuildingID: movingBuildingID) == nil
    }
    /// Only the candidate footprint owns dragging; outside touches pan in every placement mode.
    public func canDragPreview(from tile: Tile) -> Bool {
        guard isDragMode else { return false }
        guard let origin = selectedTile, let footprint = previewFootprint else { return false }
        return footprint.tiles(at: origin).contains(tile)
    }
    public var placementIssue: GameError? {
        if let id = movingBuildingID, let tile = selectedTile { return engine.relocationIssue(buildingID: id, at: tile, orientation: previewOrientation) }
        guard let kind = selectedKind, let tile = selectedTile else { return .placement("Tap open land to choose a location.") }
        return engine.placementIssue(kind, at: tile, orientation: previewOrientation)
    }
    private struct Restoration: Sendable {
        var engine: GameEngine
        var url: URL
        var message: String
        var warning: String?
    }
    /// Read and simulate off the UI thread. Invalid save bytes remain untouched.
    nonisolated private static func restore(now: Date, saveURL: URL?, configuration providedConfiguration: GameConfiguration?, requireExistingSave: Bool = false) throws -> Restoration {
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
            } else if requireExistingSave {
                throw GameError.invalidSave("The registered game file is missing.")
            }
        } catch {
            warning = "Your existing save could not be loaded and has been preserved. This temporary settlement will not overwrite it. \(error.localizedDescription)"
        }
        return Restoration(engine: engine, url: url, message: message, warning: warning)
    }
    public convenience init(clock: @escaping () -> Date = Date.init, saveURL: URL? = nil, configuration: GameConfiguration? = nil) throws {
        self.init(restoration: try Self.restore(now: clock(), saveURL: saveURL, configuration: configuration), clock: clock)
    }
    private init(restoration: Restoration, clock: @escaping () -> Date, saveAfterRestoration: Bool = true) {
        self.clock = clock
        store = SaveStore(url: restoration.url)
        #if DEBUG
        developerStore = SaveStore(url: restoration.url.appendingPathExtension("developer"))
        reviewStore = SaveStore(url: restoration.url.appendingPathExtension("review"))
        #endif
        engine = restoration.engine
        mapIdentity = restoration.engine.state.mapID
        message = restoration.message
        persistenceWarning = restoration.warning
        savesEnabled = restoration.warning == nil
        if savesEnabled && saveAfterRestoration { save() }
    }
    public static func load(clock: @escaping () -> Date = Date.init, saveURL: URL? = nil, configuration: GameConfiguration? = nil, requireExistingSave: Bool = false, saveAfterRestoration: Bool = true) async throws -> GameSession {
        let now = clock()
        let restored = try await Task.detached(priority: .userInitiated) {
            try restore(now: now, saveURL: saveURL, configuration: configuration, requireExistingSave: requireExistingSave)
        }.value
        try Task.checkCancellation()
        let session = GameSession(restoration: restored, clock: clock, saveAfterRestoration: saveAfterRestoration)
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
    public func background() { exitRoadMode(); cancelRelocationPreview(); advance(to: clock()); save() }
    /// A failed regular save blocks a game switch; protected temporary sessions never overwrite their source.
    public func suspendForGameSwitch() throws {
        cancel(); inspectedBuilding = nil
        if isActive { setActive(false) } else { save() }
        if savesEnabled, let warning = persistenceWarning { throw GameError.invalidSave(warning) }
    }
    public func save() {
        guard savesEnabled else { return }
        do {
            #if DEBUG
            if isDeveloperMode {
                try writeDeveloperState(engine.state, to: activeDeveloperStore, review: isGameplayReview, original: originalScenarioState)
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
        exitRoadMode()
        cancelRelocationPreview()
        selectedKind = kind; inspectedBuilding = nil; previewOrientation = .north
        // Offer a valid initial ghost near the current civic entity, including after relocation.
        let center = engine.civicCenter?.origin ?? configuration.map.campfire
        let map = configuration.map
        let candidates = (0..<map.height).flatMap { y in (0..<map.width).map { Tile(x: $0, y: y) } }
            .sorted { abs($0.x - center.x) + abs($0.y - center.y) < abs($1.x - center.x) + abs($1.y - center.y) }
        selectedTile = candidates.first { engine.placementIssue(kind, at: $0) == nil } ?? Tile(x: 13, y: 12)
        message = "Drag the footprint, pan outside it, pinch to zoom · green check confirms."
    }
    public func tap(_ tile: Tile) {
        if roadTool != nil { extendRoadStroke(to: tile); return }
        if selectedKind != nil || movingBuildingID != nil { selectedTile = tile }
        else {
            guard isDiscovered(tile) else { inspectedBuilding = nil; message = "Unexplored terrain · send an expedition to reveal it."; return }
            inspectedBuilding = engine.building(at: tile).flatMap { isVisible($0) ? $0 : nil }
            if let building = inspectedBuilding { message = engine.buildingName(building) }
            else if !isDiscovered(tile) { message = "Unexplored terrain · send an expedition to reveal it." }
            else if configuration.naturalDeposits?.contains(where: { ($0.accessSites ?? []).contains(tile) }) == true { message = "Stone quarry · shared valley stone reserve" }
            else if let terrain = configuration.map.terrain(at: tile) {
                let title = terrain == .clearing ? "Open clearing · buildable ground" : String(describing: terrain).capitalized
                message = "\(title) · tile \(tile.x), \(tile.y)"
            }
        }
    }
    private func cancelRelocationPreview() {
        if movingBuildingID != nil { selectedTile = nil }
        movingBuildingID = nil
    }
    public func beginRelocation(buildingID: Int) {
        guard let building = state.buildings.first(where: { $0.id == buildingID }), isVisible(building) else { return }
        if building.kind == .campfire && configuration.civicLevels == nil { message = "The campfire is the fixed settlement anchor."; return }
        exitRoadMode()
        selectedKind = nil; inspectedBuilding = nil; movingBuildingID = buildingID; selectedTile = building.origin; previewOrientation = building.resolvedOrientation
        message = "Drag the footprint · green check confirms. Relocation is free."
    }
    /// Pointer release only updates the candidate. Confirmation is the sole commit action.
    public func finishDragging() {
        guard isDragMode else { return }
        message = placementIssue?.localizedDescription ?? "Ready · tap the green check to confirm."
    }
    public func finishRelocation() {
        guard let id = movingBuildingID, let tile = selectedTile else { return }
        if let issue = engine.relocationIssue(buildingID: id, at: tile, orientation: previewOrientation) {
            message = "Choose another spot or Cancel. " + issue.localizedDescription
            return
        }
        perform {
            try engine.relocate(buildingID: id, to: tile, orientation: previewOrientation)
            cancelRelocationPreview()
            inspectedBuilding = state.buildings.first { $0.id == id }
            message = "Building moved."
        }
    }
    public func cancel() {
        exitRoadMode()
        cancelRelocationPreview(); selectedKind = nil; selectedTile = nil
        message = "Drag to explore · pinch to zoom · long-press a building to move it"
    }
    public func confirm() {
        if movingBuildingID != nil { finishRelocation(); return }
        guard let kind = selectedKind, let tile = selectedTile else { return }
        perform {
            try engine.build(kind, at: tile, orientation: previewOrientation)
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
        if !stoneAgeWasComplete && state.stoneAgeCompleted == true { message = "Stone Age complete. All requirements are met; keep building in this settlement." }
    }
    public func canAfford(_ costs: ResourceAmounts) -> Bool { engine.canAfford(costs) }
    private func perform(_ action: () throws -> Void) {
        advance(to: clock())
        do { try action(); save() } catch { message = error.localizedDescription }
    }
    #if DEBUG
    private func enterDeveloperMode(advanceNormal: Bool = true) {
        guard !isDeveloperMode else { return }
        // Commands already save their state. Avoid rewriting a normal save when no wall time elapsed.
        if advanceNormal && clock() > engine.state.lastUpdated { background() }
        normalSnapshot = (engine, savesEnabled, persistenceWarning)
        isDeveloperMode = true; savesEnabled = true; persistenceWarning = nil
        resetDeveloperControls()
    }
    private func resetDeveloperControls() {
        exitRoadMode()
        developerPaused = false; developerSpeed = 1; developerFastConstruction = false
        engine.developerFastConstruction = false
        cancelRelocationPreview()
        selectedKind = nil; selectedTile = nil; inspectedBuilding = nil
        centerRequest += 1
    }
    /// Opt-in profiling fixture in unique temporary files; never opens the user's normal/developer stores.
    public static func renderBenchmark(in directory: URL, clock: @escaping () -> Date = Date.init) throws -> GameSession {
        let url = directory.appendingPathComponent("render-benchmark-\(UUID().uuidString).json")
        let session = try GameSession(clock: clock, saveURL: url)
        session.loadDeveloperScenario(.late)
        guard session.isDeveloperMode, session.developerScenario == .late else { throw GameError.invalidSave("Unable to prepare render benchmark") }
        return session
    }
    public func loadDeveloperScenario(_ scenario: DeveloperScenario) {
        guard !isGameplayReview else { message = "Return to normal before selecting a developer scenario."; return }
        do {
            let base = normalSnapshot?.engine.configuration ?? configuration
            let replacement = try scenario.makeEngine(configuration: base, now: clock())
            try installDeveloperScenario(scenario, replacement: replacement)
        } catch { message = error.localizedDescription }
    }
    /// UI preparation stays off the main actor; dismissal cancels publication.
    public func prepareDeveloperScenario(_ scenario: DeveloperScenario) async {
        guard !isGameplayReview else { message = "Return to normal before selecting a developer scenario."; return }
        guard !isPreparingDeveloperScenario else { return }
        isPreparingDeveloperScenario = true
        defer { isPreparingDeveloperScenario = false }
        let base = normalSnapshot?.engine.configuration ?? configuration, now = clock()
        let work = Task.detached(priority: .userInitiated) { try scenario.makeEngine(configuration: base, now: now) }
        do {
            var replacement = try await withTaskCancellationHandler(operation: { try await work.value }, onCancel: { work.cancel() })
            try Task.checkCancellation()
            replacement.developerRebaseClock(to: clock())
            try installDeveloperScenario(scenario, replacement: replacement)
        } catch is CancellationError { }
        catch { message = error.localizedDescription }
    }
    private func installDeveloperScenario(_ scenario: DeveloperScenario, replacement: GameEngine) throws {
            let base = normalSnapshot?.engine.configuration ?? configuration
            // An explicit scenario reset can recover a damaged developer file while preserving its bytes.
            do {
                if FileManager.default.fileExists(atPath: developerStore.url.path) {
                    let metadata = try JSONDecoder().decode(DeveloperMetadata.self, from: Data(contentsOf: developerStore.url))
                    _ = try developerStore.load(configuration: (metadata.developerScenario ?? .early).configuration(from: base))
                }
            }
            catch {
                let backup = developerStore.url.appendingPathExtension("invalid-\(UUID().uuidString).bak")
                try FileManager.default.moveItem(at: developerStore.url, to: backup)
            }
            enterDeveloperMode()
            engine = replacement; mapIdentity = replacement.state.mapID
            developerScenario = scenario; originalScenarioState = replacement.state
            resetDeveloperControls()
            message = "Developer · " + scenario.title + ". Normal progress is isolated."
            save()
    }
    public func prepareResumeDeveloperSettlement() async {
        guard !isGameplayReview else { message = "Return to normal before resuming a developer scenario."; return }
        guard !isPreparingDeveloperScenario else { return }
        guard FileManager.default.fileExists(atPath: developerStore.url.path) else { await prepareDeveloperScenario(.early); return }
        isPreparingDeveloperScenario = true
        defer { isPreparingDeveloperScenario = false }
        let base = normalSnapshot?.engine.configuration ?? configuration, source = developerStore
        let work = Task.detached(priority: .userInitiated) {
            let metadata = try JSONDecoder().decode(DeveloperMetadata.self, from: Data(contentsOf: source.url))
            let config = try (metadata.developerScenario ?? .early).configuration(from: base)
            guard let state = try source.load(configuration: config) else { throw GameError.invalidSave("Developer save is missing") }
            return (try GameEngine(state: state, configuration: config), metadata)
        }
        do {
            let (replacement, metadata) = try await withTaskCancellationHandler(operation: { try await work.value }, onCancel: { work.cancel() })
            try Task.checkCancellation()
            enterDeveloperMode(); engine = replacement; mapIdentity = replacement.state.mapID
            developerScenario = metadata.developerScenario ?? .early; originalScenarioState = metadata.originalScenarioState
            engine.developerRebaseClock(to: clock()); resetDeveloperControls()
            message = "Developer save resumed. Offline simulation is disabled here."
        } catch is CancellationError { }
        catch { message = "Developer save preserved: " + error.localizedDescription }
    }
    public func resumeDeveloperSettlement() {
        guard !isGameplayReview else { message = "Return to normal before resuming a developer scenario."; return }
        do {
            guard FileManager.default.fileExists(atPath: developerStore.url.path) else { loadDeveloperScenario(.early); return }
            let metadata = try JSONDecoder().decode(DeveloperMetadata.self, from: Data(contentsOf: developerStore.url))
            let base = normalSnapshot?.engine.configuration ?? configuration
            let config = try (metadata.developerScenario ?? .early).configuration(from: base)
            guard let state = try developerStore.load(configuration: config) else { return }
            let replacement = try GameEngine(state: state, configuration: config)
            enterDeveloperMode(); engine = replacement; mapIdentity = replacement.state.mapID
            developerScenario = metadata.developerScenario ?? .early
            originalScenarioState = metadata.originalScenarioState
            engine.developerRebaseClock(to: clock()); resetDeveloperControls()
            message = "Developer save resumed. Offline simulation is disabled here."
        } catch { message = "Developer save preserved: " + error.localizedDescription }
    }
    @discardableResult public func returnToNormalGame() -> Bool {
        guard let snapshot = normalSnapshot else { return false }
        save()
        guard persistenceWarning == nil else { message = "Copy could not be saved. Keep this session open and retry before returning to normal."; return false }
        engine = snapshot.engine; mapIdentity = snapshot.engine.state.mapID
        savesEnabled = snapshot.savesEnabled; persistenceWarning = snapshot.warning
        normalSnapshot = nil; isDeveloperMode = false; isGameplayReview = false; resetDeveloperControls()
        message = "Returned to normal settlement."
        resume()
        return true
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
