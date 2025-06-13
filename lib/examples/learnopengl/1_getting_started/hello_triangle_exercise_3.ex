defmodule EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise3 do
  @moduledoc """
  Port of LearnOpenGL's Hello Triangle Exercise 3 to EAGL framework.

  Original: https://learnopengl.com/code_viewer_gh.php?code=src/1.getting_started/2.5.hello_triangle_exercise3/hello_triangle_exercise3.cpp

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
  import EAGL.Buffer

  # Triangle vertex data
  @first_triangle [
    -0.9, -0.5, 0.0,  # left
    -0.0, -0.5, 0.0,  # right
    -0.45, 0.5, 0.0   # top
  ]

  @second_triangle [
    0.0, -0.5, 0.0,   # left
    0.9, -0.5, 0.0,   # right
    0.45, 0.5, 0.0    # top
  ]

  @spec run_example() :: :ok | {:error, term()}
  def run_example, do: EAGL.Window.run(__MODULE__, "LearnOpenGL - Hello Triangle Exercise 3")

  @impl true
  def setup do
    IO.puts("Starting LearnOpenGL Hello Triangle Exercise 3...")

    # Compile and link shaders for both programs
    with {:ok, vertex_shader} <- create_shader(@gl_vertex_shader, "learnopengl/1_getting_started/hello_triangle_exercise_3/vertex_shader.glsl"),
         {:ok, orange_fragment} <- create_shader(@gl_fragment_shader, "learnopengl/1_getting_started/hello_triangle_exercise_3/fragment_shader_orange.glsl"),
         {:ok, yellow_fragment} <- create_shader(@gl_fragment_shader, "learnopengl/1_getting_started/hello_triangle_exercise_3/fragment_shader_yellow.glsl"),
         {:ok, orange_program} <- create_attach_link([vertex_shader, orange_fragment]),
         {:ok, yellow_program} <- create_attach_link([vertex_shader, yellow_fragment]) do

      IO.puts("✓ Created orange shader program")
      IO.puts("✓ Created yellow shader program")

      # Create VAOs and VBOs for both triangles using EAGL.Buffer helpers
      {vao1, vbo1} = create_position_array(@first_triangle)
      {vao2, vbo2} = create_position_array(@second_triangle)

      # State: {orange_program, yellow_program, vao1, vao2, vbo1, vbo2}
      {:ok, {orange_program, yellow_program, vao1, vao2, vbo1, vbo2}}
    else
      {:error, reason} ->
        IO.puts("✗ Failed to create shader programs: #{reason}")
        {:error, reason}
    end
  end

  @impl true
  def render(viewport_width, viewport_height, {orange_program, yellow_program, vao1, vao2, _vbo1, _vbo2}) do
    # Set viewport
    :gl.viewport(0, 0, trunc(viewport_width), trunc(viewport_height))

    # Set clear color (dark gray-blue) and clear screen
    :gl.clearColor(0.2, 0.3, 0.3, 1.0)
    :gl.clear(@gl_color_buffer_bit)

    # Draw first triangle (orange)
    :gl.useProgram(orange_program)
    :gl.bindVertexArray(vao1)
    :gl.drawArrays(@gl_triangles, 0, 3)

    # Draw second triangle (yellow)
    :gl.useProgram(yellow_program)
    :gl.bindVertexArray(vao2)
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
  def cleanup({orange_program, yellow_program, vao1, vao2, vbo1, vbo2}) do
    # Cleanup triangle data using EAGL.Buffer helpers
    delete_vertex_array(vao1, vbo1)
    delete_vertex_array(vao2, vbo2)

    # Cleanup shader programs
    cleanup_program(orange_program)
    cleanup_program(yellow_program)
    :ok
  end
end
