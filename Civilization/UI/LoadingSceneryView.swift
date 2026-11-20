import GameApplication
import SwiftUI

/// A fixed, small set of vector layers; no asset decoding, emitters or world state.
struct LoadingSceneryView: View {
    let scene: LoadingScenery
    let animates: Bool
    @State private var epoch = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20, paused: !animates)) { timeline in
            let time = animates ? timeline.date.timeIntervalSince(epoch).truncatingRemainder(dividingBy: 120) : 0
            Canvas { context, size in
                let drawing = LoadingLandscape(size: size, time: time, scene: scene)
                drawing.draw(in: &context)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct LoadingLandscape {
    let size: CGSize
    let time: Double
    let scene: LoadingScenery
    private var width: CGFloat { size.width }
    private var height: CGFloat { size.height }
    private func point(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x * width, y: y * height) }
    private func polygon(_ coordinates: [(Double, Double)]) -> Path {
        Path { path in
            guard let first = coordinates.first else { return }
            path.move(to: point(first.0, first.1))
            for coordinate in coordinates.dropFirst() { path.addLine(to: point(coordinate.0, coordinate.1)) }
            path.closeSubpath()
        }
    }

    func draw(in context: inout GraphicsContext) {
        let bounds = CGRect(origin: .zero, size: size)
        context.fill(Path(bounds), with: .linearGradient(
            Gradient(colors: [Color(red: 0.11, green: 0.25, blue: 0.29), Color(red: 0.69, green: 0.58, blue: 0.39), Color(red: 0.91, green: 0.71, blue: 0.44)]),
            startPoint: .zero, endPoint: point(0, 0.72)))
        let sunCenter = point(0.75, 0.35)
        let radius = min(width * 0.07, height * 0.16)
        context.fill(Path(ellipseIn: CGRect(x: sunCenter.x - radius * 2.6, y: sunCenter.y - radius * 2.6, width: radius * 5.2, height: radius * 5.2)),
                     with: .radialGradient(Gradient(colors: [.orange.opacity(0.25), .clear]), center: sunCenter, startRadius: 0, endRadius: radius * 2.6))
        context.fill(Path(ellipseIn: CGRect(x: sunCenter.x - radius, y: sunCenter.y - radius, width: radius * 2, height: radius * 2)), with: .color(Color(red: 0.97, green: 0.82, blue: 0.54)))

        let mountains: [(Double, Double)] = scene == .mountain
            ? [(0, 0.58), (0.10, 0.34), (0.22, 0.49), (0.40, 0.19), (0.53, 0.40), (0.62, 0.27), (0.78, 0.48), (0.91, 0.33), (1, 0.50), (1, 1), (0, 1)]
            : [(0, 0.58), (0.13, 0.43), (0.25, 0.51), (0.41, 0.39), (0.58, 0.50), (0.74, 0.43), (1, 0.54), (1, 1), (0, 1)]
        context.fill(polygon(mountains), with: .color(Color(red: 0.25, green: 0.36, blue: 0.33)))
        context.fill(polygon([(0, 0.61), (0.14, 0.54), (0.34, 0.63), (0.60, 0.53), (0.76, 0.58), (1, 0.48), (1, 1), (0, 1)]),
                     with: .color(Color(red: 0.18, green: 0.29, blue: 0.23)))
        river(in: &context)
        treeLine(in: &context)
        if scene == .mountain { mountainVillage(in: &context) }
        else {
            shelter(x: 0.18, y: 0.68, scale: 1, in: &context)
            shelter(x: 0.29, y: 0.64, scale: 0.65, in: &context)
            if scene == .river { shelter(x: 0.76, y: 0.64, scale: 0.55, in: &context) }
            fire(x: 0.35, y: 0.72, in: &context)
        }
        birds(in: &context)
        context.fill(polygon([(0, 0.89), (0.13, 0.80), (0.27, 0.90), (0.40, 0.85), (0.57, 0.97), (0.82, 0.90), (1, 0.83), (1, 1), (0, 1)]),
                     with: .color(Color(red: 0.075, green: 0.15, blue: 0.12)))
    }

    private func river(in context: inout GraphicsContext) {
        var path = Path()
        path.move(to: point(0.61, 0.53))
        path.addCurve(to: point(0.60, 1), control1: point(0.88, 0.68), control2: point(0.22, 0.77))
        path.addLine(to: point(0.92, 1))
        path.addCurve(to: point(0.65, 0.53), control1: point(0.48, 0.80), control2: point(0.94, 0.68))
        path.closeSubpath()
        context.fill(path, with: .linearGradient(Gradient(colors: [Color(red: 0.71, green: 0.65, blue: 0.42), Color(red: 0.22, green: 0.43, blue: 0.43)]), startPoint: point(0, 0.5), endPoint: point(0, 1)))
        // Eleven short glints stay in the river. Only opacity and small drift change.
        for index in 0..<11 {
            let row = Double(index)
            let y = 0.56 + row * 0.028
            let x = 0.67 + sin(row * 0.56) * 0.066
            let drift = sin(time * 0.6 + row) * 0.008
            var glint = Path()
            glint.move(to: point(x + drift, y))
            glint.addLine(to: point(x + drift + 0.016 + row * 0.002, y))
            context.stroke(glint, with: .color(.white.opacity(0.13 + 0.09 * (sin(time + row) + 1) / 2)), lineWidth: 1)
        }
        if scene == .river {
            // A small boat is a scenery silhouette, independent of gameplay.
            let bob = sin(time * 1.3) * 0.002
            context.fill(polygon([(0.70, 0.66 + bob), (0.76, 0.66 + bob), (0.75, 0.67 + bob), (0.71, 0.67 + bob)]), with: .color(.black.opacity(0.65)))
        }
    }

    private func treeLine(in context: inout GraphicsContext) {
        for index in 0..<17 {
            let x = Double(index) * 0.063
            if x > 0.57 && x < 0.82 { continue }
            let y = 0.58 + sin(Double(index) * 2.7) * 0.025
            let treeHeight = 0.08 + Double(index % 3) * 0.024
            let foliage = polygon([(x - 0.018, y), (x, y - treeHeight), (x + 0.018, y)])
            context.fill(foliage, with: .color(Color(red: 0.10, green: 0.23, blue: 0.19)))
            var trunk = Path()
            trunk.move(to: point(x, y - 0.01)); trunk.addLine(to: point(x, y + 0.018))
            context.stroke(trunk, with: .color(Color(red: 0.14, green: 0.19, blue: 0.13)), lineWidth: 2)
        }
    }

    private func shelter(x: Double, y: Double, scale: Double, in context: inout GraphicsContext) {
        let roof = polygon([(x - 0.052 * scale, y), (x - 0.005 * scale, y - 0.105 * scale), (x + 0.059 * scale, y)])
        context.fill(roof, with: .linearGradient(Gradient(colors: [Color(red: 0.69, green: 0.52, blue: 0.30), Color(red: 0.37, green: 0.29, blue: 0.17)]), startPoint: point(x, y - 0.1 * scale), endPoint: point(x, y)))
        context.fill(polygon([(x - 0.052 * scale, y), (x - 0.005 * scale, y - 0.105 * scale), (x + 0.007 * scale, y)]), with: .color(.black.opacity(0.22)))
        context.fill(polygon([(x - 0.012 * scale, y), (x + 0.002 * scale, y - 0.048 * scale), (x + 0.017 * scale, y)]), with: .color(.black.opacity(0.7)))
    }

    private func fire(x: Double, y: Double, in context: inout GraphicsContext) {
        let center = point(x, y)
        let glow = CGRect(x: center.x - width * 0.035, y: center.y - height * 0.06, width: width * 0.07, height: height * 0.1)
        context.fill(Path(ellipseIn: glow), with: .radialGradient(Gradient(colors: [.orange.opacity(0.30), .clear]), center: center, startRadius: 0, endRadius: width * 0.035))
        let flicker = 0.033 + sin(time * 4) * 0.004
        context.fill(polygon([(x - 0.008, y), (x - 0.002, y - flicker), (x + 0.004, y - 0.018), (x + 0.010, y)]), with: .color(.orange))
        context.fill(polygon([(x - 0.004, y), (x + 0.001, y - flicker * 0.6), (x + 0.005, y)]), with: .color(.yellow))
        for index in 0..<4 {
            let phase = (time * 0.1 + Double(index) * 0.25).truncatingRemainder(dividingBy: 1)
            let smoke = point(x + phase * 0.016, y - 0.045 - phase * 0.10)
            let diameter = height * (0.009 + phase * 0.022)
            context.fill(Path(ellipseIn: CGRect(x: smoke.x, y: smoke.y, width: diameter, height: diameter)), with: .color(.white.opacity((1 - phase) * 0.09)))
        }
    }

    private func mountainVillage(in context: inout GraphicsContext) {
        context.fill(polygon([(0.14, 0.71), (0.18, 0.57), (0.38, 0.56), (0.44, 0.71)]), with: .color(Color(red: 0.33, green: 0.35, blue: 0.26)))
        shelter(x: 0.23, y: 0.59, scale: 0.65, in: &context)
        shelter(x: 0.32, y: 0.57, scale: 0.5, in: &context)
        // Decorative hill village enclosure; no world object or defense rules.
        for index in 0..<23 {
            let x = 0.16 + Double(index) * 0.011
            let top = 0.615 + sin(Double(index) * 0.25) * 0.012
            context.fill(polygon([(x, top + 0.045), (x, top), (x + 0.0035, top - 0.009), (x + 0.007, top), (x + 0.007, top + 0.045)]), with: .color(Color(red: 0.22, green: 0.21, blue: 0.14)))
        }
        fire(x: 0.28, y: 0.60, in: &context)
    }

    private func birds(in context: inout GraphicsContext) {
        for index in 0..<3 {
            let x = 0.55 + Double(index) * 0.045 + sin(time * 0.12) * 0.025
            let y = 0.28 + Double(index % 2) * 0.035
            let flap = 0.004 + sin(time * 2 + Double(index)) * 0.003
            var bird = Path()
            bird.move(to: point(x - 0.009, y - flap))
            bird.addQuadCurve(to: point(x, y), control: point(x - 0.003, y - flap))
            bird.addQuadCurve(to: point(x + 0.009, y - flap), control: point(x + 0.003, y - flap))
            context.stroke(bird, with: .color(.black.opacity(0.5)), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
        }
    }
}
