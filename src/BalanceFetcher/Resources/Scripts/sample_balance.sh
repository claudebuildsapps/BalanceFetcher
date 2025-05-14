#!/bin/bash
# BalanceFetcher Sample Script
#
# This is a sample script for BalanceFetcher that demonstrates how to format output
# for display in the menu bar. For real use, you would replace this with actual
# code to fetch your balance from a bank API, cryptocurrency wallet, or other source.
#
# Requirements:
# - Script must output a single line of text
# - For best display, keep the output concise (ideally under 20 characters)
# - Script should handle its own error cases and return a user-friendly message
# - Exit with status code 0 for success, non-zero for errors

# Simulate fetching a balance (replace with actual API calls)
function fetch_mock_balance() {
  # Randomly generate a balance for demonstration
  local dollars=$((1000 + RANDOM % 9000))
  local cents=$((RANDOM % 100))
  
  # Format with dollar sign and 2 decimal places
  printf "$%d.%02d" $dollars $cents
}

# Simulate occasional errors
function simulate_error() {
  # 1 in 10 chance of error for demonstration
  if [ $((RANDOM % 10)) -eq 0 ]; then
    return 1
  fi
  return 0
}

# Main execution
if simulate_error; then
  # Success case - output the balance
  balance=$(fetch_mock_balance)
  echo "$balance"
  exit 0
else
  # Error case - output an error message
  echo "Error: Unavailable"
  exit 1
fi