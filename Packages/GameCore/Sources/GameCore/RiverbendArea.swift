import Foundation

public extension GameConfiguration {
    /// Ordinary expedition reveals the complete cardinal forest component touching
    /// its target area, together with an open work-face border. No temporary profile.
    func riverbendArea(within radius: Int) -> Set<Tile> {
        var revealed = tiles(within: radius)
        var forest = Set(revealed.filter { map.terrain(at: $0) == .forest })
        for tile in revealed {
            for next in RoadGeometry.neighbors(of: tile).map(\.tile) where map.terrain(at: next) == .forest { forest.insert(next) }
        }
        var queue = Array(forest), index = 0
        while index < queue.count {
            for next in RoadGeometry.neighbors(of: queue[index]).map(\.tile) where map.terrain(at: next) == .forest && forest.insert(next).inserted { queue.append(next) }
            index += 1
        }
        revealed.formUnion(forest)
        for tile in forest {
            for next in RoadGeometry.neighbors(of: tile).map(\.tile) where map.contains(next) { revealed.insert(next) }
        }
        return revealed
    }
}
