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
{:eagl, "~> 0.6.0"}
```

EAGL includes several examples to demonstrate its capabilities. Use the unified examples runner:

```
./priv/scripts/run_examples
════════════════════════════════════════════════════════════════
                         EAGL Examples Menu
════════════════════════════════════════════════════════════════

0. Non-Learn OpenGL Examples:
  01) Math Example - Comprehensive EAGL.Math functionality demo
  02) Teapot Example - 3D teapot with Phong shading

1. Learn OpenGL Getting Started Examples:

  Hello Window:     111) 1.1 Window    112) 1.2 Clear Colors

  Hello Triangle:   121) 2.1 Triangle  122) 2.2 Indexed    123) 2.3 Exercise1
                    124) 2.4 Exercise2 125) 2.5 Exercise3

  Shaders:          131) 3.1 Uniform   132) 3.2 Interpolation 133) 3.3 Class
                    134) 3.4 Exercise1 135) 3.5 Exercise2     136) 3.6 Exercise3

  Textures:         141) 4.1 Basic     142) 4.2 Combined      143) 4.3 Exercise1
                    144) 4.4 Exercise2 145) 4.5 Exercise3     146) 4.6 Exercise4

  Transformations:  151) 5.1 Basic     152) 5.2 Exercise1  153) 5.2 Exercise2

  Coordinate Systems: 161) 6.1 Basic   162) 6.2 Depth     163) 6.3 Multiple
                      164) 6.4 Exercise

  Camera:           171) 7.1 Circle    172) 7.2 Keyboard+DT

════════════════════════════════════════════════════════════════
Enter code (01, 02, 111-153), 'q' to quit, 'r' to refresh:
>
```

## Usage

### Math Operations

EAGL provides a comprehensive 3D math library based on GLM supporting:

- **Vectors**: 2D, 3D, 4D vector operations with constructor macros
- **Matrices**: 2x2, 3x3, 4x4 matrix operations with transformation functions
- **Quaternions**: Rotation representation, SLERP, and conversion functions
- **Utilities**: Trigonometry, interpolation, clamping, and geometric functions
- **OpenGL Integration**: All functions work with the tuple-in-list format required by Erlang's OpenGL bindings
- **Sigils**: Compile-time validated literals for matrices (`~m`), vertices (`~v`), and indices (`~i`)

#### Sigil Literals

EAGL provides three sigils for creating OpenGL data with compile-time validation and clean tabular formatting:

```elixir
import EAGL.Math

# Matrix sigil (~m) - supports comments and automatic size detection
identity_4x4 = ~m"""
1.0  0.0  0.0  0.0
0.0  1.0  0.0  0.0
0.0  0.0  1.0  0.0
0.0  0.0  0.0  1.0
"""

transform_matrix = ~m"""
1.0  0.0  0.0  0.0
0.0  1.0  0.0  0.0
0.0  0.0  1.0  0.0
10.0 20.0 30.0 1.0  # Translation X, Y, Z (column-major: translation is in last column)
"""

# Vertex sigil (~v) - for raw vertex buffer data
triangle_vertices = ~v"""
# position      color
 0.0   0.5  0.0  1.0  0.0  0.0  # top vertex - red
-0.5  -0.5  0.0  0.0  1.0  0.0  # bottom left - green
 0.5  -0.5  0.0  0.0  0.0  1.0  # bottom right - blue
"""

# Index sigil (~i) - for element indices (must be integers)
quad_indices = ~i"""
0  1  3  # first triangle
1  2  3  # second triangle
"""
```

#### Vector and Matrix Operations

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

### Shader Management

The uniform helpers (from Wings3D) automatically detect the type of EAGL.Math values, eliminating the need to manually unpack vectors or handle different uniform types:

- `vec2/3/4` → `glUniform2f/3f/4f`
- `mat2/3/4` → `glUniformMatrix2fv/3fv/4fv` 
- Numbers → `glUniform1f/1i`
- Booleans → `glUniform1i` (0 or 1)

```elixir
import EAGL.Shader

      # Compile and link shaders with type-safe shader types
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

