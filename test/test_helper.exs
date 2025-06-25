# Configure ExUnit
ExUnit.start()

# Test configuration
ExUnit.configure(
  exclude: [:external],
  formatters: [ExUnit.CLIFormatter]
)

IO.puts("""

EAGL Test Suite
===============

Test Tags:
- :external - Tests that require internet connectivity
             (e.g., downloading GLB files from Khronos repository)

Running Tests:
- All tests:           mix test
- Unit tests only:     mix test (excludes :external by default)
- External tests:      mix test --include external
- Specific test file:  mix test test/gltf/glb_loader_test.exs --include external

External Test Dependencies:
The :external tests download real GLB files from the Khronos glTF Sample Assets
repository to validate the GLB loader against production glTF files.

URL used for testing:
https://github.com/KhronosGroup/glTF-Sample-Assets/raw/refs/heads/main/Models/ChairDamaskPurplegold/glTF-Binary/ChairDamaskPurplegold.glb

""")
