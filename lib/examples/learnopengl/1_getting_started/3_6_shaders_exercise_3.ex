defmodule EAGL.Examples.LearnOpenGL.GettingStarted.ShadersExercise3 do
  @moduledoc """
  LearnOpenGL 3.6 - Shaders Exercise 3

  This example demonstrates outputting vertex position as fragment color, showing
  how vertex shader outputs are interpolated across the triangle surface and how
  coordinate values can be visualized as colors.
  It corresponds to the third shader exercise in the LearnOpenGL series.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/src/1.getting_started/3.6.shaders_exercise3>

  ## Exercise Description

  **Original Exercise:** "Output the vertex position to the fragment shader using the
  `out` keyword and set the fragment's color equal to this vertex position (see how
  even the vertex position values are interpolated across the triangle). Once you
  managed to do this; try to answer the following question: why is the bottom-left
  side of our triangle black?"

  **Solution Approach:**
  - Add `out vec3 vertexPos;` to vertex shader
  - Set `vertexPos = aPos;` in vertex shader
  - Add `in vec3 vertexPos;` to fragment shader
  - Set `FragColor = vec4(vertexPos, 1.0);` in fragment shader

  **Answer to Question:** The bottom-left is black because:
  - Bottom-left vertex position is (-0.5, -0.5, 0.0)
  - Negative values in RGB color space are clamped to 0.0 (black)
  - Only positive position values create visible colors

  ## Framework Adaptation Notes

  In the original LearnOpenGL C++ tutorial, this exercise teaches:
  - How vertex shader outputs are interpolated by the rasterizer
  - Understanding the relationship between coordinate spaces and color spaces
  - Visualizing geometric data as color information
  - How negative values affect color rendering

  EAGL's framework preserves all these concepts:
  - Same vertex data and shader input/output patterns
  - Demonstrates interpolation and coordinate-to-color mapping
  - Shows the visual effects of coordinate system properties

  ## Key Concept: Position-to-Color Mapping

  **Why this visualization is educational:**
  - Makes interpolation visible and understandable
  - Shows how coordinate values map to color values
  - Demonstrates the effect of negative coordinates
  - Helps understand the rasterization process

  **Coordinate to Color Mapping:**
  - X coordinate → Red channel
  - Y coordinate → Green channel
  - Z coordinate → Blue channel
  - Negative values clamped to 0.0 (black)
  - Positive values create visible colors

  ## Visual Result and Analysis

  Triangle with position-based coloring:
  - **Bottom-right (+0.5, -0.5, 0.0)**: Red channel 0.5, others 0.0 → Dark red
  - **Bottom-left (-0.5, -0.5, 0.0)**: All negative/zero → Black
  - **Top center (0.0, +0.5, 0.0)**: Green channel 0.5, others 0.0 → Dark green
  - **Interior pixels**: Interpolated between these values

  **Why bottom-left is black:**
  - Position (-0.5, -0.5, 0.0) has negative X and Y
  - RGB color channels can't be negative (clamped to 0.0)
  - Result: (0.0, 0.0, 0.0) = black

  ## Learning Objectives

  - Understanding vertex shader output interpolation
  - Coordinate space to color space mapping
  - Effects of negative values in color calculations
  - Visualizing geometric data through color

  ## Usage

      EAGL.Examples.LearnOpenGL.GettingStarted.ShadersExercise3.run_example()

  Press ENTER to exit the example.
  """

  use EAGL.Window
  use EAGL.Const

  import EAGL.Shader
  import EAGL.Buffer

  # Triangle vertex data - only positions needed for this exercise
  # Colors will be generated from positions in the shader
  @vertices [
    # positions
     0.5, -0.5, 0.0,  # bottom right
    -0.5, -0.5, 0.0,  # bottom left
     0.0,  0.5, 0.0   # top center
  ]

  @spec run_example() :: :ok | {:error, term()}
  def run_example,
    do:
      EAGL.Window.run(
        __MODULE__,
        "LearnOpenGL - 1 Getting Started - 3.6 Shaders Exercise 3",
        return_to_exit: true
      )

  @impl true
  def setup do
    IO.puts("""
    === LearnOpenGL 3.6 - Shaders Exercise 3 ===
    This example demonstrates position-to-color mapping and interpolation!

    Exercise: "Output the vertex position to the fragment shader using the `out`
    keyword and set the fragment's color equal to this vertex position. Why is
    the bottom-left side of our triangle black?"

    Solution Approach:
    - Vertex shader: out vec3 vertexPos; vertexPos = aPos;
    - Fragment shader: in vec3 vertexPos; FragColor = vec4(vertexPos, 1.0);

    Key Learning Points:
    - Vertex shader outputs are interpolated across triangle surface
    - Coordinate values can be visualized as color values
    - Negative coordinates are clamped to 0.0 in color space
    - Demonstrates the rasterization interpolation process

    Position-to-Color Mapping:
    - X coordinate → Red channel
    - Y coordinate → Green channel
    - Z coordinate → Blue channel (always 0.0 in this 2D example)

    Triangle Vertex Analysis:
    - Bottom-right (+0.5, -0.5, 0.0): Red=0.5, Green=0.0, Blue=0.0 → Dark red
    - Bottom-left (-0.5, -0.5, 0.0): Red=0.0, Green=0.0, Blue=0.0 → Black
    - Top center (0.0, +0.5, 0.0): Red=0.0, Green=0.5, Blue=0.0 → Dark green

    Answer: Bottom-left is black because:
    - Position (-0.5, -0.5, 0.0) has negative X and Y coordinates
    - RGB color channels cannot be negative (clamped to 0.0)
    - Result: (0.0, 0.0, 0.0) = black color

    This demonstrates how coordinate systems and color systems interact!

    Press ENTER to exit.
    """)

    # Compile and link shaders - position passed to fragment shader as color
    with {:ok, vertex_shader} <-
           create_shader(
             @gl_vertex_shader,
             "learnopengl/1_getting_started/3_6_shaders_exercise_3/vertex_shader.glsl"
           ),
         {:ok, fragment_shader} <-
           create_shader(
             @gl_fragment_shader,
             "learnopengl/1_getting_started/3_6_shaders_exercise_3/fragment_shader.glsl"
           ),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do
      IO.puts("Shaders compiled successfully with position-to-color mapping")

      # Create VAO/VBO with only position data (no color attributes needed)
      {vao, vbo} = create_position_array(@vertices)

      IO.puts("Only position data needed - colors generated from positions")
      IO.puts("Ready to render - You should see position-based coloring.")

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

    # Draw the triangle with position-based coloring
    # No uniforms needed - colors generated from vertex positions
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
