// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Presenter",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "Presenter",
            path: "Sources/Presenter",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("PDFKit"),
                .linkedFramework("Quartz"),
            ]
        )
    ]
)
