import SpriteKit
import GameCore
#if DEBUG
import GameApplication
#endif

/// Original deterministic vector terrain sources. Geography is read-only; no random simulation state.
@MainActor enum WorldDetails {
    private static func polygon(_ points: [CGPoint], color: UIColor) -> SKShapeNode {
        let path = CGMutablePath();path.addLines(between: points);path.closeSubpath()
        let node = SKShapeNode(path: path);node.fillColor = color;node.strokeColor = .clear;return node
    }
    private static func oval(_ rect: CGRect, color: UIColor) -> SKShapeNode {
        let n = SKShapeNode(ellipseIn: rect);n.fillColor = color;n.strokeColor = .clear;return n
    }
    static func groundTexture(at point: CGPoint, seed: Int, forest: Bool, soil: Bool) -> SKNode {
        let root = SKNode();root.position = point
        for i in 0..<5 {
            let x = CGFloat((seed * 13 + i * 17) % 37 - 18)
            let y = CGFloat((seed * 7 + i * 11) % 13 - 6)
            if abs(x)/32 + abs(y)/16 > 0.82 { continue }
            let color = soil ? UIColor(red: 0.78,green: 0.68,blue: 0.44,alpha: 0.22) : UIColor(red: 0.67,green: 0.72,blue: 0.42,alpha: forest ? 0.15 : 0.28)
            root.addChild(oval(CGRect(x:x,y:y,width:CGFloat(2+i%3),height:1.1),color:color))
        }
        if !soil && seed % 5 == 0 {
            let path=CGMutablePath();path.move(to:CGPoint(x:-3,y:0));path.addLine(to:CGPoint(x:-4,y:5));path.move(to:.zero);path.addLine(to:CGPoint(x:1,y:6));path.move(to:CGPoint(x:2,y:0));path.addLine(to:CGPoint(x:5,y:4))
            let grass=SKShapeNode(path:path);grass.strokeColor=UIColor(red:0.33,green:0.46,blue:0.24,alpha:0.5);grass.lineWidth=0.7;root.addChild(grass)
        }
        return root
    }
    static func tree(seed: Int) -> SKNode {
        let root=SKNode();let h=CGFloat(44+seed%17);let width=CGFloat(30+seed%9)
        root.addChild(oval(CGRect(x:-width*0.58,y:-7,width:width*1.3,height:13),color:.black.withAlphaComponent(0.14)))
        root.addChild(polygon([CGPoint(x:-3,y:0),CGPoint(x:-2,y:h*0.76),CGPoint(x:3,y:h*0.76),CGPoint(x:5,y:0)],color:UIColor(red:0.39,green:0.29,blue:0.18,alpha:1)))
        let dark=UIColor(red:0.23,green:0.36,blue:0.22,alpha:1)
        let middle=UIColor(red:0.33,green:0.46,blue:0.25,alpha:1)
        let light=UIColor(red:0.46,green:0.56,blue:0.31,alpha:1)
        for i in 0..<7 {
            let x=CGFloat((seed+i*13)%25-12);let y=h*0.45+CGFloat((seed+i*7)%20)
            root.addChild(oval(CGRect(x:x-width*0.35,y:y,width:width*0.75,height:width*0.62),color:i%3 == 0 ? dark : middle))
        }
        root.addChild(oval(CGRect(x:-width*0.55,y:h*0.68,width:width*0.64,height:width*0.45),color:light))
        root.addChild(oval(CGRect(x:-width*0.05,y:h*0.79,width:width*0.54,height:width*0.36),color:middle))
        for i in 0..<6 { root.addChild(oval(CGRect(x:CGFloat((seed+i*11)%25-16),y:h*0.7+CGFloat(i%3)*4,width:4,height:2),color:light.withAlphaComponent(0.65))) }
        return root
    }
    static func rocks(seed: Int) -> SKNode {
        let root=SKNode();let h=CGFloat(20+seed%16)
        root.addChild(oval(CGRect(x:-29,y:-8,width:59,height:16),color:.black.withAlphaComponent(0.13)))
        root.addChild(polygon([CGPoint(x:-28,y:0),CGPoint(x:-15,y:h*0.84),CGPoint(x:4,y:h),CGPoint(x:28,y:3),CGPoint(x:12,y:-8)],color:UIColor(red:0.48,green:0.49,blue:0.43,alpha:1)))
        root.addChild(polygon([CGPoint(x:-28,y:0),CGPoint(x:-15,y:h*0.84),CGPoint(x:4,y:h),CGPoint(x:0,y:5)],color:UIColor(red:0.68,green:0.67,blue:0.56,alpha:1)))
        root.addChild(polygon([CGPoint(x:4,y:h),CGPoint(x:28,y:3),CGPoint(x:12,y:-8),CGPoint(x:0,y:5)],color:UIColor(red:0.57,green:0.57,blue:0.49,alpha:1)))
        root.addChild(oval(CGRect(x:-24,y:1,width:13,height:4),color:UIColor(red:0.34,green:0.45,blue:0.27,alpha:0.7)))
        return root
    }
    static func waterEdge(at tile: Tile, configuration: GameConfiguration, discovered: Set<Tile>?) -> SKNode {
        let root=SKNode()
        let edges: [(Tile,CGPoint,CGPoint)] = [
            (Tile(x:tile.x-1,y:tile.y),CGPoint(x:-32,y:0),CGPoint(x:0,y:16)),
            (Tile(x:tile.x,y:tile.y-1),CGPoint(x:0,y:16),CGPoint(x:32,y:0)),
            (Tile(x:tile.x+1,y:tile.y),CGPoint(x:32,y:0),CGPoint(x:0,y:-16)),
            (Tile(x:tile.x,y:tile.y+1),CGPoint(x:0,y:-16),CGPoint(x:-32,y:0))]
        for (neighbor,a,b) in edges where configuration.map.contains(neighbor) && (discovered?.contains(neighbor) ?? true) && configuration.map.terrain(at:neighbor) != .water {
            let p=CGMutablePath();p.move(to:a);p.addLine(to:b)
            let bank=SKShapeNode(path:p);bank.strokeColor=UIColor(red:0.66,green:0.61,blue:0.43,alpha:0.95);bank.lineWidth=5;bank.lineCap = .round;root.addChild(bank)
            let shallows=SKShapeNode(path:p);shallows.strokeColor=UIColor(red:0.62,green:0.78,blue:0.72,alpha:0.45);shallows.lineWidth=1.2;root.addChild(shallows)
            if (tile.x+tile.y)%3 == 0 {
                let reed=CGMutablePath();let center=CGPoint(x:(a.x+b.x)/2,y:(a.y+b.y)/2);reed.move(to:center);reed.addLine(to:CGPoint(x:center.x-2,y:center.y+8));reed.move(to:center);reed.addLine(to:CGPoint(x:center.x+2,y:center.y+11))
                let stalk=SKShapeNode(path:reed);stalk.strokeColor=UIColor(red:0.52,green:0.59,blue:0.30,alpha:0.8);stalk.lineWidth=1;root.addChild(stalk)
            }
        }
        return root
    }
}

