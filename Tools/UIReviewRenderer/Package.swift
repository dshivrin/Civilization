// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "UIReviewRenderer", platforms: [.macOS(.v14)],
    dependencies: [.package(path: "../../Packages/GameCore")],
    targets: [.executableTarget(name: "UIReviewRenderer", dependencies: [.product(name: "GameCore", package: "GameCore"), .product(name: "GameApplication", package: "GameCore")])])
