import Foundation
import CryptoKit
import GameCore
import GamePersistence
import GameApplication

public struct InspectedSave: Encodable, Sendable {
    public let relativePath: String
    public let mapID: String
    public let buildings: Int
    public let roads: Int
    public let sha256: String
    public let operatingRules: String
}

public struct InspectionReport: Encodable, Sendable {
    public let files: [InspectedSave]
    public let registeredGames: Int?
    public let sourceByteIdentical: Bool
}

/// Selects the file's original configuration to avoid the production migration write path.
/// Never calls save, restores a session, applies offline progress, or prints private state.
public enum SaveInspection {
    private static func snapshot(_ root: URL) throws -> [String: Data] {
        let fm = FileManager.default
        guard try root.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey]).isDirectory == true,
              try root.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink != true else {
            throw GameError.invalidSave("Inspection needs a real directory, not an alias.")
        }
        var result: [String: Data] = [:]
        var enumerationError: Error?
        guard let walker = fm.enumerator(at: root, includingPropertiesForKeys: [.isSymbolicLinkKey, .isRegularFileKey],
                                        errorHandler: { _, error in enumerationError = error; return false }) else {
            throw GameError.invalidSave("Unable to enumerate backup.")
        }
        for case let file as URL in walker {
            let values = try file.resourceValues(forKeys: [.isSymbolicLinkKey, .isRegularFileKey])
            guard values.isSymbolicLink != true else { throw GameError.invalidSave("Backup contains an alias; inspection stopped.") }
            if values.isRegularFile == true {
                let normalized = file.standardizedFileURL.resolvingSymlinksInPath()
                guard normalized.path.hasPrefix(root.path + "/") else {
                    throw GameError.invalidSave("Enumerated file is outside the backup root.")
                }
                let relative = String(normalized.path.dropFirst(root.path.count + 1))
                result[relative] = try Data(contentsOf: file)
            }
        }
        if let enumerationError { throw enumerationError }
        return result
    }

    public static func inspect(root input: URL) throws -> InspectionReport {
        guard try input.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink != true else {
            throw GameError.invalidSave("Inspection root cannot be an alias.")
        }
        // Foundation enumeration expands /var and /tmp to /private; use the same root representation.
        let root = input.standardizedFileURL.resolvingSymlinksInPath()
        let original = try snapshot(root)
        let base = try GameConfiguration.bundled()
        var files: [InspectedSave] = []
        for path in original.keys.sorted() {
            let name = URL(fileURLWithPath: path).lastPathComponent
            guard name == "settlement-v1.json" || name == "settlement-v1.json.developer" || name == "settlement-v1.json.review" ||
                    (name.hasPrefix("settlement-v1.json.") && name.hasSuffix(".bak")) else { continue }
            let file = root.appendingPathComponent(path)
            guard let bytes = original[path],
                  let envelope = try JSONSerialization.jsonObject(with: bytes) as? [String: Any],
                  let stateObject = envelope["state"] as? [String: Any],
                  let identity = stateObject["mapID"] as? String else {
                throw GameError.invalidSave("Invalid save envelope: " + path)
            }
            let configuration: GameConfiguration
            switch identity {
            case "river-clearing-v1": configuration = try .legacyDevelopment()
            case "river-clearing-64x48-v1": configuration = base
            case "riverbend-player-64x48-v1": configuration = try .riverbendPlayer()
            case "river-clearing-review-64x48-v1":
                #if DEBUG
                configuration = try DeveloperScenario.grouped.makeEngine(configuration: base, now: Date(timeIntervalSince1970: 1000)).configuration
                #else
                throw GameError.invalidSave("Grouped developer geometry needs the Debug inspector; source preserved.")
                #endif
            default: throw GameError.invalidSave("Unsupported map in " + path)
            }
            let store = SaveStore(url: file)
            let review = name == "settlement-v1.json.review" || name.hasPrefix("settlement-v1.json.review.")
            let developer = name == "settlement-v1.json.developer" || name.hasPrefix("settlement-v1.json.developer.")
            let loaded = try review ? store.loadGameplayReview(configuration: configuration) : developer ? store.load(configuration: configuration) : store.loadNormal(configuration: configuration)
            guard let state = loaded else {
                throw GameError.invalidSave("Save disappeared: " + path)
            }
            _ = try GameEngine(state: state, configuration: configuration)
            files.append(InspectedSave(relativePath: path, mapID: state.mapID, buildings: state.buildings.count,
                                       roads: state.roads?.count ?? 0,
                                       sha256: SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined(),
                                       operatingRules: state.operatingRules?.rawValue ?? "legacy"))
        }
        guard !files.isEmpty else { throw GameError.invalidSave("No recognized saves found.") }
        let store = GameLibraryStore(rootURL: root)
        let index = try store.load()
        if let index {
            for game in index.games {
                let url = try store.saveURL(for: game)
                let relative = String(url.path.dropFirst(root.path.count + 1))
                guard let inspected = files.first(where: { $0.relativePath == relative }) else {
                    throw GameError.invalidSave("Registered game is missing: " + game.id)
                }
                // The library promotes legacy metadata lazily; both production identities may coexist.
                let productionIDs: Set<String> = ["river-clearing-v1", "river-clearing-64x48-v1"]
                let compatible = inspected.mapID == game.mapID || Set([inspected.mapID, game.mapID]) == productionIDs
                guard (productionIDs.contains(game.mapID) && compatible) || (game.mapID == "riverbend-player-64x48-v1" && inspected.mapID == game.mapID) else {
                    throw GameError.invalidSave("Registered game map does not match its save: " + game.id)
                }
            }
        }
        guard try snapshot(root) == original else { throw GameError.invalidSave("Backup changed during validation.") }
        return InspectionReport(files: files, registeredGames: index?.games.count, sourceByteIdentical: true)
    }
}
