// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "xpoint_sdk",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "xpoint-sdk", targets: ["xpoint_sdk"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .binaryTarget(name: "sdk", url: "https://downloads.xpoint.tech/5.7.1.13558/library/macos/sdk.xcframework.zip", checksum: "9aa6b0c9e964f073e1ef2e388e9d473da92dea0e817270842255930881e3e237"),
        .target(
            name: "xpoint_sdk",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                "sdk"
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
