import SwiftUI
import AppKit

class StatusBarController {
    private var statusItem: NSStatusItem
    private var menu: NSMenu
    
    // References to other components
    var scriptExecutor: ScriptExecutor?
    var settingsModel: SettingsModel?
    
    // Status indicators
    private var isLoading = false
    
    init() {
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
        menu.addItem(NSMenuItem(title: "Refresh", action: #selector(refresh), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        
        // Set the menu for the status item
        statusItem.menu = menu
    }
    
    @objc func refresh() {
        guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else { return }
        appDelegate.executeScript()
    }
    
    @objc func openSettings() {
        guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else { return }
        appDelegate.openSettings()
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    func updateDisplay(output: String) {
        if let firstItem = menu.item(at: 0) {
            firstItem.title = output
            
            // Update status bar icon if needed
            updateStatusIcon(based: output)
        }
    }
    
    func setLoading(_ loading: Bool) {
        isLoading = loading
        
        // Update refresh menu item
        if let refreshItem = menu.item(at: 2) {
            refreshItem.isEnabled = !loading
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