#!/bin/bash

# Exit on any error
set -e

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Building BalanceFetcher...${NC}"
# Build the application
swift build

# Get the path to the built executable
exec_path="./.build/debug/BalanceFetcher"

# Check if the application is already running
if pgrep -f "BalanceFetcher" > /dev/null; then
    echo -e "${GREEN}BalanceFetcher is already running.${NC}"
    echo "Look for the icon in your menu bar."
    echo "You can quit the app from its menu bar dropdown."
    exit 0
fi

# Prepare to run the application
echo -e "${BLUE}Launching BalanceFetcher...${NC}"

# Run the application and detach it completely from the terminal
nohup "$exec_path" > /dev/null 2>&1 &
APP_PID=$!

# Give it a moment to start up
sleep 1

# Check if the process is still running
if ps -p $APP_PID > /dev/null; then
    echo -e "${GREEN}BalanceFetcher is now running in the background!${NC}"
    echo "✓ Icon should appear in your menu bar"
    echo "✓ The app will continue running even if you close this terminal"
    echo "✓ To quit, select 'Quit' from the menu bar dropdown"
    echo ""
    echo "Enjoy using BalanceFetcher!"
else
    echo "Failed to start BalanceFetcher. Check the logs for details."
    exit 1
fi