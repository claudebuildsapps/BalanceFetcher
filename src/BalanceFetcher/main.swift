import SwiftUI
import AppKit

// Check for existing instances
func checkForExistingInstances() -> Bool {
    // Get process name
    let processName = ProcessInfo.processInfo.processName
    
    // Get all processes with this name
    let pipe = Pipe()
    let task = Process()
    task.launchPath = "/usr/bin/pgrep"
    task.arguments = ["-f", processName]
    task.standardOutput = pipe
    
    do {
        try task.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        
        // Convert output to string and split by lines
        if let output = String(data: data, encoding: .utf8) {
            let processIDs = output.components(separatedBy: .newlines).filter { !$0.isEmpty }
            
            // If more than one process (current + others), we're not the first instance
            if processIDs.count > 1 {
                return true
            }
        }
    } catch {
        print("Error checking for existing instances: \(error)")
    }
    
    return false
}

// Check if we're a duplicate instance
if checkForExistingInstances() {
    print("Another instance of BalanceFetcher is already running. Exiting.")
    exit(0)
}

// Main entry point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// Configure as a background application
app.setActivationPolicy(.accessory)

// Run the application event loop - this will keep running until quit is selected
app.run()

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var statusBar: StatusBarController?
    var scriptExecutor: ScriptExecutor?
    var refreshTimer: Timer?
    let settingsModel = SettingsModel()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Application did finish launching")
        
        // Initialize the script executor
        scriptExecutor = ScriptExecutor()
        
        // Set up default configuration if needed
        initializeDefaultSettings()
        
        // Create or get the status bar controller using our shared instance method
        statusBar = StatusBarController.getInstance()
        
        // Connect the status bar controller with the script executor
        if let statusBar = statusBar, let scriptExecutor = scriptExecutor {
            statusBar.scriptExecutor = scriptExecutor
            statusBar.settingsModel = settingsModel
            
            // Ensure menu bar icon is visible
            statusBar.ensureStatusItemVisible()
            
            // Also make sure it's visible after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                statusBar.ensureStatusItemVisible()
            }
            
            // And again after 2 seconds as a fallback
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                statusBar.ensureStatusItemVisible()
            }
        }
        
        // Start the timer for script execution
        startRefreshTimer()
        
        // Register for sleep/wake notifications
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemWillSleep),
            name: NSWorkspace.screensDidSleepNotification,
            object: nil
        )
        
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.screensDidWakeNotification,
            object: nil
        )
    }
    
    // Initialize settings with defaults if needed
    func initializeDefaultSettings() {
        let defaults = UserDefaults.standard
        
        // Only setup defaults if this appears to be first launch
        if !defaults.bool(forKey: "app_launched_before") {
            print("First launch - setting up defaults")
            
            // Set app launched flag
            defaults.set(true, forKey: "app_launched_before")
            
            // Default to command mode with appropriate bin path
            settingsModel.sourceType = .command
            settingsModel.commandString = "/usr/local/bin/ls"  // Simple default command
            
            // As a fallback, also set up the sample script
            setupSampleScript()
            
            // Save settings
            settingsModel.saveSettings()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup when application is quitting
        stopRefreshTimer()
        
        // Unregister for notifications
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        
        // Force exit to ensure complete termination
        exit(0)
    }
    
    @objc func systemWillSleep(_ notification: Notification) {
        // Pause timer during sleep to conserve resources
        stopRefreshTimer()
    }
    
    @objc func systemDidWake(_ notification: Notification) {
        // Resume timer after wake
        startRefreshTimer()
        
        // Immediately refresh to get the latest data
        executeScript()
    }
    
    @objc func openSettings() {
        // Log using the SettingsModel logging function
        SettingsModel.debugLog("Opening settings window from AppDelegate")
        
        // First, create a defensive copy of the current settings to debug
        SettingsModel.debugLog("Current settings before opening window:")
        SettingsModel.debugLog("sourceType: \(settingsModel.sourceType)")
        SettingsModel.debugLog("scriptPath: \(settingsModel.scriptPath)")
        SettingsModel.debugLog("commandString: \(settingsModel.commandString)")
        SettingsModel.debugLog("refreshInterval: \(settingsModel.refreshInterval.rawValue)")
        SettingsModel.debugLog("launchAtLogin: \(settingsModel.launchAtLogin)")
        
        // Create the window with appropriate size
        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        settingsWindow.center()
        settingsWindow.title = "BalanceFetcher Settings"
        
        do {
            // Create the hosting view with the settings view
            SettingsModel.debugLog("Creating settings view")
            let settingsView = SettingsView(settings: settingsModel)
            let hostingView = NSHostingView(rootView: settingsView)
            settingsWindow.contentView = hostingView
            
            // Show the window
            SettingsModel.debugLog("Showing settings window")
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } catch {
            SettingsModel.debugLog("❌ ERROR opening settings: \(error)")
        }
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
        SettingsModel.debugLog("executeScript called")
        
        // First make sure statusBar is initialized using our getInstance method
        if statusBar == nil {
            SettingsModel.debugLog("Status bar is nil, getting instance")
            statusBar = StatusBarController.getInstance()
            
            if let statusBar = statusBar, let scriptExecutor = scriptExecutor {
                SettingsModel.debugLog("Reconnecting statusBar components")
                statusBar.scriptExecutor = scriptExecutor
                statusBar.settingsModel = settingsModel
            }
        }
        
        // Use the shared instance as fallback
        if statusBar == nil && StatusBarController.shared != nil {
            SettingsModel.debugLog("Using shared StatusBarController instance")
            statusBar = StatusBarController.shared
        }
        
        guard let scriptExecutor = scriptExecutor, let statusBar = statusBar else {
            SettingsModel.debugLog("ERROR: Failed to get scriptExecutor or statusBar")
            return
        }
        
        SettingsModel.debugLog("Setting status to loading")
        
        // Ensure we're on the main thread for UI operations
        if !Thread.isMainThread {
            SettingsModel.debugLog("executeScript called from background thread, dispatching to main thread")
            DispatchQueue.main.async {
                self.executeScript()
            }
            return
        }
        
        // First ensure the status bar is visible before we update it
        statusBar.ensureStatusItemVisible()
        
        statusBar.setLoading(true)
        
        // Execute the appropriate script/command and get result
        let result: Result<String, Error>
        
        // Get script/command result based on settings
        switch settingsModel.sourceType {
        case .scriptFile:
            // Check if script file exists
            if !settingsModel.scriptPath.isEmpty && FileManager.default.fileExists(atPath: settingsModel.scriptPath) {
                SettingsModel.debugLog("Executing script at: \(settingsModel.scriptPath)")
                result = scriptExecutor.executeScript(at: settingsModel.scriptPath)
            } else {
                SettingsModel.debugLog("Using test command (script path empty or not found)")
                result = scriptExecutor.executeTestCommand()
            }
            
        case .command:
            // Check if command is specified
            if !settingsModel.commandString.isEmpty {
                SettingsModel.debugLog("Executing command: \(settingsModel.commandString)")
                result = scriptExecutor.executeCommand(settingsModel.commandString)
            } else {
                SettingsModel.debugLog("Using test command (command string empty)")
                result = scriptExecutor.executeTestCommand()
            }
        }
        
        // Update the display with the result
        switch result {
        case .success(let output):
            SettingsModel.debugLog("Script/command execution successful: \(output)")
            statusBar.updateDisplay(output: output)
        case .failure(let error):
            SettingsModel.debugLog("Error executing script/command: \(error.localizedDescription)")
            statusBar.updateDisplay(output: "Error: \(error.localizedDescription)")
        }
        
        statusBar.setLoading(false)
        
        // Force icon to be visible in case it disappeared
        statusBar.ensureStatusItemVisible()
        
        // Also make sure it's visible after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.statusBar?.ensureStatusItemVisible()
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