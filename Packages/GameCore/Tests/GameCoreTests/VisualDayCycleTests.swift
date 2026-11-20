import Testing
import GameApplication

// Catch broken interpolation, excessive darkness and invalid input propagation.
@Test func visualDayLightingInterpolatesContinuouslyAndWraps() {
    let dusk = VisualLighting.sample(cycleFraction: 0.25)
    let halfway = VisualLighting.sample(cycleFraction: 0.375)
    let night = VisualLighting.sample(cycleFraction: 0.5)
    #expect(abs(dusk.opacity - 0.10) < 0.000001)
    #expect(abs(halfway.opacity - 0.15) < 0.000001)
    #expect(abs(night.opacity - 0.20) < 0.000001)
    #expect(VisualLighting.sample(cycleFraction: 1) == VisualLighting.sample(cycleFraction: 0))
    #expect(VisualLighting.sample(cycleFraction: -0.5) == night)
    for index in 0...1000 {
        let light = VisualLighting.sample(cycleFraction: Double(index) / 1000)
        #expect((0...0.20).contains(light.opacity))
        #expect([light.red, light.green, light.blue].allSatisfy { $0.isFinite && (0...1).contains($0) })
    }
    #expect(VisualLighting.sample(cycleFraction: .nan) == VisualLighting.sample(cycleFraction: 0))
}

// Catch using a wall-clock jump or background interval as elapsed presentation time.
@Test func visualDayCycleSuspensionDoesNotCatchUp() {
    var cycle = VisualDayCycle(duration: 10)
    cycle.tick(timestamp: 1, animates: true)
    cycle.tick(timestamp: 1.1, animates: true)
    #expect(abs(cycle.fraction - 0.01) < 0.000001)
    cycle.tick(timestamp: 2, animates: false)
    cycle.tick(timestamp: 1000, animates: true)
    #expect(abs(cycle.fraction - 0.01) < 0.000001)
    cycle.tick(timestamp: 1000.1, animates: true)
    #expect(abs(cycle.fraction - 0.02) < 0.000001)
    cycle.suspend()
    cycle.tick(timestamp: 2000, animates: true)
    #expect(abs(cycle.fraction - 0.02) < 0.000001)
}

// Catch regressions/nonfinite timestamps poisoning the next frame or unbounded dt.
@Test func visualDayCycleRejectsBadTimeAndClampsStalls() {
    var cycle = VisualDayCycle(duration: 10)
    cycle.tick(timestamp: 5, animates: true)
    cycle.tick(timestamp: 100, animates: true)
    #expect(abs(cycle.fraction - 0.01) < 0.000001)
    cycle.tick(timestamp: .nan, animates: true)
    cycle.tick(timestamp: 200, animates: true)
    cycle.tick(timestamp: 199, animates: true)
    cycle.tick(timestamp: .infinity, animates: true)
    #expect(abs(cycle.fraction - 0.01) < 0.000001)
    cycle.tick(timestamp: 300, animates: true)
    cycle.tick(timestamp: 300.1, animates: true)
    #expect(abs(cycle.fraction - 0.02) < 0.000001)
}

// Catch static/reduced-power updates advancing or selection retaining stale elapsed time.
@Test func visualDayCycleManualSelectionAndFrozenFramesAreDeterministic() {
    var cycle = VisualDayCycle(duration: 1)
    cycle.select(.night)
    cycle.tick(timestamp: 0, animates: false)
    cycle.tick(timestamp: 100, animates: false)
    #expect(cycle.fraction == 0.5)
    cycle.tick(timestamp: 101, animates: true)
    #expect(cycle.fraction == 0.5)
    cycle.tick(timestamp: 101.1, animates: true)
    #expect(abs(cycle.fraction - 0.6) < 0.000001)
    cycle.select(.dawn)
    #expect(cycle.fraction == 0.75)
    cycle.tick(timestamp: 500, animates: true)
    #expect(cycle.fraction == 0.75)
    for index in 1...5 { cycle.tick(timestamp: 500 + Double(index) * 0.1, animates: true) }
    #expect(abs(cycle.fraction - 0.25) < 0.000001)
    var fallback = VisualDayCycle(duration: 0)
    fallback.tick(timestamp: 0, animates: true)
    fallback.tick(timestamp: 0.1, animates: true)
    #expect(fallback.fraction.isFinite && fallback.fraction > 0 && fallback.fraction < 1)
}
