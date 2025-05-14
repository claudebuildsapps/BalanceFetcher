#!/bin/bash

# Colors for output
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Application paths
APP_NAME="BalanceFetcher"
INSTALL_DIR="$HOME/Applications/$APP_NAME"
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
    
    mkdir -p "$INSTALL_DIR"
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
    
    # Copy executable
    cp ./.build/release/"$APP_NAME" "$INSTALL_DIR/"
    
    # Create launcher script
    cat > "$LAUNCHER_PATH" << EOF
#!/bin/bash
# BalanceFetcher Launcher
exec "$INSTALL_DIR/$APP_NAME" "\$@"
EOF
    
    # Make launcher executable
    chmod +x "$LAUNCHER_PATH"
    
    echo -e "${GREEN}Installation complete.${NC}"
}

# Function to create launch agent for auto-startup
create_launch_agent() {
    echo -e "${BLUE}Creating LaunchAgent for automatic startup...${NC}"
    
    cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.$APP_NAME</string>
    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL_DIR/$APP_NAME</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/dev/null</string>
    <key>StandardErrorPath</key>
    <string>/dev/null</string>
</dict>
</plist>
EOF
    
    # Load the launch agent
    launchctl load "$PLIST_FILE"
    
    echo -e "${GREEN}LaunchAgent created and loaded.${NC}"
}

# Function to start the application immediately
start_app() {
    echo -e "${BLUE}Starting $APP_NAME...${NC}"
    
    # Kill any existing instances
    killall "$APP_NAME" 2>/dev/null || true
    
    # Start the app
    "$INSTALL_DIR/$APP_NAME" &
    
    echo -e "${GREEN}$APP_NAME started. Look for the icon in your menu bar.${NC}"
}

# Main installation process
main_install() {
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
    echo ""
    echo -e "To uninstall, run: ${BLUE}./auto_install.sh uninstall${NC}"
}

# Function to uninstall the application
uninstall_app() {
    echo -e "${BLUE}Uninstalling $APP_NAME...${NC}"
    
    # Unload and remove launch agent
    launchctl unload "$PLIST_FILE" 2>/dev/null || true
    rm -f "$PLIST_FILE"
    
    # Kill running instance
    killall "$APP_NAME" 2>/dev/null || true
    
    # Remove installed files
    rm -rf "$INSTALL_DIR"
    rm -f "$LAUNCHER_PATH"
    
    echo -e "${GREEN}$APP_NAME has been completely uninstalled.${NC}"
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