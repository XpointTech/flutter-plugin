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
        .binaryTarget(name: "sdk", url: "https://downloads.xpoint.tech/5.7.0.13233/library/macos/sdk.xcframework.zip", checksum: "0c54c3ffee7c7d828ef8d83050c899769da21c036f49d1800241283ce28567cf"),
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
