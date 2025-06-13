defmodule EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise3 do
  @moduledoc """
  Port of LearnOpenGL's Hello Triangle Exercise 3 to EAGL framework.

  Original: https://learnopengl.com/Getting-started/Hello-Triangle (Exercise 3)
  Chapter 1, Section 2.5: Hello Triangle Exercise 3

  This example demonstrates:
  - Creating two triangles using separate VAOs and VBOs
  - Using the same vertex shader for both triangles
  - Using different fragment shaders (orange and yellow)
  - Rendering with different shader programs

  Run with: mix run -e "EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise3.run_example()"
  Or use the script: ./priv/scripts/triangle
  """

  use EAGL.Window
  use EAGL.Const
  import EAGL.Shader

  # First triangle (left side)
  @first_triangle [
    -0.9, -0.5, 0.0,  # left
    -0.0, -0.5, 0.0,  # right
    -0.45, 0.5, 0.0   # top
  ]

  # Second triangle (right side)
  @second_triangle [
    0.0, -0.5, 0.0,   # left
    0.9, -0.5, 0.0,   # right
    0.45, 0.5, 0.0    # top
  ]

  @spec run_example() :: :ok | {:error, term()}
  def run_example, do: EAGL.Window.run(__MODULE__, "LearnOpenGL - 1 Getting Started - 2.5 Hello Triangle Exercise 3")

  @impl true
  def setup do
    IO.puts("Starting LearnOpenGL Hello Triangle Exercise 3...")

    # Compile and link shaders - using a single with statement for educational clarity
    with {:ok, vertex_shader} <- create_shader(@gl_vertex_shader, "learnopengl/1_getting_started/2_5_hello_triangle_exercise_3/vertex_shader.glsl"),
         {:ok, orange_fragment} <- create_shader(@gl_fragment_shader, "learnopengl/1_getting_started/2_5_hello_triangle_exercise_3/orange_fragment_shader.glsl"),
         {:ok, yellow_fragment} <- create_shader(@gl_fragment_shader, "learnopengl/1_getting_started/2_5_hello_triangle_exercise_3/yellow_fragment_shader.glsl"),
         {:ok, orange_program} <- create_attach_link([vertex_shader, orange_fragment]),
         {:ok, yellow_program} <- create_attach_link([vertex_shader, yellow_fragment]) do

      IO.puts("✓ Created shader programs")

      # Create VAOs and VBOs using EAGL.Buffer helpers
      {first_vao, first_vbo} = EAGL.Buffer.create_position_array(@first_triangle)
      {second_vao, second_vbo} = EAGL.Buffer.create_position_array(@second_triangle)

      # State: {orange_program, yellow_program, first_vao, first_vbo, second_vao, second_vbo}
      {:ok, {orange_program, yellow_program, first_vao, first_vbo, second_vao, second_vbo}}
    else
      {:error, reason} ->
        IO.puts("✗ Failed to create shader programs: #{reason}")
        {:error, reason}
    end
  end

  @impl true
  def render(viewport_width, viewport_height, {orange_program, yellow_program, first_vao, _first_vbo, second_vao, _second_vbo}) do
    # Set viewport
    :gl.viewport(0, 0, trunc(viewport_width), trunc(viewport_height))

    # Set clear color (dark gray-blue) and clear screen
    :gl.clearColor(0.2, 0.3, 0.3, 1.0)
    :gl.clear(@gl_color_buffer_bit)

    # Draw first triangle (orange)
    :gl.useProgram(orange_program)
    :gl.bindVertexArray(first_vao)
    :gl.drawArrays(@gl_triangles, 0, 3)

    # Draw second triangle (yellow)
    :gl.useProgram(yellow_program)
    :gl.bindVertexArray(second_vao)
    :gl.drawArrays(@gl_triangles, 0, 3)

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
  def cleanup({orange_program, yellow_program, first_vao, first_vbo, second_vao, second_vbo}) do
    # Cleanup geometry data
    EAGL.Buffer.delete_vertex_array(first_vao, first_vbo)
    EAGL.Buffer.delete_vertex_array(second_vao, second_vbo)

    # Cleanup shader programs
    cleanup_program(orange_program)
    cleanup_program(yellow_program)
    :ok
  end
end
