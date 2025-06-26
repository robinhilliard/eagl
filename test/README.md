# EAGL Testing Documentation

## Automated Example Testing with Timeouts

EAGL includes automated testing support for examples using timeout functionality. This allows examples to be tested in continuous integration environments without manual interaction.

### How It Works

1. **Window Timeout Option**: `EAGL.Window.run/3` accepts a `timeout` option
2. **Automatic Timer**: On first render, a timer is started if timeout is set
3. **Clean Exit**: After timeout, the example outputs a specific message and exits cleanly
4. **Parallel Testing**: Multiple examples can be tested in parallel for efficiency

### Window Timeout Option

The `EAGL.Window` module now supports a `timeout` option:

```elixir
# Run with 500ms timeout for automated testing
EAGL.Window.run(MyExample, "Title", timeout: 500)

# Normal interactive mode (no timeout)
EAGL.Window.run(MyExample, "Title", enter_to_exit: true)
```

When a timeout is set:
- A timer starts on the first render call
- After the specified milliseconds, the window outputs: `EAGL_TIMEOUT: Window timed out after Xms for automated testing`
- The example then exits cleanly with proper resource cleanup

### Example Module Support

Examples need to be updated to accept and pass options to `EAGL.Window.run/3`:

```elixir
defmodule MyExample do
  use EAGL.Window

  # Before: Fixed options
  def run_example do
    EAGL.Window.run(__MODULE__, "Title", enter_to_exit: true)
  end

  # After: Configurable options
  def run_example(opts \\ []) do
    default_opts = [enter_to_exit: true]
    final_opts = Keyword.merge(default_opts, opts)
    EAGL.Window.run(__MODULE__, "Title", final_opts)
  end

  # ... rest of implementation
end
```

### Running Tests

#### Individual Example Testing

```bash
# Test a single example with timeout
mix run -e "MyExample.run_example(timeout: 500)"

# Example should show normal output, then timeout message:
# "EAGL_TIMEOUT: Window timed out after 500ms for automated testing"
```

#### Automated Test Suite

```bash
# Run the automated test suite
mix test test/examples_test.exs

# With verbose output
mix test test/examples_test.exs --trace
```

The test suite verifies:
- Examples start up without errors
- Examples render at least once (setup succeeds)
- Examples timeout correctly with the expected message
- No error messages appear in output
- Proper resource cleanup occurs

#### Parallel Testing

The test suite runs multiple examples in parallel for efficiency:

```elixir
# Run all examples in parallel with 500ms timeout each
tasks = Enum.map(@examples, fn {module, name} ->
  Task.async(fn ->
    run_example_with_timeout(module, name)
  end)
end)

results = Task.await_many(tasks, 8_000)
```

### Adding Examples to Test Suite

To add an example to the automated test suite:

1. **Update the example** to accept options:
   ```elixir
   def run_example(opts \\ []) do
     default_opts = [enter_to_exit: true]
     final_opts = Keyword.merge(default_opts, opts)
     EAGL.Window.run(__MODULE__, "Title", final_opts)
   end
   ```

2. **Add to test list** in `test/examples_test.exs`:
   ```elixir
   @examples [
     {EAGL.Examples.LearnOpenGL.GettingStarted.ShadersExercise1, "3.4 Shaders Exercise 1"},
     {EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangle, "2.1 Hello Triangle"},
     {MyNewExample, "My New Example"}  # Add here
   ]
   ```

3. **Test manually** first:
   ```bash
   mix run -e "MyNewExample.run_example(timeout: 500)"
   ```

4. **Run test suite** to verify:
   ```bash
   mix test test/examples_test.exs
   ```

### Batch Update Script

Use the provided script to update multiple examples at once:

```bash
# Make script executable (if not already)
chmod +x priv/scripts/update_examples_for_testing

# Run the update script
./priv/scripts/update_examples_for_testing
```

Note: The script provides a starting point but may require manual adjustments for complex examples.

### Testing in CI/CD

The timeout functionality enables testing examples in continuous integration:

```yaml
# Example GitHub Actions workflow
- name: Test Examples
  run: mix test test/examples_test.exs
```

