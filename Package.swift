// swift-tools-version:5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KeychainLinux",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "KeychainLinux",
            targets: ["KeychainLinux"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto.git", from: "2.5.0"),
        .package(url: "https://github.com/OperatorFoundation/Gardener", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/KeychainTypes", branch: "main"),
    ],
    targets: [
        .target(
            name: "KeychainLinux",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
                "Gardener",
                "KeychainTypes",
            ]
        ),
        .testTarget(
            name: "KeychainLinuxTests",
            dependencies: ["KeychainLinux"]),
    ],
    swiftLanguageVersions: [.v5]
)
