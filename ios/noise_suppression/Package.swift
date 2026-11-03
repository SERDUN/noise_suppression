// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "noise_suppression",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        // The plugin: NSPNoiseSuppressor, NSPRnnoiseSuppressor and the Flutter channel.
        .library(name: "noise-suppression", targets: ["noise_suppression"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        // The C core (noise_suppressor.h + RNNoise). The Android build compiles the same files.
        .target(
            name: "NoiseSuppressionCore",
            path: "Sources/NoiseSuppressionCore",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("rnnoise/include"),
                // RNNoise keeps its FFT state in a global called `common`.
                .define("common", to: "ns_rnnoise_common"),
            ]
        ),
        .target(
            name: "noise_suppression",
            dependencies: [
                "NoiseSuppressionCore",
                .product(name: "FlutterFramework", package: "FlutterFramework"),
            ],
            path: "Sources/noise_suppression",
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ],
            publicHeadersPath: "include/noise_suppression"
        ),
    ]
)
