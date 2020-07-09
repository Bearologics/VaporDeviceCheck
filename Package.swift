// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VaporDeviceCheck",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "VaporDeviceCheck",
            targets: ["VaporDeviceCheck"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.14.0"),
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0-rc.2.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "VaporDeviceCheck",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "JWT", package: "jwt")
            ]
        ),
        .testTarget(
            name: "VaporDeviceCheckTests",
            dependencies: [
                .target(name: "VaporDeviceCheck"),
                .product(name: "XCTVapor", package: "vapor")
            ]
        ),
    ]
)
