// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Toml",
    products: [
        .library(
            name: "Toml",
            targets: ["Toml"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "Toml",
            dependencies: []),
        .testTarget(
            name: "TomlTests",
            dependencies: ["Toml"]),
        ]
)
