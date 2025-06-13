# EaGL

![An Eagle carrying a teapot](/priv/images/eagl_logo.png "EAGL Logo")

Make it **Ea**sier to work with Open**GL** in Elixir, using the Erlang WX bindings to OpenGL.

## Overview

Most examples of working with OpenGL are written in C++ or C# (Unity). The purpose of the EAGL library is to make it easier to translate OpenGL tutorials
and examples from resources like [Learn OpenGL](https://learnopengl.com) into Elixir with some help to get over the initial learning bump and eventually write arbitrarily complex OpenGL applications with minimal boilerplate (using the Wings 3D Erlang source as a guide).

EAGL provides a clean, idiomatic Elixir interface for:
- OpenGL shader management and compilation
- 3D model loading (Wavefront OBJ format)
- Window creation and event handling
- Vertex Array Objects (VAO) management
- OpenGL constants and utilities
- A port of the GLM math header library

Non-goals:
- Heavy abstraction/wrapping of the Erlang wx library: we want it to be easy to see the correspondence betweeen OpenGL examples in other languages and ours
- A Shader DSL like Nx
- A UI layout/component library
- 3D mesh modelling (leave that to Wings 3D, Blender etc)

## Features

- **Math Library**: Complete 3D math operations (vectors, matrices, quaternions)
- **Shader Management**: Easy shader compilation and program linking
- **Uniform Helpers**: Simplified uniform value setting with automatic type detection
- **Model Loading**: OBJ file loader with automatic normal generation
- **Window Management**: OpenGL context creation and event handling
- **Examples**: Ready-to-run examples demonstrating various features

## Quick Start

```elixir
# Add to mix.exs
{:eagl, "~> 0.1.0"}
```

### Running Examples

EAGL includes several examples to demonstrate its capabilities:

```bash
# Simple point rendering
priv/scripts/simple_shader

# 3D teapot with Phong shading
priv/scripts/teapot

# All math library demonstrations
priv/scripts/math
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

### Uniform Helper Features

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

# Create simple position-only VAO/VBO
vertices = [-0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0]
{vao, vbo} = create_position_array(vertices)

# Or create with custom attributes
{vao, vbo} = create_vertex_array(vertices, [
  {0, 3, @gl_float, @gl_false, 0, 0}  # position at location 0
])

# Clean up
delete_vertex_array(vao, vbo)
```

### Error Handling

```elixir
import EAGL.Error

# Check for OpenGL errors
check("After buffer creation")  # Returns :ok or {:error, message}

# Get error string for error code
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

- `EAGL.Math` - Vector and matrix math operations
- `EAGL.Shader` - Shader compilation and uniform management  
- `EAGL.Model` - 3D model loading and vertex array management
- `EAGL.Window` - OpenGL context and window management
- `EAGL.Const` - OpenGL constants

## Math Library

Comprehensive 3D math library supporting:

- **Vectors**: 2D, 3D, 4D vector operations
- **Matrices**: 2x2, 3x3, 4x4 matrix operations  
- **Quaternions**: Rotation representation and SLERP
- **Utilities**: Trigonometry, interpolation, clamping
- **Geometric**: Cross products, normals, projections

All math functions work with the tuple-in-list format required by Erlang's OpenGL bindings.

## Examples

### Simple Rendering
```elixir
EAGL.Examples.SimpleShader.run_example()
```

### 3D Teapot
```elixir  
EAGL.Examples.Teapot.run_example()
```

### Math Demonstrations
```elixir
EAGL.Examples.Math.run_all_demos()
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

## Project Structure

```
lib/
├── eagl/                   # Core EAGL modules
│   ├── const.ex            # OpenGL constants
│   ├── math.ex             # GLM-style math library
│   ├── model.ex            # 3D model management
│   ├── obj_loader.ex       # Wavefront OBJ parser
│   ├── shader.ex           # Shader compilation
│   ├── window.ex           # Window management
│   └── window_behaviour.ex # Window callback behavior
├── examples/               # Example applications
└── wx/                     # wxWidgets constants
test/
├── eagl/                   # Unit tests for EAGL modules
└── eagl_test.exs           # Integration tests
priv/
├── models/                 # 3D model files (.obj)
├── scripts/                # Convenience scripts for running examples
└── shaders/                # GLSL shader files
```

## Features

- ✅ **Shader Management**: Automatic compilation, linking, and error reporting
- ✅ **3D Model Loading**: Wavefront OBJ format with normals and texture coordinates
- ✅ **Math Library**: GLM-compatible vectors, matrices, quaternions with full OpenGL integration
- ✅ **Window Management**: Cross-platform window creation with wxWidgets
- ✅ **Event Handling**: Resize, close, and paint events
- ✅ **Resource Cleanup**: Automatic cleanup of OpenGL resources
- ✅ **Error Handling**: Comprehensive error reporting and graceful degradation
- ✅ **Testing**: Full test suite with OpenGL context mocking

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
- The Erlang/OTP team for wxWidgets bindings
- The Elixir community for inspiration and support, particularly the Elixir Sydney/Australia User Group
- Claude Sonnet for giving me the patience to work through the lack of examples and get to running code on my 3rd or 4th attempt over the years to do something with gl via Erlang and WX
- The name EAGL(e) is a tip of the hat to [Wings3D](https://wings3d.com), a highpoint in BEAM-based 3D programming to date.

