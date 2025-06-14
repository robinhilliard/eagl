defmodule EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangle do
  @moduledoc """
  Port of LearnOpenGL's Hello Triangle to EAGL framework.

  Original: https://learnopengl.com/Getting-started/Hello-Triangle (Section 2.1)
  Chapter 1, Section 2.1: Hello Triangle

  This example demonstrates:
  - Creating your first triangle in OpenGL
  - Basic vertex buffer objects (VBO) and vertex array objects (VAO)
  - Simple vertex and fragment shaders
  - The OpenGL rendering pipeline fundamentals
  - Drawing with glDrawArrays

  The triangle is defined by 3 vertices in normalized device coordinates:
  ```
      (0.0, 0.5)
         /\
        /  \
       /    \
      /______\
  (-0.5,-0.5) (0.5,-0.5)
  ```

  Key concepts:
  - Vertex Buffer Object (VBO) stores vertex data
  - Vertex Array Object (VAO) stores vertex attribute configuration
  - Vertex shader processes each vertex
  - Fragment shader determines pixel colors
  - glDrawArrays() renders primitives from vertex data

  Run with: mix run -e "EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangle.run_example()"
  """

  use EAGL.Window
  use EAGL.Const
  import EAGL.Shader
  import EAGL.Buffer

  # Triangle vertex data (3 vertices in normalized device coordinates)
  @vertices [
    -0.5, -0.5, 0.0,  # left vertex
     0.5, -0.5, 0.0,  # right vertex
     0.0,  0.5, 0.0   # top vertex
  ]

  @spec run_example() :: :ok | {:error, term()}
  def run_example, do: EAGL.Window.run(__MODULE__, "LearnOpenGL - 1 Getting Started - 2.1 Hello Triangle")

  @impl true
  def setup do
    IO.puts("Starting LearnOpenGL Hello Triangle...")

    # Compile and link shaders
    with {:ok, vertex_shader} <- create_shader(@gl_vertex_shader, "learnopengl/1_getting_started/2_1_hello_triangle/vertex_shader.glsl"),
         {:ok, fragment_shader} <- create_shader(@gl_fragment_shader, "learnopengl/1_getting_started/2_1_hello_triangle/fragment_shader.glsl"),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do

      IO.puts("✓ Created shader program")

      # Create VAO and VBO for triangle geometry
      # This is the fundamental OpenGL pattern: VAO + VBO + vertex attributes
      {vao, vbo} = create_position_array(@vertices)

      IO.puts("✓ Created vertex array (3 vertices)")

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

    # Draw the triangle
    :gl.useProgram(program)
    :gl.bindVertexArray(vao)

    # Draw the triangle using glDrawArrays
    # 3 vertices starting from index 0, forming GL_TRIANGLES
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
  def cleanup({program, vao, vbo}) do
    # Cleanup vertex array data
    delete_vertex_array(vao, vbo)

    # Cleanup shader program
    cleanup_program(program)
    :ok
  end
end
