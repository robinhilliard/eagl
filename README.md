# EAGL

![An Eagle carrying a teapot](/priv/images/eagl_logo.png "EAGL Logo")

Make it **EA**sier to work with Open**GL** in Elixir, using the Erlang WX bindings to OpenGL.

## Overview

Most examples of working with OpenGL are written in C++ or C# (Unity). The purpose of the EAGL library is to make it easier to translate OpenGL tutorials
and examples from sites like [Learn OpenGL](https://learnopengl.com) into Elixir with some help to get over the initial learning curve and eventually write arbitrarily complex OpenGL applications without a 
pile of boilerplate.

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

## Examples

1. **`EAGL.Examples.SimpleShader`** - A minimal example demonstrating shader creation, compilation, and basic point rendering
2. **`EAGL.Examples.Teapot`** - A comprehensive 3D model rendering example with vertex arrays, matrix transformations, and proper resource management

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

## Usage

### Quick Start

#### Simple Shader Example
```bash
mix run -e "EAGL.Examples.SimpleShader.run_example()"
```
Creates a window with a blue point rendered using vertex and fragment shaders.

#### 3D Teapot Example  
```bash
mix run -e "EAGL.Examples.Teapot.run_example()"
```
Renders a 3D teapot model with proper 3D transformations and lighting setup.

### Convenience Scripts

For easier example running, use the scripts in `priv/scripts/`:

```bash
# Run the teapot example
./priv/scripts/teapot

# Run the simple shader example
./priv/scripts/simple_shader

# Run all examples interactively
./priv/scripts/all_examples
```

See [`priv/scripts/README.md`](priv/scripts/README.md) for more details about the available scripts.

### Using EAGL in Your Project

Add EAGL as a dependency in your `mix.exs`:

```elixir
defp deps do
  [
    {:eagl, "~> 0.1.0"}
  ]
end
```

### Basic Example

```elixir
defmodule MyApp.GLExample do
  use EAGL.Window
  use EAGL.Const
  import EAGL.Shader

  def run do
    EAGL.Window.run(__MODULE__, "My OpenGL App")
  end

  @impl true
  def setup do
    with {:ok, vertex_shader} <- create_shader(@gl_vertex_shader, "vertex.glsl"),
         {:ok, fragment_shader} <- create_shader(@gl_fragment_shader, "fragment.glsl"),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do
      {:ok, program}
    end
  end

  @impl true
  def render(_width, _height, program) do
    :gl.useProgram(program)
    # Your rendering code here
    :ok
  end

  @impl true
  def cleanup(program) do
    cleanup_program(program)
  end
end
```

## API Documentation

### Core Modules

- **`EAGL.Window`** - Window creation and event loop management
- **`EAGL.Shader`** - Shader compilation and program linking  
- **`EAGL.Model`** - 3D model loading and VAO creation
- **`EAGL.ObjLoader`** - Wavefront OBJ file parsing
- **`EAGL.Math`** - GLM-style math library with vectors, matrices, and quaternions
- **`EAGL.Const`** - OpenGL constants and enums
- **`EAGL.WindowBehaviour`** - Behavior for window callbacks

### Window Management

```elixir
# Create a window with default size (1024x768)
EAGL.Window.run(MyModule, "Window Title")

# Create a window with custom size
EAGL.Window.run(MyModule, "Window Title", {800, 600})
```

### Model Loading

```elixir
# Load a model from priv/models/
{:ok, model} = EAGL.Model.load_model_to_vao("teapot.obj")

# Use the model in rendering
:gl.bindVertexArray(model.vao)
:gl.drawElements(@gl_triangles, model.vertex_count, @gl_unsigned_int, 0)

# Clean up when done
EAGL.Model.delete_vao(model.vao)
```

### Math Operations

```elixir
use EAGL.Math

# Create vectors and matrices
position = vec3(1.0, 2.0, 3.0)
rotation = quat_from_euler(radians(45.0), 0.0, 0.0)
model_matrix = mat4_translate(mat4_identity(), position)

# Transform operations
view_matrix = mat4_look_at(
  vec3(0.0, 0.0, 5.0),  # eye position
  vec3(0.0, 0.0, 0.0),  # look at center
  vec3(0.0, 1.0, 0.0)   # up vector
)

projection_matrix = mat4_perspective(
  radians(45.0),  # field of view
  16.0/9.0,       # aspect ratio
  0.1,            # near plane
  100.0           # far plane
)
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

