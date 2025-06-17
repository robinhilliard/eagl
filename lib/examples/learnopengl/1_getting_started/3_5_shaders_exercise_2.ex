defmodule EAGL.Examples.LearnOpenGL.GettingStarted.ShadersExercise2 do
  @moduledoc """
  LearnOpenGL 3.5 - Shaders Exercise 2

  This example demonstrates using a uniform variable to apply a horizontal offset
  to the triangle position. It combines uniform variables with vertex transformations
  to show how application data can control shader behavior.
  It corresponds to the second shader exercise in the LearnOpenGL series.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/src/1.getting_started/3.5.shaders_exercise2>

  ## Exercise Description

  **Original Exercise:** "Specify a horizontal offset via a uniform and move the triangle
  to the right side of the screen in the vertex shader using this offset value"

  **Solution Approach:** Add uniform to vertex shader and apply to x-coordinate:
  - Add: `uniform float xOffset;` to vertex shader
  - Modify: `gl_Position = vec4(aPos.x + xOffset, aPos.y, aPos.z, 1.0);`
  - Set uniform from application: `set_uniform(program, "xOffset", 0.5)`

  ## Framework Adaptation Notes

  In the original LearnOpenGL C++ tutorial, this exercise teaches:
  - How to combine uniforms with vertex transformations
  - Passing application data to control shader behavior
  - Understanding the difference between vertex attributes and uniforms
  - How uniforms affect all vertices in a draw call uniformly

  EAGL's framework preserves all these concepts:
  - EAGL.Shader.set_uniform/3 handles the uniform setting with type detection
  - Same vertex data, transformation applied via uniform in shader
  - Demonstrates application-controlled geometry manipulation

  ## Key Concept: Uniform-Controlled Transformations

  **Why use uniforms for transformations:**
  - Can change transformation without recompiling shaders
  - Same transformation applied to all vertices in draw call
  - Efficient way to animate or control geometry
  - Foundation for more complex transformations (matrices)

  **Uniform vs. Vertex Attribute:**
  - Uniform: Same value for all vertices (global to draw call)
  - Vertex Attribute: Different value per vertex (per-vertex data)
  - Uniforms perfect for transformations, lighting parameters, time, etc.

  ## Visual Result

  Triangle with interpolated colors moved to the right side of screen:
      - Same colour interpolation as 3.2/3.3
  - Horizontally offset by uniform value (0.5 units to the right)
  - Demonstrates uniform-controlled positioning

  ## Learning Objectives

  - Understanding uniform variables in vertex shaders
  - Combining uniforms with vertex transformations
  - Application-controlled shader behavior
  - Difference between uniforms and vertex attributes

  ## Usage

      EAGL.Examples.LearnOpenGL.GettingStarted.ShadersExercise2.run_example()

  Press ENTER to exit the example.
  """

  use EAGL.Window
  use EAGL.Const

  import EAGL.Shader
  import EAGL.Buffer
  import EAGL.Math

  # Same triangle vertex data as previous examples - offset applied via uniform
  # Format: [x, y, z, r, g, b] per vertex
  @vertices ~v'''
  # positions        # colors
   0.5 -0.5 0.0  1.0 0.0 0.0   # bottom right - red
  -0.5 -0.5 0.0  0.0 1.0 0.0   # bottom left - green
   0.0  0.5 0.0  0.0 0.0 1.0   # top center - blue
  '''

  # Horizontal offset to move triangle to the right
  @x_offset 0.5

  @spec run_example() :: :ok | {:error, term()}
  def run_example(opts \\ []) do
    default_opts = [return_to_exit: true]
    merged_opts = Keyword.merge(default_opts, opts)

    EAGL.Window.run(
      __MODULE__,
      "LearnOpenGL - 1 Getting Started - 3.5 Shaders Exercise 2",
      merged_opts
    )
  end

  @impl true
  def setup do
    IO.puts("""
    === LearnOpenGL 3.5 - Shaders Exercise 2 ===
    This example demonstrates uniform-controlled transformations

    Exercise: "Specify a horizontal offset via a uniform and move the triangle
    to the right side of the screen in the vertex shader using this offset value"

    Solution Approach:
    - Add uniform float xOffset to vertex shader
    - Apply offset in vertex shader: gl_Position = vec4(aPos.x + xOffset, aPos.y, aPos.z, 1.0)
    - Set uniform from application: set_uniform(program, "xOffset", #{@x_offset})

    Key Learning Points:
    - Uniforms provide application control over shader behavior
    - Same uniform value applied to all vertices in draw call
    - More flexible than hardcoded transformations
    - Foundation for animation and dynamic geometry

    Uniform vs. Vertex Attribute:
    - Uniform: Same value for all vertices (global to draw call)
    - Vertex Attribute: Different value per vertex (per-vertex data)
    - Uniforms perfect for transformations, lighting, time, etc.

    EAGL Framework:
    - set_uniform/3 handles type detection and OpenGL calls
    - Clean API for setting uniform values
    - Same vertex data, transformation via uniform

    Visual Result:
    - Same colour interpolation as previous examples
    - Triangle moved #{@x_offset} units to the right
    - Demonstrates uniform-controlled positioning

    Press ENTER to exit.
    """)

    # Compile and link shaders - vertex shader uses uniform for offset
    with {:ok, vertex_shader} <-
           create_shader(
             @gl_vertex_shader,
             "learnopengl/1_getting_started/3_5_shaders_exercise_2/vertex_shader.glsl"
           ),
         {:ok, fragment_shader} <-
           create_shader(
             @gl_fragment_shader,
             "learnopengl/1_getting_started/3_5_shaders_exercise_2/fragment_shader.glsl"
           ),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do
      IO.puts("Shaders compiled successfully with uniform offset")

      # Create buffer objects with position and colour attributes
      # Each vertex has 6 floats: 3 for position, 3 for color
      attributes = vertex_attributes(:position, :color)

      {vao, vbo} = create_vertex_array(@vertices, attributes)

      IO.puts("Same vertex data - offset applied via uniform in shader")
      IO.puts("Ready to render - Triangle should be moved to the right.")

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

    # Use the shader program
    :gl.useProgram(program)

    # Set the horizontal offset uniform
    # This demonstrates application control over shader behavior
    set_uniform(program, "xOffset", @x_offset)

    # Draw the offset triangle
    :gl.bindVertexArray(vao)
    :gl.drawArrays(@gl_triangles, 0, 3)

    :ok
  end

  @impl true
  def cleanup({program, vao, vbo}) do
    delete_vertex_array(vao, vbo)
    :gl.deleteProgram(program)
    :ok
  end
end
