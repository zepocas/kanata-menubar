// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KanataMenubar",
    platforms: [.macOS(.v14)],
    targets: [
        // Pure logic (status parsing) so it can be unit tested.
        .target(name: "MenubarCore"),
        // The AppKit menubar app.
        .executableTarget(name: "KanataMenubar", dependencies: ["MenubarCore"]),
        .testTarget(name: "MenubarCoreTests", dependencies: ["MenubarCore"]),
    ]
)
