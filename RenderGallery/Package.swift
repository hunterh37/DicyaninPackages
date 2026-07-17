// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RenderGallery",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(path: "../DicyaninHumanoidMesh"),
        .package(path: "../DicyaninMetaballs")
    ],
    targets: [
        .executableTarget(
            name: "RenderGallery",
            dependencies: [
                .product(name: "DicyaninHumanoidMesh", package: "DicyaninHumanoidMesh"),
                .product(name: "DicyaninMetaballs", package: "DicyaninMetaballs")
            ]
        ),
        .executableTarget(
            name: "MetaballGallery",
            dependencies: [
                .product(name: "DicyaninMetaballs", package: "DicyaninMetaballs")
            ]
        )
    ]
)
