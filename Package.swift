// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "mote",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "mote", targets: ["Mote"])
    ],
    targets: [
        .executableTarget(
            name: "Mote",
            path: "Sources/Mote"
        ),
        .testTarget(
            name: "MoteTests",
            dependencies: ["Mote"],
            path: "Tests/MoteTests"
        )
    ]
)
