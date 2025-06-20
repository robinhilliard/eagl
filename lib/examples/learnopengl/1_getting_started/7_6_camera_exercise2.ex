defmodule EAGL.Examples.LearnOpenGL.GettingStarted.CameraExercise2 do
  @moduledoc """
  LearnOpenGL 7.6 - Camera Exercise 2: Custom LookAt Implementation

  This exercise implements a **custom LookAt function** that manually calculates
  the view matrix instead of using the built-in camera functionality. This demonstrates
  the mathematical foundations behind camera transformations and provides deeper
  understanding of how view matrices work.

  ## Original Exercise Context

  This corresponds to the LearnOpenGL Camera Exercise 2 which challenges developers to:
  "Create your own LookAt function where you manually create a view matrix as
  discussed at the start of the camera tutorial."

  ## Educational Objectives

  ### Mathematical Understanding
  - **View Matrix Construction**: Manual calculation of view transformation
  - **Coordinate System Building**: Creating right-hand coordinate system from camera orientation
  - **Vector Mathematics**: Cross products, normalisation and vector operations
  - **Matrix Operations**: Translation and rotation matrix combination

  ### Custom LookAt Function
  ```elixir
  # Built-in approach (7.4/7.5)
  view = Camera.get_view_matrix(camera)  # Uses EAGL.Math.mat4_look_at/3

  # Custom implementation (7.6)
  view = custom_look_at(camera_pos, target_pos, up_vector)  # Manual calculation
  ```

  ## Technical Implementation

  ### LookAt Mathematics
  The LookAt function constructs a view matrix by:
  1. **Direction Vector**: Calculate direction from camera to target
  2. **Right Vector**: Cross product of direction and world up
  3. **Up Vector**: Cross product of right and direction vectors
  4. **View Matrix**: Combine rotation and translation components

  ### Matrix Construction
  ```
  View Matrix = Translation * Rotation

  Where:
  - Translation moves world to camera position
  - Rotation orients world to camera coordinate system
  ```

  ## Controls

  - **W/A/S/D**: Move camera position
  - **Mouse Movement**: Rotate camera orientation
  - **Scroll Wheel**: Zoom in/out (field of view)
  - **ENTER**: Exit (when run with enter_to_exit: true)

  ## Educational Value

  This exercise demonstrates:
  - **Matrix Mathematics**: How view matrices are constructed from basic principles
  - **Coordinate Systems**: Building orthonormal coordinate systems in 3D
  - **Camera Theory**: Understanding the relationship between camera position and orientation
  - **Performance Considerations**: Comparing custom vs optimised implementations

  ## Comparison: Built-in vs Custom

  **Built-in LookAt (7.4)**:
  - Uses optimised `EAGL.Math.mat4_look_at/3`
  - Handles edge cases and optimisations
  - Less educational but more practical

  **Custom LookAt (7.6)**:
  - Manual vector and matrix calculations
  - Step-by-step view matrix construction
  - Educational insight into camera mathematics
  - Demonstrates underlying principles

  This exercise provides the mathematical foundation for understanding all 3D camera systems.
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
      "LearnOpenGL 7.6 - Camera Exercise 2 (Custom LookAt)",
      Keyword.merge([depth_testing: true, enter_to_exit: true], opts)
    )
  end

  @impl true
  def setup do
    IO.puts("""

    === LearnOpenGL 7.6: Camera Exercise 2 (Custom LookAt) ===
    This exercise demonstrates the mathematics behind camera transformations
    by implementing a custom LookAt function from scratch.

    🎯 Learning Focus:
      • Understanding view matrix mathematics
      • Manual coordinate system construction
      • Vector operations: cross products, normalisation
      • Matrix mathematics for 3D transformations

    🧮 Mathematical Concepts:
      • Building orthonormal basis vectors (right, up, forward)
      • Cross product for perpendicular vector calculation
      • Matrix composition: rotation + translation = view matrix
      • Coordinate space transformations (world → camera)

    🔍 Custom LookAt Steps:
      1. Calculate direction vector (eye → target)
      2. Calculate right vector (direction × world_up)
      3. Calculate camera up vector (right × direction)
      4. Build view matrix from basis vectors + translation

    ⚙️  Implementation Comparison:
      Built-in: Camera.get_view_matrix() - uses EAGL.Math.mat4_look_at()
      Custom:   custom_look_at() - manual step-by-step calculation

    Camera works identically, but you understand the math behind it.
    ================================================
    """)

    # Compile shaders
    {:ok, vertex} =
      create_shader(
        @gl_vertex_shader,
        "learnopengl/1_getting_started/7_6_camera_exercise2/vertex_shader.glsl"
      )

    {:ok, fragment} =
      create_shader(
        @gl_fragment_shader,
        "learnopengl/1_getting_started/7_6_camera_exercise2/fragment_shader.glsl"
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

    # Cube positions in interesting arrangement
    cube_positions = [
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

    # Create camera
    camera =
      Camera.new(
        position: vec3(0.0, 0.0, 3.0),
        yaw: -90.0,
        pitch: 0.0,
        movement_speed: 2.5,
        # Reduced for natural first-person feel
        mouse_sensitivity: 0.1,
        zoom: 45.0
      )

    current_time = :erlang.monotonic_time(:millisecond) / 1000.0

    {:ok,
     %{
       program: program,
       vao: vao,
       vbo: vbo,
       texture_id: texture_id,
       cube_positions: cube_positions,
       camera: camera,
       current_time: current_time,
       last_frame_time: current_time,
       last_mouse_x: 400.0,
       last_mouse_y: 300.0,
       first_mouse: true,
       keys_pressed: %{}
     }}
  end

  @impl true
  def render(viewport_width, viewport_height, state) do
    # Set viewport
    :gl.viewport(0, 0, trunc(viewport_width), trunc(viewport_height))

    # Clear screen
    :gl.clearColor(0.2, 0.3, 0.3, 1.0)
    :gl.clear(Bitwise.bor(@gl_color_buffer_bit, @gl_depth_buffer_bit))

    # Bind texture
    :gl.activeTexture(@gl_texture0)
    :gl.bindTexture(@gl_texture_2d, state.texture_id)

    # Use shader program
    :gl.useProgram(state.program)

    # Get camera properties
    camera_pos = state.camera.position
    camera_front = state.camera.front
    camera_up = state.camera.up

    # Calculate target position
    target = vec_add(camera_pos, camera_front)

    # Use custom LookAt function instead of built-in
    view = custom_look_at(camera_pos, target, camera_up)

    # Create projection matrix
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

    # Process movement using standard camera
    updated_camera =
      Enum.reduce(state.keys_pressed, state.camera, fn {key, _pressed}, camera ->
        case key do
          :w -> Camera.process_keyboard(camera, :forward, delta_time)
          :s -> Camera.process_keyboard(camera, :backward, delta_time)
          :a -> Camera.process_keyboard(camera, :left, delta_time)
          :d -> Camera.process_keyboard(camera, :right, delta_time)
          _ -> camera
        end
      end)

    {:ok,
     %{
       state
       | current_time: current_time,
         last_frame_time: current_time,
         camera: updated_camera,
         keys_pressed: %{}
     }}
  end

  # Handle keyboard input
  def handle_event({:key, key_code}, state) do
    case key_code do
      # W
      87 -> {:ok, %{state | keys_pressed: Map.put(state.keys_pressed, :w, true)}}
      # S
      83 -> {:ok, %{state | keys_pressed: Map.put(state.keys_pressed, :s, true)}}
      # A
      65 -> {:ok, %{state | keys_pressed: Map.put(state.keys_pressed, :a, true)}}
      # D
      68 -> {:ok, %{state | keys_pressed: Map.put(state.keys_pressed, :d, true)}}
      _ -> {:ok, state}
    end
  end

  # Handle mouse movement
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

  # Handle scroll wheel
  def handle_event({:mouse_wheel, _x, _y, wheel_rotation, _wheel_delta}, state) do
    zoom_delta = wheel_rotation / 120.0 * 2.0
    updated_camera = Camera.process_mouse_scroll(state.camera, zoom_delta)
    {:ok, %{state | camera: updated_camera}}
  end

  def handle_event(_event, state) do
    {:ok, state}
  end

  # Custom LookAt Function - The core of this exercise
  # This manually implements the mathematics behind view matrix calculation
  # Following the EXACT approach from LearnOpenGL Camera Exercise 2 C++ source
  defp custom_look_at(eye, center, up) do
    # Step 1: Calculate zaxis (from target to eye - this becomes camera's forward direction)
    # Note: This is OPPOSITE to the direction the camera looks (which is why it's negated later)
    zaxis = normalize(vec_sub(eye, center))

    # Step 2: Calculate xaxis (right vector) using cross product of world up and zaxis
    # This follows the C++ version: glm::cross(glm::normalize(worldUp), zaxis)
    xaxis = normalize(cross(up, zaxis))

    # Step 3: Calculate yaxis (camera up vector) using cross product of zaxis and xaxis
    # This ensures we have a proper orthonormal basis
    yaxis = cross(zaxis, xaxis)

    # Step 4: Extract vector components for matrix construction
    [{eye_x, eye_y, eye_z}] = eye
    [{x_x, x_y, x_z}] = xaxis
    [{y_x, y_y, y_z}] = yaxis
    [{z_x, z_y, z_z}] = zaxis

    # Step 5: Build separate translation and rotation matrices, then combine
    # Following C++ approach: rotation * translation

    # Translation matrix: move world by negative camera position
    translation = [
      {
        # Column 0
        1.0,
        0.0,
        0.0,
        0.0,
        # Column 1
        0.0,
        1.0,
        0.0,
        0.0,
        # Column 2
        0.0,
        0.0,
        1.0,
        0.0,
        # Column 3: negative camera position
        -eye_x,
        -eye_y,
        -eye_z,
        1.0
      }
    ]

    # Rotation matrix: basis vectors arranged as columns
    # C++ fills this as: rotation[col][row] = value
    # Our column-major format: {col0_r0, col0_r1, col0_r2, col0_r3, col1_r0, ...}
    rotation = [
      {
        # Column 0: right vector (xaxis)
        x_x,
        x_y,
        x_z,
        0.0,
        # Column 1: up vector (yaxis)
        y_x,
        y_y,
        y_z,
        0.0,
        # Column 2: forward vector (zaxis)
        z_x,
        z_y,
        z_z,
        0.0,
        # Column 3: no translation
        0.0,
        0.0,
        0.0,
        1.0
      }
    ]

    # Step 6: Combine matrices (rotation * translation)
    # This matches the C++ version: return rotation * translation
    mat4_mul(rotation, translation)
  end
end
