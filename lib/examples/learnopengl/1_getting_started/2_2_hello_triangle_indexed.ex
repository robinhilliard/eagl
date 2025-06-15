defmodule EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleIndexed do
  @moduledoc """
  LearnOpenGL 2.2 - Hello Triangle Indexed (Element Buffer Objects)

  This example demonstrates Element Buffer Objects (EBO) for efficient indexed rendering.
  It shows how to draw a rectangle using two triangles with shared vertices.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/src/1.getting_started/2.2.hello_triangle_indexed>

  ## Framework Adaptation Notes

  In the original LearnOpenGL C++ tutorial, this example introduces Element Buffer Objects (EBOs)
  as a way to avoid vertex duplication when drawing complex shapes.

  EAGL's framework maintains the same concepts while providing helper functions:
  - EBO creation and binding are handled by EAGL.Buffer functions
  - The core concept of indexed rendering remains unchanged
  - glDrawElements vs glDrawArrays distinction is preserved

  ## Original Tutorial Concepts Demonstrated

  1. **Element Buffer Objects (EBO)**: Storing vertex indices for reuse
  2. **Indexed Rendering**: Drawing with glDrawElements instead of glDrawArrays
  3. **Vertex Sharing**: Using 4 vertices to draw 2 triangles (6 vertices worth)
  4. **Memory Efficiency**: Avoiding duplicate vertex data
  5. **Triangle Assembly**: How indices define triangle connectivity

  ## Key Learning Points

  - Understanding indexed vs non-indexed rendering
  - Memory efficiency through vertex sharing
  - The relationship between vertices and indices
  - When to use EBOs vs simple vertex arrays
  - Triangle winding order and face culling implications

  ## Rectangle Geometry

  The rectangle is defined by 4 vertices with 6 indices (2 triangles):
  ```
  3 ---- 2
  |    / |
  |   /  |
  |  /   |
  | /    |
  0 ---- 1
  ```

  Vertices: 4 unique positions
  Indices: [0,1,3, 1,2,3] (2 triangles sharing vertices 0, 1, and 3)

  ## Difference from Previous Examples

  - **2.1 Hello Triangle**: 3 vertices, glDrawArrays (no sharing)
  - **2.2 Hello Triangle Indexed**: 4 vertices + indices, glDrawElements (vertex sharing)

  ## Usage

      EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleIndexed.run_example()

  Press ENTER to exit the example.
  """

  use EAGL.Window
  use EAGL.Const

  import EAGL.Shader
  import EAGL.Buffer

  # Rectangle vertex data (4 vertices shared between 2 triangles)
  @vertices [
    0.5,  0.5, 0.0,   # top right    (index 0)
    0.5, -0.5, 0.0,   # bottom right (index 1)
   -0.5, -0.5, 0.0,   # bottom left  (index 2)
   -0.5,  0.5, 0.0    # top left     (index 3)
  ]

  # Indices for two triangles forming a rectangle
  # Note: we can reuse vertices!
  # First triangle: 0, 1, 3 (top-right, bottom-right, top-left)
  # Second triangle: 1, 2, 3 (bottom-right, bottom-left, top-left)
  @indices [
    0, 1, 3,  # first triangle
    1, 2, 3   # second triangle
  ]

  @spec run_example() :: :ok | {:error, term()}
  def run_example,
    do:
      EAGL.Window.run(
        __MODULE__,
        "LearnOpenGL - 1 Getting Started - 2.2 Hello Triangle Indexed",
        return_to_exit: true
      )

  @impl true
  def setup do
    IO.puts("""
    === LearnOpenGL 2.2 - Hello Triangle Indexed ===
    This example demonstrates Element Buffer Objects (EBO) for efficient rendering!

    Key Concepts:
    - Element Buffer Objects (EBO) store vertex indices
    - Vertex sharing: 4 vertices create 2 triangles (instead of 6 vertices)
    - glDrawElements() renders using indices
    - Memory efficiency through vertex reuse

    Rectangle geometry:
      4 vertices: (0.5,0.5), (0.5,-0.5), (-0.5,-0.5), (-0.5,0.5)
      6 indices: [0,1,3, 1,2,3] forming 2 triangles

    Efficiency gain: 4 vertices + 6 indices vs 6 vertices

    Press ENTER to exit.
    """)

    # Compile and link shaders
    with {:ok, vertex_shader} <-
           create_shader(
             :vertex,
             "learnopengl/1_getting_started/2_2_hello_triangle_indexed/vertex_shader.glsl"
           ),
         {:ok, fragment_shader} <-
           create_shader(
             :fragment,
             "learnopengl/1_getting_started/2_2_hello_triangle_indexed/fragment_shader.glsl"
           ),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do
      IO.puts("Vertex and fragment shaders compiled and linked successfully")

      # Create VAO, VBO, and EBO for indexed rectangle geometry
      # This is the key difference from basic triangle - we use indices!
      {vao, vbo, ebo} = create_indexed_position_array(@vertices, @indices)

      IO.puts("Created VAO, VBO, and EBO (4 vertices + 6 indices uploaded to GPU)")
      IO.puts("Ready to render - You should see an orange rectangle.")

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

    # Draw the rectangle using indexed rendering
    :gl.useProgram(program)
    :gl.bindVertexArray(vao)

    # Key difference: Use glDrawElements with indices instead of glDrawArrays
    # 6 indices form 2 triangles, but we only store 4 unique vertices
    :gl.drawElements(@gl_triangles, 6, @gl_unsigned_int, 0)

    :ok
  end

  @impl true
  def cleanup({program, vao, vbo, ebo}) do
    # Cleanup indexed geometry data
    delete_indexed_array(vao, vbo, ebo)

    # Cleanup shader program
    cleanup_program(program)
    :ok
  end
end
