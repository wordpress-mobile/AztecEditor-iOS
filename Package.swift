// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WordPress-AztecEditor-iOS",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "Aztec", targets: ["Aztec"]),
        .library(name: "HTMLParser", targets: ["HTMLParser"]),
        .library(name: "WordPressEditor", targets: ["WordPressEditor"]),
    ],
    targets: [
        .target(
            name: "Aztec",
            dependencies: ["HTMLParser"],
            resources: [.process("Assets")]
        ),
        .testTarget(
            name: "AztecTests",
            dependencies: ["Aztec"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "HTMLParser"
        ),
        .testTarget(
            name: "HTMLParserTests",
            dependencies: ["HTMLParser"]
        ),
        .target(
            name: "WordPressEditor",
            dependencies: ["Aztec"]
        ),
        .testTarget(
            name: "WordPressEditorTests",
            dependencies: [
                "Aztec",
                "WordPressEditor",
            ],
            resources: [
                .process("Resources"),
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)
