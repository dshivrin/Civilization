import Testing
import GameCore

@Test func projectionRoundtripsEveryMapTile() {
    for y in 0..<24 {
        for x in 0..<32 {
            let tile = Tile(x: x, y: y)
            #expect(MapGeometry.tile(at: MapGeometry.point(for: tile)) == tile)
        }
    }
}
@Test func cameraCannotLeaveMapDiamond() {
    for x in stride(from: -2000.0, through: 2000.0, by: 100) {
        for y in stride(from: -2000.0, through: 2000.0, by: 100) {
            let constrained = MapGeometry.constrainedCamera(WorldPoint(x: x, y: y), width: 32, height: 24)
            let tile = MapGeometry.tile(at: constrained)
            #expect((1...30).contains(tile.x) && (1...22).contains(tile.y))
        }
    }
}
