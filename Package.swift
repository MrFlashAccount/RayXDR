// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "RayXDR",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "rayxdr", targets: ["ExtraBrightness"]),
        .executable(name: "rayxdr-helper", targets: ["ExtraBrightnessHelper"]),
        .executable(name: "rayxdr-menubar", targets: ["RayXDRMenuBar"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.9.4")
    ],
    targets: [
        .target(name: "ExtraBrightnessCore"),
        .executableTarget(
            name: "ExtraBrightness",
            dependencies: ["ExtraBrightnessCore"]
        ),
        .executableTarget(
            name: "ExtraBrightnessHelper",
            dependencies: ["ExtraBrightnessCore"]
        ),
        .executableTarget(
            name: "RayXDRMenuBar",
            dependencies: [
                "ExtraBrightnessCore",
                .product(name: "Sparkle", package: "Sparkle")
            ]
        ),
        .testTarget(
            name: "RayXDRTests",
            path: "Tests/RayXDRTests"
        )
    ]
)
