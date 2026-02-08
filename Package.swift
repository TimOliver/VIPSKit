// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VIPSKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "VIPSKit", targets: ["VIPSKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/TimOliver/vips-cocoa.git", from: "8.18.0"),
    ],
    targets: [
        // C shim for variadic vips functions (Swift cannot call variadic C functions)
        .target(
            name: "CVIPS",
            dependencies: [
                .product(name: "vips-static", package: "vips-cocoa"),
            ],
            path: "Sources/Internal",
            publicHeadersPath: "include",
            cSettings: [
                .define("HAVE_CONFIG_H", to: "1"),
            ],
            linkerSettings: [
                .linkedLibrary("z"),
                .linkedLibrary("iconv"),
                .linkedLibrary("resolv"),
                .linkedLibrary("c++"),
            ]
        ),

        // Swift wrapper — public API
        .target(
            name: "VIPSKit",
            dependencies: ["CVIPS"],
            path: "Sources",
            exclude: ["Internal"],
            swiftSettings: [
                .enableUpcomingFeature("AccessLevelOnImport"),
            ]
        ),

        // Tests
        .testTarget(
            name: "VIPSKitTests",
            dependencies: ["VIPSKit"],
            path: "Tests",
            exclude: [
                "TestHost",
                "VIPSImageTestCase.h",
                "VIPSImageTestCase.m",
                "VIPSImageAnalysisTests.m",
                "VIPSImageCachingTests.m",
                "VIPSImageCGImageTests.m",
                "VIPSImageColorTests.m",
                "VIPSImageCompositeTests.m",
                "VIPSImageCoreTests.m",
                "VIPSImageFilterTests.m",
                "VIPSImageLoadingTests.m",
                "VIPSImageResizeTests.m",
                "VIPSImageSavingTests.m",
                "VIPSImageTilingTests.m",
                "VIPSImageTransformTests.m",
                "VIPSTests.xctestplan",
            ],
            resources: [
                .copy("TestResources"),
            ]
        ),
    ]
)
