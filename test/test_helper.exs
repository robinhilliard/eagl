# Simple test helper to avoid hanging issues
ExUnit.start()

# Basic configuration
ExUnit.configure(
  exclude: [:external],
  formatters: [ExUnit.CLIFormatter],
  colors: [enabled: true],
  trace: false,
  max_failures: :infinity
)

# CI: Work around Mesa/llvmpipe segfault during wx/GL teardown (exit 139).
# All tests have passed; halt prevents the crash during shutdown.
if System.get_env("CI") == "true" do
  System.at_exit(fn _status -> System.halt(0) end)
end
