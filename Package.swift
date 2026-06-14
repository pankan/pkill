// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "pkill",
    platforms: [
        .macOS(.v26)
    ],
    targets: [
        .executableTarget(
            name: "pkill",
            path: "Sources/pkill"
        )
    ]
)
