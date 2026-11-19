import SwiftUI
import GameApplication
import GameCore

/// Original scalable object illustration system. No external icon files or modern symbols.
struct EraIcon: View {
    enum Domain { case research, resource, pillar }
    let domain: Domain
    let id: String
    var size: CGFloat = 34
    private var icon: IconVisual? {
        let entries: [IconVisual]?
        switch domain { case .research: entries = EraArt.catalog?.research; case .resource: entries = EraArt.catalog?.resources; case .pillar: entries = EraArt.catalog?.pillars }
        return entries?.first { $0.id == id }
    }
    var body: some View {
        Canvas { context, bounds in
            context.scaleBy(x: bounds.width / 100, y: bounds.height / 100)
            let ink = Color(red: 0.20, green: 0.24, blue: 0.20)
            let straw = Color(red: 0.82, green: 0.67, blue: 0.41)
            let clay = Color(red: 0.72, green: 0.40, blue: 0.26)
            let leaf = Color(red: 0.54, green: 0.66, blue: 0.40)
            let stone = Color(red: 0.69, green: 0.73, blue: 0.66)
            let blue = Color(red: 0.41, green: 0.67, blue: 0.72)
            func ellipse(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ fill: Color) {
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h)), with: .color(fill))
            }
            func line(_ points: [CGPoint], _ color: Color = .brown, _ width: CGFloat = 7) {
                var path = Path(); path.addLines(points); context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
            }
            func poly(_ points: [CGPoint], _ fill: Color) {
                var path = Path(); path.addLines(points); path.closeSubpath(); context.fill(path, with: .color(fill))
                context.stroke(path, with: .color(ink.opacity(0.6)), style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
            }
            func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }
            ellipse(13, 77, 76, 11, .black.opacity(0.16))
            let motif = icon?.motif ?? "rocks"
            switch motif {
            case "storyFire":
                line([p(34,78),p(67,66)], straw, 8); line([p(34,66),p(67,78)], straw, 8)
                poly([p(49,20),p(61,43),p(58,51),p(70,64),p(58,74),p(40,73),p(32,61),p(39,46)], .orange)
                poly([p(49,43),p(57,61),p(51,73),p(42,65)], straw)
                for x in [18.0,75] { ellipse(x-5,37,13,13,stone); ellipse(x-8,54,18,22,stone) }
            case "axe":
                line([p(28,83),p(69,24)], straw, 10)
                poly([p(49,23),p(69,17),p(84,31),p(72,52),p(58,45)], stone)
                line([p(58,31),p(70,40)], ink, 3)
            case "community":
                for (x,y) in [(19.0,42.0),(43,27),(68,42)] { ellipse(x,y,17,18,straw); poly([p(x-3,y+24),p(x+20,y+24),p(x+24,80),p(x-6,80)],leaf) }
            case "spear":
                line([p(24,81),p(76,24)], straw, 7)
                poly([p(66,24),p(84,12),p(82,36)],stone)
                line([p(35,24),p(72,79)],clay,5)
            case "fish":
                ellipse(20,34,50,30,blue); poly([p(63,48),p(85,29),p(83,67)],blue); ellipse(31,42,4,4,ink)
                line([p(17,77),p(41,73),p(66,77),p(86,73)],blue,3)
            case "seedling", "herbs":
                line([p(49,80),p(49,30)],straw,5)
                for (x,y) in [(24.0,45.0),(50,29),(22,62),(50,53)] { ellipse(x,y,28,13,leaf) }
                if motif == "herbs" { line([p(33,79),p(66,79)],clay,10); ellipse(65,18,13,13,clay) }
            case "animal":
                ellipse(26,40,46,32,straw); ellipse(66,30,20,22,stone)
                for x in [34.0,61] { line([p(x,63),p(x-3,81)],ink,6) }; poly([p(70,33),p(68,19),p(78,30)],straw)
            case "hide", "hideFrame", "leather":
                if motif == "hideFrame" { line([p(17,84),p(17,17),p(83,17),p(83,84)],straw,5) }
                poly([p(30,23),p(43,31),p(58,31),p(71,23),p(79,38),p(67,49),p(69,66),p(80,76),p(65,86),p(53,74),p(42,75),p(30,86),p(20,76),p(31,64),p(31,47),p(20,37)], motif == "leather" ? clay : straw)
            case "pot", "preserves":
                poly([p(34,27),p(66,27),p(63,40),p(77,55),p(72,78),p(59,85),p(40,85),p(27,77),p(23,56),p(37,40)],clay)
                ellipse(33,23,34,10,straw); ellipse(39,26,22,5,ink)
                line([p(32,61),p(42,66),p(51,61),p(61,66),p(70,61)],straw,3)
                if motif == "preserves" { ellipse(29,21,41,10,leaf); line([p(48,20),p(52,10)],straw,3) }
            case "basket":
                poly([p(19,43),p(81,43),p(73,83),p(29,83)],straw)
                var handle = Path(); handle.addArc(center:p(50,43),radius:23,startAngle:.degrees(180),endAngle:.degrees(0),clockwise:false); context.stroke(handle,with:.color(straw),lineWidth:6)
                for y in [54.0,65,76] { line([p(25,y),p(76,y)],ink.opacity(0.45),2) }
                for x in [35.0,48,61] { line([p(x,44),p(x+3,81)],ink.opacity(0.35),2) }
            case "timberFrame", "settlement", "lookout":
                let top = motif == "lookout" ? 17.0 : 30
                line([p(25,83),p(25,top+20),p(50,top),p(76,top+20),p(76,83)],straw,6)
                line([p(25,top+20),p(76,top+20)],straw,5)
                if motif != "timberFrame" { poly([p(18,top+23),p(50,top-2),p(84,top+23)],leaf); poly([p(40,84),p(40,60),p(59,60),p(59,84)],ink) }
                else { line([p(25,77),p(74,48)],straw,4); line([p(25,49),p(75,78)],straw,4) }
            case "leafStone":
                poly([p(24,69),p(37,43),p(61,35),p(79,60),p(64,82),p(37,82)],stone)
                ellipse(26,20,40,18,leaf); line([p(35,34),p(62,20)],straw,3)
            case "standingStone":
                poly([p(33,82),p(34,28),p(45,15),p(63,19),p(71,80)],stone)
                line([p(48,34),p(57,45),p(46,56),p(57,67)],ink.opacity(0.65),3)
                ellipse(18,74,14,11,clay); ellipse(75,73,13,12,straw)
            case "cairn", "rocks", "flint":
                for (x,y,w,h) in [(19.0,64.0,30.0,21.0),(44,60,34,26),(34,42,30,23),(45,25,22,21)] {
                    poly([p(x,y+h),p(x-2,y+9),p(x+w*0.4,y),p(x+w,y+6),p(x+w-2,y+h)],motif == "flint" ? ink.opacity(0.9) : stone)
                }
                if motif == "cairn" { ellipse(18,80,65,6,leaf) }
            case "trail":
                var path=Path();path.move(to:p(25,83));path.addCurve(to:p(65,26),control1:p(88,60),control2:p(6,53));context.stroke(path,with:.color(straw),style:StrokeStyle(lineWidth:7,lineCap:.round,dash:[4,8]))
                line([p(64,40),p(64,13)],ink,3);poly([p(65,13),p(84,20),p(65,28)],leaf)
            case "stakes":
                for x in [21.0,40,59,78] { poly([p(x-7,83),p(x-7,31),p(x,18),p(x+7,31),p(x+7,83)],straw) }
                line([p(13,56),p(86,56)],clay,5)
            case "logs":
                for (x,y) in [(19.0,64.0),(39,46),(60,64)] { line([p(x,y),p(x+20,y-13)],straw,18);ellipse(x-9,y-9,18,18,clay);ellipse(x-4,y-4,8,8,straw) }
            case "berries":
                for (x,y) in [(21.0,45.0),(40,59),(62,43),(50,31),(23,65)] { ellipse(x,y,19,19,clay) }; ellipse(30,20,32,13,leaf)
            case "water":
                poly([p(50,13),p(73,47),p(80,65),p(73,81),p(50,88),p(28,81),p(21,65),p(28,47)],blue)
                line([p(33,61),p(36,74),p(46,78)],.white.opacity(0.65),4)
            case "clay":
                for (x,y) in [(20.0,60.0),(38,47),(54,63)] { poly([p(x,y),p(x+19,y-8),p(x+34,y+3),p(x+26,y+20),p(x+4,y+18)],clay) }
            default: ellipse(28,25,45,56,stone)
            }
        }.frame(width: size, height: size).accessibilityHidden(true)
    }
}

struct BuildingThumbnail: View {
    let kind: BuildingKind
    var size: CGFloat = 64
    var body: some View {
        Group {
            if let image = EraArt.thumbnail(kind) { Image(uiImage: image).resizable().scaledToFit() }
            else { EraIcon(domain: .pillar, id: "economy", size: size) }
        }.frame(width: size, height: size).accessibilityHidden(true)
    }
}
