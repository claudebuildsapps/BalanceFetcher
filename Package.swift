// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BalanceFetcher",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "BalanceFetcher", targets: ["BalanceFetcher"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "BalanceFetcher",
            dependencies: [],
            path: "src/BalanceFetcher",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "BalanceFetcherTests",
            dependencies: ["BalanceFetcher"],
            path: "tests/BalanceFetcherTests"
        )
    ]
)