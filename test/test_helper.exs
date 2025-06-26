# Simple test helper to avoid hanging issues
ExUnit.start()

# Basic configuration
ExUnit.configure(
  exclude: [:external],
  formatters: [ExUnit.CLIFormatter]
)
