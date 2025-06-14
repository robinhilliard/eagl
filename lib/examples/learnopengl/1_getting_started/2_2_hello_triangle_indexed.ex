defmodule EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleIndexed do
  @moduledoc """
  Port of LearnOpenGL's Hello Triangle Indexed to EAGL framework.

  Original: https://learnopengl.com/Getting-started/Hello-Triangle (Section 2.2)
  Chapter 1, Section 2.2: Hello Triangle Indexed

  This example demonstrates:
  - Creating a rectangle using only 4 vertices instead of 6
  - Using an Element Buffer Object (EBO) to define triangle indices
  - Drawing with glDrawElements instead of glDrawArrays
  - Understanding vertex sharing and memory efficiency

  The rectangle is defined by 4 vertices with indices specifying how to form triangles:
  ```
  3 ---- 2
  |    / |
  |   /  |
  |  /   |
  | /    |
  0 ---- 1
  ```

  Key concepts:
  - EBO (Element Buffer Object) stores indices
  - 4 vertices shared between 2 triangles
  - Memory efficient - no duplicate vertices
  - glDrawElements() vs glDrawArrays()

  Run with: mix run -e "EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleIndexed.run_example()"
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
  def run_example, do: EAGL.Window.run(__MODULE__, "LearnOpenGL - 1 Getting Started - 2.2 Hello Triangle Indexed")

  @impl true
  def setup do
    IO.puts("Starting LearnOpenGL Hello Triangle Indexed...")

    # Compile and link shaders
    with {:ok, vertex_shader} <- create_shader(@gl_vertex_shader, "learnopengl/1_getting_started/2_2_hello_triangle_indexed/vertex_shader.glsl"),
         {:ok, fragment_shader} <- create_shader(@gl_fragment_shader, "learnopengl/1_getting_started/2_2_hello_triangle_indexed/fragment_shader.glsl"),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do

      IO.puts("✓ Created shader program")

      # Create VAO, VBO, and EBO for indexed rectangle geometry
      # This is the key difference from basic triangle - we use indices!
      {vao, vbo, ebo} = create_indexed_position_array(@vertices, @indices)

      IO.puts("✓ Created indexed vertex array (4 vertices, 6 indices)")

      # State: {program, vao, vbo, ebo}
      {:ok, {program, vao, vbo, ebo}}
    else
      {:error, reason} ->
        IO.puts("✗ Failed to create shader program: #{reason}")
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
  def handle_event({:key, key_code}, state) do
    if key_code == 27 do  # ESC key
      throw(:close_window)
    end
    {:ok, state}
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
