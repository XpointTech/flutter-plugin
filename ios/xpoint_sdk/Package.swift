// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "xpoint_sdk",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "xpoint-sdk", targets: ["xpoint_sdk"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .binaryTarget(name: "XPointSDK", url: "https://downloads.xpoint.tech/XPointSDKXC-5.7.1+13558.zip", checksum: "cd786b88543019f0cc2e4624651ebac886f9693cba99026447a13856a933fa0f"),
        .target(
            name: "xpoint_sdk",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                "XPointSDK"
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