Benefits:
- **No Manual Interaction**: Examples run and exit automatically
- **Parallel Execution**: Multiple examples tested simultaneously
- **Resource Safety**: Proper cleanup even on timeout
- **Failure Detection**: Test failures indicate broken examples

### Timeout Guidelines

**Recommended timeout values:**
- **Local Development**: 500-1000ms (fast feedback)
- **CI/CD**: 1000-2000ms (allow for slower environments)
- **Complex Examples**: 2000-5000ms (examples with heavy initialization)

**Choosing timeout values:**
- Should be long enough for example to initialize and render once
- Should be short enough for efficient testing
- Consider shader compilation time
- Consider model loading time for complex examples

### Troubleshooting

**Example doesn't timeout:**
- Check if `run_example/1` accepts options
- Verify options are passed to `EAGL.Window.run/3`
- Check for compilation errors

**Timeout too short:**
- Increase timeout value for complex examples
- Consider initialization time (shaders, models, textures)

**Test failures:**
- Check example output for error messages
- Verify timeout message appears
- Run example manually to debug

**Resource cleanup errors:**
- Expected during timeout (OpenGL context destroyed)
- These are logged but don't affect test results
- Examples should still exit cleanly

### Current Status

**Updated Examples (supporting timeout):**
- `ShadersExercise1` (3.4)
- `HelloTriangle` (2.1)

**Pending Examples:**
- Most other LearnOpenGL examples need updating
- Use the batch update script as a starting point
- Manual verification recommended for each example

This testing framework provides a foundation for comprehensive automated testing of EAGL examples without requiring manual interaction or complex mocking.

## Current Test Coverage

The automated test suite currently includes **ALL 23 examples** available from the `run_examples` script:

### Non-Learn OpenGL Examples (2)
1. **Math Example** - Comprehensive EAGL.Math functionality demo
2. **Teapot Example** - 3D teapot with Phong shading

### Learn OpenGL Getting Started Examples (21)

**Hello Window (2):**
3. **1.1 HelloWindow** - Basic window creation 
4. **1.2 HelloWindowClear** - Basic window with custom clear color

**Hello Triangle (5):**
5. **2.1 HelloTriangle** - Simple triangle rendering
6. **2.2 HelloTriangleIndexed** - Element buffer objects
7. **2.3 HelloTriangleExercise1** - Two triangles side by side
8. **2.4 HelloTriangleExercise2** - Rectangle with EBO
9. **2.5 HelloTriangleExercise3** - Multiple shader programs

**Shaders (6):**
10. **3.1 ShadersUniform** - Uniform variables and animation
11. **3.2 ShadersInterpolation** - Vertex color interpolation
12. **3.3 ShadersClass** - Shader abstraction 
13. **3.4 ShadersExercise1** - Custom shader positioning
14. **3.5 ShadersExercise2** - Uniform-controlled transformations
15. **3.6 ShadersExercise3** - Position-to-color mapping

**Textures (6):**
16. **4.1 Textures** - Basic texture mapping
17. **4.2 TexturesCombined** - Multiple texture units
18. **4.3 TexturesExercise1** - Texture coordinate manipulation  
19. **4.4 TexturesExercise2** - Texture wrapping modes
20. **4.5 TexturesExercise3** - Texture flipping
21. **4.6 TexturesExercise4** - Animated texture mixing

**Transformations (3):**
22. **5.1 Transformations** - Basic matrix transformations
23. **5.2 TransformationsExercise1** - Multiple object transformations
24. **5.2 TransformationsExercise2** - Complex transformation patterns

All examples run in parallel with a 500ms timeout and verify:
- Clean initialization without errors
- Proper timeout behavior  
- Expected timeout message output
- No GL errors during startup phase

This provides **complete coverage** of all examples available through the `run_examples` script, ensuring comprehensive automated testing of the entire EAGL example suite.

# GLTF Module Testing Strategy

This document outlines the comprehensive testing approach for the GLTF library, organized by risk-based priority levels.

## Overview

The GLTF library implements a complete glTF 2.0 parser with support for both `.gltf` (JSON) and `.glb` (binary) formats. Our testing strategy ensures robust coverage while being efficient and maintainable.

## Priority-Based Testing Strategy

### 🔴 Critical Priority (85-95% Coverage)

