// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let RESET = false

let package = Package(
    name: "SatelliteGuardKit",
    platforms: [
        .iOS(.v18),
        .tvOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "SatelliteGuardKit", targets: ["SatelliteGuardKit", "SGPersistence", "SGWireGuard"]),
    ],
    dependencies: [
        .package(name: "WireGuard", path: "../WireGuard"),
        .package(url: "https://github.com/rasmuslos/RFKit", branch: "main"),
    ],
    targets: [
        .target(name: "SatelliteGuardKit", dependencies: [
            .byName(name: "SGPersistence"),
            .byName(name: "SGWireGuard"),
        ]),
        .target(name: "SGPersistence", dependencies: [
            .product(name: "WireGuardKit", package: "WireGuard"),
            .product(name: "RFKit", package: "RFKit"),
        ], swiftSettings: RESET ? [.define("RESET")] : []),
        .target(name: "SGWireGuard", dependencies: [
            .target(name: "SGPersistence"),
            .product(name: "WireGuardKit", package: "WireGuard")
        ]),
    ]
)
