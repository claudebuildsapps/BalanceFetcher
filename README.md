# BalanceFetcher

A macOS menu bar application that displays the output of a script in the menu bar status area. Ideal for monitoring account balances, system metrics, or any information that can be retrieved via a script.

## Features

- Displays an icon in the macOS menu bar status area
- Runs a predefined script at configurable intervals
- Displays the script's output when the menu bar icon is clicked
- Updates automatically based on the configured refresh rate
- Startup on login option
- Configurable refresh interval
- Visual status indicators (normal, error, loading)
- Optimized for low resource usage

## Requirements

- macOS 13.0 or later
- Swift 5.9 or later

## Building and Running

The project uses Swift Package Manager for dependencies.

To build and run the project:

```bash
# Clone the repository
git clone https://github.com/yourusername/BalanceFetcher.git
cd BalanceFetcher

# Build the project
swift build

# Run the application
swift run
```

For development in Xcode:

```bash
# Generate an Xcode project
swift package generate-xcodeproj

# Open the generated project
open BalanceFetcher.xcodeproj
```

## Configuration

The application can be configured through its settings interface:

- **Script Path**: Path to the script to execute
- **Refresh Interval**: Time between script executions (15s, 30s, 1m, 5m, 15m, 30m, 1h)
- **Launch at Login**: Option to automatically start the application on system boot

## Sample Scripts

BalanceFetcher comes with example scripts in the `Resources/Scripts` directory:

- `sample_balance.sh` - A basic demonstration script with simulated balance values
- `api_balance_example.sh` - Example showing how to retrieve data from a REST API
- `crypto_balance_example.sh` - Example showing how to fetch cryptocurrency balances

You can use these as templates for creating your own custom scripts.

## Script Requirements

- Scripts must be executable (`chmod +x script.sh`)
- They should output a single line of text (ideally less than 20 characters)
- Exit with status code 0 for success, non-zero for errors
- For best display, include a currency symbol (e.g., $, €, £, ₿)

## Development

This project follows the implementation plan outlined in `IMPLEMENTATION.md`.

## License

This project is available under the MIT License. See the LICENSE file for more info.