defmodule EAGL.Examples.LearnOpenGL.GettingStarted.CameraKeyboardDt do
  @moduledoc """
  LearnOpenGL 7.2 - Camera (Keyboard + Delta Time)

  This example demonstrates interactive camera movement using keyboard input with
  delta time for frame-rate independent movement. The user can move the camera
  around the scene using WASD keys.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/src/1.getting_started/7.2.camera_keyboard_dt>

  ## Framework Adaptation Notes

  This example introduces interactive camera control concepts:
  - Keyboard input handling for camera movement
  - Delta time calculation for frame-rate independent movement
  - Camera direction vectors for forward/backward and strafe movement
  - Real-time camera position updates based on user input

  ## Key Learning Points

  - **Interactive Camera Control**: Using keyboard input to move the camera in real-time
  - **Delta Time**: Ensuring consistent movement speed regardless of frame rate
  - **Camera Direction Vectors**: Understanding forward, right, and up vectors for 3D movement
  - **Continuous Input**: Handling multiple keys pressed simultaneously for smooth movement

  ## Camera Movement Controls

  - **W**: Move forward (in the direction the camera is facing)
  - **S**: Move backward (opposite to camera direction)
  - **A**: Strafe left (perpendicular to camera direction)
  - **D**: Strafe right (perpendicular to camera direction)

  ## Implementation Details

  - Camera starts at position (0, 0, 3) looking down the negative Z-axis
  - Movement speed is scaled by delta time for consistent speed across different frame rates
  - Camera maintains a fixed forward direction (down negative Z-axis)
  - Multiple keys can be pressed simultaneously for diagonal movement

  ## Visual Effect

  Shows multiple textured cubes that the user can navigate around:
  - Camera responds immediately to keyboard input
  - Smooth, continuous movement while keys are held
  - Consistent movement speed regardless of frame rate
  - Free camera movement through 3D space
  - 10 cubes with static rotations based on their index (20 degrees × index)

  ## Usage

      EAGL.Examples.LearnOpenGL.GettingStarted.CameraKeyboardDt.run_example()

  Use WASD keys to move the camera. Press ENTER to exit.
  """

  use EAGL.Window
  use EAGL.Const

  import Bitwise
  import EAGL.Shader
  import EAGL.Buffer
  import EAGL.Texture
  import EAGL.Error
  import EAGL.Math

  # Camera movement speed (units per second)
  @camera_speed 2.5

  # 3D cube vertex data with positions and texture coordinates
  @vertices ~v'''
  # positions        # texture coords
  -0.5 -0.5 -0.5     0.0 0.0
   0.5 -0.5 -0.5     1.0 0.0
   0.5  0.5 -0.5     1.0 1.0
   0.5  0.5 -0.5     1.0 1.0
  -0.5  0.5 -0.5     0.0 1.0
  -0.5 -0.5 -0.5     0.0 0.0

  -0.5 -0.5  0.5     0.0 0.0
   0.5 -0.5  0.5     1.0 0.0
   0.5  0.5  0.5     1.0 1.0
   0.5  0.5  0.5     1.0 1.0
  -0.5  0.5  0.5     0.0 1.0
  -0.5 -0.5  0.5     0.0 0.0

  -0.5  0.5  0.5     1.0 0.0
  -0.5  0.5 -0.5     1.0 1.0
  -0.5 -0.5 -0.5     0.0 1.0
  -0.5 -0.5 -0.5     0.0 1.0
  -0.5 -0.5  0.5     0.0 0.0
  -0.5  0.5  0.5     1.0 0.0

   0.5  0.5  0.5     1.0 0.0
   0.5  0.5 -0.5     1.0 1.0
   0.5 -0.5 -0.5     0.0 1.0
   0.5 -0.5 -0.5     0.0 1.0
   0.5 -0.5  0.5     0.0 0.0
   0.5  0.5  0.5     1.0 0.0

  -0.5 -0.5 -0.5     0.0 1.0
   0.5 -0.5 -0.5     1.0 1.0
   0.5 -0.5  0.5     1.0 0.0
   0.5 -0.5  0.5     1.0 0.0
  -0.5 -0.5  0.5     0.0 0.0
  -0.5 -0.5 -0.5     0.0 1.0

  -0.5  0.5 -0.5     0.0 1.0
   0.5  0.5 -0.5     1.0 1.0
   0.5  0.5  0.5     1.0 0.0
   0.5  0.5  0.5     1.0 0.0
  -0.5  0.5  0.5     0.0 0.0
  -0.5  0.5 -0.5     0.0 1.0
  '''

  # Positions for cubes in 3D space
  @cube_positions [
    vec3(0.0, 0.0, 0.0),
    vec3(2.0, 5.0, -15.0),
    vec3(-1.5, -2.2, -2.5),
    vec3(-3.8, -2.0, -12.3),
    vec3(2.4, -0.4, -3.5),
    vec3(-1.7, 3.0, -7.5),
    vec3(1.3, -2.0, -2.5),
    vec3(1.5, 2.0, -2.5),
    vec3(1.5, 0.2, -1.5),
    vec3(-1.3, 1.0, -1.5)
  ]

  @spec run_example() :: :ok | {:error, term()}
  def run_example(opts \\ []) do
    default_opts = [depth_testing: true, enter_to_exit: true]
    merged_opts = Keyword.merge(default_opts, opts)

    EAGL.Window.run(
      __MODULE__,
      "LearnOpenGL - 1 Getting Started - 7.2 Camera (Keyboard + Delta Time)",
      merged_opts
    )
  end

  @impl true
  def setup do
    IO.puts("""
    === LearnOpenGL 7.2 - Camera (Keyboard + Delta Time) ===
    This example demonstrates interactive camera movement with keyboard input

    Key Concepts:
    - Interactive Camera Control: Real-time camera movement based on user input
    - Keyboard Input Handling: Processing WASD keys for camera movement
    - Delta Time: Frame-rate independent movement for consistent speed
    - Camera Direction Vectors: Forward, right, and up vectors for 3D movement

    Camera Movement Controls:
    - W: Move forward (negative Z direction)
    - S: Move backward (positive Z direction)
    - A: Strafe left (negative X direction)
    - D: Strafe right (positive X direction)

    Delta Time Implementation:
    - Movement speed scaled by time between frames
    - Ensures consistent movement regardless of frame rate
    - 60 FPS vs 30 FPS will have same camera speed
    - Essential for smooth camera controls

    Technical Details:
    - Camera position starts at (0, 0, 3)
    - Camera always looks down negative Z-axis (forward direction)
    - Movement vectors calculated from camera orientation
    - Multiple keys can be pressed for diagonal movement
    - 10 cubes positioned in 3D space with static rotations (matches original C++)

    Learning Progression:
    - Builds on 7.1 camera concepts with user interaction
    - Introduces real-time input handling
    - Demonstrates frame-rate independent movement
    - Foundation for more advanced camera controls

    Press WASD to move the camera. Press ENTER to exit.
    """)

    # Compile and link shaders
    with {:ok, vertex_shader} <-
           create_shader(
             @gl_vertex_shader,
             "learnopengl/1_getting_started/7_2_camera_keyboard_dt/vertex_shader.glsl"
           ),
         {:ok, fragment_shader} <-
           create_shader(
             @gl_fragment_shader,
             "learnopengl/1_getting_started/7_2_camera_keyboard_dt/fragment_shader.glsl"
           ),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do
      IO.puts("Vertex and fragment shaders compiled and linked successfully")

      # Create vertex array with position and texture coordinates
      attributes = vertex_attributes(:position, :texture_coordinate)
      {vao, vbo} = create_vertex_array(@vertices, attributes)

      IO.puts("Created VAO and VBO (cube with position and texture coordinates)")

      # Load texture
      {:ok, texture_id, width, height} =
        load_texture_from_file("priv/images/eagl_logo_black_on_white.jpg")

      IO.puts("Created texture (#{width}x#{height})")

      # Set up shader uniforms for texture
      :gl.useProgram(program)
      set_uniform(program, "texture1", 0)

      IO.puts("Ready to render - use WASD keys to move the camera around the cubes.")

      # Initialize camera state
      current_time = :erlang.monotonic_time(:millisecond) / 1000.0

      # Initial camera parameters
      camera_pos = vec3(0.0, 0.0, 3.0)
      # Looking down negative Z
      camera_front = vec3(0.0, 0.0, -1.0)
      # World up vector
      camera_up = vec3(0.0, 1.0, 0.0)

      # Pre-calculate initial matrices
      target_pos = vec_add(camera_pos, camera_front)
      view = mat4_look_at(camera_pos, target_pos, camera_up)

      # Default projection matrix (will be updated on first render with proper aspect ratio)
      projection = mat4_perspective(radians(45.0), 4.0 / 3.0, 0.1, 20.0)

      {:ok,
       %{
         program: program,
         vao: vao,
         vbo: vbo,
         texture_id: texture_id,
         # Camera position and orientation
         camera_pos: camera_pos,
         camera_front: camera_front,
         camera_up: camera_up,
         # Pre-calculated matrices
         target_pos: target_pos,
         view: view,
         projection: projection,
         # Timing for delta time
         current_time: current_time,
         last_frame_time: current_time
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

    # Set clear color and clear screen and depth buffer
    :gl.clearColor(0.2, 0.3, 0.3, 1.0)
    :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)

    # Bind texture
    :gl.activeTexture(@gl_texture0)
    :gl.bindTexture(@gl_texture_2d, state.texture_id)

    # Use the shader program
    :gl.useProgram(state.program)

    # Update projection matrix based on current viewport (in case window was resized)
    current_aspect_ratio = viewport_width / viewport_height
    projection = mat4_perspective(radians(45.0), current_aspect_ratio, 0.1, 20.0)

    # Set matrices: view is pre-calculated in state when camera moves, projection calculated for current viewport
    set_uniform(state.program, "view", state.view)
    set_uniform(state.program, "projection", projection)

    # Bind vertex array
    :gl.bindVertexArray(state.vao)

    # Draw each cube with its own model transformation
    @cube_positions
    |> Enum.with_index()
    |> Enum.each(fn {position, index} ->
      # Create model matrix for this cube (matches original C++ tutorial)
      model =
        mat4_identity()
        |> mat4_mul(mat4_translate(position))
        |> mat4_mul(mat4_rotate(vec3(1.0, 0.3, 0.5), radians(20.0 * index)))

      set_uniform(state.program, "model", model)
      :gl.drawArrays(@gl_triangles, 0, 36)
    end)

    check("After rendering with keyboard-controlled camera")
    :ok
  end

  @impl true
  def handle_event({:tick, time_delta}, state) do
    current_time = :erlang.monotonic_time(:millisecond) / 1000.0
    velocity = @camera_speed * time_delta
    camera_up = vec3(0.0, 1.0, 0.0)
    camera_front = state.camera_front

    new_camera_pos =
      state.camera_pos
      # W
      |> vec_add(
        if :wx_misc.getKeyState(?w),
          do: vec_scale(camera_front, velocity),
          else: vec3_zero()
      )
      # S
      |> vec_add(
        if :wx_misc.getKeyState(?s),
          do: vec_scale(camera_front, -velocity),
          else: vec3_zero()
      )
      # A
      |> vec_add(
        if :wx_misc.getKeyState(?a),
          do: vec_scale(normalize(cross(camera_front, camera_up)), -velocity),
          else: vec3_zero()
      )
      # D
      |> vec_add(
        if :wx_misc.getKeyState(?d),
          do: vec_scale(normalize(cross(camera_front, camera_up)), velocity),
          else: vec3_zero()
      )

    # Update view matrix only if camera position changed
    {new_target_pos, new_view} =
      if new_camera_pos != state.camera_pos do
        target_pos = vec_add(new_camera_pos, state.camera_front)
        view = mat4_look_at(new_camera_pos, target_pos, state.camera_up)
        {target_pos, view}
      else
        {state.target_pos, state.view}
      end

    {:ok,
     %{
       state
       | current_time: current_time,
         last_frame_time: current_time,
         camera_pos: new_camera_pos,
         target_pos: new_target_pos,
         view: new_view
     }}
  end

  @impl true
  def cleanup(state) do
    IO.puts("""
    Cleaning up camera keyboard example...
    - Demonstrated interactive camera movement with keyboard input
    - Implemented delta time for frame-rate independent movement
    """)

    # Clean up texture
    :gl.deleteTextures([state.texture_id])

    # Clean up buffers
    delete_vertex_array(state.vao, state.vbo)

    # Clean up shader program
    :gl.deleteProgram(state.program)

    check("After cleanup")
    :ok
  end
end
