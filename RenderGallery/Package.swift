// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RenderGallery",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(path: "../DicyaninHumanoidMesh"),
        .package(path: "../DicyaninVirtualJoystick")
    ],
    targets: [
        .executableTarget(
            name: "RenderGallery",
            dependencies: [
                .product(name: "DicyaninHumanoidMesh", package: "DicyaninHumanoidMesh")
            ]
        ),
        .executableTarget(
            name: "GamepadGallery",
            dependencies: [
                .product(name: "DicyaninVirtualJoystick", package: "DicyaninVirtualJoystick")
            ]
        )
    ]
)
