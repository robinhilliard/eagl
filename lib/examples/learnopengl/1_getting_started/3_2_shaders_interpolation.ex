defmodule EAGL.Examples.LearnOpenGL.GettingStarted.ShadersInterpolation do
  @moduledoc """
  LearnOpenGL 3.2 - Shaders Interpolation

  This example demonstrates vertex colour interpolation in shaders - how colours assigned to vertices
  are automatically interpolated across the triangle surface by the rasterizer.
  It corresponds to the Shaders Interpolation tutorial in the LearnOpenGL series.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/src/1.getting_started/3.2.shaders_interpolation>

  ## Framework Adaptation Notes

  In the original LearnOpenGL C++ tutorial, this example introduces vertex attributes for colours:
  - How to pass colour data as vertex attributes alongside position data
  - How to declare multiple vertex attributes in shaders
  - How the rasterizer automatically interpolates values between vertices
  - Understanding the difference between per-vertex and per-fragment data

  EAGL's framework preserves all these concepts while providing convenience functions:
  - EAGL.Buffer.create_vertex_array() handles the VAO/VBO setup with multiple attributes
  - The core OpenGL vertex attribute concepts remain unchanged and visible

  ## Key Concept: Fragment Interpolation

  **What happens during rasterization:**
  - Triangle has 3 vertices with different colours (red, green, blue)
  - Rasterizer determines which pixels are inside the triangle
  - For each pixel, it calculates interpolated values based on distance from vertices
  - A pixel 70% of the way from red to blue vertex gets 30% red + 70% blue
  - This creates smooth colour gradients across the triangle surface

  **Original Tutorial Concepts Demonstrated:**

  1. **Multiple Vertex Attributes**: Position (location 0) and Colour (location 1)
  2. **Vertex Attribute Stride**: 6 floats per vertex (3 position + 3 colour)
  3. **Vertex Attribute Offsets**: Position at offset 0, Colour at offset 3
  4. **Shader Input/Output**: Vertex shader outputs colour, fragment shader receives interpolated colour
  5. **Automatic Interpolation**: GPU automatically interpolates all vertex shader outputs

  ## Visual Result

  The triangle displays a colour gradient:
  - Bottom-right corner: Red (1.0, 0.0, 0.0)
  - Bottom-left corner: Green (0.0, 1.0, 0.0)
  - Top center: Blue (0.0, 0.0, 1.0)
      - Interior pixels: Smooth interpolation between these colours

  ## Difference from Previous Examples

  - **3.1 Shaders Uniform**: Single colour for entire triangle, changed via uniform
  - **3.2 Shaders Interpolation**: Different colour per vertex, interpolated across surface

  ## Usage

      EAGL.Examples.LearnOpenGL.GettingStarted.ShadersInterpolation.run_example()

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
  def run_example(opts \\ []) do
    default_opts = [enter_to_exit: true]
    merged_opts = Keyword.merge(default_opts, opts)

    EAGL.Window.run(
      __MODULE__,
      "LearnOpenGL - 1 Getting Started - 3.2 Shaders Interpolation",
      merged_opts
    )
  end

  @impl true
  def setup do
    IO.puts("""
    === LearnOpenGL 3.2 - Shaders Interpolation ===
    This example demonstrates vertex colour interpolation

    Key Concepts:
    - Multiple vertex attributes: position AND colour per vertex
    - Vertex attribute stride: 6 floats per vertex (3 pos + 3 colour)
    - Automatic interpolation: GPU interpolates colours across triangle surface
    - Fragment shader receives interpolated values, not original vertex values

    Triangle Colours:
    - Bottom-right corner: Red (1.0, 0.0, 0.0)
    - Bottom-left corner: Green (0.0, 1.0, 0.0)
    - Top center: Blue (0.0, 0.0, 1.0)
    - Interior pixels: Smooth gradients between these colors

    Rasterization Process:
    - GPU determines which pixels are inside the triangle
    - For each pixel, calculates distance from each vertex
    - Interpolates colour based on these distances
    - Creates smooth colour transitions across the surface

    EAGL Framework:
    - Uses create_vertex_array() with custom attribute specification
    - Handles VAO/VBO setup with multiple attributes automatically
    - Same visual result as original C++ tutorial

    Press ENTER to exit.
    """)

    # Compile and link shaders
    with {:ok, vertex_shader} <-
           create_shader(
             @gl_vertex_shader,
             "learnopengl/1_getting_started/3_2_shaders_interpolation/vertex_shader.glsl"
           ),
         {:ok, fragment_shader} <-
           create_shader(
             @gl_fragment_shader,
             "learnopengl/1_getting_started/3_2_shaders_interpolation/fragment_shader.glsl"
           ),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do
      IO.puts("Vertex and fragment shaders compiled and linked successfully")

      # Create VAO and VBO with multiple vertex attributes
      # Each vertex has 6 floats: 3 for position, 3 for color
      attributes = vertex_attributes(:position, :color)
      {vao, vbo} = create_vertex_array(@vertices, attributes)

      IO.puts("Created VAO and VBO with position and colour attributes")

      IO.puts(
        "Using vertex_attributes(:position, :color) helper - automatically calculates stride and offsets"
      )

      IO.puts("Position: location 0, 3 floats, stride 24 bytes, offset 0")
      IO.puts("Colour: location 1, 3 floats, stride 24 bytes, offset 12")
      IO.puts("Ready to render - You should see a triangle with interpolated colours.")

      # State: {program, vao, vbo}
      {:ok, {program, vao, vbo}}
    else
      {:error, reason} ->
        IO.puts("Failed to create shader program: #{reason}")
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

    # Use the shader program
    :gl.useProgram(program)

    # Draw the triangle with interpolated colours
    # No uniforms needed - colours come from vertex attributes
    :gl.bindVertexArray(vao)
    :gl.drawArrays(@gl_triangles, 0, 3)

    :ok
  end

  @impl true
  def cleanup({program, vao, vbo}) do
    delete_vertex_array(vao, vbo)
    :gl.deleteProgram(program)
    :ok
  end
end
