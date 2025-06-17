# EAGL Testing & Debugging Summary

This document summarises key testing and debugging practices for EAGL development.

## Running Tests

```bash
# Run all tests (unit + example tests)
mix test

# Run only unit tests (skip example automation)
mix test test/eagl/

# Run specific test file
mix test test/eagl/camera_test.exs

# Run with verbose output
mix test --trace

# Run automated example tests specifically
mix test test/examples_test.exs
```

## Test Structure

```
test/
├── eagl/                   # Unit tests for core modules
│   ├── buffer_test.exs     # Buffer management (577 lines)
│   ├── camera_test.exs     # Camera system (38 tests)
│   ├── math_test.exs       # Math library (1136 lines)
│   └── ...                 # All core modules covered
├── examples_test.exs       # Automated example testing
└── test_helper.exs         # OpenGL mocking setup
```

## OpenGL Mocking

EAGL uses comprehensive OpenGL mocking for unit tests:

```elixir
# test_helper.exs sets up mocks automatically
# Tests run without requiring actual OpenGL context

# In your tests, OpenGL calls return expected values:
assert :gl.genBuffers(1) == [1]  # Mocked response
```

## Example Testing Patterns

Examples accept timeout options for automated testing:

```elixir
# In your example modules
def run_example(opts \\ []) do
  timeout = Keyword.get(opts, :timeout, :infinity)
  EAGL.Window.run(__MODULE__, "Example", enter_to_exit: true, timeout: timeout)
end

# Automated testing
MyExample.run_example(timeout: 500)  # Exits after 500ms
```

## Error Handling & Debugging

### Using EAGL.Error

```elixir
import EAGL.Error

# Check for OpenGL errors with context
check("After buffer creation")  # Returns :ok or {:error, message}

# Get human-readable error descriptions
error_string(1280)  # "GL_INVALID_ENUM"

# Raise on error (for debugging)
check!("Critical operation")  # Raises RuntimeError if error found
```

### Common Error Patterns

```elixir
# Always check after complex operations
{vao, vbo} = create_vertex_array(vertices, attributes)
check("After VAO creation")

# Use descriptive context messages
:gl.useProgram(program)
check("After binding shader program #{program}")
```

## Debugging OpenGL Issues

### Context Creation Problems

```bash
# Linux: Install mesa development packages
sudo apt-get install libgl1-mesa-dev libglu1-mesa-dev

# macOS: Ensure forward compatibility (handled automatically)
# Windows: Update graphics drivers
```

### Common OpenGL Debugging Steps

1. **Check OpenGL version**:
   ```elixir
   version = :gl.getString(@gl_version)
   IO.puts("OpenGL Version: #{version}")
   ```

2. **Verify shader compilation**:
   ```elixir
   case compile_shader(source, type) do
     {:ok, shader} -> shader
     {:error, reason} -> 
       IO.puts("Shader compilation failed: #{reason}")
       exit(:shader_error)
   end
   ```

3. **Check resource binding**:
   ```elixir
   :gl.bindVertexArray(vao)
   check("VAO binding")
   
   :gl.useProgram(program)
   check("Program binding")
   ```

## Test Writing Guidelines

### Unit Test Structure

```elixir
defmodule EAGL.CameraTest do
  use ExUnit.Case
  import EAGL.Camera
  import EAGL.Math

  describe "camera creation" do
    test "creates camera with default parameters" do
      camera = new()
      assert camera.position == [{0.0, 0.0, 0.0}]
      assert camera.yaw == -90.0
    end
  end

  describe "camera movement" do
    test "processes forward movement correctly" do
      camera = new()
      moved_camera = process_keyboard(camera, :forward, 0.1)
      # Verify movement behaviour
    end
  end
end
```

### Example Test Patterns

```elixir
# In examples_test.exs
test "7.4 camera class example" do
  # Examples should exit cleanly with timeout
  assert :ok = Example.LearnOpenGL.GettingStarted.CameraClass.run_example(timeout: 500)
end
```

### Mocking Complex Operations

```elixir
# For operations requiring specific OpenGL state
setup do
  # Mock returns specific values your test needs
  :meck.expect(:gl, :genVertexArrays, fn 1 -> [42] end)
  :meck.expect(:gl, :bindVertexArray, fn 42 -> :ok end)
  
  on_exit(fn -> :meck.unload(:gl) end)
  :ok
end
```

## Common Issues & Solutions

### Test Timeouts in CI

- Examples use automatic timeouts (500ms default)
- No manual interaction required
- Clean resource cleanup on timeout

### IEx Break Prompts

If you see `BREAK: (a)bort` in IEx:
1. Enter 'a' to abort
2. Investigate the underlying crash
3. Usually indicates BEAM VM crash

### Missing Dependencies

EAGL shows warnings but continues:
- Image loading falls back to procedural textures
- Missing models show errors but don't crash
- Optional features degrade gracefully

### Platform-Specific Testing

- **Linux**: Requires mesa-dev packages for tests
- **macOS**: Forward compatibility handled automatically  
- **Windows**: May need updated graphics drivers

## Resource Management in Tests

```elixir
# Always clean up in tests
setup do
  on_exit(fn ->
    # Clean up any OpenGL resources
    :gl.deleteVertexArrays([vao])
    :gl.deleteBuffers([vbo])
  end)
end
```

## Performance Testing

```elixir
# For performance-critical operations
test "obj loading performance" do
  {time, _result} = :timer.tc(fn ->
    {:ok, _model} = load_model_to_vao("teapot.obj")
  end)
  
  # Assert reasonable performance (microseconds)
  assert time < 100_000  # Less than 100ms
end
```

This summary covers the key testing and debugging patterns used throughout EAGL development. 