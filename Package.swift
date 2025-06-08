// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LiteSwiftGraph",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1)
    ],
    products: [
        // Core library for all platforms
        .library(
            name: "LiteSwiftGraph",
            targets: ["LiteSwiftGraph"]),
        
        // Debug and UI components library
        .library(
            name: "LiteSwiftGraphDebug",
            targets: ["LiteSwiftGraphDebug"]),
        
        // macOS-only executables
        .executable(
            name: "LiteSwiftGraphCLI",
            targets: ["LiteSwiftGraphCLI"]),
        
        .executable(
            name: "LiteSwiftGraphUI",
            targets: ["LiteSwiftGraphUI"]),
            
        .executable(
            name: "LiteSwiftGraphExample", 
            targets: ["LiteSwiftGraphExample"])
    ],
    targets: [
        // Core library target (all platforms)
        .target(
            name: "LiteSwiftGraph"),
        
        // Debug and UI components library
        .target(
            name: "LiteSwiftGraphDebug",
            dependencies: ["LiteSwiftGraph"]
        ),
        
        // Example executable that demonstrates usage
        .executableTarget(
            name: "LiteSwiftGraphExample",
            dependencies: ["LiteSwiftGraph", "LiteSwiftGraphDebug"]
        ),
        
        // macOS CLI application
        .executableTarget(
            name: "LiteSwiftGraphCLI",
            dependencies: ["LiteSwiftGraph", "LiteSwiftGraphDebug"]
        ),
        
        // macOS UI application  
        .executableTarget(
            name: "LiteSwiftGraphUI",
            dependencies: ["LiteSwiftGraph", "LiteSwiftGraphDebug"]
        ),
        
        // Tests
        .testTarget(
            name: "LiteSwiftGraphTests",
            dependencies: ["LiteSwiftGraph"]
        ),
    ]
)