#if DEBUG
/// Original procedural comparison; opt-in only, no asset or semantic contact replacement.
@MainActor final class ConstructionReviewNode: SKNode {
    private let timberFrame = SKNode(), walls = SKNode(), roof = SKNode()
    private(set) var phase = ConstructionPresentation.ReviewStage.foundation
    var visibleGroups: (frame: Int, walls: Int, roof: Int) {
        (timberFrame.isHidden ? 0 : 1, walls.isHidden ? 0 : 1, roof.isHidden ? 0 : 1)
    }
    init(footprint: BuildingFootprint) {
        super.init(); name = "constructionReview"
        // Insets stay inside the actual captured footprint; all parts share its existing center.
        let w = CGFloat(footprint.width) * 0.42, h = CGFloat(footprint.height) * 0.42
        func projected(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: (x - y) * 32, y: -(x + y) * 16) }
        let corners = [projected(-w, -h), projected(w, -h), projected(w, h), projected(-w, h)]
        func face(_ points: [CGPoint], _ color: UIColor) -> SKShapeNode {
            let path = CGMutablePath(); path.addLines(between: points); path.closeSubpath()
            let node = SKShapeNode(path: path); node.fillColor = color; node.strokeColor = .clear; return node
        }
        let timber = UIColor(red: 0.55, green: 0.37, blue: 0.20, alpha: 1)
        let soil = face(corners, UIColor(red: 0.52, green: 0.43, blue: 0.28, alpha: 0.7)); addChild(soil)
        for point in corners {
            let peg = SKShapeNode(ellipseOf: CGSize(width: 6, height: 3)); peg.fillColor = .lightGray; peg.strokeColor = .clear
            peg.position = point; addChild(peg)
        }
        for point in corners {
            let post = SKShapeNode(rectOf: CGSize(width: 3, height: 32)); post.fillColor = timber; post.strokeColor = .clear
            post.position = CGPoint(x: point.x, y: point.y + 16); timberFrame.addChild(post)
        }
        let upper = corners.map { CGPoint(x: $0.x, y: $0.y + 32) }
        let beamPath = CGMutablePath(); beamPath.addLines(between: upper); beamPath.closeSubpath()
        let beams = SKShapeNode(path: beamPath); beams.strokeColor = timber; beams.lineWidth = 3; timberFrame.addChild(beams)
        for (a,b) in [(1,2),(2,3)] {
            walls.addChild(face([corners[a], corners[b], upper[b], upper[a]],
                UIColor(red: a == 1 ? 0.64 : 0.75, green: 0.54, blue: 0.32, alpha: 1)))
        }
        let apex = CGPoint(x: 0, y: 60)
        roof.addChild(face([upper[1], upper[2], apex], UIColor(red: 0.65, green: 0.46, blue: 0.23, alpha: 1)))
        roof.addChild(face([upper[2], upper[3], apex], UIColor(red: 0.85, green: 0.65, blue: 0.31, alpha: 1)))
        addChild(walls); addChild(timberFrame); addChild(roof)
        display(ConstructionPresentation(remaining: 1, duration: 1))
    }
    required init?(coder: NSCoder) { fatalError("Programmatic review geometry") }
    func display(_ work: ConstructionPresentation) {
        phase = work.reviewStage
        timberFrame.isHidden = phase == .foundation
        walls.isHidden = phase == .foundation || phase == .frame
        roof.isHidden = phase != .roof
    }
}
#endif
