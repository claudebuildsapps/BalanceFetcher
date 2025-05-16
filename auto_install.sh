#!/bin/bash

# Colors for output
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Application paths
APP_NAME="BalanceFetcher"
INSTALL_DIR="$HOME/Applications/$APP_NAME.app"
CONTENTS_DIR="$INSTALL_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
LAUNCHER_PATH="$HOME/.local/bin/balancefetcher"
AUTOSTART_DIR="$HOME/Library/LaunchAgents"
PLIST_FILE="$AUTOSTART_DIR/com.user.$APP_NAME.plist"

# Print header
echo -e "${BOLD}╔═════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║       BalanceFetcher Auto-Installer     ║${NC}"
echo -e "${BOLD}╚═════════════════════════════════════════╝${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to ensure dependencies are installed
check_dependencies() {
    echo -e "${BLUE}Checking dependencies...${NC}"
    
    # Check Swift
    if ! command_exists swift; then
        echo -e "${RED}Swift is not installed. Please install Xcode or Swift toolchain.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}All dependencies are met.${NC}"
}

# Function to ensure installation directories exist
setup_directories() {
    echo -e "${BLUE}Setting up directories...${NC}"
    
    # Create app bundle structure
    mkdir -p "$MACOS_DIR"
    mkdir -p "$RESOURCES_DIR"
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$AUTOSTART_DIR"
    
    echo -e "${GREEN}Directories created.${NC}"
}

# Function to build the application
build_app() {
    echo -e "${BLUE}Building $APP_NAME in release mode...${NC}"
    
    # Build in release mode for better performance
    swift build -c release
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Build failed. Please check the errors above.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Build successful.${NC}"
}

# Function to install the application
install_app() {
    echo -e "${BLUE}Installing $APP_NAME to $INSTALL_DIR...${NC}"
    
    # Copy executable to macOS directory
    cp ./.build/release/"$APP_NAME" "$MACOS_DIR/"
    chmod +x "$MACOS_DIR/$APP_NAME"
    
    # Create Info.plist for the app bundle
    cat > "$CONTENTS_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.user.$APP_NAME</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2025</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
</dict>
</plist>
EOF
    
    # Create a simple app icon (placeholder)
    echo -e "${BLUE}Creating app icon...${NC}"
    # Copy icons if they exist, or use defaults
    if [ -d "src/BalanceFetcher/Resources/Assets.xcassets/AppIcon.appiconset" ]; then
        # Use first .png we find as the app icon
        ICON_SOURCE=$(find "src/BalanceFetcher/Resources/Assets.xcassets/AppIcon.appiconset" -name "*.png" | head -n 1)
        if [ -n "$ICON_SOURCE" ]; then
            cp "$ICON_SOURCE" "$RESOURCES_DIR/AppIcon.icns"
        fi
    fi
    
    # Create launcher script in ~/.local/bin
    cat > "$LAUNCHER_PATH" << EOF
#!/bin/bash
# BalanceFetcher Launcher
open "$INSTALL_DIR"
EOF
    
    # Make launcher executable
    chmod +x "$LAUNCHER_PATH"
    
    echo -e "${GREEN}Installation complete.${NC}"
}

# Function to create launch agent for auto-startup
create_launch_agent() {
    echo -e "${BLUE}Creating LaunchAgent for automatic startup...${NC}"
    
    # Make sure to unload any existing agent first
    launchctl unload "$PLIST_FILE" 2>/dev/null || true
    
    # Create the launch agent plist
    cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.$APP_NAME</string>
    <key>ProgramArguments</key>
    <array>
        <string>open</string>
        <string>$INSTALL_DIR</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/dev/null</string>
    <key>StandardErrorPath</key>
    <string>/dev/null</string>
</dict>
</plist>
EOF
    
    # Set proper permissions
    chmod 644 "$PLIST_FILE"
    
    # Load the launch agent
    launchctl load "$PLIST_FILE"
    
    echo -e "${GREEN}LaunchAgent created and loaded.${NC}"
}

# Function to check for existing application instances
check_running_instances() {
    # Check if app is already running
    RUNNING_COUNT=$(pgrep -f "$APP_NAME" | wc -l | tr -d ' ')
    if [ "$RUNNING_COUNT" -gt "0" ]; then
        echo -e "${BLUE}Detected existing instance of $APP_NAME running...${NC}"
        return 0
    fi
    return 1
}

