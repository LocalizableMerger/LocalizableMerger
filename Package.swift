// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "LocalizableMerger",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "localizable-merger", targets: ["localizable-merger"]),
        .library(name: "LocalizableMergerCore", targets: ["LocalizableMergerCore"]),
        .plugin(name: "LocalizableMergerPlugin", targets: ["LocalizableMergerPlugin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.0.0"),
    ],
    targets: [
        .target(
            name: "LocalizableMergerCore",
            dependencies: [.product(name: "Yams", package: "Yams")]
        ),
        .executableTarget(
            name: "localizable-merger",
            dependencies: [
                "LocalizableMergerCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .plugin(
            name: "LocalizableMergerPlugin",
            capability: .command(
                intent: .custom(
                    verb: "merge-localizables",
                    description: "Merge the base .strings files into the target .strings files."
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "LocalizableMerger writes the generated .strings files.")
                ]
            ),
            dependencies: ["localizable-merger"]
        ),
        .testTarget(
            name: "LocalizableMergerCoreTests",
            dependencies: ["LocalizableMergerCore"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
