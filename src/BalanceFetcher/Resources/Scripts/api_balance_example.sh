#!/bin/bash
# BalanceFetcher API Example Script
#
# This script demonstrates how to fetch data from an API and extract
# balance information. You would customize this for your specific provider.
#
# Dependencies:
# - curl: for making HTTP requests
# - jq: for parsing JSON responses (install with brew install jq)

# Configuration
# Replace these with your actual API details
API_URL="https://api.example.com/v1/accounts/balance"
API_KEY="YOUR_API_KEY_HERE"

# Function to fetch balance from API
fetch_balance() {
  # Make API request
  response=$(curl -s -f -H "Authorization: Bearer $API_KEY" "$API_URL")
  
  # Check if curl command succeeded
  if [ $? -ne 0 ]; then
    echo "Error: Connection failed"
    exit 1
  fi
  
  # Parse JSON response (requires jq)
  if command -v jq &> /dev/null; then
    # Extract balance from JSON (customize jq query for your API)
    balance=$(echo "$response" | jq -r '.data.balance')
    
    # Check if jq extraction succeeded
    if [ $? -ne 0 ] || [ "$balance" == "null" ]; then
      echo "Error: Invalid data"
      exit 1
    fi
    
    # Format balance for display
    formatted_balance=$(printf "$%.2f" $balance)
    echo "$formatted_balance"
    exit 0
  else
    # jq not installed
    echo "Error: jq required"
    exit 1
  fi
}

# Execute main function
fetch_balance