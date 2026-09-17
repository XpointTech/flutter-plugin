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
        .binaryTarget(name: "XPointSDK", url: "https://downloads.xpoint.tech/XPointSDKXC-5.7.0+13233.zip", checksum: "c2bced540a856f94389713ed886f937160a619426803b0ef5a3e23da3ebab537"),
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
