import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var settings: SettingsModel
    @State private var showFileImporter = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("BalanceFetcher Settings")
                .font(.title)
                .padding(.bottom, 10)
            
            // Script Path Section
            VStack(alignment: .leading) {
                Text("Script Path")
                    .font(.headline)
                
                HStack {
                    TextField("Path to script", text: $settings.scriptPath)
                        .frame(minWidth: 300)
                        .disabled(showFileImporter)
                    
                    Button("Browse...") {
                        openFileDialog()
                    }
                    .disabled(showFileImporter)
                }
                .padding(.bottom, 5)
                
                Text("Select the script to execute for retrieving balance information.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Refresh Interval Section
            VStack(alignment: .leading) {
                Text("Refresh Interval")
                    .font(.headline)
                
                Picker("", selection: $settings.refreshInterval) {
                    ForEach(SettingsModel.RefreshInterval.allCases) { interval in
                        Text(interval.rawValue).tag(interval)
                    }
                }
                .pickerStyle(PopUpButtonPickerStyle())
                .padding(.bottom, 5)
                
                Text("How often the script should be executed to update the balance.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Launch at Login Section
            VStack(alignment: .leading) {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                    .padding(.bottom, 5)
                    .onChange(of: settings.launchAtLogin) { newValue in
                        // Update launch at login status when toggled
                        settings.updateLaunchAtLoginStatus()
                    }
                
                Text("Start BalanceFetcher automatically when you log in.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Buttons
            HStack {
                Spacer()
                
                Button("Cancel") {
                    // Close without saving
                    presentationMode.wrappedValue.dismiss()
                }
                
                Button("Save") {
                    // Save settings and close
                    settings.saveSettings()
                    
                    // Notify AppDelegate that settings changed
                    if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                        appDelegate.startRefreshTimer()
                    }
                    
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(minWidth: 450, minHeight: 300)
    }
    
    // Function to open a file picker dialog using NSOpenPanel
    private func openFileDialog() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedContentTypes = [UTType.shellScript, UTType.executable]
        openPanel.title = "Select Script"
        openPanel.message = "Choose a script to execute for retrieving balance information"
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                DispatchQueue.main.async {
                    settings.scriptPath = url.path
                }
            }
        }
    }
}