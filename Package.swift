// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Clicker",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "Clicker", targets: ["Clicker"])],
    targets: [
        .target(name: "ClickerCore"),
        .executableTarget(name: "Clicker", dependencies: ["ClickerCore"]),
        .testTarget(name: "ClickerCoreTests", dependencies: ["ClickerCore"]),
        .testTarget(name: "ClickerTests", dependencies: ["Clicker"])
    ]
)
