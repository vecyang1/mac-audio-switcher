#!/usr/bin/swift

import Foundation

// Create a new Xcode project using xcodebuild
let projectName = "AudioSwitchPro"
let srcPath = "/Users/vecsatfoxmailcom/Documents/A-coding/25.06.18 Audio-switch/src"

// Change to src directory
FileManager.default.changeCurrentDirectoryPath(srcPath)

// Create project using xcodeproj template
let createProjectCommand = """
    xcodebuild -create-xcframework \
    -framework AudioSwitchPro \
    -output AudioSwitchPro.xcframework
"""

print("Creating Xcode project structure...")

// Alternative: Use swift package to generate xcodeproj
let packageContents = """
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AudioSwitchPro",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "AudioSwitchPro", targets: ["AudioSwitchPro"])
    ],
    targets: [
        .executableTarget(
            name: "AudioSwitchPro",
            path: "AudioSwitchPro"
        )
    ]
)
"""

do {
    try packageContents.write(toFile: "Package.swift", atomically: true, encoding: .utf8)
    
    // Generate xcodeproj from Package.swift
    let task = Process()
    task.launchPath = "/usr/bin/swift"
    task.arguments = ["package", "generate-xcodeproj"]
    task.launch()
    task.waitUntilExit()
    
    if task.terminationStatus == 0 {
        print("✅ Xcode project created successfully!")
        print("Opening project...")
        
        let openTask = Process()
        openTask.launchPath = "/usr/bin/open"
        openTask.arguments = ["AudioSwitchPro.xcodeproj"]
        openTask.launch()
    } else {
        print("❌ Failed to create Xcode project")
    }
} catch {
    print("Error: \(error)")
}