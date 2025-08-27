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
        .package(url: "https://github.com/supabase-community/supabase-swift.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "InventoryManagement",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "InventoryManagementTests",
            dependencies: ["InventoryManagement"],
            path: "Tests/InventoryManagementTests"
        ),
    ]
)