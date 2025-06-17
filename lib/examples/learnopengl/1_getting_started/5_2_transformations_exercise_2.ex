defmodule EAGL.Examples.LearnOpenGL.GettingStarted.TransformationsExercise2 do
  @moduledoc """
  LearnOpenGL 5.2 - Transformations Exercise 2

  This exercise demonstrates rendering multiple objects with different transformation
  behaviors in the same scene. It showcases two containers: one that rotates around
  a translated position (orbiting effect), and another that scales rhythmically
  based on a sine wave, creating a pulsing effect.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial exercises:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/src/1.getting_started/5.2.transformations_exercise2>

  ## Exercise Focus

  This exercise demonstrates:
  - **Multiple Object Rendering**: Drawing the same geometry with different transformations
  - **Combined Transformations**: Translation + rotation vs translation + scaling
  - **Time-based Animations**: Using time for both rotation and scaling effects
  - **Transformation Order Effects**: How T*R and T*S create orbiting/corner-scaling behavior

  ## Framework Adaptation Notes

  ### State Management

  Uses map-based state following the 4.x texture examples pattern:
  ```elixir
  %{
    program: program_id,
    vao: vertex_array_id,
    vbo: vertex_buffer_id,
    ebo: element_buffer_id,
    texture1_id: texture1_id,
    texture2_id: texture2_id
  }
  ```

  ### Vertex Layout

  Vertex attributes match EAGL's standard layout:
  - `location = 0`: Position (vec3)
  - `location = 2`: Texture coordinates (vec2)

  The shader uses `aTexCoord` at location 2 to match EAGL.Buffer conventions.

  ### Transformation Differences

  **Container 1** (Bottom-right, orbiting):
  - `translate(0.5, -0.5, 0.0)` first
  - `rotate(time, 0, 0, 1)` second
  - Creates an orbiting effect around the world origin (not its own center)

  **Container 2** (Top-left, corner-scaling):
  - `translate(-0.5, 0.5, 0.0)` first
  - `scale(sin(time), sin(time), sin(time))` second
  - Creates scaling from the world origin corner (not its own center)

  ## Educational Notes

  ### Matrix Order Matters

  The order of transformations affects the final result:
  - Container 1: T * R = First translate, then rotate around world origin = orbiting
  - Container 2: T * S = First translate, then scale from world origin = corner scaling
  - To rotate/scale around object center: use R * T or S * T instead

  ### Animation Techniques

  - **Rotation**: Continuous rotation using time directly
  - **Scaling**: Sine wave creates rhythmic pulsing between 0 and 1
  - **Multiple Objects**: Same VAO/geometry, different transformation matrices

  ### Performance Considerations

  - Single VAO/VBO setup used for both containers
  - Matrix calculations per frame for animations
  - Uniform updates for each object before drawing

  ## Keybindings

  - **ENTER**: Exit the example (when `return_to_exit: true`)
  - **ESC**: Alternative exit method
  """

  use EAGL.Window
  use EAGL.Const
  import EAGL.Buffer
  import EAGL.Shader
  import EAGL.Texture
  import EAGL.Math
  import EAGL.Error

  def run_example do
    EAGL.Window.run(__MODULE__, "LearnOpenGL 5.2 - Transformations Exercise 2",
      return_to_exit: true
    )
  end

  @impl true
  def setup do
    IO.puts("""
    === LearnOpenGL 5.2 - Transformations Exercise 2 ===
    This exercise demonstrates multiple animated transformations

    Key Concepts:
    - Multiple transformation matrices applied to the same geometry
    - Different animation patterns: rotation vs scaling
    - Matrix multiplication order effects on final positioning
    - Time-based animations using sine waves and linear progression
    - Single VAO geometry rendered with different transforms

    Animation Details:
    - Container 1: Orbits in bottom-right area (translate + rotate)
    - Container 2: Scales at top-left corner (translate + scale)
    - Both use time-based animations for smooth motion
    - Demonstrates transformation order effects: T*R vs T*S

    Visual Results:
    - Container 1 orbits around its translated position
    - Container 2 scales from the corner (not center)
    - Matrix order creates these specific animation patterns
    - Same geometry, different transformation effects

    Press ENTER to exit.
    """)

    # Compile and link shaders using 'with' for consistent error handling
    with {:ok, vertex_shader} <-
           create_shader(
             @gl_vertex_shader,
             "learnopengl/1_getting_started/5_2_transformations_exercise_2/vertex_shader.glsl"
           ),
         {:ok, fragment_shader} <-
           create_shader(
             @gl_fragment_shader,
             "learnopengl/1_getting_started/5_2_transformations_exercise_2/fragment_shader.glsl"
           ),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do
      IO.puts("Vertex and fragment shaders compiled and linked successfully")

      # Set up vertex data for a quad (container shape)
      vertices = ~v"""
      # position      texture_coords
       0.5   0.5  0.0  1.0  1.0  # top right
       0.5  -0.5  0.0  1.0  0.0  # bottom right
      -0.5  -0.5  0.0  0.0  0.0  # bottom left
      -0.5   0.5  0.0  0.0  1.0  # top left
      """

      indices = ~i"""
      0  1  3  # first triangle
      1  2  3  # second triangle
      """

      # Create vertex array with position and texture coordinates
      # Each vertex: 3 position + 2 texture = 5 floats (20 bytes)
      attributes = vertex_attributes(:position, :texture_coordinate)
      {vao, vbo, ebo} = create_indexed_array(vertices, indices, attributes)

      IO.puts("Created VAO, VBO, and EBO (rectangle with position and texture coordinates)")

      # Load two textures like the original LearnOpenGL exercise
      {:ok, texture1_id, width1, height1} =
        load_texture_from_file("priv/images/eagl_logo_black_on_white.jpg")

      IO.puts("Created texture 1: EAGL logo (#{width1}x#{height1})")

      # Use checkerboard for clear visual contrast (demonstrates texture mixing better)
      {:ok, texture2_id, width2, height2} = create_checkerboard_texture(256, 32)
      IO.puts("Created texture 2: checkerboard pattern (#{width2}x#{height2})")

      # Set up shader uniforms for both textures
      :gl.useProgram(program)

      set_uniforms(program, [
        # Use texture unit 0
        {"texture1", 0},
        # Use texture unit 1
        {"texture2", 1}
      ])

      IO.puts("Ready to render - you should see two animated textured containers.")

      # Initialize current time for animation
      current_time = :erlang.monotonic_time(:millisecond) / 1000.0

      {:ok,
       %{
         program: program,
         vao: vao,
         vbo: vbo,
         ebo: ebo,
         texture1_id: texture1_id,
         texture2_id: texture2_id,
         current_time: current_time
       }}
    else
      {:error, reason} ->
        IO.puts("Failed to create shader program or texture: #{reason}")
        {:error, reason}
    end
  end

  @impl true
  def render(_width, _height, state) do
    # Clear the screen
    :gl.clearColor(0.2, 0.3, 0.3, 1.0)
    :gl.clear(@gl_color_buffer_bit)

    # Bind textures like the original exercise
    :gl.activeTexture(@gl_texture0)
    :gl.bindTexture(@gl_texture_2d, state.texture1_id)
    :gl.activeTexture(@gl_texture1)
    :gl.bindTexture(@gl_texture_2d, state.texture2_id)

    # Use shader program
    :gl.useProgram(state.program)

    # Use current time from state (EAGL framework pattern)
    # Original LearnOpenGL: time calculated directly in render with glfwGetTime()
    # EAGL approach: uses time from state updated by tick handler each frame
    # Benefits: cleaner separation of state updates from rendering logic

    # ===== FIRST CONTAINER - Rotating (bottom-right) =====
    # Create transformation: translate first, then rotate
    # This creates an orbiting effect around the translated position
    transform1 =
      mat4_identity()
      # Move to bottom-right
      |> mat4_mul(mat4_translate(vec3(0.5, -0.5, 0.0)))
      # Rotate around Z-axis
      |> mat4_mul(mat4_rotate_z(state.current_time))

    # Set transformation uniform and draw first container
    set_uniform(state.program, "transform", transform1)

    # Draw first container
    :gl.bindVertexArray(state.vao)
    :gl.drawElements(@gl_triangles, 6, @gl_unsigned_int, 0)

    # ===== SECOND CONTAINER - Scaling (top-left) =====
    # Create transformation: translate first, then scale
    # This creates a pulsing effect at the translated position
    # Original LearnOpenGL uses sin() without abs() - allows negative scaling
    # Oscillates between -1 and 1
    scale_factor = :math.sin(state.current_time)

    transform2 =
      mat4_identity()
      # Move to top-left
      |> mat4_mul(mat4_translate(vec3(-0.5, 0.5, 0.0)))
      # Scale uniformly
      |> mat4_mul(mat4_scale(vec3(scale_factor, scale_factor, scale_factor)))

    # Set transformation uniform and draw second container
    set_uniform(state.program, "transform", transform2)

    # Draw second container
    :gl.drawElements(@gl_triangles, 6, @gl_unsigned_int, 0)

    check("After rendering both containers")
    :ok
  end

  @impl true
  def handle_event(:tick, state) do
    # Update animation time each tick (EAGL framework pattern)
    # Called at 60 FPS to update the time state used for transformation animations
    # This separates timing logic from rendering for cleaner architecture
    # Benefits: fixed frame rate, better testability, separation of concerns
    current_time = :erlang.monotonic_time(:millisecond) / 1000.0
    {:ok, %{state | current_time: current_time}}
  end

  @impl true
  def cleanup(state) do
    IO.puts("Cleaning up transformations exercise 2 resources...")

    # Clean up textures
    :gl.deleteTextures([state.texture1_id, state.texture2_id])

    # Clean up buffers
    delete_indexed_array(state.vao, state.vbo, state.ebo)

    # Clean up shader program
    :gl.deleteProgram(state.program)

    check("After cleanup")
    IO.puts("Cleanup complete!")
    :ok
  end
end
