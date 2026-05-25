// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "RayCastUltraBrightness",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "extra-brightness", targets: ["ExtraBrightness"]),
        .executable(name: "extra-brightness-helper", targets: ["ExtraBrightnessHelper"])
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
