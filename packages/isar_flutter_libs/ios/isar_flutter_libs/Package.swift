// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "isar_flutter_libs",
    platforms: [
        .iOS("13.0"),
    ],
    products: [
        .library(
            name: "isar-flutter-libs",
            targets: ["isar_flutter_libs"]
        ),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
    ],
    targets: [
        .binaryTarget(
            name: "isar_legacy_core",
            path: "isar_legacy.xcframework"
        ),
        .target(
            name: "CIsarLegacyCore",
            dependencies: ["isar_legacy_core"],
            path: "Core",
            publicHeadersPath: "include"
        ),
        .target(
            name: "isar_flutter_libs",
            dependencies: [
                .product(
                    name: "FlutterFramework",
                    package: "FlutterFramework"
                ),
                "CIsarLegacyCore",
            ],
            path: "Sources/isar_flutter_libs"
        ),
    ]
)
