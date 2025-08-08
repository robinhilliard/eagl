defmodule EAGL.Examples.LearnOpenGL.GettingStarted.TransformationsExercise1 do
  @moduledoc """
  LearnOpenGL 5.2 - Transformations Exercise 1

  This exercise demonstrates multiple transformation techniques by rendering two
  containers with different transformation behaviors. It builds on the basic
  transformations from 5.1 and shows how to apply different transformations
  to multiple objects in a single scene.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial exercises:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/src/1.getting_started/5.1.transformations>

  ## Exercise Focus

  This exercise demonstrates:
  - **Multiple Draw Calls**: Rendering the same geometry with different transformations
  - **Varying Transformations**: Different transformation matrices for different objects
  - **Animation Techniques**: Scaling with sine functions and continuous rotation
  - **Matrix Isolation**: How each object gets its own transformation matrix

  ## EAGL Implementation

  This implementation renders two textured rectangles:
  1. **First Container**: Positioned at bottom-right, rotates continuously
  2. **Second Container**: Positioned at top-left, scales up and down using sine wave

  The key insight is that we can render the same VAO multiple times with different
  transformation matrices to create distinct objects in the scene.

  ## Key Learning Points

  - **Object Instancing**: Same geometry, different transformations
  - **Sine Wave Animation**: Using trigonometric functions for smooth scaling
  - **Matrix Independence**: Each draw call uses its own transformation matrix
  - **Performance**: Multiple draw calls vs instanced rendering considerations
  - **Transformation Variety**: Rotation vs scaling animations

  ## Mathematical Background

  - **Sine Wave Scaling**: `sin(time)` creates oscillation between -1 and 1
  - **Absolute Scaling**: Using `abs(sin(time))` to prevent negative scaling
  - **Time-based Animation**: System time drives smooth, continuous motion
  - **Matrix Composition**: Different combinations of transformations per object

  ## Visual Effect

  Two containers are displayed simultaneously:
  - Bottom-right container rotates smoothly around its center
  - Top-left container pulses in size, scaling larger and smaller rhythmically

  ## Usage

      EAGL.Examples.LearnOpenGL.GettingStarted.TransformationsExercise1.run_example()

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
  # Format: [x, y, z, s, t] per vertex
  @vertices ~v'''
  # positions        # texture coords
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
  def run_example(opts \\ []) do
    default_opts = [enter_to_exit: true]
    merged_opts = Keyword.merge(default_opts, opts)

    EAGL.Window.run(
      __MODULE__,
      "LearnOpenGL - 1 Getting Started - 5.2 Transformations Exercise 1",
      merged_opts
    )
  end

  @impl true
  def setup do
    IO.puts("""
    === LearnOpenGL 5.2 - Transformations Exercise 1 ===
    This exercise demonstrates multiple transformations on different objects

    Exercise Focus:
    - Multiple Draw Calls: Same geometry, different transformations
    - Two containers with distinct animation behaviors
    - Matrix independence: each object has its own transformation
    - Performance insight: multiple transforms vs instanced rendering

    Container Behaviors:
    - Container 1 (bottom-right): Orbits around world origin (translate then rotate)
    - Container 2 (top-left): Scales from world origin (translate then scale)
    - Both use the same VAO/texture but different transformation matrices
    - Demonstrates how transformation order affects the final result

    Animation Techniques:
    - Rotation: Continuous time-based rotation matrix
    - Scaling: abs(sin(time)) creates pulsing scale effect
    - Translation: Static positioning for each container
    - Time synchronization: Both animations use same time source

    Learning Points:
    - **Transformation Order Effects**: T*R vs R*T produces different results
    - T*R (translate then rotate) = orbiting around world origin
    - T*S (translate then scale) = scaling from world origin corner
    - Object instancing with transformations
    - Sine wave mathematics for smooth scaling
    - Matrix isolation prevents interference between objects
    - Multiple rendering passes with different uniforms

    Note: To rotate/scale around object center, use R*T or S*T order instead.

    EAGL Framework Features:
    - Same transformation functions as 5.1 example
    - Multiple uniform updates per frame
    - Efficient matrix calculations
    - Clear animation timing control

    Press ENTER to exit.
    """)

    # Compile and link shaders (same as 5.1)
    with {:ok, vertex_shader} <-
           create_shader(
             @gl_vertex_shader,
             "learnopengl/1_getting_started/5_2_transformations_exercise_1/vertex_shader.glsl"
           ),
         {:ok, fragment_shader} <-
           create_shader(
             @gl_fragment_shader,
             "learnopengl/1_getting_started/5_2_transformations_exercise_1/fragment_shader.glsl"
           ),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do
      IO.puts("Vertex and fragment shaders compiled and linked successfully")

      # Create vertex array with position and texture coordinates
      # Each vertex: 3 position + 2 texture = 5 floats (20 bytes)
      attributes = vertex_attributes(:position, :texture_coordinate)

      {vao, vbo, ebo} = create_indexed_array(@vertices, @indices, attributes)

      IO.puts("Created VAO, VBO, and EBO (rectangle with position and texture coordinates)")

      # Load texture
      {:ok, texture_id, width, height} =
        load_texture_from_file("priv/images/eagl_logo_black_on_white.jpg")

      IO.puts("Created texture (#{width}x#{height})")

      # Set up shader uniforms for texture
      :gl.useProgram(program)
      # Use texture unit 0
      set_uniform(program, "texture1", 0)

      IO.puts("Ready to render - you should see two animated containers.")

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

    # Use current time from state (EAGL framework pattern)
    # Original LearnOpenGL: time calculated directly in render with glfwGetTime()
    # EAGL approach: uses time from state updated by tick handler each frame
    # Benefits: cleaner separation of state updates from rendering logic

    # Bind VAO once (will be used for both containers)
    :gl.bindVertexArray(state.vao)

    # First container: bottom-right, rotating
    transform1 =
      mat4_identity()
      # Move to bottom-right
      |> mat4_mul(mat4_translate(vec3(0.5, -0.5, 0.0)))
      # Rotate around Z-axis
      |> mat4_mul(mat4_rotate_z(state.current_time))

    set_uniform(state.program, "transform", transform1)
    check("After setting first transform uniform")

    # Draw first container
    :gl.drawElements(@gl_triangles, 6, @gl_unsigned_int, 0)

    # Second container: top-left, scaling
    # Use abs(sin(time)) to prevent negative scaling which would flip the texture
    scale_factor = abs(:math.sin(state.current_time))

    transform2 =
      mat4_identity()
      # Move to top-left
      |> mat4_mul(mat4_translate(vec3(-0.5, 0.5, 0.0)))
      # Scale based on sine wave
      |> mat4_mul(mat4_scale(vec3(scale_factor, scale_factor, 1.0)))

    set_uniform(state.program, "transform", transform2)
    check("After setting second transform uniform")

    # Draw second container
    :gl.drawElements(@gl_triangles, 6, @gl_unsigned_int, 0)

    check("After rendering both containers")
    :ok
  end

  @impl true
  def handle_event({:tick, _time_delta}, state) do
    # Update animation time each tick (EAGL framework pattern)
    # Called at 60 FPS to update the time state used for transformation animations
    # This separates timing logic from rendering for cleaner architecture
    # Benefits: fixed frame rate, better testability, separation of concerns
    current_time = :erlang.monotonic_time(:millisecond) / 1000.0
    {:ok, %{state | current_time: current_time}}
  end

  @impl true
  def cleanup(state) do
    IO.puts("""
    Cleaning up transformations exercise 1...
    - Demonstrated multiple objects with different transformations
    - Showed rotation and scaling animations simultaneously
    - Used sine wave mathematics for smooth scaling effects
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
