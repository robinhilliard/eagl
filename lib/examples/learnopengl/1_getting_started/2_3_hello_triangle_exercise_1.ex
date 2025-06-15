defmodule EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise1 do
  @moduledoc """
  LearnOpenGL 2.3 - Hello Triangle Exercise 1 (Two Triangles Side by Side)

  This example demonstrates drawing multiple triangles with a single draw call.
  It solves the first exercise from the Hello Triangle tutorial.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/src/1.getting_started/2.3.hello_triangle_exercise1>

  ## Framework Adaptation Notes

  In the original LearnOpenGL C++ tutorial, this exercise asks you to draw 2 triangles
  next to each other using glDrawArrays by adding more vertices to your data.

  EAGL's framework maintains the same approach:
  - Single VAO/VBO containing all vertex data
  - One glDrawArrays call renders both triangles
  - No indexing - each triangle uses 3 unique vertices

  ## Original Tutorial Exercise

  **Exercise 1**: Try to draw 2 triangles next to each other using glDrawArrays
  by adding more vertices to your data.

  ## Solution Concepts Demonstrated

  1. **Multiple Primitives**: Drawing 2 triangles with one draw call
  2. **Vertex Array Layout**: 6 vertices arranged as 2 separate triangles
  3. **Spatial Positioning**: Placing triangles side by side in NDC space
  4. **Draw Call Efficiency**: Single glDrawArrays for multiple primitives
  5. **Vertex Ordering**: Understanding how vertices form triangles

  ## Key Learning Points

  - How to structure vertex data for multiple primitives
  - The relationship between vertex count and triangle count
  - Positioning geometry in normalized device coordinates
  - When to use glDrawArrays vs glDrawElements
  - Understanding primitive assembly from vertex streams

  ## Triangle Geometry

  Two triangles positioned side by side:
  ```
  Left Triangle:     Right Triangle:
      /\\                 /\\
     /  \\               /  \\
    /____\\             /____\\
  ```

  6 vertices total: 3 for left triangle + 3 for right triangle
  No vertex sharing (unlike indexed rendering)

  ## Difference from Previous Examples

  - **2.1 Hello Triangle**: 1 triangle, 3 vertices
  - **2.2 Hello Triangle Indexed**: 1 rectangle (2 triangles), 4 vertices + indices
  - **2.3 Exercise 1**: 2 triangles, 6 vertices (no sharing)

  ## Usage

      EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise1.run_example()

  Press ENTER to exit the example.
  """

  use EAGL.Window
  use EAGL.Const

  import EAGL.Shader
  import EAGL.Buffer

  # Two triangles side by side (6 vertices total)
  @vertices [
    # First triangle (left)
    -0.9, -0.5, 0.0,  # Left vertex
    -0.0, -0.5, 0.0,  # Right vertex (shared x=0 boundary)
    -0.45, 0.5, 0.0,  # Top vertex

    # Second triangle (right)
    0.0, -0.5, 0.0,   # Left vertex (shared x=0 boundary)
    0.9, -0.5, 0.0,   # Right vertex
    0.45, 0.5, 0.0    # Top vertex
  ]

  @spec run_example() :: :ok | {:error, term()}
  def run_example,
    do:
      EAGL.Window.run(
        __MODULE__,
        "LearnOpenGL - 1 Getting Started - 2.3 Hello Triangle Exercise 1",
        return_to_exit: true
      )

  @impl true
  def setup do
    IO.puts("""
    === LearnOpenGL 2.3 - Hello Triangle Exercise 1 ===
    This example demonstrates drawing 2 triangles side by side!

    Exercise Goal:
    - Draw 2 triangles next to each other using glDrawArrays
    - Add more vertices to your data (6 vertices total)

    Key Concepts:
    - Multiple primitives in single VAO/VBO
    - 6 vertices = 2 triangles (3 vertices each)
    - Single glDrawArrays call renders both
    - No vertex sharing (unlike indexed rendering)

    Triangle layout: Left triangle + Right triangle
    Vertices 0-2: Left triangle, Vertices 3-5: Right triangle

    Press ENTER to exit.
    """)

    # Compile and link shaders
    with {:ok, vertex_shader} <-
           create_shader(
             @gl_vertex_shader,
             "learnopengl/1_getting_started/2_3_hello_triangle_exercise_1/vertex_shader.glsl"
           ),
         {:ok, fragment_shader} <-
           create_shader(
             @gl_fragment_shader,
             "learnopengl/1_getting_started/2_3_hello_triangle_exercise_1/fragment_shader.glsl"
           ),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do
      IO.puts("Vertex and fragment shaders compiled and linked successfully")

      # Create VAO and VBO for two triangles
      {vao, vbo} = create_position_array(@vertices)

      IO.puts("Created VAO and VBO (6 vertices uploaded to GPU)")
      IO.puts("Ready to render - You should see two orange triangles side by side.")

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

    # Draw the two triangles
    :gl.useProgram(program)
    :gl.bindVertexArray(vao)

    # Draw using vertex arrays - 6 vertices = 2 triangles
    :gl.drawArrays(@gl_triangles, 0, 6)

    :ok
  end

  @impl true
  def cleanup({program, vao, vbo}) do
    # Cleanup geometry data
    delete_vertex_array(vao, vbo)

    # Cleanup shader program
    cleanup_program(program)
    :ok
  end
end
