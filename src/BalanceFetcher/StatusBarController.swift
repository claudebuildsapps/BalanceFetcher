import SwiftUI
import AppKit

class StatusBarController {
    // Use a static shared instance to ensure we always have a reference
    static var shared: StatusBarController?
    
    // Status item is marked as private(set) so it can't be modified externally
    private(set) var statusItem: NSStatusItem
    private var menu: NSMenu
    
    // References to other components
    var scriptExecutor: ScriptExecutor?
    var settingsModel: SettingsModel?
    
    // Status indicators
    private var isLoading = false
    
    // Flag to track if the status bar has been initialized
    private static var isInitialized = false
    
    init() {
        SettingsModel.debugLog("Initializing StatusBarController")
        
        // Create the status item in the menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Set the default menu bar icon
        if let button = statusItem.button {
            if let iconImage = NSImage(named: "MenuBarIcons") {
                button.image = iconImage
                button.image?.size = NSSize(width: 18, height: 18)
            } else {
                // Fallback to system icon if custom icon is not available
                button.image = NSImage(systemSymbolName: "dollarsign.circle", accessibilityDescription: "Balance")
            }
        }
        
        // Create the menu
        menu = NSMenu()
        
        // Add menu items
        menu.addItem(NSMenuItem(title: "Loading...", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // Create refresh menu item with this object as target
        let refreshItem = NSMenuItem(title: "Refresh", action: #selector(refresh), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Create settings menu item with this object as target
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        // Create quit menu item with this object as target
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        // Set the menu for the status item
        statusItem.menu = menu
        
        // Store a reference to this instance for later recovery
        StatusBarController.shared = self
        StatusBarController.isInitialized = true
        
        SettingsModel.debugLog("StatusBarController initialization complete")
    }
    
    // Class method to get the current instance or create a new one if needed
    class func getInstance() -> StatusBarController {
        SettingsModel.debugLog("Getting StatusBarController instance")
        
        if let existingInstance = shared {
            SettingsModel.debugLog("Using existing StatusBarController instance")
            return existingInstance
        }
        
        SettingsModel.debugLog("Creating new StatusBarController instance")
        let newInstance = StatusBarController()
        shared = newInstance
        return newInstance
    }
    
    @objc func refresh() {
        guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else { return }
        appDelegate.executeScript()
    }
    
    @objc func openSettings() {
        print("🔘 [StatusBarController] Open settings menu item clicked")
        
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            print("🔘 [StatusBarController] Found AppDelegate, calling openSettings()")
            appDelegate.openSettings()
        } else {
            print("❌ [StatusBarController] ERROR: AppDelegate is nil, cannot open settings")
        }
    }
    
    @objc func quit() {
        // Force exit completely
        exit(0)
    }
    
    func updateDisplay(output: String) {
        if let firstItem = menu.item(at: 0) {
            firstItem.title = output
            
            // Update status bar icon if needed
            updateStatusIcon(based: output)
        }
        
        // Ensure menu bar item is visible
        ensureStatusItemVisible()
    }
    
    // Make sure the status item is visible in the menu bar
    func ensureStatusItemVisible() {
        SettingsModel.debugLog("Ensuring status item is visible")
        
        // Check if we're on the main thread, if not, dispatch to main thread
        if !Thread.isMainThread {
            SettingsModel.debugLog("ensureStatusItemVisible called from background thread, dispatching to main thread")
            DispatchQueue.main.async {
                self.ensureStatusItemVisible()
            }
            return
        }
        
        // If button is nil, the status item might have been removed
        if statusItem.button == nil || statusItem.menu == nil {
            SettingsModel.debugLog("Status item button or menu is nil, recreating")
            
            // Recreate status item
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            
            // Set the default menu bar icon
            if let button = statusItem.button {
                if let iconImage = NSImage(named: "MenuBarIcons") {
                    button.image = iconImage
                    button.image?.size = NSSize(width: 18, height: 18)
                    SettingsModel.debugLog("Status item icon set to custom icon")
                } else {
                    // Fallback to system icon if custom icon is not available
                    button.image = NSImage(systemSymbolName: "dollarsign.circle", accessibilityDescription: "Balance")
                    SettingsModel.debugLog("Status item icon set to system icon")
                }
            } else {
                SettingsModel.debugLog("WARNING: Status item button is still nil after recreation")
            }
            
            // Reattach menu
            statusItem.menu = menu
            SettingsModel.debugLog("Menu reattached to status item")
        } else {
            SettingsModel.debugLog("Status item already visible")
        }
        
        // Ensure we have a reference to the shared instance
        StatusBarController.shared = self
    }
    
    func setLoading(_ loading: Bool) {
        isLoading = loading
        
        // Ensure status item is visible
        ensureStatusItemVisible()
        
        // Update refresh menu item (index may be different now with explicit targets)
        for i in 0..<menu.items.count {
            if menu.items[i].action == #selector(refresh) {
                menu.items[i].isEnabled = !loading
                break
            }
        }
        
        // Visual indicator of loading state
        if loading {
            if let button = statusItem.button {
                if let loadingIcon = NSImage(named: "MenuBarIconLoading") {
                    button.image = loadingIcon
                    button.image?.size = NSSize(width: 18, height: 18)
                } else {
                    // Fallback to system icon
                    button.image = NSImage(systemSymbolName: "arrow.triangle.2.circlepath", accessibilityDescription: "Loading")
                }
            }
        } else {
            updateStatusIcon(based: menu.item(at: 0)?.title ?? "")
        }
    }
    
    private func updateStatusIcon(based output: String) {
        // Ensure status item is visible
        ensureStatusItemVisible()
        
        if let button = statusItem.button {
            if output.contains("Error") {
                // Use error icon
                if let errorIcon = NSImage(named: "MenuBarIconError") {
                    button.image = errorIcon
                    button.image?.size = NSSize(width: 18, height: 18)
                } else {
                    // Fallback to system icon
                    button.image = NSImage(systemSymbolName: "exclamationmark.circle", accessibilityDescription: "Error")
                }
            } else {
                // Use normal icon
                if let normalIcon = NSImage(named: "MenuBarIcons") {
                    button.image = normalIcon
                    button.image?.size = NSSize(width: 18, height: 18)
                } else {
                    // Fallback to system icon
                    button.image = NSImage(systemSymbolName: "dollarsign.circle", accessibilityDescription: "Balance")
                }
            }
        }
    }
}