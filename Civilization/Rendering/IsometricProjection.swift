import CoreGraphics
import GameCore

/// Ground-contact anchor: the center of a logical tile. All ground uses a 2:1 diamond.
enum IsometricProjection {
    static let halfWidth: CGFloat = 32
    static let halfHeight: CGFloat = 16
    static func point(_ tile: Tile) -> CGPoint {
        let point = MapGeometry.point(for: tile)
        return CGPoint(x: point.x, y: point.y)
    }
    static func tile(_ point: CGPoint) -> Tile {
        MapGeometry.tile(at: WorldPoint(x: point.x, y: point.y))
    }
    static func diamond(at point: CGPoint = .zero, width: CGFloat = 64, height: CGFloat = 32) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: point.x, y: point.y + height / 2))
        path.addLine(to: CGPoint(x: point.x + width / 2, y: point.y))
        path.addLine(to: CGPoint(x: point.x, y: point.y - height / 2))
        path.addLine(to: CGPoint(x: point.x - width / 2, y: point.y))
        path.closeSubpath()
        return path
    }
}
