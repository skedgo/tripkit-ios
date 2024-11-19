// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "TripKit",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v15),
    .macOS(.v11),
  ],
  products: [
    .library(name: "TripKit", targets: ["TripKit"]),
    .library(name: "TripKitUI", targets: ["TripKitUI"]),
    .library(name: "TripKitInterApp", targets: ["TripKitInterApp"]),
    .library(name: "TripKit-Dynamic", type: .dynamic, targets: ["TripKit"]),
    .library(name: "TripKitUI-Dynamic", type: .dynamic, targets: ["TripKitUI"]),
    .library(name: "TripKitInterApp-Dynamic", type: .dynamic, targets: ["TripKitInterApp"]),
  ],
  dependencies: [
    .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "6.1.0")),
    .package(url: "https://github.com/onevcat/Kingfisher.git", .upToNextMajor(from: "7.0.0")),
    .package(url: "https://github.com/skedgo/GeoMonitor.git", .upToNextMinor(from: "0.1.2")),
    .package(url: "https://github.com/skedgo/TGCardViewController.git", .upToNextMajor(from: "2.2.10")),
  ],
  targets: [
    .target(
      name: "TripKit",
      dependencies: [],
      exclude: ["Supporting Files/Info.plist"]
    ),
    .target(
      name: "TripKitUI",
      dependencies: [
        "TripKit",
        "Kingfisher",
        .product(name: "RxCocoa", package: "RxSwift"),
        "TGCardViewController",
        "GeoMonitor",
      ],
      exclude: ["Supporting Files/Info.plist", "vendor/RxCombine/LICENSE"]
    ),
    .target(
      name: "TripKitInterApp",
      dependencies: [
        "TripKit",
      ],
      exclude: ["Supporting Files/Info.plist"]
    ),
    .testTarget(
      name: "TripKitTests",
      dependencies: [
        "TripKit",
        .product(name: "RxCocoa", package: "RxSwift"),
      ],
      exclude: [
        "Data",
        "Supporting Files/Info.plist",
      ]
    ),
    .testTarget(
      name: "TripKitUITests",
      dependencies: [
        "TripKit",
        "TripKitUI",
        .product(name: "RxCocoa", package: "RxSwift"),
      ],
      exclude: [
        "Data",
        "vendor/RxBlocking/README.md",
        "vendor/RxBlocking/Info.plist",
        "vendor/RxTest/Info.plist",
      ]
    ),
  ]
)

#if os(Linux)
package.targets = package.targets.filter { $0.name == "TripKit" || $0.name == "TripKitTests" }
package.products = package.products.filter { $0.name == "TripKit" }
package.dependencies = package.dependencies.filter { $0.url?.contains("RxSwift") == true }
#endif
