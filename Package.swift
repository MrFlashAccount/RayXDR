// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "RayXDR",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "rayxdr", targets: ["ExtraBrightness"]),
        .executable(name: "rayxdr-helper", targets: ["ExtraBrightnessHelper"])
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
        )
    ]
)
