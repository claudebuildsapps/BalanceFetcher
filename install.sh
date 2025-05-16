#!/bin/bash

# Exit on any error
set -e

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Directory where the app will be installed
INSTALL_DIR="$HOME/Applications/BalanceFetcher"
BIN_DIR="$HOME/.local/bin"

# Function to display usage instructions
display_usage() {
  echo "BalanceFetcher Installer"
  echo ""
  echo "Usage: $0 [command]"
  echo ""
  echo "Commands:"
  echo "  install    Install BalanceFetcher (default if no command provided)"
  echo "  uninstall  Remove BalanceFetcher from your system"
  echo "  update     Update to the latest version"
  echo ""
}

# Function to install the application
install_app() {
  echo -e "${BLUE}Installing BalanceFetcher...${NC}"
  
  # Create installation directory if it doesn't exist
  mkdir -p "$INSTALL_DIR"
  mkdir -p "$BIN_DIR"
  
  # Build the application in release mode
  echo -e "${BLUE}Building application...${NC}"
  swift build -c release
  
  # Copy the built executable to the installation directory
  cp ./.build/release/BalanceFetcher "$INSTALL_DIR/"
  
  # Create a launcher script in ~/.local/bin
  echo -e "${BLUE}Creating launcher script...${NC}"
  cat > "$BIN_DIR/balancefetcher" << EOF
#!/bin/bash
# Launcher for BalanceFetcher
exec "$INSTALL_DIR/BalanceFetcher" "\$@"
EOF
  
  # Make the launcher script executable
  chmod +x "$BIN_DIR/balancefetcher"
  
  # Check if ~/.local/bin is in the PATH
  if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo -e "${YELLOW}Note: $BIN_DIR is not in your PATH.${NC}"
    echo -e "Consider adding this line to your shell profile (e.g., ~/.bashrc or ~/.zshrc):"
    echo -e "  export PATH=\"\$PATH:$BIN_DIR\""
  fi
  
  echo -e "${GREEN}Installation complete!${NC}"
  echo -e "You can now run BalanceFetcher by typing 'balancefetcher' in your terminal,"
  echo -e "or by running '$INSTALL_DIR/BalanceFetcher' directly."
}

# Function to uninstall the application
uninstall_app() {
  echo -e "${BLUE}Uninstalling BalanceFetcher...${NC}"
  
  # Kill the application if it's running
  if pgrep -f "BalanceFetcher" > /dev/null; then
    echo -e "${BLUE}Terminating running instances...${NC}"
    pkill -f "BalanceFetcher" || true
  fi
  
  # Remove the installation directory
  if [ -d "$INSTALL_DIR" ]; then
    echo -e "${BLUE}Removing application files...${NC}"
    rm -rf "$INSTALL_DIR"
  fi
  
  # Remove the launcher script
  if [ -f "$BIN_DIR/balancefetcher" ]; then
    echo -e "${BLUE}Removing launcher script...${NC}"
    rm "$BIN_DIR/balancefetcher"
  fi
  
  echo -e "${GREEN}BalanceFetcher has been uninstalled.${NC}"
}

# Function to update the application
update_app() {
  echo -e "${BLUE}Updating BalanceFetcher...${NC}"
  
  # Pull the latest changes if this is a git repository
  if [ -d .git ]; then
    echo -e "${BLUE}Fetching latest updates...${NC}"
    git pull
  fi
  
  # Reinstall the application
  install_app
  
  echo -e "${GREEN}BalanceFetcher has been updated to the latest version.${NC}"
}

# Process command line arguments
if [ $# -eq 0 ]; then
  install_app
elif [ "$1" = "install" ]; then
  install_app
elif [ "$1" = "uninstall" ]; then
  uninstall_app
elif [ "$1" = "update" ]; then
  update_app
elif [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  display_usage
else
  echo -e "${YELLOW}Unknown command: $1${NC}"
  display_usage
  exit 1
fi

exit 0