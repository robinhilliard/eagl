defmodule EAGL.Examples.LearnOpenGL.GettingStarted.ShadersUniform do
  @moduledoc """
  LearnOpenGL 3.1 - Shaders Uniform

  This example demonstrates uniform variables in shaders - global variables that remain constant
  across all vertices in a draw call but can be updated between draw calls.
  It corresponds to the Shaders Uniform tutorial in the LearnOpenGL series.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/src/1.getting_started/3.1.shaders_uniform>

  ## Framework Adaptation Notes

  In the original LearnOpenGL C++ tutorial, this example introduces uniform variables:
  - How to declare uniforms in GLSL
  - How to get uniform locations from the application
  - How to update uniform values using glUniform* functions
  - Creating animated effects by updating uniforms per frame

  EAGL's framework preserves all these concepts while providing convenience functions:
  - EAGL.Shader.set_uniform() handles the glGetUniformLocation + glUniform* pattern
  - Error checking and type detection are automated
  - The core OpenGL uniform concepts remain unchanged and visible

  ## Key Difference: Animation Timing

  **Original LearnOpenGL approach:** Time calculation happens directly in the render loop:
  ```c++
  while (!glfwWindowShouldClose(window)) {
      float timeValue = glfwGetTime();  // Get time in render loop
      float greenValue = sin(timeValue) / 2.0f + 0.5f;
      glUniform4f(vertexColorLocation, 0.0f, greenValue, 0.0f, 1.0f);
      // ... render
  }
  ```

  **EAGL approach:** Uses the tick handler pattern for clean separation of concerns:
  - `handle_event(:tick, state)` updates time state each frame
  - `render/3` uses the current time state for animation
  - This separates state management from rendering logic

  ## Original Tutorial Concepts Demonstrated

  1. **Uniform Declaration**: Declaring `uniform vec4 ourColor` in the fragment shader
  2. **Uniform Location**: Getting the uniform location using `glGetUniformLocation`
  3. **Uniform Updates**: Using `glUniform4f` to update the uniform value
  4. **Animation**: Updating the uniform each frame using `sin(time)` for color cycling
  5. **Shader Communication**: Passing data from application to shader via uniforms

  ## Key Learning Points

  - Understanding the difference between attributes and uniforms
  - Uniforms are global variables that stay constant per draw call
  - Uniforms can be updated between draw calls to create dynamic effects
  - Time-based animation using mathematical functions
  - The OpenGL uniform system and how it bridges CPU and GPU

  ## Color Animation

  The triangle color cycles through a green color animation:
  - Color varies from dark green (0.0) to bright green (1.0)
  - Uses `sin(time)` to create smooth oscillation
  - Red and blue components remain at 0.0
  - Alpha remains at 1.0 (fully opaque)

  ## Difference from Previous Examples

  - **2.1 Hello Triangle**: Static orange triangle with hardcoded fragment color
  - **3.1 Shaders Uniform**: Dynamic color animation using uniform variables

  ## Usage

      EAGL.Examples.LearnOpenGL.GettingStarted.ShadersUniform.run_example()

  Press ENTER to exit the example.
  """

  use EAGL.Window
  use EAGL.Const

  import EAGL.Shader
  import EAGL.Buffer
  import EAGL.Math

  # Triangle vertex data (3 vertices in normalized device coordinates)
  @vertices ~v'''
  -0.5 -0.5 0.0   # left vertex
   0.5 -0.5 0.0   # right vertex
   0.0  0.5 0.0   # top vertex
  '''

  @spec run_example() :: :ok | {:error, term()}
  def run_example(opts \\ []) do
    default_opts = [enter_to_exit: true]
    merged_opts = Keyword.merge(default_opts, opts)

    EAGL.Window.run(
      __MODULE__,
      "LearnOpenGL - 1 Getting Started - 3.1 Shaders Uniform",
      merged_opts
    )
  end

  @impl true
  def setup do
    IO.puts("""
    === LearnOpenGL 3.1 - Shaders Uniform ===
    This example demonstrates uniform variables in shaders

    Key Concepts:
    - Uniform variables are global to the shader program
    - Uniforms remain constant across all vertices in a draw call
    - Uniforms can be updated between draw calls from the application
    - Perfect for passing time, transformations, colors, etc.
    - Mathematical functions like sin() create smooth animations

    Animation:
    - Triangle color cycles from dark green to bright green
    - Uses sin(time) to create smooth oscillation
    - Demonstrates dynamic uniform updates each frame

    EAGL Framework Difference:
    - Original tutorial: time calculated directly in render loop
    - EAGL approach: tick handler updates time state each frame
    - This separates state management from rendering logic
    - Same visual result, cleaner architecture

    Press ENTER to exit.
    """)

    # Compile and link shaders
    with {:ok, vertex_shader} <-
           create_shader(
             @gl_vertex_shader,
             "learnopengl/1_getting_started/3_1_shaders_uniform/vertex_shader.glsl"
           ),
         {:ok, fragment_shader} <-
           create_shader(
             @gl_fragment_shader,
             "learnopengl/1_getting_started/3_1_shaders_uniform/fragment_shader.glsl"
           ),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do
      IO.puts("Vertex and fragment shaders compiled and linked successfully")

      # Create VAO and VBO for triangle geometry
      {vao, vbo} = create_position_array(@vertices)

      IO.puts("Created VAO and VBO (3 vertices uploaded to GPU)")
      IO.puts("Ready to render - You should see a color-changing triangle.")

      # Initialize current time for animation
      current_time = :erlang.monotonic_time(:millisecond) / 1000.0
      {:ok, {program, vao, vbo, current_time}}
    else
      {:error, reason} ->
        IO.puts("Failed to create shader program: #{reason}")
        {:error, reason}
    end
  end

  @impl true
  def render(viewport_width, viewport_height, {program, vao, _vbo, current_time}) do
    # Set viewport
    :gl.viewport(0, 0, trunc(viewport_width), trunc(viewport_height))

    # Set clear color (dark gray-blue) and clear screen
    :gl.clearColor(0.2, 0.3, 0.3, 1.0)
    :gl.clear(@gl_color_buffer_bit)

    # Use the shader program
    :gl.useProgram(program)

    # Calculate animated color using sine wave (EAGL framework pattern)
    # Original LearnOpenGL: time calculated directly in render with glfwGetTime()
    # EAGL approach: uses time from state updated by tick handler each frame
    # Benefits: cleaner separation of state updates from rendering logic
    # Math: sin(time) oscillates -1 to 1, we map to 0.0 to 1.0 for green intensity
    green_value = :math.sin(current_time) / 2.0 + 0.5

    # Set uniform color for animated effect
    # EAGL's set_uniform() handles glGetUniformLocation + glUniform4f pattern
    # Format: {red, green, blue, alpha} where green animates, others stay constant
    set_uniform(program, "ourColor", [{0.0, green_value, 0.0, 1.0}])

    # Draw the triangle
    :gl.bindVertexArray(vao)
    :gl.drawArrays(@gl_triangles, 0, 3)

    :ok
  end

  @impl true
  def handle_event(:tick, {program, vao, vbo, _current_time}) do
    # Update animation time each tick (EAGL framework pattern)
    # Called at 60 FPS to update the time state used for color animation
    # This separates timing logic from rendering for cleaner architecture
    # Benefits: fixed frame rate, better testability, separation of concerns
    current_time = :erlang.monotonic_time(:millisecond) / 1000.0
    {:ok, {program, vao, vbo, current_time}}
  end

  @impl true
  def cleanup({program, vao, vbo, _current_time}) do
    # Clean up OpenGL resources
    delete_vertex_array(vao, vbo)
    cleanup_program(program)
    :ok
  end
end
