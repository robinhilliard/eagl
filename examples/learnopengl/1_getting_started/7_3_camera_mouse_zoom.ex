defmodule EAGL.Examples.LearnOpenGL.GettingStarted.CameraMouseZoom do
  @moduledoc """
  LearnOpenGL 7.3 - Camera (Mouse + Zoom)

  This example demonstrates advanced camera control using mouse input for look around
  and scroll wheel for zoom control, with two blended textures. The camera responds to mouse movement for
  controlling the look direction (yaw and pitch) and scroll wheel for field of view.
  Combines image texture loading with procedural checkerboard generation for educational comparison.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/src/1.getting_started/7.3.camera_mouse_zoom>

  ## Learning Objectives

  This example teaches:
  - **Mouse Input Processing**: Converting mouse movements to camera rotation
  - **Euler Angle Mathematics**: Understanding yaw/pitch for 3D orientation
  - **Camera Vector Calculation**: Computing front vector from angles
  - **Zoom Implementation**: Using field of view for zoom effects
  - **Complete Camera Control**: Combined keyboard movement with mouse look

  ## Educational Progression

  **7.1**: Automatic camera rotation (circular movement)
  **7.2**: Keyboard movement (WASD) + delta time
  **7.3**: Mouse look + zoom implementation (this example - includes movement)
  **7.4**: Combined system with camera class
  **7.5**: Addressing "flying" camera limitations
  **7.6**: Understanding underlying mathematics

  ## Controls

  - **Mouse Movement**: Look around (yaw and pitch)
  - **Scroll Wheel**: Zoom in/out (field of view)
  - **W/A/S/D**: Move forward/left/backward/right
  - **ENTER**: Exit (when run with enter_to_exit: true)

    **Note**: This example combines the keyboard movement from 7.2 with the mouse look
  and zoom functionality, providing a complete camera control system. Keyboard input
  provides continuous movement while keys are held down, matching the C++ behaviour.

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
  - Narrow FOV (< 45°) = zoomed in (minimum 1°)
  - Wide FOV (45°) = zoomed out (maximum 45°)
  - Clamped to [1°, 45°] to match C++ tutorial range

  ### Texture Blending
  - **Texture1**: Base texture (EAGL logo black on white)
  - **Texture2**: Procedural checkerboard pattern (8-pixel squares, 128x128 resolution)
  - Blended using `mix()` function with 20% overlay (matches C++ tutorial approach)
  - Demonstrates both image loading and procedural texture generation

  This example demonstrates manual camera implementation with mouse controls and texture
  blending, showing both image loading and procedural texture generation techniques.
  """

  use EAGL.Window
  use EAGL.Const

  import EAGL.Shader
  import EAGL.Texture
  import EAGL.Buffer
  import EAGL.Math
  import EAGL.Error
  import Bitwise

  # Camera movement speed (units per second)
  @camera_speed 2.5

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
      • Two texture blending (image + procedural checkerboard)

    Technical Implementation:
      This example demonstrates manual camera implementation with
      mouse look controls and field of view zoom functionality.
      Combined with keyboard movement for complete camera control.

    💡 Controls: WASD to move, mouse to look around, scroll wheel to zoom
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

    # Set up shader uniforms for textures (tell OpenGL which texture units to use)
    :gl.useProgram(program)
    set_uniform(program, "texture1", 0)
    set_uniform(program, "texture2", 1)

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

    # Load first texture (container/wood texture)
    {texture1_result, texture1_id, _width1, _height1} =
      case load_texture_from_file("priv/images/eagl_logo_black_on_white.png") do
        {:ok, id, w, h} -> {:ok, id, w, h}
        {:error, _reason} -> create_checkerboard_texture(256, 32)
      end

    if texture1_result != :ok do
      IO.puts("Warning: Using fallback checkerboard texture for texture1")
    end

    # Create second texture as procedural checkerboard (like 4.2 example)
    {:ok, texture2_id, width2, height2} = create_checkerboard_texture(128, 8)
    IO.puts("Created texture 2: fine checkerboard pattern (#{width2}x#{height2})")

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
    camera_front = vec3(0.0, 0.0, -1.0)
    camera_up = vec3(0.0, 1.0, 0.0)

    # Camera orientation angles
    yaw = -90.0
    pitch = 0.0
    last_mouse_x = 0
    last_mouse_y = 0.0
    fov = 45.0

    {:ok,
     %{
       program: program,
       vao: vao,
       vbo: vbo,
       texture1_id: texture1_id,
       texture2_id: texture2_id,
       cube_positions: cube_positions,
       # Camera position and orientation
       camera_pos: camera_pos,
       camera_front: camera_front,
       camera_up: camera_up,
       # Camera angles and zoom
       yaw: yaw,
       pitch: pitch,
       fov: fov,
       # Timing for delta time
       current_time: current_time,
       last_frame_time: current_time,
       last_mouse_x: last_mouse_x,
       last_mouse_y: last_mouse_y,
       # Flag to ignore first mouse movement
       first_mouse: true
     }}
  end

  @impl true
  def render(viewport_width, viewport_height, state) do
    # Set viewport
    :gl.viewport(0, 0, trunc(viewport_width), trunc(viewport_height))

    # Set clear color and clear screen and depth buffer
    :gl.clearColor(0.2, 0.3, 0.3, 1.0)
    :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)

    # Bind textures on corresponding texture units
    :gl.activeTexture(@gl_texture0)
    :gl.bindTexture(@gl_texture_2d, state.texture1_id)
    :gl.activeTexture(@gl_texture1)
    :gl.bindTexture(@gl_texture_2d, state.texture2_id)

    # Use the shader program
    :gl.useProgram(state.program)

    # Calculate view matrix (matches C++ approach - done each frame)
    target_pos = vec_add(state.camera_pos, state.camera_front)
    view = mat4_look_at(state.camera_pos, target_pos, state.camera_up)

    # Update projection matrix based on current viewport and fov
    aspect_ratio = viewport_width / viewport_height
    projection = mat4_perspective(radians(state.fov), aspect_ratio, 0.1, 100.0)

    # Set matrices using batch API
    set_uniforms(state.program,
      view: view,
      projection: projection
    )

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
    :gl.deleteTextures([state.texture1_id, state.texture2_id])
    :gl.deleteProgram(state.program)
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

    {:ok,
     %{
       state
       | current_time: current_time,
         last_frame_time: current_time,
         camera_pos: new_camera_pos
     }}
  end

  # Handle mouse movement for camera look around
  def handle_event({:mouse_motion, x, y}, state) do
    # Convert to float (ensure proper type)
    mouse_x = x / 1.0
    mouse_y = y / 1.0

    # Skip first mouse movement to avoid sudden jump (matches C++ pattern)
    if state.first_mouse do
      {:ok, %{state | last_mouse_x: mouse_x, last_mouse_y: mouse_y, first_mouse: false}}
    else
      # Calculate mouse offset (matches C++ tutorial exactly)
      x_offset = mouse_x - state.last_mouse_x
      # Reversed since y-coordinates go from bottom to top
      y_offset = state.last_mouse_y - mouse_y

      # Apply mouse sensitivity (using EAGL default of 0.05 for natural feel)
      mouse_sensitivity = 0.05
      x_offset = x_offset * mouse_sensitivity
      y_offset = y_offset * mouse_sensitivity

      # Update yaw and pitch
      new_yaw = state.yaw + x_offset
      new_pitch = state.pitch + y_offset

      # Constrain pitch to prevent camera flipping (matches C++ constraints)
      new_pitch =
        cond do
          new_pitch > 89.0 -> 89.0
          new_pitch < -89.0 -> -89.0
          true -> new_pitch
        end

      # Calculate new camera front vector using exact C++ formula (inlined)
      # Convert degrees to radians for math functions
      yaw_rad = radians(new_yaw)
      pitch_rad = radians(new_pitch)

      # Exact C++ formula:
      # direction.x = cos(glm::radians(yaw)) * cos(glm::radians(pitch));
      # direction.y = sin(glm::radians(pitch));
      # direction.z = sin(glm::radians(yaw)) * cos(glm::radians(pitch));
      front_x = :math.cos(yaw_rad) * :math.cos(pitch_rad)
      front_y = :math.sin(pitch_rad)
      front_z = :math.sin(yaw_rad) * :math.cos(pitch_rad)

      # Ensure the vector is normalized (critical for proper camera behavior)
      new_camera_front = normalize(vec3(front_x, front_y, front_z))

      {:ok,
       %{
         state
         | yaw: new_yaw,
           pitch: new_pitch,
           camera_front: new_camera_front,
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

    # Update field of view with constraints (matches C++ tutorial: 1.0 to 45.0)
    new_fov = clamp(state.fov + zoom_delta, 1.0, 45.0)

    {:ok, %{state | fov: new_fov}}
  end

  # Ignore other events
  def handle_event(_event, state) do
    {:ok, state}
  end
end
