// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .define("SPM"),
]

let package = Package(
    name: "WordPress-AztecEditor-iOS",
    platforms: [.iOS(.v11)],
    products: [
        .library(name: "Aztec", targets: ["Aztec"]),
        .library(name: "WordPressEditor", targets: ["WordPressEditor"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Aztec",
            dependencies: [
            ],
            path: "Aztec",
            resources: [
                .process("Assets"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "AztecTests",
            dependencies: ["Aztec"],
            path: "AztecTests",
            resources: [
                .process("Resources"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "WordPressEditor",
            dependencies: [
                "Aztec",
            ],
            path: "WordPressEditor/WordPressEditor",
            resources: [
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "WordPressEditorTests",
            dependencies: [
                "Aztec",
                "WordPressEditor",
            ],
            path: "WordPressEditor/WordPressEditorTests",
            resources: [
                .process("Resources"),
            ],
            swiftSettings: swiftSettings
        )
    ],
    swiftLanguageVersions: [.v5]
)
