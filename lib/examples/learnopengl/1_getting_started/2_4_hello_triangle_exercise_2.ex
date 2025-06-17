defmodule EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise2 do
  @moduledoc """
  LearnOpenGL 2.4 - Hello Triangle Exercise 2 (Rectangle with EBO)

  This example demonstrates creating two triangles using Element Buffer Objects.
  It solves the second exercise from the Hello Triangle tutorial.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/src/1.getting_started/2.4.hello_triangle_exercise2>

  ## Framework Adaptation Notes

  In the original LearnOpenGL C++ tutorial, this exercise asks you to create two triangles
  using a single VAO and VBO, with an Element Buffer Object (EBO) to avoid vertex duplication.

  EAGL's framework maintains the same approach:
  - Single VAO/VBO/EBO for efficient vertex sharing
  - glDrawElements for indexed rendering
  - 4 vertices create 2 triangles through clever indexing

  ## Original Tutorial Exercise

  **Exercise 2**: Now create the same 2 triangles using an EBO so there are only 4 vertices
  in total instead of 6. This is a solution to the previous exercise using indices.

  ## Solution Concepts Demonstrated

  1. **Element Buffer Objects (EBO)**: Storing indices for vertex reuse
  2. **Vertex Sharing**: 4 vertices used to create 2 triangles
  3. **Indexed Rendering**: glDrawElements with index buffer
  4. **Memory Efficiency**: Reducing vertex data through sharing
  5. **Rectangle Formation**: Two triangles forming a quad

  ## Key Learning Points

  - How EBOs enable vertex sharing between primitives
  - The efficiency difference between indexed and non-indexed rendering
  - Understanding triangle winding order and connectivity
  - When indexed rendering provides the most benefit
  - The relationship between vertex count and primitive count

  ## Rectangle Geometry

  Two triangles sharing vertices to form a rectangle:
  ```
  3 ---- 2
  |    / |
  |   /  |
  |  /   |
  | /    |
  0 ---- 1
  ```

  4 vertices total, 6 indices: [0,1,3, 1,2,3]
  Triangle 1: vertices 0,1,3 | Triangle 2: vertices 1,2,3

  ## Difference from Previous Examples

  - **2.3 Exercise 1**: 2 triangles, 6 vertices (no sharing)
  - **2.4 Exercise 2**: 2 triangles, 4 vertices + indices (vertex sharing)

  ## Usage

      EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise2.run_example()

  Press ENTER to exit the example.
  """

  use EAGL.Window
  use EAGL.Const

  import EAGL.Shader
  import EAGL.Buffer
  import EAGL.Math

  # Rectangle vertex data (4 vertices shared between 2 triangles)
  @vertices ~v'''
   0.5  0.5 0.0   # top right    (index 0)
   0.5 -0.5 0.0   # bottom right (index 1)
  -0.5 -0.5 0.0   # bottom left  (index 2)
  -0.5  0.5 0.0   # top left     (index 3)
  '''

  # Indices for two triangles forming a rectangle
  # First triangle: 0, 1, 3 (top-right, bottom-right, top-left)
  # Second triangle: 1, 2, 3 (bottom-right, bottom-left, top-left)
  @indices ~i'''
  0 1 3  # first triangle
  1 2 3  # second triangle
  '''

  @spec run_example() :: :ok | {:error, term()}
  def run_example(opts \\ []) do
    default_opts = [return_to_exit: true]
    merged_opts = Keyword.merge(default_opts, opts)

    EAGL.Window.run(
      __MODULE__,
      "LearnOpenGL - 1 Getting Started - 2.4 Hello Triangle Exercise 2",
      merged_opts
    )
  end

  @impl true
  def setup do
    IO.puts("""
    === LearnOpenGL 2.4 - Hello Triangle Exercise 2 ===
    This example demonstrates creating 2 triangles using an EBO

    Exercise Goal:
    - Create the same 2 triangles using an EBO
    - Use only 4 vertices instead of 6
    - Solution to Exercise 1 using indices

    Key Concepts:
    - Element Buffer Objects (EBO) store vertex indices
    - Vertex sharing: 4 vertices form 2 triangles
    - glDrawElements() for indexed rendering
    - Memory efficiency through vertex reuse

    Efficiency comparison:
    - Exercise 1: 6 vertices (no sharing)
    - Exercise 2: 4 vertices + 6 indices (sharing)

    Press ENTER to exit.
    """)

    # Compile and link shaders
    with {:ok, vertex_shader} <-
           create_shader(
             @gl_vertex_shader,
             "learnopengl/1_getting_started/2_4_hello_triangle_exercise_2/vertex_shader.glsl"
           ),
         {:ok, fragment_shader} <-
           create_shader(
             @gl_fragment_shader,
             "learnopengl/1_getting_started/2_4_hello_triangle_exercise_2/fragment_shader.glsl"
           ),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do
      IO.puts("Vertex and fragment shaders compiled and linked successfully")

      # Create VAO, VBO, and EBO for indexed rectangle geometry
      {vao, vbo, ebo} = create_indexed_position_array(@vertices, @indices)

      IO.puts("Created VAO, VBO, and EBO (4 vertices + 6 indices uploaded to GPU)")
      IO.puts("Ready to render - You should see an orange rectangle (2 triangles).")

      # State: {program, vao, vbo, ebo}
      {:ok, {program, vao, vbo, ebo}}
    else
      {:error, reason} ->
        IO.puts("Failed to create shader program: #{reason}")
        {:error, reason}
    end
  end

  @impl true
  def render(viewport_width, viewport_height, {program, vao, _vbo, _ebo}) do
    # Set viewport
    :gl.viewport(0, 0, trunc(viewport_width), trunc(viewport_height))

    # Set clear color (dark gray-blue) and clear screen
    :gl.clearColor(0.2, 0.3, 0.3, 1.0)
    :gl.clear(@gl_color_buffer_bit)

    # Draw the rectangle (two triangles)
    :gl.useProgram(program)
    :gl.bindVertexArray(vao)

    # Draw using indices - this is the key difference from Exercise 3
    # We draw 6 indices (2 triangles * 3 vertices each) but only need 4 actual vertices
    :gl.drawElements(@gl_triangles, 6, @gl_unsigned_int, 0)

    :ok
  end

  @impl true
  def cleanup({program, vao, vbo, ebo}) do
    # Cleanup geometry data
    delete_indexed_array(vao, vbo, ebo)

    # Cleanup shader program
    cleanup_program(program)
    :ok
  end
end
