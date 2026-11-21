import Foundation
import GameCore

public extension GameLibraryStore {
    /// Only a validated supported primary can correct a stale display identity.
    /// A backup never determines whether a primary is retired or relabeled.
    func reconcilingLargePrimaryLabels(_ index: GameLibraryIndex) throws -> GameLibraryIndex {
        struct Identity: Decodable {
            struct State: Decodable { let mapID: String }
            let state: State
            let profile: String?
            let isGameplayReview: Bool?
            let developerScenario: String?
        }
        var result = index
        for i in result.games.indices where result.games[i].retiredSmallMap != true {
            let url = try saveURL(for: result.games[i])
            guard let data = try? Data(contentsOf: url),
                  let header = try? JSONDecoder().decode(Identity.self, from: data),
                  header.profile == nil, header.isGameplayReview != true, header.developerScenario == nil,
                  ["river-clearing-64x48-v1", "riverbend-player-64x48-v1"].contains(header.state.mapID) else { continue }
            let configuration = try header.state.mapID == "riverbend-player-64x48-v1" ? GameConfiguration.riverbendPlayer() : GameConfiguration.bundled()
            guard let _ = try? SaveStore(url: url).loadNormal(configuration: configuration) else { continue }
            result.games[i].mapID = header.state.mapID
        }
        return result
    }

    /// Classification uses the committed historical configuration and production validator.
    /// Filenames, display names, index labels and guessed coordinate bounds are not evidence.
    func isObsoleteSmallMap(_ url: URL) -> Bool {
        struct Identity: Decodable {
            struct State: Decodable { let mapID: String }
            let state: State
            let profile: String?
            let isGameplayReview: Bool?
            let developerScenario: String?
        }
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              attributes[.type] as? FileAttributeType == .typeRegular,
              let data = try? Data(contentsOf: url), let header = try? JSONDecoder().decode(Identity.self, from: data),
              header.profile == nil, header.isGameplayReview != true, header.developerScenario == nil,
              let old = try? GameConfiguration.legacyDevelopment(), old.map.id == "river-clearing-v1",
              old.map.width == 32, old.map.height == 24, header.state.mapID == old.map.id,
              let loaded = try? SaveStore(url: url).loadNormal(configuration: old), loaded.mapID == old.map.id else { return false }
        return true
    }

    /// Recoverable retirement: keep every source byte, copy/verify the normal file and
    /// its backup siblings, then publish only the index marker. A failed copy or stale
    /// index never hides a game. Partial verified copies can safely be retried.
    func retiringObsoleteSmallMaps(_ index: GameLibraryIndex, publish: Bool = true) throws -> GameLibraryIndex {
        let initial = try load()
        guard initial == index || (initial == nil && index.games.count == 1 && index.games.first?.id == "legacy") else { throw GameError.invalidSave("Saved-game selection changed; retry retirement.") }
        let originalIndexBytes = initial == nil ? nil : try Data(contentsOf: indexURL)
        var updated = index
        var checkedSources: [(URL, Data)] = []
        for i in updated.games.indices where updated.games[i].retiredSmallMap != true {
            let source = try saveURL(for: updated.games[i])
            guard isObsoleteSmallMap(source) else { continue }
            let archive = rootURL.appendingPathComponent("retired-small-maps").appendingPathComponent(updated.games[i].id)
            try validateRetirementPath(archive)
            try FileManager.default.createDirectory(at: archive, withIntermediateDirectories: true)
            let siblings = try FileManager.default.contentsOfDirectory(at: source.deletingLastPathComponent(), includingPropertiesForKeys: nil)
            let files = [source] + siblings.filter { $0.lastPathComponent.hasPrefix(source.lastPathComponent + ".") && $0.lastPathComponent.hasSuffix(".bak") }
            for file in files {
                let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
                guard attributes[.type] as? FileAttributeType == .typeRegular else { throw GameError.invalidSave("Archive source must be a regular file.") }
                let data = try Data(contentsOf: file), target = archive.appendingPathComponent(file.lastPathComponent)
                try preserveRetirementCopy(data, at: target)
                checkedSources.append((file, data))
            }
            if let originalIndexBytes {
                try preserveRetirementCopy(originalIndexBytes, at: archive.appendingPathComponent("library-index-before-retirement.json"))
            } else {
                try preserveRetirementCopy(Data("No library index existed before retirement.\n".utf8), at: archive.appendingPathComponent("library-index-absent.txt"))
            }
            updated.games[i].retiredSmallMap = true
        }
        guard updated != index else { return index }
        guard try load() == initial,
              try originalIndexBytes == (initial == nil ? nil : Data(contentsOf: indexURL)),
              try checkedSources.allSatisfy({ try Data(contentsOf: $0.0) == $0.1 }) else { throw GameError.invalidSave("Archive source changed; original selection preserved.") }
        if publish { try save(updated) }
        return updated
    }
    private func preserveRetirementCopy(_ data: Data, at target: URL) throws {
        try validateRetirementPath(target)
        if !FileManager.default.fileExists(atPath: target.path) { try data.write(to: target, options: .atomic) }
        guard try Data(contentsOf: target) == data else { throw GameError.invalidSave("Archive differs from source; original game preserved.") }
    }
    private func validateRetirementPath(_ url: URL) throws {
        let root = rootURL.standardizedFileURL
        guard url.standardizedFileURL.path.hasPrefix(root.path + "/") else { throw GameError.invalidSave("Archive must remain inside its library.") }
        var current = root
        for part in url.pathComponents.dropFirst(root.pathComponents.count) {
            current.appendPathComponent(part)
            if let a = try? FileManager.default.attributesOfItem(atPath: current.path), a[.type] as? FileAttributeType == .typeSymbolicLink { throw GameError.invalidSave("Archive aliases are unsupported.") }
        }
    }
}
