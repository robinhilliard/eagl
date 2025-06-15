defmodule EAGL.Examples.LearnOpenGL.GettingStarted.ShadersExercise1 do
  @moduledoc """
  LearnOpenGL 3.4 - Shaders Exercise 1

  This example demonstrates how to modify vertex positions in the vertex shader
  to create an upside-down triangle. It shows how vertex transformations can be
  applied directly in the shader rather than modifying vertex data.
  It corresponds to the first shader exercise in the LearnOpenGL series.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/src/1.getting_started/3.4.shaders_exercise1>

  ## Exercise Description

  **Original Exercise:** "Adjust the vertex shader so that the triangle is upside down"

  **Solution Approach:** Negate the y-coordinate in the vertex shader:
  - Original: `gl_Position = vec4(aPos, 1.0);`
  - Modified: `gl_Position = vec4(aPos.x, -aPos.y, aPos.z, 1.0);`

  ## Framework Adaptation Notes

  In the original LearnOpenGL C++ tutorial, this exercise teaches:
  - How vertex shaders can transform vertex positions
  - The difference between modifying data vs. modifying shaders
  - Understanding coordinate systems and transformations
  - How simple mathematical operations in shaders affect rendering

  EAGL's framework preserves all these concepts:
  - Same vertex data as previous examples (no changes needed)
  - Transformation happens entirely in the vertex shader
  - Demonstrates shader-based coordinate manipulation

  ## Key Concept: Vertex Transformation

  **Why transform in the vertex shader:**
  - More efficient than modifying vertex data on CPU
  - Can be combined with other transformations (matrices, etc.)
  - Demonstrates the power and flexibility of programmable shaders
  - Shows how shaders can manipulate geometry dynamically

  **Coordinate System Understanding:**
  - OpenGL uses right-handed coordinate system
  - Y-axis points up in normalized device coordinates
  - Negating Y flips the triangle vertically
  - This is a fundamental transformation concept

  ## Visual Result

  Triangle with interpolated colors but flipped upside-down:
  - Top corners: Red (right) and Green (left) - now at bottom
  - Bottom center: Blue - now at top
  - Same color interpolation as 3.2/3.3, just flipped

  ## Learning Objectives

  - Understanding vertex shader transformations
  - Coordinate system manipulation
  - Difference between data modification vs. shader modification
  - Basic mathematical operations in GLSL

  ## Usage

      EAGL.Examples.LearnOpenGL.GettingStarted.ShadersExercise1.run_example()

  Press ENTER to exit the example.
  """

  use EAGL.Window
  use EAGL.Const

  import EAGL.Shader
  import EAGL.Buffer

  # Same triangle vertex data as 3.2/3.3 - transformation happens in shader
  # Format: [x, y, z, r, g, b] per vertex
  @vertices [
    # positions        # colors
     0.5, -0.5, 0.0,   1.0, 0.0, 0.0,  # bottom right - red
    -0.5, -0.5, 0.0,   0.0, 1.0, 0.0,  # bottom left - green
     0.0,  0.5, 0.0,   0.0, 0.0, 1.0   # top center - blue
  ]

  @spec run_example() :: :ok | {:error, term()}
  def run_example,
    do:
      EAGL.Window.run(
        __MODULE__,
        "LearnOpenGL - 1 Getting Started - 3.4 Shaders Exercise 1",
        return_to_exit: true
      )

  @impl true
  def setup do
    IO.puts("""
    === LearnOpenGL 3.4 - Shaders Exercise 1 ===
    This example demonstrates vertex transformation in shaders!

    Exercise: "Adjust the vertex shader so that the triangle is upside down"

    Solution Approach:
    - Keep the same vertex data (no CPU-side changes)
    - Modify the vertex shader to negate the y-coordinate
    - Original: gl_Position = vec4(aPos, 1.0);
    - Modified: gl_Position = vec4(aPos.x, -aPos.y, aPos.z, 1.0);

    Key Learning Points:
    - Vertex shaders can transform positions dynamically
    - More efficient than modifying vertex data on CPU
    - Demonstrates coordinate system understanding
    - Shows power of programmable shader pipeline

    Coordinate System:
    - OpenGL uses right-handed coordinate system
    - Y-axis points up in normalized device coordinates
    - Negating Y flips the triangle vertically
    - This is a fundamental transformation concept

    Visual Result:
    - Same color interpolation as previous examples
    - Triangle is now upside-down (blue at top, red/green at bottom)
    - Demonstrates shader-based geometry manipulation

    Press ENTER to exit.
    """)

    # Compile and link shaders - vertex shader contains the transformation
    with {:ok, vertex_shader} <-
           create_shader(
             :vertex,
             "learnopengl/1_getting_started/3_4_shaders_exercise_1/vertex_shader.glsl"
           ),
         {:ok, fragment_shader} <-
           create_shader(
             :fragment,
             "learnopengl/1_getting_started/3_4_shaders_exercise_1/fragment_shader.glsl"
           ),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do
      IO.puts("Shaders compiled successfully with vertex transformation")

      # Create buffer objects with color attribute
      # Position and color data interleaved: [x, y, z, r, g, b] per vertex
      attributes = vertex_attributes(:position, :color)

      {vao, vbo} = create_vertex_array(@vertices, attributes)

      IO.puts("Same vertex data as 3.2/3.3 - transformation happens in shader")
      IO.puts("Ready to render - Triangle should be upside-down with same colors.")

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

    # Use the shader program with vertex transformation
    :gl.useProgram(program)

    # Draw the upside-down triangle
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
