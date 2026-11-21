import GameCore

/// Presentation-only opaque scallops. Inputs are discovery and map bounds, never hidden terrain.
public enum FogBoundary {
    public struct Edge: Equatable, Sendable {
        public let known: Tile
        public let unknown: Tile
        public let radius: Double
    }
    public static func edges(known: Set<Tile>, width: Int, height: Int) -> [Edge] {
        known.sorted { $0.y == $1.y ? $0.x < $1.x : $0.y < $1.y }.flatMap { tile in
            RoadGeometry.neighbors(of: tile).map(\.tile).compactMap { next in
                guard (0..<width).contains(next.x), (0..<height).contains(next.y), !known.contains(next) else { return nil }
                let seed = abs(tile.x * 17 + tile.y * 31 + next.x * 7 + next.y * 11)
                return Edge(known: tile, unknown: next, radius: Double(18 + seed % 9))
            }
        }
    }
}

#if DEBUG
public typealias ReviewFogBoundary = FogBoundary
#endif
