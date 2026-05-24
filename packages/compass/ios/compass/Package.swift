// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "compass",
    platforms: [
        .iOS("15.0"),
    ],
    products: [
        .library(name: "compass", targets: ["compass"]),
    ],
    targets: [
        .target(
            name: "compass",
            path: "Sources/compass"
        ),
    ]
)
