#!/bin/bash
# BalanceFetcher Cryptocurrency Balance Example
#
# This script demonstrates how to fetch cryptocurrency balances
# and format them for display in the menu bar.
#
# Dependencies:
# - curl: for making HTTP requests
# - jq: for parsing JSON responses (install with brew install jq)

# Configuration
# Replace with your actual wallet address or API details
BTC_ADDRESS="YOUR_BTC_ADDRESS_HERE"
ETH_ADDRESS="YOUR_ETH_ADDRESS_HERE"

# Function to fetch Bitcoin balance
fetch_btc_balance() {
  # Using Blockchain.info public API
  response=$(curl -s -f "https://blockchain.info/balance?active=$BTC_ADDRESS")
  
  if [ $? -ne 0 ]; then
    echo "Error: BTC API failed"
    return 1
  fi
  
  if command -v jq &> /dev/null; then
    # Extract balance in satoshis and convert to BTC (1 BTC = 100,000,000 satoshis)
    satoshis=$(echo "$response" | jq -r ".[\"$BTC_ADDRESS\"].final_balance")
    
    if [ $? -ne 0 ] || [ -z "$satoshis" ]; then
      echo "Error: Invalid BTC data"
      return 1
    fi
    
    # Convert satoshis to BTC with 8 decimal places
    btc=$(echo "scale=8; $satoshis / 100000000" | bc)
    echo "$btc BTC"
    return 0
  else
    echo "Error: jq required"
    return 1
  fi
}

# Function to fetch Ethereum balance
fetch_eth_balance() {
  # Using Etherscan public API
  # Note: For production use, register for an API key at https://etherscan.io/apis
  response=$(curl -s -f "https://api.etherscan.io/api?module=account&action=balance&address=$ETH_ADDRESS&tag=latest")
  
  if [ $? -ne 0 ]; then
    echo "Error: ETH API failed"
    return 1
  fi
  
  if command -v jq &> /dev/null; then
    # Check status and extract balance in wei
    status=$(echo "$response" | jq -r '.status')
    
    if [ "$status" != "1" ]; then
      echo "Error: ETH API error"
      return 1
    fi
    
    wei=$(echo "$response" | jq -r '.result')
    
    if [ $? -ne 0 ] || [ -z "$wei" ]; then
      echo "Error: Invalid ETH data"
      return 1
    fi
    
    # Convert wei to ETH (1 ETH = 10^18 wei)
    eth=$(echo "scale=6; $wei / 1000000000000000000" | bc)
    echo "$eth ETH"
    return 0
  else
    echo "Error: jq required"
    return 1
  fi
}

# Main execution logic
# Uncomment the balance method you want to use
balance=$(fetch_btc_balance)
# balance=$(fetch_eth_balance)

# Return the balance
echo "$balance"