### Texture Management

EAGL provides meaningful texture abstractions:
- **Image Loading**: `load_texture_from_file()` with automatic fallback to checkerboard patterns
- **Texture Creation**: `create_texture()` returns `{:ok, id}` tuples for error handling
- **Type-Safe Parameters**: `set_texture_parameters()` with compile-time validated options
- **Data Loading**: `load_texture_data()` handles format/type conversion with defaults
- **Procedural Textures**: `create_checkerboard_texture()` generates test patterns
- **Graceful Degradation**: Helpful warnings when optional dependencies aren't available
- **Direct OpenGL**: Use `:gl` functions directly for binding, mipmaps, and cleanup


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

      # Set texture parameters with type-safe keyword options
      set_texture_parameters(
        wrap_s: @gl_repeat,
        wrap_t: @gl_repeat,
        min_filter: @gl_linear_mipmap_linear,
        mag_filter: @gl_linear
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

### Model Loading
Currently we only support the .obj format.

```elixir
import EAGL.Model

# Load OBJ file (with automatic normal generation if missing)
{:ok, model} = load_model_to_vao("teapot.obj")

# Render the model
:gl.bindVertexArray(model.vao)
:gl.drawElements(@gl_triangles, model.vertex_count, @gl_unsigned_int, 0)
```

### Buffer Management

EAGL provides type-safe, buffer management with automatic stride/offset calculation and standard attribute helpers.

```elixir
import EAGL.Buffer

# Simple position-only VAO/VBO (most common case)
vertices = ~v"""
-0.5  -0.5  0.0
 0.5  -0.5  0.0
 0.0   0.5  0.0
"""
{vao, vbo} = create_position_array(vertices)

# Multiple attribute configuration - choose your approach:
# Position + color vertices (6 floats per vertex: x,y,z,r,g,b)
position_color_vertices = ~v"""
# position      color
-0.5  -0.5  0.0  1.0  0.0  0.0  # vertex 1: position + red
 0.5  -0.5  0.0  0.0  1.0  0.0  # vertex 2: position + green  
 0.0   0.5  0.0  0.0  0.0  1.0  # vertex 3: position + blue
"""

# APPROACH 1: Automatic calculation (recommended for standard layouts)
# Automatically calculates stride/offset - no manual math required.
attributes = vertex_attributes(:position, :color)
{vao, vbo} = create_vertex_array(position_color_vertices, attributes)

# APPROACH 2: Manual configuration (for fine control or non-standard layouts)  
# Specify exactly what you want - useful for custom stride, non-sequential locations, etc.
attributes = [
  position_attribute(stride: 24, offset: 0),      # uses default location 0
  color_attribute(stride: 24, offset: 12)         # uses default location 1
]
{vao, vbo} = create_vertex_array(position_color_vertices, attributes)

# APPROACH 3: Custom locations (override defaults)
attributes = [
  position_attribute(location: 5, stride: 24, offset: 0),    # custom location 5
  color_attribute(location: 2, stride: 24, offset: 12)       # custom location 2
]
{vao, vbo} = create_vertex_array(position_color_vertices, attributes)

# Use automatic approach when:  - Standard position/color/texture/normal layouts
#                               - Sequential attribute locations (0, 1, 2, 3...)
#                               - Tightly packed (no padding between attributes)
#
# Use manual approach when:     - Custom attribute locations or sizes
#                               - Non-standard data types or normalization 
#                               - Attribute padding or unusual stride patterns
#                               - Need to match specific shader attribute locations

# Indexed geometry (rectangles, quads, models)
quad_vertices = ~v"""
 0.5   0.5  0.0  # top right
 0.5  -0.5  0.0  # bottom right
-0.5  -0.5  0.0  # bottom left
-0.5   0.5  0.0  # top left
"""
indices = ~i"""
0  1  3  # first triangle
1  2  3  # second triangle
"""
{vao, vbo, ebo} = create_indexed_position_array(quad_vertices, indices)

# Complex interleaved vertex data with multiple attributes
# Format: position(3) + color(3) + texture_coord(2) = 8 floats per vertex
interleaved_vertices = ~v"""
# x     y     z     r     g     b     s     t
-0.5  -0.5   0.0   1.0   0.0   0.0   0.0   0.0  # bottom left
 0.5  -0.5   0.0   0.0   1.0   0.0   1.0   0.0  # bottom right
 0.0   0.5   0.0   0.0   0.0   1.0   0.5   1.0  # top centre
"""

# Three standard attributes with automatic calculation
{vao, vbo} = create_vertex_array(interleaved_vertices, vertex_attributes(:position, :color, :texture_coordinate))

# Clean up resources
delete_vertex_array(vao, vbo)
delete_indexed_array(vao, vbo, ebo)  # For indexed arrays
```

**Standard Attribute Helpers:**
- `position_attribute()` - 3 floats (x, y, z), defaults to location 0 but can be overridden
- `color_attribute()` - 3 floats (r, g, b), defaults to location 1 but can be overridden  
- `texture_coordinate_attribute()` - 2 floats (s, t), defaults to location 2 but can be overridden
- `normal_attribute()` - 3 floats (nx, ny, nz), defaults to location 3 but can be overridden

**Two Configuration Approaches:**

1. **Automatic Layout** (recommended): `vertex_attributes()` assigns sequential locations (0, 1, 2, 3...) and calculates stride/offset automatically
2. **Manual Layout**: Individual attribute helpers allow custom locations, stride, and offset for non-standard layouts

**Key Benefits:**
- **Flexible locations**: Default locations can be overridden with `location:` option
- **Automatic calculation**: `vertex_attributes()` eliminates manual stride/offset math for standard layouts
- **Type safety**: Compile-time checks for attribute configuration  
- **Mix approaches**: Use automatic layout for common cases, manual for custom requirements

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
- **Tick Events**: Automatic 60 FPS tick events for animations and updates (optional `handle_event/2` callback)

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
    EAGL.Window.run(__MODULE__, "Tutorial Example", enter_to_exit: true)
    
    # Custom window size and options
    EAGL.Window.run(__MODULE__, "Custom Size App", size: {1280, 720}, depth_testing: true, enter_to_exit: true)
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

  # Optional: Handle tick events for animations (60 FPS)
  @impl true
  def handle_event(:tick, state) do
    # Update animations, physics, etc.
    {:ok, updated_state}
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

**Note**: EAGL automatically detects macOS and enables forward compatibility for OpenGL 3.0+ contexts, which is required by Apple's OpenGL implementation. This matches the behaviour of the `#ifdef __APPLE__` code commonly found in OpenGL tutorials.

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
│   ├── buffer.ex           # VAO/VBO helper functions (516 lines)
│   ├── const.ex            # OpenGL constants (842 lines)
│   ├── error.ex            # Error checking and reporting (110 lines)
│   ├── math.ex             # GLM-style math library (1494 lines)
│   ├── model.ex            # 3D model management (191 lines)
│   ├── obj_loader.ex       # Wavefront OBJ parser (456 lines)
│   ├── shader.ex           # Shader compilation (322 lines)
│   ├── texture.ex          # Texture loading and management (451 lines)
│   ├── window.ex           # Window management (597 lines)
│   └── window_behaviour.ex # Window callback behavior (66 lines)
├── examples/               # Example applications
│   ├── math_example.ex     # Math library demonstrations
│   ├── teapot_example.ex   # 3D teapot rendering
│   └── learnopengl/        # LearnOpenGL tutorial ports
└── wx/                     # wxWidgets constants
test/
├── eagl/                   # Unit tests for EAGL modules
│   ├── buffer_test.exs     # Buffer management tests (577 lines)
│   ├── error_test.exs      # Error handling tests (55 lines)
│   ├── math_test.exs       # Math library tests (1136 lines)
│   ├── model_test.exs      # Model loading tests (250 lines)
│   ├── obj_loader_test.exs # OBJ parser tests (141 lines)
│   ├── shader_test.exs     # Shader compilation tests (1033 lines)
│   └── texture_test.exs    # Texture management tests (449 lines)
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
- ✅ **Texture Management**: Comprehensive texture creation, configuration, and loading
- ✅ **3D Model Loading**: Wavefront OBJ format with normals and texture coordinates
- ✅ **Math Library**: GLM-compatible vectors, matrices, quaternions with full OpenGL integration
- ✅ **Buffer Helpers**: Wings3D-inspired VAO/VBO management functions
- ✅ **Error Handling**: Comprehensive OpenGL error checking and reporting
- ✅ **Window Management**: Cross-platform window creation with wxWidgets
- ✅ **Event Handling**: Resize, close, paint, and 60 FPS tick events
- ✅ **Resource Cleanup**: Automatic cleanup of OpenGL resources
- ✅ **LearnOpenGL Examples**: Partial "Getting Started" series - direct ports of OpenGL tutorials
- ✅ **Testing**: Full test suite with OpenGL context mocking

## Roadmap

The current focus is to:

- [ ] **In Progress**: Complete the "Getting Started" LearnOpenGL examples series
  - ✅ Hello Window (1.1-1.2): 2 examples
  - ✅ Hello Triangle (2.1-2.5): 5 examples  
  - ✅ Shaders (3.1-3.6): 6 examples
  - ✅ Textures (4.1-4.6): 6 examples
  - ✅ Transformations (5.1-5.2): 3 examples
  - ✅ Coordinate Systems (6.1-6.4): 4 examples
  - ✅ Camera (7.1-7.2): 2 examples completed
- [ ] Continue with "Lighting" chapter examples
- [ ] Load common model types like GLTF

And in future:

- [ ] Be able to apply post-processing effects
- [ ] More extensive camera/lighting/material helpers
- [ ] Access to a physics engine
- [ ] Built-in GPU profiling tools

## Troubleshooting

### Common Issues

#### Example Testing Timeouts
Examples use automatic timeouts for testing and will exit cleanly after the specified duration:

```bash
# Run all tests including automated example tests
mix test

# Run only unit tests if you want to skip example testing
mix test test/eagl/

# Run automated example tests specifically
mix test test/examples_test.exs
```

#### IEx Break Prompt
If you encounter an unexpected error in IEx and see a `BREAK: (a)bort` prompt, this indicates a crash in the BEAM VM. Enter 'a' to abort and return to the shell, then investigate the error that caused the crash.

#### Test Timeouts in CI
Examples now use automatic timeouts and run successfully in continuous integration environments:
- Examples accept a `timeout:` option for automated testing
- CI environments run examples with 500ms timeouts
- Examples exit cleanly after timeout with proper resource cleanup
- No manual interaction required

### Platform-Specific Issues

#### OpenGL Context Creation Failures
If you encounter context creation errors:
- **Linux**: Ensure mesa development packages are installed
- **macOS**: Update to a supported macOS version (10.9+)
- **Windows**: Update graphics drivers

#### Missing Dependencies
If optional dependencies are missing, EAGL will show warnings but continue with fallback behaviour:
- Image loading falls back to procedural textures
- Missing models show error messages but don't crash

## Contributing

We welcome contributions. Suggested contributions include:
- **LearnOpenGL tutorial ports**: Help correct the tutorial series (I will do the initial ports)
- **Documentation improvements**: Examples, API documentation
- **Platform-specific optimisations**: Performance or compatibility improvements
- **Example applications**: Links to demo projects showcasing EAGL capabilities
- **Bug fixes**: Issues with existing functionality
- **Testing improvements**: Better mocks, integration tests, or test utilities

Please read through these guidelines before submitting changes.

### Development Setup

1. Fork and clone the repository
2. Install dependencies: `mix deps.get`
3. Run tests to ensure everything works: `mix test`
4. Try the examples: `./priv/scripts/run_examples`

### Code Standards

#### Style Guidelines
- Follow standard Elixir formatting (`mix format`) but...
- Keep matricies in tabular format and wrap with `# mix format: off|on`
- Use the `~m`atrix, `~v`ertex and `~i`ndex sigils for compile time constants
- Use descriptive variable names, especially for OpenGL state
- Include typespecs for public functions
- Document complex algorithms and OpenGL-specific concepts

#### Testing Requirements  
- Add tests for new functionality
- Ensure existing tests pass: `mix test`
- Update examples to accept `opts` parameter for timeout testing
- Mock OpenGL calls in unit tests where possible

#### Documentation Standards
- Update README.md for new features
- Add docstrings for public functions
- Include code examples in documentation
- Our tone is calm, concise and factual e.g. avoid 'sales' language and over-use of '!'
- Write in Australian/British English for documentation, US English for code

### Design Philosophy

EAGL focuses on **meaningful abstractions** rather than thin wrappers around OpenGL calls:

#### ✅ **Provide Value**
- **Error handling**: `{:ok, result}` tuples and comprehensive error checking
- **Type safety**: Compile-time validation and clear parameter names (`wrap_s: @gl_repeat`)
- **Sensible defaults**: Reduce boilerplate with common parameter combinations
- **Complex operations**: Multi-step procedures like shader compilation and linking
- **Data transformations**: Converting Elixir structures to OpenGL formats
- **Testing utilities**: Procedural textures and geometry for development

#### ❌ **Avoid Thin Wrappers**
- **Simple OpenGL calls**: Use `:gl.bindTexture()`, `:gl.generateMipmap()` directly
- **One-line functions**: Don't wrap functions that only add `check()` calls
- **State management**: Let users manage OpenGL state explicitly when appropriate

#### 🎯 **User Experience Goals**
- **Selective imports**: `import EAGL.Error` for explicit error checking
- **Direct OpenGL access**: When EAGL doesn't add substantial value
- **Direct OpenGL integration**: Mix EAGL helpers with direct OpenGL calls

### Submitting Changes

1. **Create a feature branch**: `git checkout -b feature/descriptive-name`
2. **Make your changes** following the style guidelines above
3. **Add or update tests** for your changes
4. **Run the full test suite**: `mix test`
5. **Update documentation** if you've added new features
6. **Commit with clear messages**: Use present tense, describe what the commit does
7. **Push your branch**: `git push origin feature/descriptive-name`
8. **Open a Pull Request** with:
   - Clear description of the changes
   - Reference to any related issues
   - Screenshots for visual changes
   - Test results if applicable

### Questions and Support

- **Issues**: Use GitHub issues for bugs and feature requests
- **Discussions**: Use GitHub discussions for questions and design discussions
- **Examples**: Look at existing code in `lib/examples/` for patterns

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Learn OpenGL](https://learnopengl.com) for excellent OpenGL book and tutorial code. If the examples helped you understand OpenGL better please consider a [donation to the author](https://www.paypal.me/learnopengl/), Joey De Vries.
- [Wings3D](https://wings3d.com) for inspiration and helper function patterns - the name EAGL(e) is a tip of the hat to this project
- The Erlang/OTP team and particularly Dan Gudmundsson for the wxWidgets bindings
- The [local Elixir User Group](https://https://elixir.sydney) for putting up with my occasional random talks
- [Cursor](https://cursor.com) and Claude Sonnet for giving me the patience to get to running code and porting Joey's Learning OpenGL examples

