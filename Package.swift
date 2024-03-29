// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "YUKTask",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
  ],
  products: [
    .library(name: "YUKTask", targets: ["YUKTask"]),
  ],
  dependencies: [
    .package(name: "YUKLock", url: "https://github.com/alberussoftware/yuk-lock-iOS.git", .branch("master")),
  ],
  targets: [
    .target(
      name: "YUKTask",
      dependencies: ["YUKLock"],
      exclude: [
        "./Deprecated",
        "./Task/GroupTasks/AnyProducerTaskArrayBuilder.swift.gyb",
      ]
    ),
    .testTarget(
      name: "YUKTaskTests",
      dependencies: ["YUKTask", "YUKLock"]
    ),
  ]
)
