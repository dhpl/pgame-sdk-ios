// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PGameSDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "PGameSDK", type: .dynamic, targets: ["PGameSDK"])
    ],
    targets: [
        .target(
            name: "PGameSDK"
        )
    ]
)
