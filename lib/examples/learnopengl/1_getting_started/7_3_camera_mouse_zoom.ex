defmodule EAGL.Examples.LearnOpenGL.GettingStarted.CameraMouseZoom do
  @moduledoc """
  LearnOpenGL 7.3 - Camera (Mouse + Zoom)

  This example demonstrates advanced camera control using mouse input for look around
  and scroll wheel for zoom control. The camera responds to mouse movement for
  controlling the look direction (yaw and pitch) and scroll wheel for field of view.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/src/1.getting_started/7.3.camera_mouse_zoom>

  ## Learning Objectives

  This example teaches:
  - **Mouse Input Processing**: Converting mouse movements to camera rotation
  - **Euler Angle Mathematics**: Understanding yaw/pitch for 3D orientation
  - **Camera Vector Calculation**: Computing front vector from angles
  - **Zoom Implementation**: Using field of view for zoom effects
  - **Input State Management**: Handling continuous input processing

  ## Pedagogical Design Notes

  **⚠️ INTENTIONAL LIMITATIONS (For Learning)**

  This example uses a **simplified manual camera implementation** that exhibits
  some unnatural behaviours that students should notice:

  1. **"World Rotation" Feel**: Camera control may feel like rotating the entire
     world rather than natural first-person movement
  2. **Manual State Tracking**: Complex manual management of camera vectors and state
  3. **Code Duplication**: Repetitive camera calculations spread throughout the code

  **These limitations are pedagogically intentional** and represent the natural
  progression of camera system development. They demonstrate:
  - The complexity of manual camera implementation
  - The need for better abstractions (addressed in 7.4)
  - Common pitfalls when building camera systems from scratch

  ## Educational Progression

  **7.1-7.2**: Basic movement concepts
  **7.3**: Mouse look + manual implementation (this example)
  **7.4**: Code organisation with camera class
  **7.5**: Addressing "flying" camera limitations
  **7.6**: Understanding underlying mathematics

  ## Controls

  - **Mouse Movement**: Look around (yaw and pitch)
  - **Scroll Wheel**: Zoom in/out (field of view)
  - **ENTER**: Exit (when run with enter_to_exit: true)

  ## Technical Implementation

  ### Mouse Look Mathematics
  - **Yaw**: Horizontal rotation around the world Y-axis
  - **Pitch**: Vertical rotation around the camera's right vector
  - **Constraints**: Pitch clamped to [-89°, 89°] to prevent gimbal lock

  ### Camera Front Vector Calculation
  ```
  front.x = cos(yaw) * cos(pitch)
  front.y = sin(pitch)
  front.z = sin(yaw) * cos(pitch)
  ```

  ### Field of View Zoom
  - Narrow FOV (< 45°) = zoomed in
  - Wide FOV (> 45°) = zoomed out
  - Clamped to [1°, 45°] for practical range

  **Note**: The camera behaviour in this example represents an early stage of camera
  development. Students should observe the limitations and consider how they might be
  improved - these observations lead naturally to the solutions presented in examples 7.4-7.6.
  """

  use EAGL.Window
  use EAGL.Const

  import EAGL.Shader
  import EAGL.Texture
  import EAGL.Buffer
  import EAGL.Math
  import EAGL.Error

  def run_example(opts \\ []) do
    EAGL.Window.run(
      __MODULE__,
      "LearnOpenGL 7.3 - Camera (Mouse + Zoom)",
      Keyword.merge([depth_testing: true, enter_to_exit: true], opts)
    )
  end

  @impl true
  def setup do
    IO.puts("""

    === LearnOpenGL 7.3: Camera (Mouse + Zoom) ===
    This example demonstrates mouse look and zoom with manual camera implementation.

    🎯 Learning Focus:
      • Mouse input processing for camera rotation
      • Manual camera vector calculations
      • Field of view zoom implementation

    ⚠️  Pedagogical Note:
      This example uses simplified manual camera implementation.
      You may notice the camera feels like 'rotating the world'
      rather than natural first-person movement.

      This behaviour is intentionally preserved from the original
      LearnOpenGL tutorial to demonstrate the need for better
      camera abstractions (introduced in 7.4).

    💡 Controls: Move mouse to look around, scroll wheel to zoom
    =====================================
    """)

    # Compile shaders
    {:ok, vertex} =
      create_shader(
        @gl_vertex_shader,
        "learnopengl/1_getting_started/7_3_camera_mouse_zoom/vertex_shader.glsl"
      )

    {:ok, fragment} =
      create_shader(
        @gl_fragment_shader,
        "learnopengl/1_getting_started/7_3_camera_mouse_zoom/fragment_shader.glsl"
      )

    {:ok, program} = create_attach_link([vertex, fragment])

    # Create cube with texture coordinates
    # Each face needs texture coordinates for proper texturing
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

    # Create vertex array with position and texture coordinate attributes
    {vao, vbo} = create_vertex_array(vertices, vertex_attributes(:position, :texture_coordinate))

    # Load texture (with fallback to checkerboard if image loading unavailable)
    {texture_result, texture_id, _width, _height} =
      case load_texture_from_file("priv/images/eagl_logo_black_on_white.png") do
        {:ok, id, w, h} -> {:ok, id, w, h}
        {:error, _reason} -> create_checkerboard_texture(256, 32)
      end

    if texture_result != :ok do
      IO.puts("Warning: Using fallback checkerboard texture")
    end

    check("After setup")

    # Multiple cube positions for a more interesting scene
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

    # Initialize camera state
    current_time = :erlang.monotonic_time(:millisecond) / 1000.0

    # Initial camera parameters
    camera_pos = vec3(0.0, 0.0, 3.0)
    camera_up = vec3(0.0, 1.0, 0.0)

    # Camera orientation angles
    # Start looking down negative Z-axis
    yaw = -90.0
    # Start level (no up/down tilt)
    pitch = 0.0
    # Field of view in degrees (middle of 1-45 range)
    fov = 25.0

    # Calculate initial camera front vector from yaw and pitch
    camera_front = calculate_front_vector(yaw, pitch)

    # Calculate initial view matrix
    target_pos = vec_add(camera_pos, camera_front)
    view = mat4_look_at(camera_pos, target_pos, camera_up)

    {:ok,
     %{
       program: program,
       vao: vao,
       vbo: vbo,
       texture_id: texture_id,
       cube_positions: cube_positions,
       # Camera position and orientation
       camera_pos: camera_pos,
       camera_front: camera_front,
       camera_up: camera_up,
       # Camera angles and zoom
       yaw: yaw,
       pitch: pitch,
       fov: fov,
       # Pre-calculated view matrix
       view: view,
       # Timing for delta time
       current_time: current_time,
       last_frame_time: current_time,
       # Mouse state
       # Center of typical window
       last_mouse_x: 400.0,
       last_mouse_y: 300.0,
       # Flag to ignore first mouse movement
       first_mouse: true,
       mouse_sensitivity: 0.1,
       # Input state
       keys_pressed: %{}
     }}
  end

  @impl true
  def render(viewport_width, viewport_height, state) do
    # Set viewport
    :gl.viewport(0, 0, trunc(viewport_width), trunc(viewport_height))

    # Set clear color and clear screen and depth buffer
    :gl.clearColor(0.2, 0.3, 0.3, 1.0)
    :gl.clear(Bitwise.bor(@gl_color_buffer_bit, @gl_depth_buffer_bit))

    # Bind texture
    :gl.activeTexture(@gl_texture0)
    :gl.bindTexture(@gl_texture_2d, state.texture_id)

    # Use the shader program
    :gl.useProgram(state.program)

    # Update projection matrix based on current viewport and fov
    aspect_ratio = viewport_width / viewport_height
    projection = mat4_perspective(radians(state.fov), aspect_ratio, 0.1, 20.0)

    # Set matrices: view is pre-calculated in state when camera moves, projection calculated for current viewport
    set_uniform(state.program, "view", state.view)
    set_uniform(state.program, "projection", projection)

    # Bind the vertex array
    :gl.bindVertexArray(state.vao)

    # Render multiple cubes at different positions
    Enum.with_index(state.cube_positions, fn cube_pos, i ->
      # Calculate model matrix for this cube
      angle = 20.0 * i

      model =
        mat4_translate(cube_pos) |> mat4_mul(mat4_rotate(vec3(1.0, 0.3, 0.5), radians(angle)))

      # Set model uniform
      set_uniform(state.program, "model", model)

      # Draw the cube
      :gl.drawArrays(@gl_triangles, 0, 36)
    end)

    check("After render")
    :ok
  end

  @impl true
  def cleanup(state) do
    # Clean up OpenGL resources
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

    # Process camera movement based on currently pressed keys
    new_camera_pos =
      process_camera_movement(
        state.camera_pos,
        state.camera_front,
        state.keys_pressed,
        delta_time
      )

    # Recalculate view matrix if camera position changed
    new_view =
      if new_camera_pos != state.camera_pos do
        target_pos = vec_add(new_camera_pos, state.camera_front)
        mat4_look_at(new_camera_pos, target_pos, state.camera_up)
      else
        state.view
      end

    # Clear keys pressed (they'll be re-added if still pressed)
    new_keys = %{}

    {:ok,
     %{
       state
       | current_time: current_time,
         last_frame_time: current_time,
         camera_pos: new_camera_pos,
         view: new_view,
         keys_pressed: new_keys
     }}
  end

  # Handle keyboard input for camera movement (WASD)
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

  # Handle mouse movement for camera look around
  def handle_event({:mouse_motion, x, y}, state) do
    # Convert to float
    mouse_x = x * 1.0
    mouse_y = y * 1.0

    # Skip first mouse movement to avoid sudden jump
    if state.first_mouse do
      {:ok, %{state | last_mouse_x: mouse_x, last_mouse_y: mouse_y, first_mouse: false}}
    else
      # Calculate mouse offset
      x_offset = (mouse_x - state.last_mouse_x) * state.mouse_sensitivity
      # Reversed since y-coordinates go from bottom to top
      y_offset = (state.last_mouse_y - mouse_y) * state.mouse_sensitivity

      # Update yaw and pitch
      new_yaw = state.yaw + x_offset
      # Constrain pitch to prevent camera flipping
      new_pitch = clamp(state.pitch + y_offset, -89.0, 89.0)

      # Calculate new camera front vector
      new_camera_front = calculate_front_vector(new_yaw, new_pitch)

      # Recalculate view matrix
      target_pos = vec_add(state.camera_pos, new_camera_front)
      new_view = mat4_look_at(state.camera_pos, target_pos, state.camera_up)

      {:ok,
       %{
         state
         | yaw: new_yaw,
           pitch: new_pitch,
           camera_front: new_camera_front,
           view: new_view,
           last_mouse_x: mouse_x,
           last_mouse_y: mouse_y
       }}
    end
  end

  # Handle scroll wheel for zoom control
  def handle_event({:mouse_wheel, _x, _y, wheel_rotation, _wheel_delta}, state) do
    # wheel_rotation is typically -120 (scroll up) or +120 (scroll down)
    # Convert to a smaller zoom delta - scroll up should zoom in (reduce FOV)
    # Positive rotation increases FOV (zoom out)
    zoom_delta = wheel_rotation / 120.0 * 2.0

    # Update field of view with constraints
    new_fov = clamp(state.fov + zoom_delta, 1.0, 45.0)

    {:ok, %{state | fov: new_fov}}
  end

  # Ignore other events
  def handle_event(_event, state) do
    {:ok, state}
  end

  # Private helper functions

  # Calculate camera front vector from yaw and pitch angles
  defp calculate_front_vector(yaw, pitch) do
    # Convert degrees to radians for math functions
    yaw_rad = radians(yaw)
    pitch_rad = radians(pitch)

    front_x = :math.cos(yaw_rad) * :math.cos(pitch_rad)
    front_y = :math.sin(pitch_rad)
    front_z = :math.sin(yaw_rad) * :math.cos(pitch_rad)

    normalize(vec3(front_x, front_y, front_z))
  end

  # Process camera movement based on pressed keys
  defp process_camera_movement(camera_pos, camera_front, keys_pressed, delta_time) do
    camera_speed = 2.5 * delta_time

    # Calculate right vector (perpendicular to front and up)
    camera_right = normalize(cross(camera_front, vec3(0.0, 1.0, 0.0)))

    # Apply movement based on pressed keys
    new_pos = camera_pos

    new_pos =
      if Map.get(keys_pressed, :w, false) do
        vec_add(new_pos, vec_scale(camera_front, camera_speed))
      else
        new_pos
      end

    new_pos =
      if Map.get(keys_pressed, :s, false) do
        vec_sub(new_pos, vec_scale(camera_front, camera_speed))
      else
        new_pos
      end

    new_pos =
      if Map.get(keys_pressed, :a, false) do
        vec_sub(new_pos, vec_scale(camera_right, camera_speed))
      else
        new_pos
      end

    new_pos =
      if Map.get(keys_pressed, :d, false) do
        vec_add(new_pos, vec_scale(camera_right, camera_speed))
      else
        new_pos
      end

    new_pos
  end
end