**Modules**: GLB Loader, Data Store, Integration Tests

These modules handle the core file parsing and data management functionality. Failures here break the entire loading pipeline.

**Test Files**:
- `test/gltf_integration_test.exs` - End-to-end tests with real glTF files
- `test/gltf/glb_loader_test.exs` - GLB binary format parsing
- `test/gltf/data_store_test.exs` - Binary data management

**Focus Areas**:
- File I/O and HTTP client support
- Binary parsing according to glTF specification
- Error handling for malformed files
- Memory management for large assets
- All buffer types (GLB chunks, external files, data URIs)

### 🟡 High Priority (60-80% Coverage)

**Modules**: Accessor, Mesh, Buffer, Material

Core data structures with complex validation logic and data transformation.

**Test Files**:
- `test/gltf/accessor_test.exs` - Data type validation and sparse accessors
- `test/gltf/mesh_test.exs` - Primitive validation and attribute handling
- `test/gltf/buffer_test.exs` - Buffer loading and validation
- `test/gltf/material_test.exs` - Material properties and PBR validation

**Focus Areas**:
- Data type validation (component types, accessor types)
- Complex nested structures
- Real-world usage patterns
- Edge cases and boundary conditions

### 🟢 Medium Priority (40-60% Coverage)

**Modules**: Camera, Animation, Node, Texture, Image

Important modules with some validation logic but less complexity.

**Test Files**:
- `test/gltf/camera_test.exs` - Camera projection validation
- `test/gltf/animation_test.exs` - Animation channel validation
- `test/gltf/node_test.exs` - Node hierarchy and transforms
- `test/gltf/texture_test.exs` - Texture reference validation
- `test/gltf/image_test.exs` - Image loading and formats

**Focus Areas**:
- Basic validation logic
- Reference integrity
- Common usage patterns
- Error scenarios

### 🔵 Low Priority (30-50% Coverage)

**Modules**: Asset, Scene, BufferView, Sampler, Skin

Simple data containers with minimal validation logic.

**Test Files**:
- `test/gltf/asset_test.exs` - Version validation and metadata
- `test/gltf/scene_test.exs` - Scene node references
- `test/gltf/buffer_view_test.exs` - Buffer view parameters
- `test/gltf/sampler_test.exs` - Texture sampling parameters
- `test/gltf/skin_test.exs` - Skinning matrix references

**Focus Areas**:
- Basic load/unload functionality
- Required field validation
- Extension and extras preservation

## Running Tests

### Using the Test Runner

The `test/test_runner.exs` script provides organized test execution:

```bash
# Run all tests
elixir test/test_runner.exs

# Run only critical tests (for CI/PR checks)
elixir test/test_runner.exs --critical

# Run integration tests only
elixir test/test_runner.exs --integration

# Run tests by priority level
elixir test/test_runner.exs --priority high
elixir test/test_runner.exs --priority medium
elixir test/test_runner.exs --priority low

# Generate coverage report
elixir test/test_runner.exs --coverage
```

### Using Mix Directly

```bash
# Run all tests
mix test

# Run specific test file
mix test test/gltf/glb_loader_test.exs

# Run tests with coverage
mix test --cover

# Run tests matching pattern
mix test --only integration
```

## Test Structure and Patterns

### Integration Tests (`test/gltf_integration_test.exs`)

- **Purpose**: End-to-end validation with real glTF files
- **Scope**: Downloads and tests against Khronos sample assets
- **Validates**: Complete loading pipeline, structure integrity, index validation
- **Key Features**:
  - Downloads sample GLB files from Khronos repository
  - Tests multiple file formats and complexity levels
  - Validates both JSON library support (Poison/Jason)
  - Comprehensive error handling scenarios

### Critical Module Tests

**GLB Loader** (`test/gltf/glb_loader_test.exs`):
- Binary parsing according to glTF spec section 4
- HTTP client support (httpc, req, httpoison)
- Validation modes (normal/strict)
- Edge cases (malformed files, truncation, padding)

**Data Store** (`test/gltf/data_store_test.exs`):
- All buffer types (GLB chunks, external files, data URIs)
- Buffer slicing operations
- Memory efficiency with large files
- Mixed buffer type scenarios

