import SwiftUI
import AppKit

// Main entry point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var statusBar: StatusBarController?
    var scriptExecutor: ScriptExecutor?
    var refreshTimer: Timer?
    let settingsModel = SettingsModel()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize the script executor
        scriptExecutor = ScriptExecutor()
        
        // Set up sample script if no script is configured
        if settingsModel.scriptPath.isEmpty {
            setupSampleScript()
        }
        
        // Create the status bar item
        statusBar = StatusBarController()
        
        // Connect the status bar controller with the script executor
        if let statusBar = statusBar, let scriptExecutor = scriptExecutor {
            statusBar.scriptExecutor = scriptExecutor
            statusBar.settingsModel = settingsModel
        }
        
        // Start the timer for script execution
        startRefreshTimer()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        stopRefreshTimer()
    }
    
    @objc func openSettings() {
        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        settingsWindow.center()
        settingsWindow.title = "BalanceFetcher Settings"
        settingsWindow.contentView = NSHostingView(rootView: SettingsView(settings: settingsModel))
        settingsWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func startRefreshTimer() {
        stopRefreshTimer()
        
        // Create a new timer with the configured refresh interval
        let interval = settingsModel.refreshInterval.seconds
        refreshTimer = Timer.scheduledTimer(
            timeInterval: interval,
            target: self,
            selector: #selector(executeScript),
            userInfo: nil,
            repeats: true
        )
        
        // Execute the script immediately
        executeScript()
    }
    
    func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    @objc func executeScript() {
        guard let scriptExecutor = scriptExecutor, let statusBar = statusBar else { return }
        
        // If a script path is set and the file exists, execute it
        if !settingsModel.scriptPath.isEmpty && FileManager.default.fileExists(atPath: settingsModel.scriptPath) {
            let result = scriptExecutor.executeScript(at: settingsModel.scriptPath)
            switch result {
            case .success(let output):
                statusBar.updateDisplay(output: output)
            case .failure(let error):
                statusBar.updateDisplay(output: "Error: \(error.localizedDescription)")
            }
        } else {
            // Execute a test command if no script is set
            let result = scriptExecutor.executeTestCommand()
            switch result {
            case .success(let output):
                statusBar.updateDisplay(output: output)
            case .failure(let error):
                statusBar.updateDisplay(output: "Error: \(error.localizedDescription)")
            }
        }
    }
    
    // Set up the sample script for first-time users
    func setupSampleScript() {
        // Find the bundled sample script
        if let resourcePath = Bundle.main.resourcePath {
            let sampleScriptPath = resourcePath + "/Scripts/sample_balance.sh"
            
            // Check if the sample script exists
            if FileManager.default.fileExists(atPath: sampleScriptPath) {
                // Make sure it's executable
                do {
                    try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: sampleScriptPath)
                    
                    // Update settings model with the sample script path
                    settingsModel.scriptPath = sampleScriptPath
                    settingsModel.saveSettings()
                } catch {
                    print("Failed to set permissions on sample script: \(error)")
                }
            } else {
                // Set up a destination in the user's home directory
                let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
                let scriptsDir = homeDir + "/.config/balancefetcher/scripts"
                let destPath = scriptsDir + "/sample_balance.sh"
                
                // Create scripts directory if it doesn't exist
                do {
                    try FileManager.default.createDirectory(
                        atPath: scriptsDir,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                    
                    // Copy the script from the bundle
                    if let bundlePath = Bundle.main.path(forResource: "sample_balance", ofType: "sh", inDirectory: "Scripts") {
                        try FileManager.default.copyItem(atPath: bundlePath, toPath: destPath)
                        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: destPath)
                        
                        // Update settings model with the sample script path
                        settingsModel.scriptPath = destPath
                        settingsModel.saveSettings()
                    }
                } catch {
                    print("Failed to set up sample script: \(error)")
                }
            }
        }
    }
}