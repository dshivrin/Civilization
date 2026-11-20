import Foundation
import Darwin
import SaveInspection

// SwiftPM resolves GameCore/GameApplication resources; no copied binaries/bundle setup needed.
guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("Usage: SaveInspector <local-save-directory>\n".utf8))
    exit(2)
}
do {
    let report = try SaveInspection.inspect(root: URL(fileURLWithPath: CommandLine.arguments[1]))
    let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    FileHandle.standardOutput.write(try encoder.encode(report))
    FileHandle.standardOutput.write(Data("\n".utf8))
} catch {
    FileHandle.standardError.write(Data(("Validation failed: " + error.localizedDescription + "\n").utf8))
    exit(1)
}
