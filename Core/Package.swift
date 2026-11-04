// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpeedTalkCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SpeedTalkCore", targets: ["SpeedTalkCore"])
    ],
    targets: [
        .target(
            name: "SpeedTalkCore",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "SpeedTalkCoreTests",
            dependencies: ["SpeedTalkCore"]
        )
    ]
)
