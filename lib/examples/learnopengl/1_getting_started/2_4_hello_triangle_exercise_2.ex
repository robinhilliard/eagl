defmodule EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise2 do
  @moduledoc """
  Port of LearnOpenGL's Hello Triangle Exercise 2 to EAGL framework.

  Original: https://learnopengl.com/Getting-started/Hello-Triangle (Exercise 2)
  Chapter 1, Section 2.4: Hello Triangle Exercise 2

  This example demonstrates:
  - Creating two triangles using a single VAO and VBO
  - Using an Element Buffer Object (EBO) to avoid vertex duplication
  - Drawing with glDrawElements instead of glDrawArrays
  - Efficient vertex data sharing between triangles

  The two triangles share vertices to form a rectangle:
  ```
  3 ---- 2
  |    / |
  |   /  |
  |  /   |
  | /    |
  0 ---- 1
  ```

  Run with: mix run -e "EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise2.run_example()"
  Or use the script: ./priv/scripts/triangle2
  """

  use EAGL.Window
  use EAGL.Const
  import EAGL.Shader

  # Rectangle vertex data (4 vertices shared between 2 triangles)
  @vertices [
    0.5,  0.5, 0.0,   # top right    (index 0)
    0.5, -0.5, 0.0,   # bottom right (index 1)
   -0.5, -0.5, 0.0,   # bottom left  (index 2)
   -0.5,  0.5, 0.0    # top left     (index 3)
  ]

  # Indices for two triangles forming a rectangle
  # First triangle: 0, 1, 3 (top-right, bottom-right, top-left)
  # Second triangle: 1, 2, 3 (bottom-right, bottom-left, top-left)
  @indices [
    0, 1, 3,  # first triangle
    1, 2, 3   # second triangle
  ]

  @spec run_example() :: :ok | {:error, term()}
  def run_example, do: EAGL.Window.run(__MODULE__, "LearnOpenGL - 1 Getting Started - 2.4 Hello Triangle Exercise 2")

  @impl true
  def setup do
    IO.puts("Starting LearnOpenGL Hello Triangle Exercise 2...")

    # Compile and link shaders
    with {:ok, vertex_shader} <- create_shader(@gl_vertex_shader, "learnopengl/1_getting_started/2_4_hello_triangle_exercise_2/vertex_shader.glsl"),
         {:ok, fragment_shader} <- create_shader(@gl_fragment_shader, "learnopengl/1_getting_started/2_4_hello_triangle_exercise_2/fragment_shader.glsl"),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do

      IO.puts("✓ Created shader program")

      # Create VAO, VBO, and EBO
      {vao, vbo, ebo} = create_rectangle_data()

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

    # Draw the rectangle (two triangles)
    :gl.useProgram(program)
    :gl.bindVertexArray(vao)

    # Draw using indices - this is the key difference from Exercise 3
    # We draw 6 indices (2 triangles * 3 vertices each) but only need 4 actual vertices
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
    # Cleanup geometry data
    :gl.deleteVertexArrays([vao])
    :gl.deleteBuffers([vbo])
    :gl.deleteBuffers([ebo])

    # Cleanup shader program
    cleanup_program(program)
    :ok
  end

  defp create_rectangle_data do
    # Generate VAO, VBO, and EBO
    [vao] = :gl.genVertexArrays(1)
    [vbo] = :gl.genBuffers(1)
    [ebo] = :gl.genBuffers(1)

    # Bind VAO first
    :gl.bindVertexArray(vao)

    # Bind and fill VBO with vertex data
    :gl.bindBuffer(@gl_array_buffer, vbo)
    vertex_data = for v <- @vertices, into: <<>>, do: <<v::float-32-native>>
    :gl.bufferData(@gl_array_buffer, byte_size(vertex_data), vertex_data, @gl_static_draw)

    # Bind and fill EBO with index data
    :gl.bindBuffer(@gl_element_array_buffer, ebo)
    index_data = for i <- @indices, into: <<>>, do: <<i::unsigned-32-native>>
    :gl.bufferData(@gl_element_array_buffer, byte_size(index_data), index_data, @gl_static_draw)

    # Configure vertex attribute (position at location 0)
    :gl.vertexAttribPointer(0, 3, @gl_float, @gl_false, 3 * 4, 0)  # 4 bytes per float
    :gl.enableVertexAttribArray(0)

    # Unbind (good practice)
    :gl.bindBuffer(@gl_array_buffer, 0)
    # Note: Don't unbind EBO while VAO is active - VAO stores the EBO binding
    :gl.bindVertexArray(0)

    {vao, vbo, ebo}
  end
end
