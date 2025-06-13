defmodule EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise1 do
  @moduledoc """
  Port of LearnOpenGL's Hello Triangle Exercise 1 to EAGL framework.

  Original: https://learnopengl.com/Getting-started/Hello-Triangle (Exercise 1)
  Chapter 1, Section 2.3: Hello Triangle Exercise 1

  Exercise: Try to draw 2 triangles next to each other using glDrawArrays
  by adding more vertices to your data.

  This example demonstrates:
  - Drawing multiple triangles with a single VAO/VBO
  - Using glDrawArrays with 6 vertices (2 triangles)
  - Positioning triangles side by side in normalized device coordinates

  Key concepts:
  - Two separate triangles defined by 6 vertices total
  - Single draw call renders both triangles
  - Left triangle: vertices 0-2, Right triangle: vertices 3-5

  Run with: mix run -e "EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise1.run_example()"
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
  def run_example, do: EAGL.Window.run(__MODULE__, "LearnOpenGL - 1 Getting Started - 2.3 Hello Triangle Exercise 1")

  @impl true
  def setup do
    IO.puts("Starting LearnOpenGL Hello Triangle Exercise 1...")

    # Compile and link shaders
    with {:ok, vertex_shader} <- create_shader(@gl_vertex_shader, "learnopengl/1_getting_started/2_3_hello_triangle_exercise_1/vertex_shader.glsl"),
         {:ok, fragment_shader} <- create_shader(@gl_fragment_shader, "learnopengl/1_getting_started/2_3_hello_triangle_exercise_1/fragment_shader.glsl"),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do

      IO.puts("✓ Created shader program")

      # Create VAO and VBO for two triangles
      {vao, vbo} = create_position_array(@vertices)

      # State: {program, vao, vbo}
      {:ok, {program, vao, vbo}}
    else
      {:error, reason} ->
        IO.puts("✗ Failed to create shader program: #{reason}")
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
  def handle_event({:key, key_code}, state) do
    if key_code == 27 do  # ESC key
      throw(:close_window)
    end
    {:ok, state}
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
