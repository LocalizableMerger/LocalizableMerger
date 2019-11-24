// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "localizable-merger",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(
        url: "https://github.com/behrang/YamlSwift.git",
        from: "3.4.4")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "localizable-merger",
            dependencies: []),
        .testTarget(
            name: "localizable-mergerTests",
            dependencies: ["localizable-merger"]),
    ]
)