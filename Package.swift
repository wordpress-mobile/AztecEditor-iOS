// swift-tools-version:5.10

import PackageDescription

let package = Package(
    name: "WordPressAztecEditor",
    platforms: [.iOS(.v11)],
    products: [
        .library(name: "Aztec", targets: ["Aztec"]),
        .library(name: "WordPressEditor", targets: ["WordPressEditor"]),
    ],
    targets: [
        .target(
            name: "Aztec",
            path: "Aztec",
            resources: [.process("Assets")]
        ),
        .testTarget(
            name: "AztecTests",
            dependencies: ["Aztec"],
            path: "AztecTests",
            resources: [.process("Resources")]
        ),
        .target(
            name: "WordPressEditor",
            dependencies: ["Aztec"],
            path: "WordPressEditor/WordPressEditor"
        ),
        .testTarget(
            name: "WordPressEditorTests",
            dependencies: ["Aztec", "WordPressEditor"],
            path: "WordPressEditor/WordPressEditorTests",
            resources: [.process("Resources")]
        )
    ],
    swiftLanguageVersions: [.v5]
)
