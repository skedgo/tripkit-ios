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
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "TripKit",
      targets: ["TripKit"]),
    .library(
      name: "TripKitObjc",
      type: .dynamic,
      targets: ["TripKitObjc"]),
    .library(
      name: "TripKitUI",
      targets: ["TripKitUI"]),
  ],
  dependencies: [
    .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "6.1.0")),
    .package(url: "https://github.com/onevcat/Kingfisher.git", .upToNextMajor(from: "6.2.0")),
    .package(name: "TGCardViewController", url: "https://gitlab.com/SkedGo/iOS/TGCardViewController.git", .branch("spm")),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "TripKitObjc",
      dependencies: []),
    .target(
      name: "TripKit",
      dependencies: [
        .target(name: "TripKitObjc")
      ]),
    .target(
      name: "TripKitUI",
      dependencies: [
        .target(name: "TripKit"),
        "Kingfisher",
        "RxSwift",
        .product(name: "RxCocoa", package: "RxSwift"),
        "TGCardViewController",
      ]),
    .testTarget(
      name: "TripKitTests",
      dependencies: [
        "TripKit",
        "TripKitUI",
        .product(name: "RxCocoa", package: "RxSwift"),
      ]),
  ]
)
