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