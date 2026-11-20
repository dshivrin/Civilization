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
    public var games: [SavedGame] { index.games }
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
        let configuration = try providedConfiguration ?? GameConfiguration.bundled()
        let store = GameLibraryStore(rootURL: try resolvedRoot(rootURL))
        let existing = try await Task.detached { try store.load() }.value
        let original = SavedGame(id: "legacy", name: "Original settlement", createdAt: clock(), mapID: configuration.map.id)
        var index = existing ?? GameLibraryIndex(activeGameID: original.id, games: [original])
        if let selectedGameID {
            guard existing != nil, index.games.contains(where: { $0.id == selectedGameID }) else {
                throw GameError.invalidSave("The requested saved game is unavailable.")
            }
            index.activeGameID = selectedGameID
        }
        guard let selected = index.games.first(where: { $0.id == index.activeGameID }), selected.mapID == configuration.map.id else {
            throw GameError.invalidSave("The selected game's map is not supported.")
        }
        let url = try store.saveURL(for: selected)
        // Register only after the first save exists. A corrupt legacy file retains its protected temporary mode.
        let session = try await GameSession.load(clock: clock, saveURL: url, configuration: configuration,
                                                 requireExistingSave: existing != nil, saveAfterRestoration: existing == nil)
        if let warning = session.persistenceWarning,
           selected.id != "legacy" || !FileManager.default.fileExists(atPath: url.path) {
            throw GameError.invalidSave(warning)
        }
        try Task.checkCancellation()
        if existing == nil || index.activeGameID != existing?.activeGameID { try store.save(index) }
        return GameLibrary(session: session, index: index, store: store, configuration: configuration, clock: clock)
    }

    /// A valid index can offer explicit recovery choices without loading or changing any game.
    public static func availableGames(rootURL: URL? = nil) throws -> [SavedGame] {
        try GameLibraryStore(rootURL: resolvedRoot(rootURL)).load()?.games ?? []
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
        guard let game = games.first(where: { $0.id == id }), game.mapID == configuration.map.id else {
            throw GameError.invalidSave("This game or its map is unavailable.")
        }
        isBusy = true
        defer { isBusy = false; session.setActive(desiredActive) }
        try session.suspendForGameSwitch()
        let url = try store.saveURL(for: game)
        let candidate = try await GameSession.load(clock: clock, saveURL: url, configuration: configuration, requireExistingSave: true, saveAfterRestoration: false)
        if let warning = candidate.persistenceWarning { throw GameError.invalidSave(warning) }
        try Task.checkCancellation()
        var updated = index; updated.activeGameID = id
        try store.save(updated)
        index = updated; session = candidate
    }

    @discardableResult public func createGame(name: String?) async throws -> SavedGame {
        try checkCanSwitch()
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
