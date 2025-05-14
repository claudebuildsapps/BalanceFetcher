# MacOS Menu Bar Script Display

## Overview
A simple MacOS menu bar application that displays the output of a script in the menu bar status area (top right of screen).

## Core Functionality
- Display an icon in the MacOS menu bar status area
- Run a predefined script at configurable intervals
- Display the script's output when the menu bar icon is clicked
- Update the display automatically based on the configured refresh rate

## Technical Requirements
- Written in Swift
- Compatible with MacOS 13.0+
- Minimal resource usage (CPU, memory)
- Startup on login option
- Configurable refresh interval

## User Interface
- Menu bar icon with appropriate visual design
- Dropdown menu showing script output
- Settings interface for configuration:
  - Script path selection
  - Refresh interval adjustment
  - Launch at login toggle
  - Quit application option

## Settings
- **Script Path**: Path to the script to execute
- **Refresh Interval**: Time between script executions (15s, 30s, 1m, 5m, 15m, 30m, 1h)
- **Launch at Login**: Option to automatically start the application on system boot

## Development Phases
1. **Basic Implementation**
   - Menu bar icon display
   - Script execution functionality
   - Simple dropdown display

2. **Configuration and Settings**
   - Settings interface
   - Persistence of user preferences
   - Launch at login implementation

3. **Polish and Refinements**
   - Error handling
   - Visual refinements
   - Performance optimizations

## Technical Considerations
- Use SwiftUI for UI components
- NSStatusBar API for menu bar integration
- UserDefaults for settings persistence
- LaunchServices API for startup item management

## Future Enhancements
- Custom formatting options for script output
- Support for multiple scripts with tabs
- Notification on specific output conditions
- Light/dark mode-specific icons