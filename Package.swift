// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Image",
    products: [
        .library(
            name: "Image",
            targets: [
                "Image",
            ]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Image",
            dependencies: [
                
            ]
        ),
        .testTarget(
            name: "ImageTests",
            dependencies: [
                "Image",
            ]
        ),
    ]
)
