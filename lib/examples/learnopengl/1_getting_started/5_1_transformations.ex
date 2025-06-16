defmodule EAGL.Examples.LearnOpenGL.GettingStarted.Transformations do
  @moduledoc """
  LearnOpenGL 5.1 - Transformations

  This example demonstrates basic matrix transformations in OpenGL - using translation,
  rotation, and scaling matrices to transform objects without modifying vertex data.
  It corresponds to the Transformations tutorial in the LearnOpenGL series.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/src/1.getting_started/5.1.transformations>

  ## Framework Adaptation Notes

  In the original LearnOpenGL C++ tutorial, this example introduces:
  - Creating transformation matrices using GLM library functions
  - Passing matrices to shaders as uniforms
  - Applying transformations in vertex shaders
  - Understanding transformation order (Scale → Rotate → Translate)
  - Time-based animations using continuous transformations

  EAGL's framework preserves all these concepts while providing enhanced functionality:
  - **Comprehensive Math Library**: Uses EAGL.Math with GLM-compatible functions
  - **Simplified Uniform Setting**: Enhanced `set_uniform()` function handles matrix types automatically
  - **Time-based Animation**: Smooth rotation animation using system time
  - **Error Handling**: Comprehensive error checking throughout setup and rendering
  - **Educational Value**: Clear documentation of transformation concepts

  ## EAGL vs Original Implementation

  **Original LearnOpenGL approach:** Manual GLM matrix creation and uniform setting:
  ```c++
  glm::mat4 trans = glm::mat4(1.0f);
  trans = glm::translate(trans, glm::vec3(0.5f, -0.5f, 0.0f));
  trans = glm::rotate(trans, (float)glfwGetTime(), glm::vec3(0.0f, 0.0f, 1.0f));
  unsigned int transformLoc = glGetUniformLocation(ourShader.ID, "transform");
  glUniformMatrix4fv(transformLoc, 1, GL_FALSE, glm::value_ptr(trans));
  ```

  **EAGL approach:** Streamlined matrix operations with automatic uniform handling:
  ```elixir
  transform = mat4_identity()
              |> mat4_mul(mat4_translate(vec3(0.5, -0.5, 0.0)))
              |> mat4_mul(mat4_rotate_z(time))
  set_uniform(program, "transform", transform)
  ```

  ## Key Learning Points

  - **Transformation Matrices**: How scale, rotation, and translation matrices work
  - **Matrix Multiplication**: Understanding the order of matrix operations (right-to-left)
  - **Vertex Transformation**: How the vertex shader applies transformations
  - **Homogeneous Coordinates**: Why we use 4x4 matrices for 3D transformations
  - **Animation**: Creating smooth movement through time-based transformations

  ## Mathematical Background

  This example demonstrates the fundamental 2D transformations:
  - **Translation**: Moving objects in space using a translation matrix
  - **Rotation**: Rotating objects around the Z-axis using trigonometric functions
  - **Scaling**: Changing object size uniformly or non-uniformly
  - **Combination**: Multiplying matrices to combine multiple transformations

  ## Visual Effect

  The example shows a textured rectangle that **orbits** around the world origin in a
  circular motion. This demonstrates the importance of transformation order:

  - **Translation first, then rotation**: `T * R` = Object orbits around world origin
  - The rectangle is first moved to (0.5, -0.5), then rotated around (0, 0, 0)
  - This creates a circular orbit motion, not rotation around the rectangle's center

  To rotate around the rectangle's center instead, you would use: `R * T` (rotate first, then translate).

  ## Usage

      EAGL.Examples.LearnOpenGL.GettingStarted.Transformations.run_example()

  Press ENTER to exit the example.
  """

  use EAGL.Window
  use EAGL.Const

  import EAGL.Shader
  import EAGL.Buffer
  import EAGL.Texture
  import EAGL.Error
  import EAGL.Math

  # Rectangle vertex data with positions and texture coordinates
  # Format: [x, y, z, s, t] per vertex - simplified from 4.x examples
  @vertices ~v'''
  # positions    # texture coords
   0.5  0.5 0.0  1.0 1.0   # top right
   0.5 -0.5 0.0  1.0 0.0   # bottom right
  -0.5 -0.5 0.0  0.0 0.0   # bottom left
  -0.5  0.5 0.0  0.0 1.0   # top left
  '''

  # Indices for drawing the rectangle using two triangles
  @indices ~i'''
  0 1 3  # first triangle
  1 2 3  # second triangle
  '''

  @spec run_example() :: :ok | {:error, term()}
  def run_example,
    do:
      EAGL.Window.run(
        __MODULE__,
        "LearnOpenGL - 1 Getting Started - 5.1 Transformations",
        return_to_exit: true
      )

  @impl true
  def setup do
    IO.puts("""
    === LearnOpenGL 5.1 - Transformations ===
    This example demonstrates matrix transformations in OpenGL

    Key Concepts:
    - Transformation matrices allow moving, rotating, and scaling objects
    - Matrices are passed to shaders as uniforms and applied in vertex shaders
    - Matrix multiplication combines multiple transformations efficiently
    - Transform order matters: Scale → Rotate → Translate (read right-to-left)
    - Time-based transformations create smooth animations

    Matrix Operations:
    - Translation matrix moves objects in 3D space
    - Rotation matrix rotates objects around specified axes
    - Scale matrix changes object size uniformly or per-axis
    - Identity matrix leaves objects unchanged (multiplication neutral element)

    Animation Details:
    - Rectangle orbits around the world origin (not rotating around its own center)
    - Transform order: translate first, then rotate = orbiting motion
    - Rotation speed based on system time for smooth animation
    - Demonstrates how transformation order affects the final result
    - Combined transformation shows matrix multiplication in action

    EAGL Framework Features:
    - Comprehensive EAGL.Math library with GLM-compatible functions
    - Automatic matrix uniform handling with type detection
    - Time-based animation using monotonic time
    - Same OpenGL concepts as original tutorial with enhanced usability

    Press ENTER to exit.
    """)

    # Compile and link shaders
    with {:ok, vertex_shader} <-
           create_shader(
             :vertex,
             "learnopengl/1_getting_started/5_1_transformations/vertex_shader.glsl"
           ),
         {:ok, fragment_shader} <-
           create_shader(
             :fragment,
             "learnopengl/1_getting_started/5_1_transformations/fragment_shader.glsl"
           ),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do
      IO.puts("Vertex and fragment shaders compiled and linked successfully")

      # Create vertex array with position and texture coordinates
      # Each vertex: 3 position + 2 texture = 5 floats (20 bytes)
      attributes = vertex_attributes(:position, :texture_coordinate)

      {vao, vbo, ebo} = create_indexed_array(@vertices, @indices, attributes)

      IO.puts("Created VAO, VBO, and EBO (rectangle with position and texture coordinates)")

      # Load texture using EAGL.Texture abstraction
      {:ok, texture_id, width, height} =
        load_texture_from_file("priv/images/eagl_logo_black_on_white.jpg")

      IO.puts("Created texture (#{width}x#{height})")

      # Set up shader uniforms for texture
      :gl.useProgram(program)
      set_uniform(program, "texture1", 0)  # Use texture unit 0

      IO.puts("Ready to render - you should see a rotating textured rectangle.")

      # Initialize current time for animation
      current_time = :erlang.monotonic_time(:millisecond) / 1000.0

      {:ok,
       %{
         program: program,
         vao: vao,
         vbo: vbo,
         ebo: ebo,
         texture_id: texture_id,
         current_time: current_time
       }}
    else
      {:error, reason} ->
        IO.puts("Failed to create shader program or texture: #{reason}")
        {:error, reason}
    end
  end

  @impl true
  def render(viewport_width, viewport_height, state) do
    # Set viewport
    :gl.viewport(0, 0, trunc(viewport_width), trunc(viewport_height))

    # Set clear color and clear screen
    :gl.clearColor(0.2, 0.3, 0.3, 1.0)
    :gl.clear(@gl_color_buffer_bit)

    # Bind texture
    :gl.activeTexture(@gl_texture0)
    :gl.bindTexture(@gl_texture_2d, state.texture_id)

    # Use the shader program
    :gl.useProgram(state.program)

    # Create transformation matrix using time from state (EAGL framework pattern)
    # Original LearnOpenGL: time calculated directly in render with glfwGetTime()
    # EAGL approach: uses time from state updated by tick handler each frame
    # Benefits: cleaner separation of state updates from rendering logic
    transform =
      mat4_identity()
      |> mat4_mul(mat4_translate(vec3(0.5, -0.5, 0.0)))  # Move to bottom-right
      |> mat4_mul(mat4_rotate_z(state.current_time))      # Rotate around Z-axis

    # Pass transformation matrix to shader
    set_uniform(state.program, "transform", transform)

    check("After setting transform uniform")

    # Draw the rectangle
    :gl.bindVertexArray(state.vao)
    :gl.drawElements(@gl_triangles, 6, @gl_unsigned_int, 0)

    check("After rendering")
    :ok
  end

  @impl true
  def handle_event(:tick, state) do
    # Update animation time each tick (EAGL framework pattern)
    # Called at 60 FPS to update the time state used for transformation animation
    # This separates timing logic from rendering for cleaner architecture
    # Benefits: fixed frame rate, better testability, separation of concerns
    current_time = :erlang.monotonic_time(:millisecond) / 1000.0
    {:ok, %{state | current_time: current_time}}
  end

  @impl true
  def cleanup(state) do
    IO.puts("""
    Cleaning up transformations example...
    - Demonstrated matrix transformations with translation and rotation
    - Showed time-based animation using transformation matrices
    """)

    # Clean up texture
    :gl.deleteTextures([state.texture_id])

    # Clean up buffers
    delete_vertex_array(state.vao, state.vbo)
    :gl.deleteBuffers([state.ebo])

    # Clean up shader program
    :gl.deleteProgram(state.program)

    check("After cleanup")
    :ok
  end
end
