import Foundation

public struct WorldPoint: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
}
/// Coordinate conversion has no graphics-framework dependency and never changes terrain or occupancy.
public enum MapGeometry {
    public static func point(for tile: Tile) -> WorldPoint {
        WorldPoint(x: Double(tile.x - tile.y) * 32, y: -Double(tile.x + tile.y) * 16)
    }
    public static func tile(at point: WorldPoint) -> Tile {
        Tile(x: Int(floor((point.x / 32 - point.y / 16) / 2 + 0.5)),
             y: Int(floor((-point.y / 16 - point.x / 32) / 2 + 0.5)))
    }
    public static func constrainedCamera(_ point: WorldPoint, width: Int, height: Int) -> WorldPoint {
        // Constrain in logical map space, not the bounding rectangle of its diamond.
        // Keeping the viewport center one tile inside the map guarantees visible ground at every zoom.
        let x = min(Double(width - 2), max(1, (point.x / 32 - point.y / 16) / 2))
        let y = min(Double(height - 2), max(1, (-point.y / 16 - point.x / 32) / 2))
        return WorldPoint(x: (x - y) * 32, y: -(x + y) * 16)
    }
}
