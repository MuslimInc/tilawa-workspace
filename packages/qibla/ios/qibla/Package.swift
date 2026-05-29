// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "qibla",
    platforms: [
        .iOS("15.0"),
    ],
    products: [
        .library(name: "qibla", targets: ["qibla"]),
    ],
    targets: [
        .target(
            name: "qibla",
            path: "Sources/qibla"
        ),
    ]
)
