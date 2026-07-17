// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DicyaninMetaballs",
    platforms: [
        .visionOS(.v2),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "DicyaninMetaballs",
            targets: ["DicyaninMetaballs"]
        )
    ],
    targets: [
        .target(
            name: "DicyaninMetaballs",
            resources: [
                .copy("Shaders/Metaballs.metal"),
                .copy("Shaders/MarchingCubesTables.h")
            ]
        ),
        .testTarget(
            name: "DicyaninMetaballsTests",
            dependencies: ["DicyaninMetaballs"]
        )
    ]
)
