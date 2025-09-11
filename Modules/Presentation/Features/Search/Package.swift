// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "Search",
    platforms: [
        .macOS(.v10_15), .iOS(.v16)
    ],
    products: [
        .library(
            name: "Search",
            targets: ["Search"]
        ),
        .library(
            name: "SearchMock",
            targets: ["SearchMock"]
        )
        
    ],
    dependencies: [
        .package(path: "../../../Infrastructure/MEGASwift"),
        .package(path: "../../../Infrastructure/MEGAFoundation"),
        .package(path: "../../../Localization/MEGAL10n"),
        .package(path: "../../../UI/MEGASwiftUI"),
        .package(path: "../../../UI/MEGAUIKit"),
        .package(url: "https://github.com/meganz/MEGADesignToken.git", branch: "main"),
        .package(path: "../../../Infrastracture/MEGATest")
    ],
    targets: [
        .target(
            name: "Search",
            dependencies: [
                "MEGASwiftUI",
                "MEGAL10n",
                "MEGASwift",
                "MEGADesignToken",
                "MEGAFoundation",
                "MEGAUIKit"
            ],
            swiftSettings: settings
        ),
        .target(
            name: "SearchMock",
            dependencies: ["Search"],
            swiftSettings: settings
        ),
        .testTarget(
            name: "SearchTests",
            dependencies: [
                "Search", 
                "SearchMock",
                "MEGAUIKit",
                "MEGATest"
            ],
            resources: [
                .process("folder.png"),
                .process("scenery.png")
            ],
            swiftSettings: settings
        )
    ]
)
