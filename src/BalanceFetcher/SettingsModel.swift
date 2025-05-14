import Foundation
import SwiftUI
import ServiceManagement

class SettingsModel: ObservableObject {
    @Published var scriptPath: String = ""
    @Published var refreshInterval: RefreshInterval = .thirtySeconds
    @Published var launchAtLogin: Bool = false
    
    // Get the current application bundle identifier
    private var appBundleIdentifier: String {
        return Bundle.main.bundleIdentifier ?? "com.yourcompany.BalanceFetcher"
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
        static let scriptPath = "scriptPath"
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
        let defaults = UserDefaults.standard
        defaults.set(scriptPath, forKey: Keys.scriptPath)
        defaults.set(refreshInterval.rawValue, forKey: Keys.refreshInterval)
        defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
        
        // Update launch at login status
        updateLaunchAtLoginStatus()
    }
    
    // Load settings from UserDefaults
    func loadSettings() {
        let defaults = UserDefaults.standard
        
        if let savedPath = defaults.string(forKey: Keys.scriptPath) {
            scriptPath = savedPath
        }
        
        if let intervalString = defaults.string(forKey: Keys.refreshInterval),
           let interval = RefreshInterval.allCases.first(where: { $0.rawValue == intervalString }) {
            refreshInterval = interval
        }
        
        launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
    }
    
    // Check if app is currently set to launch at login
    func checkLaunchAtLoginStatus() {
        #if os(macOS)
        if #available(macOS 13.0, *) {
            // Modern API for macOS 13+
            SMAppService.mainApp.status == .enabled ? (launchAtLogin = true) : (launchAtLogin = false)
        } else {
            // For macOS versions prior to 13, just set default value
            // This is simplified to avoid deprecated API issues
            launchAtLogin = false
        }
        #endif
    }
    
    // Update the launch at login status based on current setting
    func updateLaunchAtLoginStatus() {
        #if os(macOS)
        if #available(macOS 13.0, *) {
            // Modern API for macOS 13+
            do {
                if launchAtLogin {
                    if SMAppService.mainApp.status == .notRegistered {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
            } catch {
                print("Failed to \(launchAtLogin ? "register" : "unregister") app for launch at login: \(error)")
            }
        } else {
            // For macOS versions prior to 13
            print("Launch at login is only supported on macOS 13 and later")
        }
        #endif
    }
}