// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "MEGASwiftUI",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "MEGASwiftUI",
            targets: ["MEGASwiftUI"]),
        .library(
            name: "MEGASwiftUIMock",
            targets: ["MEGASwiftUIMock"])
    ],
    dependencies: [
        .package(url: "https://github.com/meganz/MEGADesignToken.git", branch: "main"),
        .package(path: "../MEGAUI"),
        .package(path: "../../../Presentation/MEGAL10n"),
        .package(path: "../../Presentation/MEGAAppPresentation"),
        .package(path: "../../Infrastracture/MEGAFoundation"),
        .package(path: "../../Infrastracture/MEGATest")
    ],
    targets: [
        .target(
            name: "MEGASwiftUI",
            dependencies: [
                "MEGAUI",
                "MEGAAppPresentation",
                "MEGAFoundation",
                "MEGAL10n",
                "MEGADesignToken"
            ],
            swiftSettings: settings
        ),
        .target(
            name: "MEGASwiftUIMock",
            dependencies: ["MEGASwiftUI", "MEGAFoundation"],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]),
        .testTarget(
            name: "MEGASwiftUITests",
            dependencies: ["MEGASwiftUI",
                           "MEGASwiftUIMock",
                           "MEGAL10n",
                           "MEGATest"
                          ],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")])
    ],
    swiftLanguageModes: [.v6]
)
