import Foundation
import GameCore

public struct BuildingVisual: Codable, Sendable {
    public var id: String
    public var file: String
    public var thumbnail: String
    public var worldWidth: Double
    public var worldHeight: Double
    public var anchorX: Double
    public var anchorY: Double
}
public struct IconVisual: Codable, Sendable {
    public var id: String
    public var motif: String
    public var tint: String
}
public enum ArtCatalogError: Error, Equatable { case invalid(String) }

/// Visual-only catalog. It never changes authoritative building definitions or encoded game state.
public struct ArtCatalog: Codable, Sendable {
    public var version: Int
    public var direction: String
    public var buildings: [BuildingVisual]
    public var research: [IconVisual]
    public var resources: [IconVisual]
    public var pillars: [IconVisual]
    public static func bundled() throws -> Self {
        guard let url = Bundle.module.url(forResource: "art-catalog", withExtension: "json") else { throw ArtCatalogError.invalid("Missing art catalog") }
        return try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
    }
    public func building(_ kind: BuildingKind) -> BuildingVisual? { buildings.first { $0.id == kind.rawValue } }
    public func validate(configuration: GameConfiguration) throws {
        func require(_ value: Bool, _ message: String) throws { if !value { throw ArtCatalogError.invalid(message) } }
        func safe(_ path: String) -> Bool {
            !path.isEmpty && !path.hasPrefix("/") && !path.contains("..") && !path.contains("\\") && path.hasSuffix(".png")
        }
        try require(version == 1 && !direction.isEmpty, "Unsupported visual catalog")
        try require(Set(buildings.map(\.id)) == Set(configuration.buildings.map { $0.kind.rawValue }) && buildings.count == configuration.buildings.count, "Incomplete or duplicate building art")
        try require(Set(research.map(\.id)) == Set(configuration.technologyDefinitions.map(\.id)) && research.count == configuration.technologyDefinitions.count, "Incomplete or duplicate research icons")
        try require(Set(resources.map(\.id)) == Set(Resource.allCases.map(\.rawValue)) && resources.count == Resource.allCases.count, "Incomplete or duplicate resource icons")
        try require(Set(pillars.map(\.id)) == Set(DevelopmentPillar.allCases.map(\.rawValue)) && pillars.count == DevelopmentPillar.allCases.count, "Incomplete or duplicate pillar icons")
        for visual in buildings {
            try require(safe(visual.file) && safe(visual.thumbnail), "Unsafe asset path")
            try require(visual.anchorX.isFinite && visual.anchorY.isFinite && (0...1).contains(visual.anchorX) && (0...1).contains(visual.anchorY), "Invalid contact anchor")
            try require(visual.worldWidth.isFinite && visual.worldHeight.isFinite && (32...192).contains(visual.worldWidth) && (32...224).contains(visual.worldHeight), "Invalid visual dimensions")
        }
        for icon in research + resources + pillars { try require(!icon.motif.isEmpty && icon.tint.count == 6 && icon.tint.allSatisfy(\.isHexDigit), "Invalid icon identity") }
    }
}

public enum VisualActivityPolicy {
    public static func allowsProduction(isOperational: Bool, productivity: Double, reduceMotion: Bool) -> Bool {
        isOperational && productivity.isFinite && productivity > 0 && !reduceMotion
    }
    public static let maximumSmokeParticles = 12
    public static let maximumWaterRipples = 24
}

/// A small alpha-only hit mask. Coordinates use the image's top-left origin.
public struct SpriteAlphaMask: Sendable {
    public let width: Int
    public let height: Int
    private let alpha: [UInt8]
    public init(width: Int, height: Int, alpha: [UInt8]) throws {
        guard (1...4096).contains(width), (1...4096).contains(height), alpha.count == width * height else { throw ArtCatalogError.invalid("Invalid sprite alpha mask") }
        self.width = width; self.height = height; self.alpha = alpha
    }
    public func contains(normalizedX x: Double, normalizedY y: Double) -> Bool {
        guard x.isFinite, y.isFinite, (0...1).contains(x), (0...1).contains(y) else { return false }
        let column = min(width - 1, Int(x * Double(width)))
        let row = min(height - 1, Int(y * Double(height)))
        return alpha[row * width + column] >= 32
    }
}
