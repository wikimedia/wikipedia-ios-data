// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WKData",
    platforms: [.iOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "WKData",
            targets: ["WKData"]),
        .library(name: "WKDataMocks",
            targets: ["WKDataMocks"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "WKData",
            dependencies: [],
            path: "Sources/WKData"),
        .target(name: "WKDataMocks",
               dependencies: ["WKData"],
                path: "Sources/WKDataMocks",
                resources: [.process("Resources")]),
        .testTarget(
            name: "WKDataTests",
            dependencies: ["WKData", "WKDataMocks"]),
    ]
)

// TTD Tomorrow:

// Make a separate mocks target / product / whatevs? WKDataTests can depend on it, (it will contain mockmediawikinetworkservice). It could also contain a mock WKWatchlistFetcher. Demo could then import WKDataMocks, and inject it's mock watchlist fetcher into the view model.
