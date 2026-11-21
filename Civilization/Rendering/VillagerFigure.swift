import SpriteKit
import GameApplication

/// Shared retained-joint scaffold. Provisional geometry, not a production character atlas.
@MainActor final class VillagerFigure: SKNode {
    let reviewIdentity = UUID().uuidString
    private let directionRoot = SKNode(), torso = SKNode(), head = SKNode()
    private let nose: SKShapeNode, backHair: SKShapeNode
    private let legs = [SKNode(), SKNode()], arms = [SKNode(), SKNode()]
    private let cargo = SKNode()
    private let tunic = SKShapeNode(rectOf: CGSize(width: 6.5, height: 8), cornerRadius: 2)
    private let braid = SKNode()
    private var baseTunic = UIColor.clear
    private(set) var alternateLook = false
    func setAlternateLook(_ value: Bool) {
        alternateLook = value
        tunic.fillColor = value ? UIColor(red: 0.20, green: 0.53, blue: 0.73, alpha: 1) : baseTunic
        braid.isHidden = !value
    }
    private(set) var activity = VisualAgentActivity.idle
    private(set) var facing = VisualAgentFacing.nearRight
    var jointSummary: String {
        String(format: "joints=%.3f,%.3f,%.3f,%.3f,%.3f,%.3f scale=%.3f noseHidden=%d cargo=%d",
            arms[0].zRotation, arms[1].zRotation, legs[0].zRotation, legs[1].zRotation,
            torso.position.y, head.zRotation, directionRoot.xScale, nose.isHidden ? 1 : 0, cargo.isHidden ? 0 : 1)
    }
    init(profile: Int) {
        let index = max(0, profile) % 3
        let skin = UIColor(red: 0.70-Double(index)*0.08, green: 0.48-Double(index)*0.05, blue: 0.30, alpha: 1)
        let hair = UIColor(red: 0.23, green: 0.16, blue: 0.10, alpha: 1)
        nose = SKShapeNode(ellipseOf: CGSize(width: 1.8, height: 1.3))
        backHair = SKShapeNode(ellipseOf: CGSize(width: 5, height: 5.5))
        super.init()
        let shadow = oval(width: 9, height: 4, color: .black.withAlphaComponent(0.18))
        shadow.position.y = -1; addChild(shadow); addChild(directionRoot)
        for (i, leg) in legs.enumerated() {
            leg.position = CGPoint(x: i == 0 ? -1.7 : 1.7, y: 4.8)
            let shape = SKShapeNode(rectOf: CGSize(width: 2, height: 4.8), cornerRadius: 0.7)
            shape.fillColor = skin; shape.strokeColor = .clear; shape.position.y = -2.4
            leg.addChild(shape); directionRoot.addChild(leg)
        }
        directionRoot.addChild(torso)
        let palette: [UIColor] = [UIColor(red: 0.61, green: 0.32, blue: 0.17, alpha: 1),
            UIColor(red: 0.37, green: 0.47, blue: 0.30, alpha: 1), UIColor(red: 0.71, green: 0.57, blue: 0.35, alpha: 1)]
        baseTunic = palette[index]
        tunic.fillColor = palette[index]; tunic.strokeColor = .clear; tunic.position.y = 8; torso.addChild(tunic)
        for (i, arm) in arms.enumerated() {
            arm.position = CGPoint(x: i == 0 ? -3.5 : 3.5, y: 10)
            let shape = SKShapeNode(rectOf: CGSize(width: 1.7, height: 5), cornerRadius: 0.7)
            shape.fillColor = skin; shape.strokeColor = .clear; shape.position.y = -2.5; arm.addChild(shape)
            let hand = oval(width: 2, height: 2, color: skin); hand.position.y = -5; arm.addChild(hand)
            torso.addChild(arm)
        }
        let face = oval(width: 5, height: 5.5, color: skin); head.addChild(face)
        let crown = oval(width: 5.2, height: 2.4, color: hair); crown.position.y = 2.2; head.addChild(crown)
        backHair.fillColor = hair; backHair.strokeColor = .clear; head.addChild(backHair)
        nose.fillColor = skin; nose.strokeColor = .clear; nose.position = CGPoint(x: 2.6, y: -0.4); head.addChild(nose)
        // An attached pale braid changes silhouette while retaining the same head anchor.
        for i in 0..<4 {
            let knot = oval(width: 2.6, height: 2.4, color: UIColor(red: 0.91, green: 0.73, blue: 0.36, alpha: 1))
            knot.position = CGPoint(x: -2.7 - Double(i) * 0.3, y: 1 - Double(i) * 1.7); braid.addChild(knot)
        }
        head.addChild(braid); braid.isHidden = true
        head.position.y = 14; torso.addChild(head)
        for y in [6.5, 8.5] as [CGFloat] {
            let log = SKShapeNode(rectOf: CGSize(width: 9, height: 2), cornerRadius: 1)
            log.fillColor = UIColor(red: 0.37, green: 0.23, blue: 0.12, alpha: 1); log.strokeColor = .clear
            log.position = CGPoint(x: 0, y: y); cargo.addChild(log)
        }
        torso.addChild(cargo)
        display(.sample(activity: .idle, elapsed: 0), activity: .idle, facing: .nearRight)
    }
    required init?(coder: NSCoder) { fatalError("Programmatic provisional figure") }
    private func oval(width: CGFloat, height: CGFloat, color: UIColor) -> SKShapeNode {
        let shape = SKShapeNode(ellipseOf: CGSize(width: width, height: height)); shape.fillColor = color; shape.strokeColor = .clear
        return shape
    }
    func display(_ pose: VisualAgentPose, activity: VisualAgentActivity, facing: VisualAgentFacing) {
        self.activity = activity; self.facing = facing
        directionRoot.xScale = (facing.left ? -1 : 1) * pose.turnScale
        torso.position.y = pose.bodyOffsetY; torso.zRotation = pose.bodyTilt
        head.zRotation = pose.headTilt; nose.isHidden = facing.away; backHair.isHidden = !facing.away
        for (i, angle) in [pose.leftLegAngle, pose.rightLegAngle].enumerated() {
            legs[i].zRotation = angle; legs[i].position.y = 4.8 * cos(angle)
        }
        arms[0].zRotation = pose.leftArmAngle; arms[1].zRotation = pose.rightArmAngle
        cargo.isHidden = !pose.cargoVisible
    }
}
