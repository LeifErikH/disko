// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Disko",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Disko",
            path: "Sources/Disko",
            swiftSettings: [.enableUpcomingFeature("BareSlashRegexLiterals")]
        )
    ]
)
