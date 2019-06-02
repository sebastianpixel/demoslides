// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Demoslides",
    platforms: [
        .macOS(.v10_12)
    ],
    products: [
        Product.executable(name: "demoslides", targets: ["Demoslides"])
    ],
    dependencies: [
        .package(url: "https://github.com/sebastianpixel/swift-commandlinekit", .branch("master")),
        .package(url: "https://github.com/jpsim/Yams.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "Demoslides",
            dependencies: ["Procedure"]
        ),
        .target(
            name: "Procedure",
            dependencies: ["UI", "Request"]
        ),
        .target(
            name: "UI",
            dependencies: ["Environment"]
        ),
        .target(
            name: "Request",
            dependencies: ["Environment"]
        ),
        .target(name: "Environment",
                dependencies: ["Model", "Yams"]
        ),
        .target(name: "Model",
                dependencies: ["Utils"]
        ),
        .target(
            name: "Utils",
            dependencies: ["CommandLineKit"]
        )
    ],
    swiftLanguageVersions: [.v5]
)
