// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireGuard",
    platforms: [
        .iOS(.v15)
        .tvOS(.v17),
        .macOS(.v12),
    ],
    products: [
        .library(name: "WireGuardKit", targets: ["WireGuardKit"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "WireGuardKit", dependencies: ["WireGuardKitGo", "WireGuardKitC"]),
        .target(name: "WireGuardKitC", dependencies: [], publicHeadersPath: "."),
        .target(name: "WireGuardKitGo", dependencies: [], exclude: ["goruntime-boottime-over-monotonic.diff", "go.mod", "go.sum", "api-apple.go", "Makefile"], publicHeadersPath: ".", linkerSettings: [.linkedLibrary("wg-go")]),
    ]
)