### Module-Specific Tests

Each module test follows a consistent pattern:

```elixir
defmodule GLTF.ModuleTest do
  use ExUnit.Case, async: true
  doctest GLTF.Module

  describe "load/1" do
    # Basic loading scenarios
  end

  describe "validation" do
    # Error cases and edge conditions
  end

  describe "real-world patterns" do
    # Common usage scenarios
  end
end
```

## Writing New Tests

### For Critical Modules

1. **Comprehensive Coverage**: Aim for 85-95% line coverage
2. **Error Scenarios**: Test all error paths and edge cases
3. **Performance**: Include tests with large datasets
4. **Real-world Data**: Use actual glTF files when possible

### For Simple Data Containers

1. **Basic Functionality**: Test load/create functions
2. **Required Fields**: Validate required field checking
3. **Extensions**: Ensure extensions/extras are preserved
4. **Minimal Coverage**: 30-50% is sufficient

### Test Organization

```
test/
├── README.md                    # This file
├── test_runner.exs             # Priority-based test runner
├── gltf_integration_test.exs   # End-to-end integration tests
├── fixtures/                   # Test data and samples
│   ├── samples/               # Downloaded Khronos samples
│   └── custom/                # Custom test files
└── gltf/                      # Module-specific tests
    ├── glb_loader_test.exs    # Critical: GLB parsing
    ├── data_store_test.exs    # Critical: Data management
    ├── accessor_test.exs      # High: Data validation
    ├── mesh_test.exs          # High: Complex structures
    ├── asset_test.exs         # Low: Simple containers
    └── ...
```

## Coverage Reports

Generate detailed coverage reports:

```bash
# Generate coverage with ExCoveralls
mix test --cover

# Open HTML coverage report
open cover/excoveralls.html
```

### Coverage Targets by Priority

| Priority | Target Coverage | Rationale |
|----------|----------------|-----------|
| Critical | 85-95% | Mission-critical, failure breaks everything |
| High     | 60-80% | Important validation logic |
| Medium   | 40-60% | Some validation, mostly containers |
| Low      | 30-50% | Simple data containers |

## Integration with CI/CD

### Pull Request Checks
```bash
# Run critical tests for fast feedback
elixir test/test_runner.exs --critical
```

### Full CI Pipeline
```bash
# Run all tests with coverage
elixir test/test_runner.exs --coverage
```

### Performance Testing
```bash
# Run integration tests with large files
elixir test/test_runner.exs --integration
```

## Testing Philosophy

1. **Risk-Based Prioritization**: Focus testing effort where failures have the highest impact
2. **Real-World Validation**: Use actual glTF files from the Khronos sample repository
3. **Specification Compliance**: Ensure adherence to glTF 2.0 specification
4. **Maintainable Tests**: Write clear, self-documenting tests that are easy to update
5. **Efficient Execution**: Organize tests so developers can run relevant subsets quickly

## Common Test Patterns

### Testing Load Functions
```elixir
test "loads valid data" do
  json_data = %{"required_field" => "value"}
  assert {:ok, struct} = Module.load(json_data)
  assert struct.required_field == "value"
end

test "rejects missing required field" do
  json_data = %{}
  assert {:error, :missing_required_field} = Module.load(json_data)
end
```

### Testing Real-World Scenarios
```elixir
test "typical usage pattern" do
  # Use realistic data that matches common glTF exports
  json_data = %{
    "componentType" => 5126,  # FLOAT
    "count" => 24,           # 8 vertices * 3 positions
    "type" => "VEC3"         # 3D positions
  }
  
  assert {:ok, accessor} = Accessor.load(json_data)
  assert Accessor.element_size(accessor) == 12  # 4 bytes * 3 components
end
```

### Testing Error Scenarios
```elixir
test "handles malformed data gracefully" do
  invalid_cases = [
    {"nil value", nil},
    {"wrong type", "should_be_number"},
    {"out of range", -1}
  ]
  
  for {description, invalid_value} <- invalid_cases do
    json_data = %{"field" => invalid_value}
    assert {:error, _reason} = Module.load(json_data)
  end
end
```

This testing strategy ensures robust coverage while maintaining development velocity and code quality. 