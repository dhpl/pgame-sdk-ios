// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PGameSDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "PGameSDK", targets: ["PGameSDK"])
    ],
    targets: [
        .binaryTarget(
            name: "PGameSDK",
            path: "PGameSDK.xcframework"
        )
    ]
)
