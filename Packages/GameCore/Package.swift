// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "CivilizationCore", platforms: [.iOS(.v18), .macOS(.v14)],
    products: [.library(name: "GameCore", targets: ["GameCore"]), .library(name: "GamePersistence", targets: ["GamePersistence"]), .library(name: "GameApplication", targets: ["GameApplication"])],
    targets: [
        .target(name: "GameCore", resources: [.process("Resources")]),
        .target(name: "GamePersistence", dependencies: ["GameCore"]),
        .target(name: "GameApplication", dependencies: ["GameCore", "GamePersistence"], resources: [.process("Resources")]),
        .testTarget(name: "GameCoreTests", dependencies: ["GameCore", "GamePersistence", "GameApplication"], resources: [.copy("Fixtures")])
    ]
)
