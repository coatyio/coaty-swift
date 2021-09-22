// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CoatySwift",
    defaultLocalization: "en",
    platforms: [
            .macOS(.v10_13),
            .iOS(.v10),
            .tvOS(.v10),
            .watchOS(.v3)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "CoatySwift",
            targets: ["CoatySwift"]),
//        .executable(
//            name: "CoatySwiftExample",
//            targets: ["CoatySwiftExample"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/lukasz-zet/CocoaMQTT", .branch("master")),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "5.1.1"),
        .package(url: "https://github.com/DaveWoodCom/XCGLogger.git", from: "7.0.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CoatySwift",
            dependencies: ["CocoaMQTT", "RxSwift", "XCGLogger"],
            path: "Sources",
            resources: [
                .process("Info.plist"),
            ]
        ),
        .testTarget(
            name: "CoatySwiftTests",
            dependencies: ["CoatySwift"],
            path: "Tests"
        ),
    ]
)
