// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CoatySwift",
    defaultLocalization: "en",
    platforms: [
            .macOS(.v10_13),
            .iOS(.v10),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "CoatySwift",
            targets: ["CoatySwift"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/emqx/CocoaMQTT", from: "2.0.7"),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "5.1.1"),
        .package(url: "https://github.com/DaveWoodCom/XCGLogger.git", from: "7.0.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CoatySwift",
            dependencies: ["CocoaMQTT", "RxSwift", "XCGLogger"],
            path: "Source"
        ),
        .testTarget(
            name: "CoatySwiftTests",
            dependencies: ["CoatySwift"],
            path: "Tests"
        ),
    ]
)
