defmodule EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise3 do
  @moduledoc """
  LearnOpenGL 2.5 - Hello Triangle Exercise 3 (Multiple Shader Programs)

  This example demonstrates using multiple shader programs to render different colored triangles.
  It solves the third exercise from the Hello Triangle tutorial.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/src/1.getting_started/2.5.hello_triangle_exercise3>

  ## Framework Adaptation Notes

  In the original LearnOpenGL C++ tutorial, this exercise asks you to create two triangles
  that render with different colors by using different fragment shaders.

  EAGL's framework maintains the same approach:
  - Two separate VAO/VBO pairs for independent geometry
  - Shared vertex shader between both programs
  - Different fragment shaders for different colors
  - Multiple draw calls with different shader programs

  ## Original Tutorial Exercise

  **Exercise 3**: Create two shader programs where the second program uses a different
  fragment shader that outputs the color yellow; draw both triangles again where one
  outputs the color orange and the other outputs the color yellow.

  ## Solution Concepts Demonstrated

  1. **Multiple Shader Programs**: Creating and managing separate programs
  2. **Shader Reuse**: Same vertex shader used in both programs
  3. **Fragment Shader Variants**: Different colors from different shaders
  4. **Separate Geometry**: Independent VAO/VBO pairs
  5. **Multi-Pass Rendering**: Multiple draw calls with different programs

  ## Key Learning Points

  - How to create and manage multiple shader programs
  - Sharing shaders between different programs
  - The relationship between shader programs and rendering state
  - When to use separate geometry vs shared geometry
  - Understanding the cost of shader program switches

  ## Triangle Geometry and Colors

  Two separate triangles with different colors:
  ```
  Left Triangle (Orange)    Right Triangle (Yellow)
        /\\                       /\\
       /  \\                     /  \\
      /____\\                   /____\\
  ```

  - Left triangle: Orange fragment shader
  - Right triangle: Yellow fragment shader
  - Same vertex shader for both triangles

  ## Difference from Previous Examples

  - **2.3 Exercise 1**: 2 triangles, 1 shader program, same color
  - **2.4 Exercise 2**: 2 triangles (rectangle), 1 shader program, same color
  - **2.5 Exercise 3**: 2 triangles, 2 shader programs, different colors

  ## Usage

      EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise3.run_example()

  Press ENTER to exit the example.
  """

  use EAGL.Window
  use EAGL.Const

  import EAGL.Shader
  import EAGL.Buffer

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
  def run_example,
    do:
      EAGL.Window.run(
        __MODULE__,
        "LearnOpenGL - 1 Getting Started - 2.5 Hello Triangle Exercise 3",
        return_to_exit: true
      )

  @impl true
  def setup do
    IO.puts("""
    === LearnOpenGL 2.5 - Hello Triangle Exercise 3 ===
    This example demonstrates multiple shader programs with different colors!

    Exercise Goal:
    - Create two shader programs with different fragment shaders
    - One triangle outputs orange, the other outputs yellow
    - Use the same vertex shader for both programs

    Key Concepts:
    - Multiple shader programs in one application
    - Shader reuse: same vertex shader, different fragment shaders
    - Separate VAO/VBO pairs for independent geometry
    - Multi-pass rendering with program switches

    Rendering approach:
    - Draw call 1: Orange program + Left triangle
    - Draw call 2: Yellow program + Right triangle

    Press ENTER to exit.
    """)

    # Compile and link shaders - using a single with statement for educational clarity
    with {:ok, vertex_shader} <-
           create_shader(
             @gl_vertex_shader,
             "learnopengl/1_getting_started/2_5_hello_triangle_exercise_3/vertex_shader.glsl"
           ),
         {:ok, orange_fragment} <-
           create_shader(
             @gl_fragment_shader,
             "learnopengl/1_getting_started/2_5_hello_triangle_exercise_3/orange_fragment_shader.glsl"
           ),
         {:ok, yellow_fragment} <-
           create_shader(
             @gl_fragment_shader,
             "learnopengl/1_getting_started/2_5_hello_triangle_exercise_3/yellow_fragment_shader.glsl"
           ),
         {:ok, orange_program} <- create_attach_link([vertex_shader, orange_fragment]),
         {:ok, yellow_program} <- create_attach_link([vertex_shader, yellow_fragment]) do
      IO.puts("✓ Compiled vertex shader (shared between both programs)")
      IO.puts("✓ Compiled orange and yellow fragment shaders")
      IO.puts("✓ Created two shader programs successfully")

      # Create VAOs and VBOs using EAGL.Buffer helpers
      {first_vao, first_vbo} = create_position_array(@first_triangle)
      {second_vao, second_vbo} = create_position_array(@second_triangle)

      IO.puts("✓ Created separate VAO/VBO pairs for each triangle")
      IO.puts("✓ Ready to render! You should see an orange and yellow triangle.")

      # State: {orange_program, yellow_program, first_vao, first_vbo, second_vao, second_vbo}
      {:ok, {orange_program, yellow_program, first_vao, first_vbo, second_vao, second_vbo}}
    else
      {:error, reason} ->
        IO.puts("✗ Failed to create shader programs: #{reason}")
        {:error, reason}
    end
  end

  @impl true
  def render(
        viewport_width,
        viewport_height,
        {orange_program, yellow_program, first_vao, _first_vbo, second_vao, _second_vbo}
      ) do
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
  def cleanup({orange_program, yellow_program, first_vao, first_vbo, second_vao, second_vbo}) do
    # Cleanup geometry data
    delete_vertex_array(first_vao, first_vbo)
    delete_vertex_array(second_vao, second_vbo)

    # Cleanup shader programs
    cleanup_program(orange_program)
    cleanup_program(yellow_program)
    :ok
  end
end
