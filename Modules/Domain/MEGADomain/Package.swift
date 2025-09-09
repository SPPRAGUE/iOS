// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "MEGADomain",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "MEGADomain",
            targets: ["MEGADomain"]),
        .library(
            name: "MEGADomainMock",
            targets: ["MEGADomainMock"])
    ],
    dependencies: [
        .package(path: "../../MEGASharedRepo/MEGASwift"),
        .package(path: "../../MEGASharedRepo/MEGAPreference"),
        .package(path: "../../MEGASharedRepo/MEGAInfrastructure"),
        .package(path: "../../Infrastracture/MEGAFoundation"),
        .package(path: "../../Infrastracture/MEGATest"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "MEGADomain",
            dependencies: ["MEGASwift",
                           "MEGAPreference",
                           "MEGAFoundation",
                           "MEGAInfrastructure",
                           .product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
            ],
            swiftSettings: settings),
        .target(
            name: "MEGADomainMock",
            dependencies: [
                "MEGADomain",
                .product(name: "MEGAInfrastructure", package: "MEGAInfrastructure")
            ],
            swiftSettings: settings),
        .testTarget(
            name: "MEGADomainTests",
            dependencies: ["MEGADomain", "MEGADomainMock", "MEGATest"],
            swiftSettings: settings)
    ],
    swiftLanguageModes: [.v6]
)
