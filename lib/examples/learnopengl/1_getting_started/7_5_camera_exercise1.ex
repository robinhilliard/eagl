defmodule EAGL.Examples.LearnOpenGL.GettingStarted.CameraExercise1 do
  @moduledoc """
  LearnOpenGL 7.5 - Camera Exercise 1: True FPS Camera

  This exercise implements a **true FPS (First-Person Shooter) camera** where the player
  cannot fly and is constrained to the XZ plane. This addresses some of the camera control
  issues from previous examples and provides a more natural ground-based navigation experience.

  ## Original Exercise Context

  This corresponds to the LearnOpenGL Camera Exercise 1 which challenges developers to:
  "Transform the camera class in such a way that it becomes a **true** fps camera where
  you cannot fly; you can only look around while staying on the `xz` plane."

  ## FPS Camera Constraints

  ### Movement Restrictions
  - **Y-Position Locked**: Camera Y-position remains constant (cannot fly up/down)
  - **Ground-Based Movement**: All movement is constrained to the XZ plane
  - **Horizontal Strafe**: Left/right movement follows camera orientation but stays level
  - **Forward/Backward**: Movement follows camera's horizontal direction only

  ### Look Controls
  - **Horizontal Look**: Full 360° horizontal rotation (yaw)
  - **Vertical Look**: Pitch is still functional for looking up/down
  - **Pitch Constraints**: Maintains ±89° pitch limits to prevent camera flipping

  ## Technical Implementation

  ### Movement Processing
  ```elixir
  # Standard camera movement (7.4)
  camera = Camera.process_keyboard(camera, :forward, delta_time)  # Can move up/down

  # FPS constrained movement (7.5)
  camera = process_fps_movement(camera, :forward, delta_time)     # Y locked
  ```

  ### Key Differences from 7.4
  - **Y-Position Preservation**: Forward/backward movement doesn't change Y coordinate
  - **Horizontal Strafe**: Side movement is calculated in XZ plane only
  - **Ground Alignment**: Camera feels more like walking than flying

  ## Controls

  - **W/A/S/D**: Move forward/left/backward/right (ground-based)
  - **Mouse Movement**: Look around (first-person view, pitch/yaw)
  - **Scroll Wheel**: Zoom in/out (field of view)
  - **ENTER**: Exit (when run with enter_to_exit: true)

  ## Educational Value

  This exercise demonstrates:
  - **Constraint Application**: How to apply movement restrictions to existing camera systems
  - **Vector Manipulation**: Working with horizontal-only movement vectors
  - **Game Design**: Understanding the difference between "fly" camera and "FPS" camera
  - **Y-Axis Control**: Maintaining consistent ground level in 3D navigation

  ## Comparison: Flying vs FPS Camera

  **Flying Camera (7.4)**:
  - Can move in all directions (X, Y, Z)
  - Forward movement follows exact camera direction
  - Suitable for free-form 3D navigation

  **FPS Camera (7.5)**:
  - Movement constrained to ground plane (XZ only)
  - Forward movement ignores vertical camera angle
  - More natural for ground-based games

  This exercise bridges the gap between abstract 3D navigation and practical game camera systems.
  """

  use EAGL.Window
  use EAGL.Const

  import EAGL.Shader
  import EAGL.Texture
  import EAGL.Buffer
  import EAGL.Math
  import EAGL.Error
  alias EAGL.Camera

  def run_example(opts \\ []) do
    EAGL.Window.run(
      __MODULE__,
      "LearnOpenGL 7.5 - Camera Exercise 1 (FPS Camera)",
      Keyword.merge([depth_testing: true, enter_to_exit: true], opts)
    )
  end

  @impl true
  def setup do
    IO.puts("""

    === LearnOpenGL 7.5: Camera Exercise 1 (FPS Camera) ===
    This exercise solves the 'flying camera' problem from previous examples
    by implementing a true FPS camera constrained to the ground plane.

    Learning Focus:
      • Understanding camera movement constraints
      • Implementing FPS-style ground-based navigation
      • Vector manipulation for horizontal-only movement
      • Game design: Flying vs ground-based cameras

    Problem Solved:
      In examples 7.1-7.4, when you look up/down and press W/S,
      the camera moves up/down in 3D space ("flying" behaviour).
      This is unnatural for first-person games.

    ✅ FPS Solution:
      • Y-position locked to ground level (1.5 units = eye height)
      • Forward/backward movement ignores camera pitch
      • Movement vectors projected onto XZ plane only
      • Natural ground-based navigation like FPS games

    Technical Implementation:
      • process_fps_movement() constrains movement to XZ plane
      • Horizontal front/right vectors calculated (Y = 0)
      • Ground level maintained regardless of look direction

    Try this: Look up/down and press W - notice you stay on ground
    ===============================================
    """)

    # Compile shaders
    {:ok, vertex} =
      create_shader(
        @gl_vertex_shader,
        "learnopengl/1_getting_started/7_5_camera_exercise1/vertex_shader.glsl"
      )

    {:ok, fragment} =
      create_shader(
        @gl_fragment_shader,
        "learnopengl/1_getting_started/7_5_camera_exercise1/fragment_shader.glsl"
      )

    {:ok, program} = create_attach_link([vertex, fragment])

    # Create cube with texture coordinates
    vertices = ~v"""
    # Positions        Texture coordinates
    # Front face
    -0.5 -0.5  0.5     0.0  0.0
     0.5 -0.5  0.5     1.0  0.0
     0.5  0.5  0.5     1.0  1.0
     0.5  0.5  0.5     1.0  1.0
    -0.5  0.5  0.5     0.0  1.0
    -0.5 -0.5  0.5     0.0  0.0

    # Back face
    -0.5 -0.5 -0.5     0.0  0.0
     0.5 -0.5 -0.5     1.0  0.0
     0.5  0.5 -0.5     1.0  1.0
     0.5  0.5 -0.5     1.0  1.0
    -0.5  0.5 -0.5     0.0  1.0
    -0.5 -0.5 -0.5     0.0  0.0

    # Left face
    -0.5  0.5  0.5     1.0  0.0
    -0.5  0.5 -0.5     1.0  1.0
    -0.5 -0.5 -0.5     0.0  1.0
    -0.5 -0.5 -0.5     0.0  1.0
    -0.5 -0.5  0.5     0.0  0.0
    -0.5  0.5  0.5     1.0  0.0

    # Right face
     0.5  0.5  0.5     1.0  0.0
     0.5  0.5 -0.5     1.0  1.0
     0.5 -0.5 -0.5     0.0  1.0
     0.5 -0.5 -0.5     0.0  1.0
     0.5 -0.5  0.5     0.0  0.0
     0.5  0.5  0.5     1.0  0.0

    # Bottom face
    -0.5 -0.5 -0.5     0.0  1.0
     0.5 -0.5 -0.5     1.0  1.0
     0.5 -0.5  0.5     1.0  0.0
     0.5 -0.5  0.5     1.0  0.0
    -0.5 -0.5  0.5     0.0  0.0
    -0.5 -0.5 -0.5     0.0  1.0

    # Top face
    -0.5  0.5 -0.5     0.0  1.0
     0.5  0.5 -0.5     1.0  1.0
     0.5  0.5  0.5     1.0  0.0
     0.5  0.5  0.5     1.0  0.0
    -0.5  0.5  0.5     0.0  0.0
    -0.5  0.5 -0.5     0.0  1.0
    """

    # Create vertex array
    {vao, vbo} = create_vertex_array(vertices, vertex_attributes(:position, :texture_coordinate))

    # Load texture
    {texture_result, texture_id, _width, _height} =
      case load_texture_from_file("priv/images/eagl_logo_black_on_white.png") do
        {:ok, id, w, h} -> {:ok, id, w, h}
        {:error, _reason} -> create_checkerboard_texture(256, 32)
      end

    if texture_result != :ok do
      IO.puts("Warning: Using fallback checkerboard texture")
    end

    check("After setup")

    # Cube positions
    cube_positions = [
      vec3(0.0, 0.0, 0.0),
      # Keep cubes at ground level
      vec3(2.0, 0.0, -15.0),
      vec3(-1.5, 0.0, -2.5),
      vec3(-3.8, 0.0, -12.3),
      vec3(2.4, 0.0, -3.5),
      vec3(-1.7, 0.0, -7.5),
      vec3(1.3, 0.0, -2.5),
      vec3(1.5, 0.0, -2.5),
      vec3(1.5, 0.0, -1.5),
      vec3(-1.3, 0.0, -1.5)
    ]

    # Create FPS camera at ground level
    camera =
      Camera.new(
        # 1.5 units above ground (eye level)
        position: vec3(0.0, 1.5, 3.0),
        yaw: -90.0,
        pitch: 0.0,
        movement_speed: 3.0,
        zoom: 45.0
      )

    # Track the ground level for FPS constraint
    ground_level = 1.5

    current_time = :erlang.monotonic_time(:millisecond) / 1000.0

    {:ok,
     %{
       program: program,
       vao: vao,
       vbo: vbo,
       texture_id: texture_id,
       cube_positions: cube_positions,
       camera: camera,
       # FPS constraint
       ground_level: ground_level,
       current_time: current_time,
       last_frame_time: current_time,
       last_mouse_x: 400.0,
       last_mouse_y: 300.0,
       first_mouse: true
     }}
  end

  @impl true
  def render(viewport_width, viewport_height, state) do
    # Set viewport
    :gl.viewport(0, 0, trunc(viewport_width), trunc(viewport_height))

    # Clear screen
    # Darker for ground-level feel
    :gl.clearColor(0.1, 0.1, 0.2, 1.0)
    :gl.clear(Bitwise.bor(@gl_color_buffer_bit, @gl_depth_buffer_bit))

    # Bind texture
    :gl.activeTexture(@gl_texture0)
    :gl.bindTexture(@gl_texture_2d, state.texture_id)

    # Use shader program
    :gl.useProgram(state.program)

    # Get matrices from camera
    view = Camera.get_view_matrix(state.camera)
    aspect_ratio = viewport_width / viewport_height

    projection =
      mat4_perspective(
        radians(state.camera.zoom),
        aspect_ratio,
        0.1,
        20.0
      )

    # Set matrices
    set_uniform(state.program, "view", view)
    set_uniform(state.program, "projection", projection)

    # Bind vertex array
    :gl.bindVertexArray(state.vao)

    # Render cubes
    Enum.with_index(state.cube_positions, fn cube_pos, i ->
      angle = 20.0 * i

      model =
        mat4_translate(cube_pos) |> mat4_mul(mat4_rotate(vec3(1.0, 0.3, 0.5), radians(angle)))

      set_uniform(state.program, "model", model)
      :gl.drawArrays(@gl_triangles, 0, 36)
    end)

    check("After render")
    :ok
  end

  @impl true
  def cleanup(state) do
    :gl.deleteVertexArrays([state.vao])
    :gl.deleteBuffers([state.vbo])
    :gl.deleteTextures([state.texture_id])
    :gl.deleteProgram(state.program)
    :ok
  end

  @impl true
  def handle_event(:tick, state) do
    current_time = :erlang.monotonic_time(:millisecond) / 1000.0
    delta_time = current_time - state.last_frame_time

    # Process FPS movement using simplified keyboard input function
    updated_camera =
      Camera.process_fps_keyboard_input(state.camera, delta_time, state.ground_level)

    {:ok,
     %{
       state
       | current_time: current_time,
         last_frame_time: current_time,
         camera: updated_camera
     }}
  end

  # Handle mouse movement (unchanged from 7.4)
  def handle_event({:mouse_motion, x, y}, state) do
    mouse_x = x * 1.0
    mouse_y = y * 1.0

    if state.first_mouse do
      {:ok, %{state | last_mouse_x: mouse_x, last_mouse_y: mouse_y, first_mouse: false}}
    else
      x_offset = mouse_x - state.last_mouse_x
      y_offset = state.last_mouse_y - mouse_y

      updated_camera = Camera.process_mouse_movement(state.camera, x_offset, y_offset)

      {:ok,
       %{
         state
         | camera: updated_camera,
           last_mouse_x: mouse_x,
           last_mouse_y: mouse_y
       }}
    end
  end

  # Handle scroll wheel (unchanged from 7.4)
  def handle_event({:mouse_wheel, _x, _y, wheel_rotation, _wheel_delta}, state) do
    zoom_delta = wheel_rotation / 120.0 * 2.0
    updated_camera = Camera.process_mouse_scroll(state.camera, zoom_delta)
    {:ok, %{state | camera: updated_camera}}
  end

  def handle_event(_event, state) do
    {:ok, state}
  end
end
