defmodule EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangle do
  @moduledoc """
  LearnOpenGL 2.1 - Hello Triangle

  This example demonstrates your first triangle in OpenGL - the foundation of all 3D graphics.
  It corresponds to the Hello Triangle tutorial in the LearnOpenGL series.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/src/1.getting_started/2.1.hello_triangle>

  ## Framework Adaptation Notes

  In the original LearnOpenGL C++ tutorial, this example introduces the core OpenGL rendering pipeline:
  vertex data → vertex shader → primitive assembly → fragment shader → framebuffer.

  EAGL's framework simplifies the setup while preserving all educational concepts:
  - Shader compilation and linking are handled by EAGL.Shader helpers
  - VAO/VBO creation uses EAGL.Buffer convenience functions
  - Error checking and resource cleanup are automated
  - The core OpenGL concepts remain unchanged and visible

  ## Original Tutorial Concepts Demonstrated

  1. **Vertex Data**: Defining triangle vertices in normalized device coordinates (-1 to 1)
  2. **Vertex Buffer Objects (VBO)**: Storing vertex data in GPU memory
  3. **Vertex Array Objects (VAO)**: Configuring how vertex data is interpreted
  4. **Vertex Shaders**: Processing each vertex (position transformation)
  5. **Fragment Shaders**: Determining pixel colors
  6. **Rendering Pipeline**: glDrawArrays() triggers the complete pipeline

  ## Key Learning Points

  - Understanding normalized device coordinates (NDC)
  - The relationship between VBOs and VAOs
  - How shaders process vertices and fragments
  - The OpenGL rendering pipeline flow
  - Basic primitive rendering with glDrawArrays

  ## Triangle Geometry

  The triangle is defined by 3 vertices in normalized device coordinates:
  ```
      (0.0, 0.5)
         /\\
        /  \\
       /    \\
      /______\\
  (-0.5,-0.5) (0.5,-0.5)
  ```

  ## Difference from Previous Examples

  - **1.1 Hello Window**: Just a black window (no geometry)
  - **1.2 Hello Window Clear**: Custom clear color (no geometry)
  - **2.1 Hello Triangle**: First actual geometry rendering with shaders

  ## Usage

      EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangle.run_example()

  Press ENTER to exit the example.
  """

  use EAGL.Window
  use EAGL.Const

  import EAGL.Shader
  import EAGL.Buffer
  import EAGL.Math

  # Triangle vertex data (3 vertices in normalized device coordinates)
  @vertices ~v'''
  -0.5 -0.5 0.0  # left vertex
   0.5 -0.5 0.0  # right vertex
   0.0  0.5 0.0  # top vertex
  '''

  @spec run_example() :: :ok | {:error, term()}
  def run_example,
    do:
      EAGL.Window.run(
        __MODULE__,
        "LearnOpenGL - 1 Getting Started - 2.1 Hello Triangle",
        return_to_exit: true
      )

  @impl true
  def setup do
    IO.puts("""
    === LearnOpenGL 2.1 - Hello Triangle ===
    This example demonstrates your first triangle in OpenGL

    Key Concepts:
    - Vertex Buffer Objects (VBO) store vertex data in GPU memory
    - Vertex Array Objects (VAO) configure vertex attribute layout
    - Vertex shaders process each vertex
    - Fragment shaders determine pixel colors
    - glDrawArrays() renders primitives from vertex data

    Triangle vertices in Normalized Device Coordinates:
      Top:    ( 0.0,  0.5, 0.0)
      Left:   (-0.5, -0.5, 0.0)
      Right:  ( 0.5, -0.5, 0.0)

    Press ENTER to exit.
    """)

    # Compile and link shaders
    with {:ok, vertex_shader} <-
           create_shader(
             @gl_vertex_shader,
             "learnopengl/1_getting_started/2_1_hello_triangle/vertex_shader.glsl"
           ),
         {:ok, fragment_shader} <-
           create_shader(
             @gl_fragment_shader,
             "learnopengl/1_getting_started/2_1_hello_triangle/fragment_shader.glsl"
           ),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do
      IO.puts("Vertex and fragment shaders compiled and linked successfully")

      # Create VAO and VBO for triangle geometry
      # This is the fundamental OpenGL pattern: VAO + VBO + vertex attributes
      {vao, vbo} = create_position_array(@vertices)

      IO.puts("Created VAO and VBO (3 vertices uploaded to GPU)")
      IO.puts("Ready to render - you should see an orange triangle.")

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

    # Draw the triangle
    :gl.useProgram(program)
    :gl.bindVertexArray(vao)

    # Draw the triangle using glDrawArrays
    # 3 vertices starting from index 0, forming GL_TRIANGLES
    :gl.drawArrays(@gl_triangles, 0, 3)

    :ok
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
