#if DEBUG
import SpriteKit
import GameApplication
import OSLog
import Darwin

/// Opt-in local diagnostics only; excluded from Release, never uploaded or saved as game state.
@MainActor final class RenderDiagnostics {
    private let enabled = ProcessInfo.processInfo.environment["CIVILIZATION_RENDER_METRICS"] == "1"
    private let start = CACurrentMediaTime()
    private var previous: Double?
    private var window = CACurrentMediaTime()
    private var samples: [Double] = []
    private var firstFrame = true
    private let logger = Logger(subsystem: "com.civilization.seed", category: "render")
    func observe(_ scene: SKScene) {
        guard enabled else { return }
        let now = CACurrentMediaTime()
        if firstFrame { logger.notice("FIRST_SCENE_FRAME_MS \((now-self.start)*1000,privacy:.public)");firstFrame = false }
        if let previous { samples.append(now - previous) }
        previous = now
        guard now - window >= 5, let summary = RenderFrameSummary(samples: samples) else { return }
        var nodes = 0
        scene.enumerateChildNodes(withName: "//*") { _,_ in nodes += 1 }
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count) }
        }
        let memory = result == KERN_SUCCESS ? Double(info.phys_footprint)/1024/1024 : -1
        #if targetEnvironment(simulator)
        let environment = "simulator"
        #else
        let environment = "device"
        #endif
        let line = "RENDER_METRICS environment=\(environment) fps=\(String(format:"%.1f",summary.framesPerSecond)) p95FrameMs=\(String(format:"%.2f",summary.p95Milliseconds)) nodes=\(nodes) memoryMiB=\(String(format:"%.1f",memory)) samples=\(summary.frameCount)"
        logger.notice("\(line,privacy:.public)")
        print(line)
        samples.removeAll(keepingCapacity: true);window = now
    }
}
#endif
