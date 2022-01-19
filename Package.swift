// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KeychainLinux",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(
            name: "KeychainLinux",
            targets: ["KeychainLinux"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto.git", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "KeychainLinux",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto")]),
        .testTarget(
            name: "KeychainLinuxTests",
            dependencies: ["KeychainLinux"]),
    ],
    swiftLanguageVersions: [.v5]
)
