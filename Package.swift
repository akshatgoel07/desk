// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Desk",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "Desk",
            path: "Sources/Desk",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "DeskTests",
            dependencies: ["Desk"],
            path: "Tests/DeskTests",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
