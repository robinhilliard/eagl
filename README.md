<div align="center">
  <h1>EAGL</h1>
  <img src="assets/eagl_logo_grey_on_transparent.png" alt="EAGL Logo" title="EAGL Logo" width="200">
  <p>
    Make it EAsier to work<br>
    with OpenGL in Elixir.
  </p>
</div>

## Overview

Most examples of working with OpenGL are written in C++ or C# (Unity). The purpose of the EAGL library is to:
- Make it easier to translate OpenGL tutorials and examples from resources like [Learn OpenGL](https://learnopengl.com) into Elixir. 
- Provide basic helper functions to bridge the gap between idiomatic Elixir and OpenGL's state machine, using the Wings 3D Erlang source as a guide to prescriptive vs helpful additions
- Enable other libraries and apps to build on this one and libraries like [ECSx](https://github.com/ecsx-framework/ECSx) and the list at [Awesome Elixir Gaming](https://github.com/njwest/Awesome-Elixir-Gaming)

The following are non-goals:
- Focussing on 2D GPU graphics (see [Scenic](https://github.com/ScenicFramework/scenic) for that)
- Wrapping of the Erlang wx library
- A Shader DSL
- A UI layout/component library
- 3D mesh modelling (leave that to Wings 3D, Blender etc)

## Quick Start

```elixir
# Add to mix.exs
{:eagl, "~> 0.4.0"}
```

EAGL includes several examples to demonstrate its capabilities. Use the unified examples runner:

```
./priv/scripts/run_examples
═══════════════════════════════════════════════════════════════
                    EAGL Examples Menu
═══════════════════════════════════════════════════════════════

 1) Math Example
    Comprehensive example demonstrating all EAGL.Math functionality

 2) Teapot Example
    Draw a 3D teapot with Phong shading

LearnOpenGL Examples:

  1. Getting Started:
     3) 1.1 Hello Window
        Basic window creation - Foundation of all OpenGL applications

     4) 1.2 Hello Window Clear
        Custom clear colors - Understanding OpenGL's state machine

     5) 2.1 Hello Triangle
        Your first triangle - Basic VAO/VBO and shader fundamentals

     6) 2.2 Hello Triangle Indexed
        Element Buffer Objects (EBO) - Basic indexed rectangle rendering

     7) 2.3 Hello Triangle Exercise 1
        Two Triangles Side by Side - Using glDrawArrays with 6 vertices

     ... further examples skipped ...

═══════════════════════════════════════════════════════════════
Enter example number (1-17), 'q' to quit, or 'r' to refresh:
>
```

## Usage

### Math Operations

```elixir
import EAGL.Math

# Vector operations
position = vec3(1.0, 2.0, 3.0)
direction = vec3(0.0, 1.0, 0.0) 
result = vec_add(position, direction)
length = vec_length(position)

# Matrix transformations
model = mat4_translate(vec3(5.0, 0.0, 0.0))
view = mat4_look_at(
  vec3(0.0, 0.0, 5.0),  # eye
  vec3(0.0, 0.0, 0.0),  # target
  vec3(0.0, 1.0, 0.0)   # up
)
projection = mat4_perspective(radians(45.0), 16.0/9.0, 0.1, 100.0)
```

EAGL provides a comprehensive 3D math library based on GLM supporting:

- **Vectors**: 2D, 3D, 4D vector operations with constructor macros
- **Matrices**: 2x2, 3x3, 4x4 matrix operations with transformation functions
- **Quaternions**: Rotation representation, SLERP, and conversion functions
- **Utilities**: Trigonometry, interpolation, clamping, and geometric functions
- **OpenGL Integration**: All functions work with the tuple-in-list format required by Erlang's OpenGL bindings

### Shader Management

```elixir
import EAGL.Shader

# Compile and link shaders
{:ok, vertex} = create_shader(@gl_vertex_shader, "vertex.glsl")
{:ok, fragment} = create_shader(@gl_fragment_shader, "fragment.glsl")
{:ok, program} = create_attach_link([vertex, fragment])

# Set uniforms with automatic type detection
set_uniform(program, "model_matrix", model_matrix)
set_uniform(program, "light_position", vec3(10.0, 10.0, 5.0))
set_uniform(program, "time", :erlang.monotonic_time(:millisecond))

# Or set multiple uniforms at once
set_uniforms(program, [
  model: model_matrix,
  view: view_matrix,
  projection: projection_matrix,
  light_position: vec3(10.0, 10.0, 5.0),
  light_color: vec3(1.0, 1.0, 1.0)
])
```

The uniform helpers (from Wings3D) automatically detect the type of EAGL.Math values, eliminating the need to manually unpack vectors or handle different uniform types:

- `vec2/3/4` → `glUniform2f/3f/4f`
- `mat2/3/4` → `glUniformMatrix2fv/3fv/4fv` 
- Numbers → `glUniform1f/1i`
- Booleans → `glUniform1i` (0 or 1)

### Texture Management

```elixir
import EAGL.Texture
import EAGL.Error

# Load texture from image file (requires optional stb_image dependency)
{:ok, texture_id, width, height} = load_texture_from_file("priv/images/eagl_logo_black_on_white.jpg")

# Or create procedural textures for testing
{:ok, texture_id, width, height} = create_checkerboard_texture(256, 32)

# Manual texture creation and configuration
{:ok, texture_id} = create_texture()
:gl.bindTexture(@gl_texture_2d, texture_id)

# Set texture parameters with atom-to-constant conversion
set_texture_parameters(
  wrap_s: :repeat,
  wrap_t: :repeat,
  min_filter: :linear_mipmap_linear,
  mag_filter: :linear
)

# Load pixel data with format handling
load_texture_data(width, height, pixel_data, 
  internal_format: :rgb,
  format: :rgb,
  type: :unsigned_byte
)

# Generate mipmaps and check for errors
:gl.generateMipmap(@gl_texture_2d)
check("After generating mipmaps")

# Use multiple textures
:gl.activeTexture(@gl_texture0)
:gl.bindTexture(@gl_texture_2d, texture1_id)
:gl.activeTexture(@gl_texture1)
:gl.bindTexture(@gl_texture_2d, texture2_id)

# Clean up
:gl.deleteTextures([texture_id])
```

EAGL provides meaningful texture abstractions:

- **Image Loading**: `load_texture_from_file()` with automatic fallback to checkerboard patterns
- **Texture Creation**: `create_texture()` returns `{:ok, id}` tuples for error handling
- **Parameter Setting**: `set_texture_parameters()` converts atoms to OpenGL constants
- **Data Loading**: `load_texture_data()` handles format/type conversion with defaults
- **Procedural Textures**: `create_checkerboard_texture()` generates test patterns
- **Graceful Degradation**: Helpful warnings when optional dependencies aren't available
- **Direct OpenGL**: Use `:gl` functions directly for binding, mipmaps, and cleanup

### Model Loading

```elixir
import EAGL.Model

# Load OBJ file (with automatic normal generation if missing)
{:ok, model} = load_model_to_vao("teapot.obj")

# Render the model
:gl.bindVertexArray(model.vao)
:gl.drawElements(@gl_triangles, model.vertex_count, @gl_unsigned_int, 0)
```

### Buffer Management

```elixir
import EAGL.Buffer

# Create simple position-only VAO/VBO (convenience function)
vertices = [-0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0]
{vao, vbo} = create_position_array(vertices)

# Or create with custom attributes (general function)
{vao, vbo} = create_vertex_array(vertices, [
  {0, 3, @gl_float, @gl_false, 0, 0}  # position at location 0
])

# Clean up
delete_vertex_array(vao, vbo)
```

### Error Handling

```elixir
import EAGL.Error

# Check for OpenGL errors with context
check("After buffer creation")  # Returns :ok or {:error, message}

# Get human-readable error string for error code
error_string(1280)  # "GL_INVALID_ENUM"

# Check and raise on error (useful for debugging)
check!("Critical operation")  # Raises RuntimeError if error found
```

### Window Creation

EAGL provides flexible window creation with a clean, options-based API:

- **Default Size**: 1024x768 pixels (can be customized with `size:` option)
- **2D Rendering** (default): No depth buffer, suitable for triangles, sprites, UI elements
- **3D Rendering**: Enables depth testing and depth buffer for proper 3D scene rendering
- **Automatic ENTER Handling**: Optional ENTER key handling for simple examples and tutorials

```elixir
defmodule MyApp do
  use EAGL.Window
  import EAGL.Shader
  import EAGL.Math

  def run_example do
    # For 2D rendering (triangles, sprites, UI) - uses default 1024x768 size
    EAGL.Window.run(__MODULE__, "My 2D OpenGL App")
    
    # For 3D rendering (models, scenes with depth)
    EAGL.Window.run(__MODULE__, "My 3D OpenGL App", depth_testing: true)
    
    # For tutorials/examples with automatic ENTER key handling
    EAGL.Window.run(__MODULE__, "Tutorial Example", return_to_exit: true)
    
    # Custom window size and options
    EAGL.Window.run(__MODULE__, "Custom Size App", size: {1280, 720}, depth_testing: true, return_to_exit: true)
  end

  @impl true
  def setup do
    # Initialize shaders, load models, etc.
    {:ok, initial_state}
  end

  @impl true
  def render(width, height, state) do
    # Your render function should handle clearing the screen
    :gl.clearColor(0.2, 0.3, 0.3, 1.0)
    
    # For 2D rendering (depth_testing: false, default)
    :gl.clear(@gl_color_buffer_bit)
    
    # For 3D rendering (depth_testing: true)
    # :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)
    
    # Render your content here
    :ok
  end

  @impl true
  def cleanup(state) do
    # Clean up resources
    :ok
  end
end
```

## Requirements

- **Elixir**: 1.14 or later
- **Erlang/OTP**: 25 or later (with wx support - included in standard distributions)
- **OpenGL**: 3.3 or later (for modern shader support)

### Platform-specific Notes

#### All Platforms
EAGL uses Erlang's built-in `wx` module for windowing, which is included with standard Erlang/OTP installations. No additional GUI libraries need to be installed.

#### Linux
Ensure you have OpenGL drivers installed:
```bash
# Ubuntu/Debian
sudo apt-get install libgl1-mesa-dev libglu1-mesa-dev

# Fedora/RHEL
sudo dnf install mesa-libGL-devel mesa-libGLU-devel
```

#### macOS
OpenGL is included with macOS. No additional setup required.

**Note**: EAGL automatically detects macOS and enables forward compatibility for OpenGL 3.0+ contexts, which is required by Apple's OpenGL implementation. This matches the behavior of the `#ifdef __APPLE__` code commonly found in OpenGL tutorials.

#### Windows  
OpenGL is typically available through graphics drivers. If you encounter issues, ensure your graphics drivers are up to date.

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/eagl.git
   cd eagl
   ```

2. Install dependencies:
   ```bash
   mix deps.get
   ```

3. Compile the project:
   ```bash
   mix compile
   ```

4. Run tests to verify everything works:
   ```bash
   mix test
   ```

5. Try the examples:
   ```bash
   ./priv/scripts/run_examples
   ```

## Project Structure

```
lib/
├── eagl/                   # Core EAGL modules
│   ├── buffer.ex           # VAO/VBO helper functions
│   ├── const.ex            # OpenGL constants
│   ├── error.ex            # Error checking and reporting
│   ├── math.ex             # GLM-style math library
│   ├── model.ex            # 3D model management
│   ├── obj_loader.ex       # Wavefront OBJ parser
│   ├── shader.ex           # Shader compilation
│   ├── window.ex           # Window management
│   └── window_behaviour.ex # Window callback behavior
├── examples/               # Example applications
│   ├── math_example.ex     # Math library demonstrations
│   ├── teapot_example.ex   # 3D teapot rendering
│   └── learnopengl/        # LearnOpenGL tutorial ports
└── wx/                     # wxWidgets constants
test/
├── eagl/                   # Unit tests for EAGL modules
└── eagl_test.exs           # Integration tests
priv/
├── models/                 # 3D model files (.obj)
├── scripts/                # Convenience scripts
│   └── run_examples        # Unified examples runner
└── shaders/                # GLSL shader files
    └── learnopengl/        # LearnOpenGL tutorial shaders
```

## Features

- ✅ **Shader Management**: Automatic compilation, linking, and error reporting
- ✅ **Texture Management**: Comprehensive texture creation, configuration, and loading with Wings3D-inspired helpers
- ✅ **3D Model Loading**: Wavefront OBJ format with normals and texture coordinates
- ✅ **Math Library**: GLM-compatible vectors, matrices, quaternions with full OpenGL integration
- ✅ **Buffer Helpers**: Wings3D-inspired VAO/VBO management functions
- ✅ **Error Handling**: Comprehensive OpenGL error checking and reporting
- ✅ **Window Management**: Cross-platform window creation with wxWidgets
- ✅ **Event Handling**: Resize, close, and paint events
- ✅ **Resource Cleanup**: Automatic cleanup of OpenGL resources
- ✅ **LearnOpenGL Examples**: Direct ports of popular OpenGL tutorials
- ✅ **Testing**: Full test suite with OpenGL context mocking

## Roadmap

The current focus is to:

- [ ] Port all the Learning OpenGL examples, adding helper functions when necessary
- [ ] Load common model types like GLTF

And in future:

- [ ] Be able to apply post-processing effects
- [ ] More extensive camera/lighting/material helpers
- [ ] Access to a physics engine
- [ ] Built-in GPU profiling tools

### Community Contributions Welcome
- Documentation improvements and tutorials
- Additional LearnOpenGL tutorial ports
- Platform-specific optimizations
- Example applications and demos

## Troubleshooting

### Development Issues
Most of these are obvious, but it helps AI assistants remember how to get around the project.

#### Interactive Examples Hanging
Examples require user interaction (ENTER key to exit). When running tests:
```bash
# Run only unit tests, exclude interactive examples
mix test test/eagl/ --exclude interactive

# Or set a timeout for interactive tests
mix test --timeout 10000
```


#### BREAK Prompt in IEx
If you encounter an unexpected error in IEx and see a `BREAK: (a)bort` prompt
enter 'a' to abort and return to the shell. You can then run other shell commands.
```

#### Test Timeouts
Interactive examples wait for ENTER key presses and will timeout in CI:
- Use `@tag :interactive` for examples that require user input
- CI automatically excludes these tests
- Local development can run them individually

#### Examples Runner Interactive Input
The examples runner script requires user input and cannot be automated:
```bash
# This will hang waiting for user input:
./priv/scripts/run_examples

# Piping input incorrectly will also hang:
echo "16" | ./priv/scripts/run_examples  # WRONG - hangs waiting for ENTER

# To test examples programmatically, run them directly:
mix run -e "EAGL.Examples.Math.run_example()"
timeout 5s mix run -e "EAGL.Examples.Teapot.run_example()"

# If you need to script the examples runner, use proper input format:
printf "16\nq\n" | timeout 10s ./priv/scripts/run_examples
```


## Contributing

### Design Philosophy

EAGL focuses on **meaningful abstractions** rather than wrappers around OpenGL calls:

#### ✅ **Provide When Valuable**
- **Error handling patterns**: `{:ok, result}` tuples and comprehensive error checking
- **Type conversions/safety**: Atoms to OpenGL constants (`set_texture_parameters(wrap_s: :repeat)`)
- **Sensible defaults**: Reduce boilerplate with common parameter combinations
- **Complex operations**: Repeated Multi-step procedures like shader compilation and linking
- **Data transformations**: Converting Elixir data structures to OpenGL formats
- **Procedural generation**: Built-in patterns like checkerboard textures for testing
- **Dependencies**: Libraries available to C++ programmers that need to be sourced in Elixir

#### ❌ **Avoid Thin Wrappers**
- **Simple OpenGL calls**: Use `:gl.bindTexture()`, `:gl.generateMipmap()` directly
- **One-line functions**: Don't wrap functions that only add `check()` calls
- **State management**: Let users manage OpenGL state explicitly when appropriate

#### 🎯 **User Experience**
- **Import what you need**: `import EAGL.Error` for explicit error checking
- **Call OpenGL directly**: When EAGL doesn't add substantial value
- **Mix and match**: Use EAGL helpers alongside direct OpenGL calls seamlessly

This philosophy keeps the API clean, focused, and educational while helping where it matters most.

### Written Language

Documentation is written in Australian English while function, variable and module names use US English for useability. Limit use of exclamation marks to warnings and avoid sales language - readers are already interested in using OpenGL with Elixir. Keep explanations and observations concise.

### Source Control Instructions

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Learn OpenGL](https://learnopengl.com) for excellent OpenGL book and tutorial code. If the examples helped you understand OpenGL better please consider a [donation to the author](https://www.paypal.me/learnopengl/), Joey De Vries.
- [Wings3D](https://wings3d.com) for inspiration and helper function patterns - the name EAGL(e) is a tip of the hat to this project
- The Erlang/OTP team for wxWidgets bindings
- The Elixir community for inspiration and support, particularly the [Elixir Sydney/Australia User Group](https://https://elixir.sydney)
- [Cursor](https://cursor.com) and Claude Sonnet for giving me the patience to get to running code and port the Learning OpenGL examples

