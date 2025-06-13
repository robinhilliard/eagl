# EAGL

![An Eagle carrying a teapot](assets/eagl_logo_grey_on_transparent.png "EAGL Logo")

Make it **EA**sier to work with Open**GL** in Elixir, using the Erlang WX bindings to OpenGL.

## Overview

Most examples of working with OpenGL are written in C++ or C# (Unity). The purpose of the EAGL library is to
- Make it easier to translate OpenGL tutorials and examples from resources like [Learn OpenGL](https://learnopengl.com) into Elixir. 
- Provide basic helper functions to bridge the gap between idiomatic Elixir and OpenGL's state machine, using the Wings 3D Erlang source as a guide.
- Enable other libraries and apps to build on this one - e.g. there should be Unity-like tool for the BEAM.

Non-goals:
- Wrapping of the Erlang wx library
- A Shader DSL
- A UI layout/component library
- 3D mesh modelling (leave that to Wings 3D, Blender etc)

## Quick Start

```elixir
# Add to mix.exs
{:eagl, "~> 0.1.0"}
```

### Running Examples

EAGL includes several examples to demonstrate its capabilities. Use the unified examples runner:

```bash
# Interactive menu with all examples
./priv/scripts/run_examples
```

Available examples:
1. **Math Example** - Comprehensive demonstration of all EAGL.Math functionality (terminal-based)
2. **Teapot Example** - 3D teapot with Phong shading (OpenGL window)
3. **LearnOpenGL 2.3** - Hello Triangle Exercise 1 (glDrawArrays)
4. **LearnOpenGL 2.4** - Hello Triangle Exercise 2 (Element Buffer Objects)
5. **LearnOpenGL 2.5** - Hello Triangle Exercise 3 (Multiple Shader Programs)

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

### Uniform Helper Features (from Wings 3D)

The uniform helpers automatically detect the type of EAGL.Math values:

- `vec2/3/4` → `glUniform2f/3f/4f`
- `mat2/3/4` → `glUniformMatrix2fv/3fv/4fv` 
- Numbers → `glUniform1f/1i`
- Booleans → `glUniform1i` (0 or 1)

This eliminates the need to manually unpack vectors or handle different uniform types.

### Model Loading

```elixir
import EAGL.Model

# Load OBJ file with automatic normal generation
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

```elixir
defmodule MyApp do
  use EAGL.Window
  import EAGL.Shader
  import EAGL.Math

  def run_example do
    EAGL.Window.run(__MODULE__, "My OpenGL App")
  end

  @impl true
  def setup do
    # Initialize shaders, load models, etc.
    {:ok, initial_state}
  end

  @impl true
  def render(width, height, state) do
    # Render frame
    :ok
  end

  @impl true
  def cleanup(state) do
    # Clean up resources
    :ok
  end
end
```

## Library Structure

- `EAGL.Math` - Vector and matrix math operations (GLM-inspired)
- `EAGL.Shader` - Shader compilation and uniform management (Wings3D-inspired)
- `EAGL.Model` - 3D model loading and vertex array management
- `EAGL.Buffer` - VAO/VBO helper functions
- `EAGL.Error` - OpenGL error checking and reporting
- `EAGL.Window` - OpenGL context and window management
- `EAGL.Const` - OpenGL constants

## Math Library

Comprehensive 3D math library supporting:

- **Vectors**: 2D, 3D, 4D vector operations with constructor macros
- **Matrices**: 2x2, 3x3, 4x4 matrix operations with transformation functions
- **Quaternions**: Rotation representation, SLERP, and conversion functions
- **Utilities**: Trigonometry, interpolation, clamping, and geometric functions
- **OpenGL Integration**: All functions work with Erlang's OpenGL binding format

All math functions work with the tuple-in-list format required by Erlang's OpenGL bindings.

## Examples

### Interactive Examples Runner
```bash
./priv/scripts/run_examples
```

### Individual Examples
```elixir
# Math library demonstrations (terminal output)
EAGL.Examples.Math.run_example()

# 3D teapot with Phong shading (OpenGL window)
EAGL.Examples.Teapot.run_example()

# LearnOpenGL tutorials (OpenGL windows)
EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise1.run_example()
EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise2.run_example()
EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise3.run_example()
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

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Learn OpenGL](https://learnopengl.com) for excellent OpenGL tutorials
- [Wings3D](https://wings3d.com) for inspiration and helper function patterns - the name EAGL(e) is a tip of the hat to this project
- The Erlang/OTP team for wxWidgets bindings
- The Elixir community for inspiration and support, particularly the [Elixir Sydney/Australia User Group](https://https://elixir.sydney)
- [Cursor](https://cursor.com) and Claude Sonnet for giving me the patience to get to running code and port the Learning OpenGL examples