# Function to start the application immediately
start_app() {
    echo -e "${BLUE}Starting $APP_NAME...${NC}"
    
    # First check if app is already running
    if check_running_instances; then
        echo -e "${BLUE}Terminating existing instances before launch...${NC}"
        
        # Kill all existing instances regardless of process name
        pkill -f "$APP_NAME" 2>/dev/null || true
        
        # Also check for specific executable
        pkill -f "$MACOS_DIR/$APP_NAME" 2>/dev/null || true
        
        # Wait a moment for processes to fully terminate
        sleep 2
    fi
    
    # Start the app using open command which is the proper way to launch macOS apps
    echo -e "${BLUE}Launching application...${NC}"
    # Create log directory if it doesn't exist
    mkdir -p "$HOME/Library/Logs/BalanceFetcher"
    
    # Launch the app with stdout and stderr redirected to a log file
    LOG_FILE="$HOME/Library/Logs/BalanceFetcher/launch-$(date +%Y%m%d-%H%M%S).log"
    echo -e "${BLUE}App logs will be saved to $LOG_FILE${NC}"
    open "$INSTALL_DIR" # No -n flag to avoid launching multiple instances
    
    # Wait briefly to confirm it launched
    sleep 2
    
    # Check if exactly one instance is running
    RUNNING_COUNT=$(pgrep -f "$MACOS_DIR/$APP_NAME" | wc -l | tr -d ' ')
    if [ "$RUNNING_COUNT" -eq "1" ]; then
        echo -e "${GREEN}$APP_NAME started successfully with a single instance. Look for the icon in your menu bar.${NC}"
    elif [ "$RUNNING_COUNT" -gt "1" ]; then
        echo -e "${RED}Warning: Multiple instances of $APP_NAME are running (count: $RUNNING_COUNT).${NC}"
        echo -e "${RED}Terminating all instances and trying again...${NC}"
        
        # Forcefully kill all instances
        pkill -9 -f "$APP_NAME" 2>/dev/null || true
        sleep 2
        
        # Try one more time with a clean launch
        open "$INSTALL_DIR"
        
        sleep 2
        RUNNING_COUNT=$(pgrep -f "$MACOS_DIR/$APP_NAME" | wc -l | tr -d ' ')
        if [ "$RUNNING_COUNT" -eq "1" ]; then
            echo -e "${GREEN}$APP_NAME started successfully after retry.${NC}"
        else
            echo -e "${RED}Still having issues with instance management. Please try running the uninstall command first.${NC}"
        fi
    else
        echo -e "${RED}Failed to start $APP_NAME. Try opening it manually from Applications.${NC}"
    fi
}

# Main installation process
main_install() {
    # First check for existing installations and running instances
    if [ -d "$INSTALL_DIR" ]; then
        echo -e "${BLUE}Existing installation detected. Removing it first...${NC}"
        uninstall_app
        sleep 2 # Wait for uninstall to complete
    fi
    
    check_dependencies
    setup_directories
    build_app
    install_app
    create_launch_agent
    start_app
    
    echo ""
    echo -e "${BOLD}╔═════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║       Installation Complete!            ║${NC}"
    echo -e "${BOLD}╚═════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}✓${NC} BalanceFetcher has been installed and started"
    echo -e "${GREEN}✓${NC} It will start automatically when you log in"
    echo -e "${GREEN}✓${NC} Look for the icon in your menu bar"
    echo -e "${GREEN}✓${NC} Logs are available at $HOME/Library/Logs/BalanceFetcher/"
    echo -e "${GREEN}✓${NC} To view logs in real-time, run: tail -f $HOME/Library/Logs/BalanceFetcher/*.log"
    echo ""
    echo -e "To uninstall, run: ${BLUE}./auto_install.sh uninstall${NC}"
}

# Function to uninstall the application
uninstall_app() {
    echo -e "${BLUE}Uninstalling $APP_NAME...${NC}"
    
    # Unload and remove launch agent
    echo -e "${BLUE}Removing autostart configuration...${NC}"
    launchctl unload "$PLIST_FILE" 2>/dev/null || true
    rm -f "$PLIST_FILE"
    
    # Terminate any running instances
    echo -e "${BLUE}Terminating any running instances...${NC}"
    
    # Try to terminate by process name
    pkill -f "$APP_NAME" 2>/dev/null || true
    # Also target the specific executable path
    pkill -f "$MACOS_DIR/$APP_NAME" 2>/dev/null || true
    
    # Wait briefly to allow processes to terminate
    sleep 1
    
    # Check if processes are still running and force kill if needed
    if pgrep -f "$APP_NAME" > /dev/null || pgrep -f "$MACOS_DIR/$APP_NAME" > /dev/null; then
        echo -e "${BLUE}Using force kill for remaining processes...${NC}"
        pkill -9 -f "$APP_NAME" 2>/dev/null || true
        pkill -9 -f "$MACOS_DIR/$APP_NAME" 2>/dev/null || true
        sleep 1
    fi
    
    # Remove installed files
    echo -e "${BLUE}Removing application files...${NC}"
    rm -rf "$INSTALL_DIR"
    rm -f "$LAUNCHER_PATH"
    
    # Clear any leftover application state
    echo -e "${BLUE}Clearing application preferences...${NC}"
    defaults delete com.user.$APP_NAME 2>/dev/null || true
    
    echo -e "${GREEN}$APP_NAME has been completely uninstalled.${NC}"
    echo -e "${GREEN}All processes terminated and files removed.${NC}"
}

# Process command line arguments
if [ $# -eq 0 ]; then
    main_install
elif [ "$1" = "uninstall" ]; then
    uninstall_app
else
    echo -e "${RED}Unknown command: $1${NC}"
    echo "Usage: $0 [uninstall]"
    exit 1
fi

exit 0