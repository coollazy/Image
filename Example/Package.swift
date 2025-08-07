// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Example",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .executable(name: "App", targets: ["App"]),
    ],
    dependencies: [
        .package(path: "../"),
//        .package(url: "https://github.com/coollazy/Image.git", .upToNextMinor(from: "1.0.0")),
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Image", package: "Image"),
            ])
    ]
)
