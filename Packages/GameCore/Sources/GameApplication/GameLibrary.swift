import Foundation
import Observation
import GameCore
import GamePersistence

/// Owns one independent game. New files precede registration; existing targets stay memory-only until selection commits.
@MainActor @Observable
public final class GameLibrary {
    public private(set) var session: GameSession
    public private(set) var index: GameLibraryIndex
    public private(set) var isBusy = false
    public var games: [SavedGame] { index.games.filter { $0.retiredSmallMap != true } }
    public var archivedSmallGames: [SavedGame] { index.games.filter { $0.retiredSmallMap == true } }
    public var activeGameID: String { index.activeGameID }
    @ObservationIgnored private let store: GameLibraryStore
    @ObservationIgnored private let configuration: GameConfiguration
    @ObservationIgnored private let clock: () -> Date
    @ObservationIgnored private var desiredActive = false

    private init(session: GameSession, index: GameLibraryIndex, store: GameLibraryStore,
                 configuration: GameConfiguration, clock: @escaping () -> Date) {
        self.session = session; self.index = index; self.store = store
        self.configuration = configuration; self.clock = clock
    }

    public static func load(rootURL: URL? = nil, clock: @escaping () -> Date = Date.init,
                            configuration providedConfiguration: GameConfiguration? = nil, selectedGameID: String? = nil) async throws -> GameLibrary {
        var configuration = try providedConfiguration ?? GameConfiguration.bundled()
        let store = GameLibraryStore(rootURL: try resolvedRoot(rootURL))
        let existing = try await Task.detached { try store.load() }.value
        let original = SavedGame(id: "legacy", name: "Original settlement", createdAt: clock(), mapID: configuration.map.id)
        var index = existing ?? GameLibraryIndex(activeGameID: original.id, games: [original])
        if providedConfiguration == nil {
            index = try store.reconcilingLargePrimaryLabels(store.retiringObsoleteSmallMaps(index, publish: existing != nil))
            if index.games.first(where: { $0.id == index.activeGameID })?.retiredSmallMap == true {
                guard let available = index.games.first(where: { $0.retiredSmallMap != true }) else { throw GameError.invalidSave("Old small-map games are archived. Start a new Riverbend campaign.") }
                index.activeGameID = available.id
            }
        }
        if let selectedGameID {
            guard existing != nil, index.games.contains(where: { $0.id == selectedGameID && $0.retiredSmallMap != true }) else {
                throw GameError.invalidSave("The requested saved game is unavailable.")
            }
            index.activeGameID = selectedGameID
        }
        guard let selected = index.games.first(where: { $0.id == index.activeGameID }) else {
            throw GameError.invalidSave("The selected game is unavailable.")
        }
        if providedConfiguration == nil && selected.mapID == "riverbend-player-64x48-v1" { configuration = try .riverbendPlayer() }
        guard selected.mapID == configuration.map.id else {
            throw GameError.invalidSave("The selected game's map is not supported.")
        }
        let url = try store.saveURL(for: selected)
        // Register only after the first save exists. A corrupt legacy file retains its protected temporary mode.
        let session = try await GameSession.load(clock: clock, saveURL: url, configuration: configuration,
                                                 requireExistingSave: existing != nil, saveAfterRestoration: existing == nil)
        if session.persistenceWarning != nil,
           selected.id != "legacy" || !FileManager.default.fileExists(atPath: url.path) {
            throw GameError.invalidSave("The selected game could not be opened. Existing files have been preserved.")
        }
        try Task.checkCancellation()
        if existing != index { try store.save(index) }
        return GameLibrary(session: session, index: index, store: store, configuration: configuration, clock: clock)
    }

    /// Reads entry availability without restoring, advancing, migrating or writing any game.
    public static func hasSavedGame(rootURL: URL? = nil) throws -> Bool {
        let store = GameLibraryStore(rootURL: try resolvedRoot(rootURL))
        if let index = try store.load() {
            return try index.games.contains { game in
                guard game.retiredSmallMap != true else { return false }
                let url = try store.saveURL(for: game)
                return !store.isObsoleteSmallMap(url)
            }
        }
        let original = SavedGame(id: "legacy", name: "Original settlement", createdAt: Date(), mapID: "entry")
        let url = try store.saveURL(for: original)
        return FileManager.default.fileExists(atPath: url.path) && !store.isObsoleteSmallMap(url)
    }

