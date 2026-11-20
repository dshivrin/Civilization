// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CivilizationSaveInspector",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "SaveInspector", targets: ["SaveInspector"])],
    dependencies: [.package(path: "../../Packages/GameCore")],
    targets: [
        .target(name: "SaveInspection", dependencies: [
            .product(name: "GameCore", package: "GameCore"),
            .product(name: "GamePersistence", package: "GameCore"),
            .product(name: "GameApplication", package: "GameCore")]),
        .executableTarget(name: "SaveInspector", dependencies: ["SaveInspection"]),
        .testTarget(name: "SaveInspectionTests", dependencies: ["SaveInspection",
            .product(name: "GameCore", package: "GameCore"),
            .product(name: "GamePersistence", package: "GameCore"),
            .product(name: "GameApplication", package: "GameCore")])
    ]
)
