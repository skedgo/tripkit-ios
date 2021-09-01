// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "TripKit",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v13),
    .macOS(.v11),
  ],
  products: [
    .library(
      name: "TripKit",
      targets: ["TripKit"]
    ),
    .library(
      name: "TripKitUI",
      targets: ["TripKitUI"]),
  ],
  dependencies: [
    .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "6.1.0")),
    .package(url: "https://github.com/onevcat/Kingfisher.git", .upToNextMajor(from: "6.2.0")),
    .package(url: "https://github.com/skedgo/TGCardViewController.git", .upToNextMajor(from: "1.7.0")),
  ],
  targets: [
    .target(
      name: "TripKitObjc",
      dependencies: []
    ),
    .target(
      name: "TripKit",
      dependencies: [
        .target(name: "TripKitObjc")
      ],
      exclude: ["Supporting Files/Info.plist"]
    ),
    .target(
      name: "TripKitUI",
      dependencies: [
        .target(name: "TripKit"),
        "Kingfisher",
        .product(name: "RxCocoa", package: "RxSwift"),
        "TGCardViewController",
      ],
      exclude: ["Supporting Files/Info.plist"]
    ),
    .testTarget(
      name: "TripKitObjcTests",
      dependencies: [
        "TripKitObjc",
      ]
    ),
    .testTarget(
      name: "TripKitTests",
      dependencies: [
        "TripKit",
        .product(name: "RxCocoa", package: "RxSwift"),
      ],
      exclude: [
        "Data",
        "polygon/data",
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
