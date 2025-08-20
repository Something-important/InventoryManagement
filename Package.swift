// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "InventoryManagement",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "InventoryManagement",
            targets: ["InventoryManagement"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "4.0.0")
    ],
    targets: [
        .target(
            name: "InventoryManagement",
            dependencies: [
                .product(name: "JWTKit", package: "jwt-kit")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "InventoryManagementTests",
            dependencies: ["InventoryManagement"],
            path: "Tests/InventoryManagementTests"
        ),
    ]
)