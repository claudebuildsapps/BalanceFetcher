import Foundation
import SwiftUI
import ServiceManagement

class SettingsModel: ObservableObject {
    // Source type enum
    enum SourceType: Int {
        case scriptFile = 0
        case command = 1
    }
    
    // Debug logging flag
    static let DEBUG_LOGGING = true
    
    // Published properties for UI binding
    @Published var sourceType: SourceType = .command  // Default to command mode
    @Published var scriptPath: String = ""
    @Published var commandString: String = "/usr/local/bin/"  // Default to common bin directory
    @Published var refreshInterval: RefreshInterval = .thirtySeconds
    @Published var launchAtLogin: Bool = false
    
    // Log file path
    static let logFile: String = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        
        let logDirectory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs/BalanceFetcher")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        
        return logDirectory.appendingPathComponent("BalanceFetcher_\(timestamp).log").path
    }()
    
    // Add a debug log method
    static func debugLog(_ message: String) {
        if DEBUG_LOGGING {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            let timestamp = formatter.string(from: Date())
            let logMessage = "\(timestamp) 🔍 [SettingsModel] \(message)"
            
            // Print to console
            print(logMessage)
            
            // Write to log file
            do {
                let fileManager = FileManager.default
                if !fileManager.fileExists(atPath: logFile) {
                    fileManager.createFile(atPath: logFile, contents: nil)
                }
                
                let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: logFile))
                fileHandle.seekToEndOfFile()
                if let data = "\(logMessage)\n".data(using: .utf8) {
                    fileHandle.write(data)
                }
                try fileHandle.close()
            } catch {
                print("Error writing to log file: \(error)")
            }
        }
    }
    
    // Get the current application bundle identifier
    private var appBundleIdentifier: String {
        return Bundle.main.bundleIdentifier ?? "com.user.BalanceFetcher"
    }
    
    // Available refresh intervals
    enum RefreshInterval: String, CaseIterable, Identifiable {
        case fifteenSeconds = "15 seconds"
        case thirtySeconds = "30 seconds"
        case oneMinute = "1 minute"
        case fiveMinutes = "5 minutes"
        case fifteenMinutes = "15 minutes"
        case thirtyMinutes = "30 minutes"
        case oneHour = "1 hour"
        
        var id: String { self.rawValue }
        
        var seconds: TimeInterval {
            switch self {
            case .fifteenSeconds: return 15
            case .thirtySeconds: return 30
            case .oneMinute: return 60
            case .fiveMinutes: return 300
            case .fifteenMinutes: return 900
            case .thirtyMinutes: return 1800
            case .oneHour: return 3600
            }
        }
    }
    
    // Keys for UserDefaults
    private enum Keys {
        static let sourceType = "sourceType"
        static let scriptPath = "scriptPath"
        static let commandString = "commandString"
        static let refreshInterval = "refreshInterval"
        static let launchAtLogin = "launchAtLogin"
    }
    
    // Initialize with saved settings or defaults
    init() {
        loadSettings()
        
        // Check if app is set to launch at login
        checkLaunchAtLoginStatus()
    }
    
    // Save settings to UserDefaults
    func saveSettings() {
        SettingsModel.debugLog("Saving settings to UserDefaults")
        
        // Make sure we're on the main thread when updating
        if !Thread.isMainThread {
            SettingsModel.debugLog("Warning: saveSettings called from background thread, dispatching to main thread")
            DispatchQueue.main.sync {
                self.saveSettings()
            }
            return
        }
        
        // Log current values before saving
        SettingsModel.debugLog("Saving sourceType: \(sourceType)")
        SettingsModel.debugLog("Saving scriptPath: \(scriptPath)")
        SettingsModel.debugLog("Saving commandString: \(commandString)")
        SettingsModel.debugLog("Saving refreshInterval: \(refreshInterval.rawValue)")
        SettingsModel.debugLog("Saving launchAtLogin: \(launchAtLogin)")
        
        let defaults = UserDefaults.standard
        
        // Use a do-catch block to catch any potential errors
        do {
            defaults.set(sourceType.rawValue, forKey: Keys.sourceType)
            defaults.set(scriptPath, forKey: Keys.scriptPath)
            defaults.set(commandString, forKey: Keys.commandString)
            defaults.set(refreshInterval.rawValue, forKey: Keys.refreshInterval)
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            
            // Force synchronize to make sure settings are saved immediately
            defaults.synchronize()
            
            SettingsModel.debugLog("Settings saved successfully")
            
            // Update launch at login status
            updateLaunchAtLoginStatus()
        } catch {
            SettingsModel.debugLog("Error saving settings: \(error.localizedDescription)")
        }
    }
    
    // Load settings from UserDefaults
    func loadSettings() {
        SettingsModel.debugLog("Loading settings from UserDefaults")
        
        // Make sure we're on the main thread when updating @Published properties
        if !Thread.isMainThread {
            SettingsModel.debugLog("Warning: loadSettings called from background thread, dispatching to main thread")
            DispatchQueue.main.sync {
                self.loadSettings()
            }
            return
        }
        
        let defaults = UserDefaults.standard
        
        do {
            // Load source type
            if let sourceTypeValue = defaults.object(forKey: Keys.sourceType) as? Int,
               let type = SourceType(rawValue: sourceTypeValue) {
                SettingsModel.debugLog("Loaded sourceType: \(type)")
                sourceType = type
            }
            
            // Load script path
            if let savedPath = defaults.string(forKey: Keys.scriptPath) {
                SettingsModel.debugLog("Loaded scriptPath: \(savedPath)")
                scriptPath = savedPath
            }
            
            // Load command string
            if let savedCommand = defaults.string(forKey: Keys.commandString) {
                SettingsModel.debugLog("Loaded commandString: \(savedCommand)")
                commandString = savedCommand
            }
            
            // Load refresh interval
            if let intervalString = defaults.string(forKey: Keys.refreshInterval),
               let interval = RefreshInterval.allCases.first(where: { $0.rawValue == intervalString }) {
                SettingsModel.debugLog("Loaded refreshInterval: \(interval.rawValue)")
                refreshInterval = interval
            }
            
            // Load launch at login setting
            let loginSetting = defaults.bool(forKey: Keys.launchAtLogin)
            SettingsModel.debugLog("Loaded launchAtLogin: \(loginSetting)")
            launchAtLogin = loginSetting
            
            SettingsModel.debugLog("Settings loaded successfully")
        } catch {
            SettingsModel.debugLog("Error loading settings: \(error.localizedDescription)")
        }
    }
    
    // Check if app is currently set to launch at login
    func checkLaunchAtLoginStatus() {
        SettingsModel.debugLog("Checking current launch at login status")
        
        // Make sure we're on the main thread
        if !Thread.isMainThread {
            SettingsModel.debugLog("Warning: checkLaunchAtLoginStatus called from background thread, dispatching to main thread")
            DispatchQueue.main.async {
                self.checkLaunchAtLoginStatus()
            }
            return
        }
        
        #if os(macOS)
        if #available(macOS 13.0, *) {
            // Modern API for macOS 13+
            do {
                let status = SMAppService.mainApp.status
                SettingsModel.debugLog("Current SMAppService status: \(status)")
                
                let isEnabled = (status == .enabled)
                SettingsModel.debugLog("Setting launchAtLogin to: \(isEnabled)")
                launchAtLogin = isEnabled
            } catch {
                SettingsModel.debugLog("❌ ERROR checking launch at login status: \(error)")
                launchAtLogin = false
            }
        } else {
            // For macOS versions prior to 13, just set default value
            // This is simplified to avoid deprecated API issues
            SettingsModel.debugLog("macOS version < 13.0, setting launchAtLogin to false")
            launchAtLogin = false
        }
        #endif
    }
    
    // Update the launch at login status based on current setting
    func updateLaunchAtLoginStatus() {
        SettingsModel.debugLog("Updating launch at login status to: \(launchAtLogin)")
        
        // Make sure we're on the main thread
        if !Thread.isMainThread {
            SettingsModel.debugLog("Warning: updateLaunchAtLoginStatus called from background thread, dispatching to main thread")
            DispatchQueue.main.sync {
                self.updateLaunchAtLoginStatus()
            }
            return
        }
        
        #if os(macOS)
        if #available(macOS 13.0, *) {
            // Modern API for macOS 13+
            do {
                let currentStatus = SMAppService.mainApp.status
                SettingsModel.debugLog("Current SMAppService status: \(currentStatus)")
                
                if launchAtLogin {
                    if currentStatus == .notRegistered {
                        SettingsModel.debugLog("Registering app for launch at login")
                        try SMAppService.mainApp.register()
                        SettingsModel.debugLog("App registered for launch at login successfully")
                    } else {
                        SettingsModel.debugLog("App already registered for launch at login")
                    }
                } else {
                    if currentStatus == .enabled {
                        SettingsModel.debugLog("Unregistering app from launch at login")
                        try SMAppService.mainApp.unregister()
                        SettingsModel.debugLog("App unregistered from launch at login successfully")
                    } else {
                        SettingsModel.debugLog("App already not registered for launch at login")
                    }
                }
            } catch {
                SettingsModel.debugLog("❌ ERROR: Failed to \(launchAtLogin ? "register" : "unregister") app for launch at login: \(error)")
            }
        } else {
            // For macOS versions prior to 13
            SettingsModel.debugLog("⚠️ Launch at login is only supported on macOS 13 and later")
        }
        #endif
    }
}