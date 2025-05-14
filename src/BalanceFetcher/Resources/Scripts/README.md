# BalanceFetcher Scripts

This directory contains sample scripts that can be used with BalanceFetcher to display balance information in your menu bar.

## Available Scripts

1. **sample_balance.sh** - A simple demonstration script that returns random balance values for testing
2. **api_balance_example.sh** - Example of how to fetch balance from a REST API
3. **crypto_balance_example.sh** - Example of how to fetch cryptocurrency balances

## Creating Your Own Scripts

When creating a script for BalanceFetcher, follow these guidelines:

1. Make sure your script is executable (`chmod +x your_script.sh`)
2. The script must output a single line of text (ideally less than 20 characters)
3. For best display, include a currency symbol (e.g., $, €, £, ₿)
4. Return exit code 0 for success, non-zero for errors
5. Handle all errors gracefully with user-friendly error messages

## Permissions

For security, BalanceFetcher requires explicit permission to run your script. When selecting a script in the settings, you'll be prompted to approve access.

## Dependencies

Some example scripts require additional tools:
- **curl**: For making API requests (included in macOS)
- **jq**: For parsing JSON responses (install via `brew install jq`)

## Example Output

Good balance outputs:
- `$1,234.56`
- `€789.10`
- `1.25 BTC`
- `$1.2K`

## Script Execution

Scripts will be executed at the interval configured in BalanceFetcher settings. The output will be displayed in the menu bar and in the dropdown menu.