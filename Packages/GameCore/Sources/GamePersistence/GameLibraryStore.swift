import Foundation
import GameCore

public struct SavedGame: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var createdAt: Date
    public var mapID: String
    public init(id: String, name: String, createdAt: Date, mapID: String) {
        self.id = id; self.name = name; self.createdAt = createdAt; self.mapID = mapID
    }
}

/// Selection metadata is separate from the unchanged v5 game envelopes.
public struct GameLibraryIndex: Codable, Equatable, Sendable {
    public var version: Int = 1
    public var activeGameID: String
    public var games: [SavedGame]
    public init(activeGameID: String, games: [SavedGame]) {
        self.activeGameID = activeGameID; self.games = games
    }
}

public struct GameLibraryStore: Sendable {
    public let rootURL: URL
    public var indexURL: URL { rootURL.appendingPathComponent("games-index.json") }
    public init(rootURL: URL) { self.rootURL = rootURL.standardizedFileURL }

    public func loadOrCreate(mapID: String, now: Date) throws -> GameLibraryIndex {
        if let index = try load() { return index }
        let original = SavedGame(id: "legacy", name: "Original settlement", createdAt: now, mapID: mapID)
        let index = GameLibraryIndex(activeGameID: original.id, games: [original])
        try save(index)
        return index
    }

    public func load() throws -> GameLibraryIndex? {
        try validateDescendant(indexURL)
        guard FileManager.default.fileExists(atPath: indexURL.path) else { return nil }
        do {
            let index = try JSONDecoder().decode(GameLibraryIndex.self, from: Data(contentsOf: indexURL))
            try validate(index)
            return index
        } catch let error as GameError { throw error }
        catch { throw GameError.invalidSave("The saved-game list could not be read. Existing files have been preserved.") }
    }

    public func save(_ index: GameLibraryIndex) throws {
        try validate(index)
        try validateDescendant(indexURL)
        // Never replace an unexpectedly corrupt/unsupported list with a fresh one.
        if FileManager.default.fileExists(atPath: indexURL.path) { _ = try load() }
        let data = try JSONEncoder().encode(index)
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
        try data.write(to: indexURL, options: .atomic)
    }

    public func saveURL(for game: SavedGame) throws -> URL {
        try validate(game)
        let url = game.id == "legacy" ? rootURL.appendingPathComponent("settlement-v1.json") :
            rootURL.appendingPathComponent("games").appendingPathComponent(game.id).appendingPathComponent("settlement-v1.json")
        try validateDescendant(url)
        try validateDescendant(url.appendingPathExtension("developer"))
        return url
    }

    private func validate(_ index: GameLibraryIndex) throws {
        guard index.version == 1, !index.games.isEmpty,
              Set(index.games.map(\.id)).count == index.games.count,
              index.games.contains(where: { $0.id == "legacy" }),
              index.games.contains(where: { $0.id == index.activeGameID }) else {
            throw GameError.invalidSave("Invalid or unsupported saved-game list. Existing files have been preserved.")
        }
        for game in index.games { _ = try saveURL(for: game) }
    }
    private func validate(_ game: SavedGame) throws {
        let validID = game.id == "legacy" || UUID(uuidString: game.id)?.uuidString == game.id
        guard validID, !game.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              game.name.count <= 80, game.name.rangeOfCharacter(from: .controlCharacters) == nil,
              !game.mapID.isEmpty, game.mapID.count <= 128, game.createdAt.timeIntervalSince1970.isFinite else {
            throw GameError.invalidSave("Invalid saved-game identity or description.")
        }
    }
    private func validateDescendant(_ url: URL) throws {
        let root = rootURL.resolvingSymlinksInPath().path
        guard url.resolvingSymlinksInPath().path.hasPrefix(root + "/") else {
            throw GameError.invalidSave("Saved-game paths must stay inside their library.")
        }
        // Reject even within-library aliases so one game's file cannot become another's.
        var componentURL = rootURL
        for component in url.standardizedFileURL.pathComponents.dropFirst(rootURL.pathComponents.count) {
            componentURL.appendPathComponent(component)
            if let attributes = try? FileManager.default.attributesOfItem(atPath: componentURL.path),
               attributes[.type] as? FileAttributeType == .typeSymbolicLink {
                throw GameError.invalidSave("Saved-game aliases are not supported. Existing files have been preserved.")
            }
        }
    }
}