    /// Starts separately without opening the previous selection, even when that game is damaged.
    public static func startNewGame(rootURL: URL? = nil, clock: @escaping () -> Date = Date.init) async throws -> GameLibrary {
        let configuration = try GameConfiguration.riverbendPlayer()
        let store = GameLibraryStore(rootURL: try resolvedRoot(rootURL))
        let loaded = try store.load()
        var original = SavedGame(id: "legacy", name: "Original settlement", createdAt: clock(), mapID: configuration.map.id)
        let originalExists = FileManager.default.fileExists(atPath: try store.saveURL(for: original).path)
        var existing = loaded
        if let loaded {
            existing = try store.reconcilingLargePrimaryLabels(store.retiringObsoleteSmallMaps(loaded))
        } else if originalExists {
            original.mapID = try GameConfiguration.bundled().map.id
            let unindexed = GameLibraryIndex(activeGameID: original.id, games: [original])
            // Archive before creating a new slot or publishing any selection/label.
            existing = try store.reconcilingLargePrimaryLabels(store.retiringObsoleteSmallMaps(unindexed, publish: false))
        }
        let game = existing == nil && !originalExists ? original :
            SavedGame(id: UUID().uuidString, name: "Settlement \((existing?.games.count ?? 1) + 1)", createdAt: clock(), mapID: configuration.map.id)
        let url = try store.saveURL(for: game)
        guard !FileManager.default.fileExists(atPath: url.path) else {
            throw GameError.invalidSave("This game already exists. Existing progress has been preserved.")
        }
        let session = try await GameSession.load(clock: clock, saveURL: url, configuration: configuration)
        if let warning = session.persistenceWarning { throw GameError.invalidSave(warning) }
        try Task.checkCancellation()
        var preservedOriginal = original
        if originalExists { preservedOriginal.mapID = try GameConfiguration.bundled().map.id }
        var index = existing ?? GameLibraryIndex(activeGameID: original.id, games: [preservedOriginal])
        if game.id != original.id { index.games.append(game) }
        index.activeGameID = game.id
        try store.save(index)
        return GameLibrary(session: session, index: index, store: store, configuration: configuration, clock: clock)
    }

    /// A valid index can offer explicit recovery choices without loading or changing any game.
    public static func availableGames(rootURL: URL? = nil) throws -> [SavedGame] {
        try GameLibraryStore(rootURL: resolvedRoot(rootURL)).load()?.games.filter { $0.retiredSmallMap != true } ?? []
    }
    private static func resolvedRoot(_ rootURL: URL?) throws -> URL {
        try rootURL ?? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                               appropriateFor: nil, create: true).appendingPathComponent("Civilization")
    }

    public func setActive(_ active: Bool) {
        desiredActive = active
        if !isBusy { session.setActive(active) }
    }

    public func openGame(id: String) async throws {
        try checkCanSwitch()
        guard id != activeGameID else { return }
        guard let game = games.first(where: { $0.id == id }) else {
            throw GameError.invalidSave("This game or its map is unavailable.")
        }
        isBusy = true
        defer { isBusy = false; session.setActive(desiredActive) }
        try session.suspendForGameSwitch()
        let url = try store.saveURL(for: game)
        let targetConfiguration = try game.mapID == "riverbend-player-64x48-v1" ? GameConfiguration.riverbendPlayer() : GameConfiguration.bundled()
        guard targetConfiguration.map.id == game.mapID else { throw GameError.invalidSave("This saved game has an unsupported map.") }
        let candidate = try await GameSession.load(clock: clock, saveURL: url, configuration: targetConfiguration, requireExistingSave: true, saveAfterRestoration: false)
        if candidate.persistenceWarning != nil { throw GameError.invalidSave("This game could not be opened. Existing files have been preserved.") }
        try Task.checkCancellation()
        var updated = index; updated.activeGameID = id
        try store.save(updated)
        index = updated; session = candidate
    }

    @discardableResult public func createGame(name: String?) async throws -> SavedGame {
        try checkCanSwitch()
        let configuration = try GameConfiguration.riverbendPlayer()
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let game = SavedGame(id: UUID().uuidString, name: trimmed.isEmpty ? "Settlement \(games.count + 1)" : trimmed,
                             createdAt: clock(), mapID: configuration.map.id)
        let url = try store.saveURL(for: game)
        guard !FileManager.default.fileExists(atPath: url.path) else { throw GameError.invalidSave("This game identity already exists.") }
        isBusy = true
        defer { isBusy = false; session.setActive(desiredActive) }
        try session.suspendForGameSwitch()
        let candidate = try await GameSession.load(clock: clock, saveURL: url, configuration: configuration)
        if let warning = candidate.persistenceWarning { throw GameError.invalidSave(warning) }
        try Task.checkCancellation()
        var updated = index; updated.games.append(game); updated.activeGameID = game.id
        try store.save(updated)
        index = updated; session = candidate
        return game
    }

    private func checkCanSwitch() throws {
        guard !isBusy else { throw GameError.invalidSave("Another game is already opening.") }
        #if DEBUG
        guard !session.isDeveloperMode else { throw GameError.invalidSave("Return to the normal settlement before managing saved games.") }
        #endif
    }
}
