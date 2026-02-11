// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Presenter",
    platforms: [
        .macOS(.v13),
        .iOS(.v17)
    ],
    targets: [
        .executableTarget(
            name: "Presenter",
            path: "Sources/Presenter",
            linkerSettings: [
                .linkedFramework("AppKit", .when(platforms: [.macOS])),
                .linkedFramework("PDFKit"),
                .linkedFramework("Quartz", .when(platforms: [.macOS])),
            ]
        ),
        .executableTarget(
            name: "PresenterMobile",
            path: "Sources/PresenterMobile",
            linkerSettings: [
                .linkedFramework("UIKit", .when(platforms: [.iOS])),
                .linkedFramework("PDFKit"),
            ]
        )
    ]
)
