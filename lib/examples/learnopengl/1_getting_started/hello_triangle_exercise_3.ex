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

    # Compile and link shaders
    with {:ok, orange_program} <- create_shader_program("orange"),
         {:ok, yellow_program} <- create_shader_program("yellow") do

      # Create VAOs and VBOs for both triangles
      {vao1, vbo1} = create_triangle_data(@first_triangle)
      {vao2, vbo2} = create_triangle_data(@second_triangle)

      # State: {orange_program, yellow_program, vao1, vao2, vbo1, vbo2}
      {:ok, {orange_program, yellow_program, vao1, vao2, vbo1, vbo2}}
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
    # Cleanup triangle data
    :gl.deleteVertexArrays([vao1])
    :gl.deleteBuffers([vbo1])
    :gl.deleteVertexArrays([vao2])
    :gl.deleteBuffers([vbo2])

    # Cleanup shader programs
    :gl.deleteProgram(orange_program)
    :gl.deleteProgram(yellow_program)
    :ok
  end

  defp create_shader_program(color) do
    vertex_filename = "learnopengl/1_getting_started/hello_triangle_exercise_3/vertex_shader.glsl"
    fragment_filename = case color do
      "orange" -> "learnopengl/1_getting_started/hello_triangle_exercise_3/fragment_shader_orange.glsl"
      "yellow" -> "learnopengl/1_getting_started/hello_triangle_exercise_3/fragment_shader_yellow.glsl"
    end

    with {:ok, vertex_shader} <- create_shader(@gl_vertex_shader, vertex_filename),
         {:ok, fragment_shader} <- create_shader(@gl_fragment_shader, fragment_filename),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do
      IO.puts("✓ Created #{color} shader program")
      {:ok, program}
    else
      {:error, reason} ->
        IO.puts("✗ Failed to create #{color} shader program: #{reason}")
        {:error, reason}
    end
  end

  defp create_triangle_data(vertices) do
    # Generate VAO and VBO
    [vao] = :gl.genVertexArrays(1)
    [vbo] = :gl.genBuffers(1)

    # Bind VAO
    :gl.bindVertexArray(vao)

    # Bind and fill VBO
    :gl.bindBuffer(@gl_array_buffer, vbo)
    vertex_data = for v <- vertices, into: <<>>, do: <<v::float-32-native>>
    :gl.bufferData(@gl_array_buffer, byte_size(vertex_data), vertex_data, @gl_static_draw)

    # Configure vertex attribute (position at location 0)
    :gl.vertexAttribPointer(0, 3, @gl_float, @gl_false, 3 * 4, 0)  # 4 bytes per float
    :gl.enableVertexAttribArray(0)

    # Unbind (optional but good practice)
    :gl.bindBuffer(@gl_array_buffer, 0)
    :gl.bindVertexArray(0)

    {vao, vbo}
  end
end
