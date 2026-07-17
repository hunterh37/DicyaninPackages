// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DicyaninSpatialUI",
    platforms: [
        .visionOS(.v1),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "DicyaninSpatialUI",
            targets: ["DicyaninSpatialUI"]),
    ],
    targets: [
        .target(
            name: "DicyaninSpatialUI"),
        .testTarget(
            name: "DicyaninSpatialUITests",
            dependencies: ["DicyaninSpatialUI"]),
    ],
    swiftLanguageModes: [.v5]
)
