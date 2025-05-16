import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SettingsView: View {
    // Create local copies of settings that only get applied on save
    @ObservedObject var settings: SettingsModel
    @State private var localSourceType: SettingsModel.SourceType
    @State private var localScriptPath: String
    @State private var localCommandString: String 
    @State private var localRefreshInterval: SettingsModel.RefreshInterval
    @State private var localLaunchAtLogin: Bool
    
    // Error handling state
    @State private var showError = false
    @State private var errorMessage = ""
    
    @State private var showFileImporter = false
    @Environment(\.presentationMode) var presentationMode
    
    // Helper function for debug logging
    private func debugLog(_ message: String) {
        if SettingsModel.DEBUG_LOGGING {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            let timestamp = formatter.string(from: Date())
            let logMessage = "\(timestamp) ⚙️ [SettingsView] \(message)"
            
            // Print to console
            print(logMessage)
            
            // Write to log file
            do {
                if let data = "\(logMessage)\n".data(using: .utf8) {
                    let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: SettingsModel.logFile))
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    try fileHandle.close()
                }
            } catch {
                print("Error writing to log file: \(error)")
            }
        }
    }
    
    // This function has been replaced by inline code
    
    // Initialize with current settings
    init(settings: SettingsModel) {
        self.settings = settings
        
        // Log the current settings
        if SettingsModel.DEBUG_LOGGING {
            print("⚙️ [SettingsView] Initializing with settings:")
            print("⚙️ [SettingsView] sourceType: \(settings.sourceType)")
            print("⚙️ [SettingsView] scriptPath: \(settings.scriptPath)")
            print("⚙️ [SettingsView] commandString: \(settings.commandString)")
            print("⚙️ [SettingsView] refreshInterval: \(settings.refreshInterval.rawValue)")
            print("⚙️ [SettingsView] launchAtLogin: \(settings.launchAtLogin)")
        }
        
        // Initialize state variables with the current settings
        _localSourceType = State(initialValue: settings.sourceType)
        _localScriptPath = State(initialValue: settings.scriptPath)
        _localCommandString = State(initialValue: settings.commandString)
        _localRefreshInterval = State(initialValue: settings.refreshInterval)
        _localLaunchAtLogin = State(initialValue: settings.launchAtLogin)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BalanceFetcher Settings")
                .font(.headline)
                .padding(.bottom, 5)
            
            // Source Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Data Source").font(.subheadline).bold()
                
                Picker("", selection: $localSourceType) {
                    Text("Script File").tag(SettingsModel.SourceType.scriptFile)
                    Text("Shell Command").tag(SettingsModel.SourceType.command)
                }
                .pickerStyle(SegmentedPickerStyle())
                .labelsHidden()
            }
            
            // Script Path or Command Section
            VStack(alignment: .leading, spacing: 5) {
                if localSourceType == .scriptFile {
                    HStack {
                        TextField("Path to script", text: $localScriptPath)
                            .frame(minWidth: 250)
                        
                        Button("Browse") {
                            openFileDialog()
                        }
                        .frame(width: 70)
                    }
                    
                    Text("Select the script to execute for balance information.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    TextField("Shell command (e.g., /usr/local/bin/mycmd)", text: $localCommandString)
                    
                    Text("Enter a shell command to execute (must output a single line)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Refresh Interval Section
            VStack(alignment: .leading, spacing: 5) {
                Text("Refresh Interval").font(.subheadline).bold()
                
                Picker("", selection: $localRefreshInterval) {
                    ForEach(SettingsModel.RefreshInterval.allCases) { interval in
                        Text(interval.rawValue).tag(interval)
                    }
                }
                .pickerStyle(PopUpButtonPickerStyle())
                .labelsHidden()
                
                Text("How often to update the balance.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Launch at Login Section
            Toggle("Launch at Login", isOn: $localLaunchAtLogin)
            
            Text("Start automatically when you log in.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Buttons
            HStack {
                Spacer()
                
                Button("Cancel") {
                    debugLog("Cancel button pressed")
                    debugLog("Discarding local changes:")
                    debugLog("Discarded sourceType: \(localSourceType)")
                    debugLog("Discarded scriptPath: \(localScriptPath)")
                    debugLog("Discarded commandString: \(localCommandString)")
                    debugLog("Discarded refreshInterval: \(localRefreshInterval.rawValue)")
                    debugLog("Discarded launchAtLogin: \(localLaunchAtLogin)")
                    
                    // Display logs in terminal window for debugging
                    debugLog("Opening log terminal")
                    debugLog("Log file path: \(SettingsModel.logFile)")
                    
                    // Use shell escape for paths with spaces
                    let escapedPath = SettingsModel.logFile.replacingOccurrences(of: " ", with: "\\ ")
                    let command = "cat \(escapedPath); echo \"\\n--- WATCHING FOR CHANGES ---\"; tail -f \(escapedPath)"
                    
                    let logCommand = "osascript -e 'tell application \"Terminal\" to do script \"\(command)\"'"
                    debugLog("Running command: \(logCommand)")
                    Process.launchedProcess(launchPath: "/bin/bash", arguments: ["-c", logCommand])
                    
                    presentationMode.wrappedValue.dismiss()
                }
                
                Button("Save") {
                    do {
                        debugLog("Save button pressed")
                        
                        // Log before applying changes
                        debugLog("Before applying changes to settings:")
                        debugLog("Local sourceType: \(localSourceType)")
                        debugLog("Local scriptPath: \(localScriptPath)")
                        debugLog("Local commandString: \(localCommandString)")
                        debugLog("Local refreshInterval: \(localRefreshInterval.rawValue)")
                        debugLog("Local launchAtLogin: \(localLaunchAtLogin)")
                        
                        // Apply local changes to the actual settings
                        settings.sourceType = localSourceType
                        debugLog("Applied sourceType")
                        
                        settings.scriptPath = localScriptPath
                        debugLog("Applied scriptPath")
                        
                        settings.commandString = localCommandString
                        debugLog("Applied commandString")
                        
                        settings.refreshInterval = localRefreshInterval
                        debugLog("Applied refreshInterval")
                        
                        // Only update launch at login if it changed
                        if settings.launchAtLogin != localLaunchAtLogin {
                            debugLog("Updating launchAtLogin")
                            settings.launchAtLogin = localLaunchAtLogin
                            settings.updateLaunchAtLoginStatus()
                        }
                        
                        // Save to persistent storage
                        debugLog("Saving settings to persistent storage")
                        settings.saveSettings()
                        
                        // Notify AppDelegate that settings changed
                        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                            debugLog("Updating AppDelegate")
                            
                            // Ensure we restart the timer properly
                            debugLog("Stopping refresh timer")
                            appDelegate.stopRefreshTimer()
                            
                            debugLog("Starting refresh timer")
                            appDelegate.startRefreshTimer()
                            
                            // Force refresh display
                            debugLog("Scheduling execute script")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.debugLog("Executing script after delay")
                                appDelegate.executeScript()
                            }
                        } else {
                            debugLog("⚠️ WARNING: AppDelegate is nil")
                        }
                        
                        // Display logs in terminal window for debugging
                        debugLog("Opening log terminal")
                        debugLog("Log file path: \(SettingsModel.logFile)")
                        
                        // Use shell escape for paths with spaces
                        let escapedPath = SettingsModel.logFile.replacingOccurrences(of: " ", with: "\\ ")
                        let command = "cat \(escapedPath); echo \"\\n--- WATCHING FOR CHANGES ---\"; tail -f \(escapedPath)"
                        
                        let logCommand = "osascript -e 'tell application \"Terminal\" to do script \"\(command)\"'"
                        debugLog("Running command: \(logCommand)")
                        Process.launchedProcess(launchPath: "/bin/bash", arguments: ["-c", logCommand])
                        
                        debugLog("Dismissing settings window")
                        presentationMode.wrappedValue.dismiss()
                    } catch {
                        // Log any errors that occur
                        debugLog("❌ ERROR in save operation: \(error.localizedDescription)")
                        errorMessage = "Error saving settings: \(error.localizedDescription)"
                        showError = true
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400, height: 340)
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Settings Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            debugLog("Settings view appeared")
        }
        .onDisappear {
            debugLog("Settings view disappeared")
        }
    }
    
    // Function to open a file picker dialog using NSOpenPanel
    private func openFileDialog() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedContentTypes = [UTType.shellScript, UTType.executable]
        openPanel.title = "Select Script"
        openPanel.message = "Choose a script to execute"
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                DispatchQueue.main.async {
                    // Update the local variable, not the actual setting
                    self.localScriptPath = url.path
                }
            }
        }
    }
}