defmodule EAGL.Examples.LearnOpenGL.GettingStarted.ShadersClass do
  @moduledoc """
  LearnOpenGL 3.3 - Shaders Class

  This example demonstrates the same vertex colour interpolation as 3.2, but emphasises
  the importance of shader abstraction and organisation. It shows how to structure
  shader management in a clean, reusable way.
  It corresponds to the Shaders Class tutorial in the LearnOpenGL series.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/src/1.getting_started/3.3.shaders_class>

  ## Framework Adaptation Notes

  In the original LearnOpenGL C++ tutorial, this example introduces shader class abstraction:
  - How to encapsulate shader compilation, linking, and error handling
  - How to create reusable shader management utilities
  - How to provide clean APIs for setting uniforms and using shaders
  - The importance of proper resource management and cleanup

  EAGL's framework already provides this abstraction through EAGL.Shader:
  - create_shader/2 handles compilation with automatic error reporting
  - create_attach_link/1 handles linking with error checking
  - set_uniform/3 provides type-safe uniform setting
  - All following the same patterns as the original tutorial's Shader class

  ## Key Concept: Shader Abstraction

  **Why shader classes/modules are important:**
  - Encapsulate complex OpenGL shader operations
  - Provide error handling and debugging information
  - Enable code reuse across multiple examples
  - Simplify shader management in larger applications
  - Abstract away low-level OpenGL details

  **EAGL.Shader Module Features:**
  - Automatic shader compilation with error reporting
  - File-based shader loading from priv/shaders/
  - Type-safe uniform setting with automatic type detection
  - Resource cleanup and management
  - Consistent error handling patterns

  ## Visual Result

  Identical to 3.2 Shaders Interpolation:
  - Bottom-right corner: Red (1.0, 0.0, 0.0)
  - Bottom-left corner: Green (0.0, 1.0, 0.0)
  - Top center: Blue (0.0, 0.0, 1.0)
  - Interior pixels: Smooth interpolation between these colors

  ## Difference from Previous Examples

  - **3.2 Shaders Interpolation**: Focus on interpolation concept
  - **3.3 Shaders Class**: Same visual result, emphasis on clean shader abstraction

  ## Usage

      EAGL.Examples.LearnOpenGL.GettingStarted.ShadersClass.run_example()

  Press ENTER to exit the example.
  """

  use EAGL.Window
  use EAGL.Const

  import EAGL.Shader
  import EAGL.Buffer
  import EAGL.Math

  # Triangle vertex data with positions and colors interleaved
  # Format: [x, y, z, r, g, b] per vertex
  @vertices ~v'''
  # positions        # colors
   0.5 -0.5 0.0  1.0 0.0 0.0   # bottom right - red
  -0.5 -0.5 0.0  0.0 1.0 0.0   # bottom left - green
   0.0  0.5 0.0  0.0 0.0 1.0   # top center - blue
  '''

  @spec run_example() :: :ok | {:error, term()}
  def run_example,
    do:
      EAGL.Window.run(
        __MODULE__,
        "LearnOpenGL - 1 Getting Started - 3.3 Shaders Class",
        return_to_exit: true
      )

  @impl true
  def setup do
    IO.puts("""
    === LearnOpenGL 3.3 - Shaders Class ===
    This example demonstrates shader abstraction and organization

    Key Concepts:
    - Shader class/module abstraction for clean code organization
    - Encapsulation of shader compilation, linking, and error handling
    - Reusable shader management utilities
    - Proper resource management and cleanup patterns

    EAGL.Shader Module Features:
    - create_shader/2: Compiles shaders with automatic error reporting
    - create_attach_link/1: Links shader programs with error checking
    - set_uniform/3: Type-safe uniform setting with automatic detection
    - File-based shader loading from organized directory structure
    - Consistent error handling and resource cleanup

    Benefits of Shader Abstraction:
    - Reduces code duplication across examples
    - Provides consistent error handling and debugging
    - Simplifies shader management in complex applications
    - Abstracts away low-level OpenGL details
    - Enables rapid prototyping and experimentation

    Visual Result:
    - Same colour interpolation as 3.2 Shaders Interpolation
          - Focus is on clean code organisation, not visual differences
    - Demonstrates how good abstraction doesn't change functionality

    Press ENTER to exit.
    """)

    # Demonstrate EAGL's shader abstraction - clean, simple API
    # This replaces the manual shader compilation code from earlier examples
    with {:ok, vertex_shader} <-
           create_shader(
             :vertex,
             "learnopengl/1_getting_started/3_3_shaders_class/vertex_shader.glsl"
           ),
         {:ok, fragment_shader} <-
           create_shader(
             :fragment,
             "learnopengl/1_getting_started/3_3_shaders_class/fragment_shader.glsl"
           ),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do
      IO.puts("Shader abstraction working properly")
      IO.puts("EAGL.Shader handled compilation, linking, and error checking")

      # Create buffer objects using EAGL.Buffer helpers
      # This demonstrates a clean attribute specification pattern
      attributes = vertex_attributes(:position, :color)

      {vao, vbo} = create_vertex_array(@vertices, attributes)

      IO.puts("Buffer abstraction working properly")
      IO.puts("EAGL.Buffer used vertex_attributes(:position, :color) helper")
      IO.puts("Clean, readable code with proper error handling")

      # State: {program, vao, vbo}
      {:ok, {program, vao, vbo}}
    else
      {:error, reason} ->
        IO.puts("Shader abstraction caught error: #{reason}")
        {:error, reason}
    end
  end

  @impl true
  def render(viewport_width, viewport_height, {program, vao, _vbo}) do
    # Set viewport
    :gl.viewport(0, 0, trunc(viewport_width), trunc(viewport_height))

    # Set clear color (dark gray-blue) and clear screen
    :gl.clearColor(0.2, 0.3, 0.3, 1.0)
    :gl.clear(@gl_color_buffer_bit)

    # Use the shader program - abstracted away the complexity
    :gl.useProgram(program)

    # Draw the triangle - same result as 3.2, but cleaner code organization
    :gl.bindVertexArray(vao)
    :gl.drawArrays(@gl_triangles, 0, 3)

    :ok
  end

  @impl true
  def cleanup({program, vao, vbo}) do
    # Demonstrate proper resource cleanup - part of good abstraction
    delete_vertex_array(vao, vbo)
    :gl.deleteProgram(program)
    IO.puts("Resources cleaned up properly through abstraction")
    :ok
  end
end
