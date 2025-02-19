// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Support",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Support",
            targets: ["Support"]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(
            name: "ZendeskSupportSDK",
            url: "https://github.com/zendesk/support_sdk_ios.git",
            from: "5.4.1"
        ),
        .package(
            name: "Logger",
            path: "../Logger"
        ),
        .package(
            name: "Secrets",
            path: "../Secrets"
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Support",
            dependencies: ["ZendeskSupportSDK", "Logger", "Secrets"],
            path: "Sources"
        ),
        .testTarget(
            name: "SupportTests",
            dependencies: ["Support"],
            path: "Tests",
            resources: [
                .copy("Samples/Secrets.plist"),
                .copy("Samples/app_log.txt")
            ]
        )
    ]
)
