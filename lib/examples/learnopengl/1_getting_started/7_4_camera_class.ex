defmodule EAGL.Examples.LearnOpenGL.GettingStarted.CameraClass do
  @moduledoc """
  LearnOpenGL 7.4 - Camera Class

  This example demonstrates the power of proper camera abstraction using the EAGL.Camera
  module. It provides smooth, natural first-person camera controls with WASD movement,
  mouse look, and scroll zoom functionality.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/src/1.getting_started/7.4.camera_class>

  ## Learning Objectives

  This example teaches:
  - **Camera Abstraction**: Encapsulating complex camera mathematics in a clean API
  - **Code Organisation**: Moving from scattered manual implementation to modular design
  - **Software Engineering**: Benefits of abstraction, encapsulation, and tested code
  - **API Design**: Simple, intuitive interfaces hiding complex functionality

  ## Educational Progression Context

  **7.1-7.3**: Manual camera implementation with increasing complexity
  **7.4**: Code organisation and abstraction (this example)
  **7.5**: Addressing specific camera behavior limitations
  **7.6**: Understanding the mathematical foundations

  This example represents a crucial step in the learning progression - moving from
  "how to implement camera controls" to "how to organize and structure camera code."

  ## Key Improvements Over 7.3

  ### Code Simplification
  ```elixir
  # Manual Implementation (7.3) - Complex and error-prone
  camera_pos: camera_pos,
  camera_front: camera_front,
  camera_up: camera_up,
  yaw: yaw,
  pitch: pitch,
  fov: fov,
  # Plus manual front vector calculation...
  # Plus manual movement processing...
  # Plus manual mouse handling...

  # Camera Class (7.4) - Clean and maintainable
  camera: Camera.new(position: vec3(0.0, 0.0, 3.0))
  camera = Camera.process_keyboard(camera, :forward, delta_time)
  camera = Camera.process_mouse_movement(camera, x_offset, y_offset)
  view = Camera.get_view_matrix(camera)
  ```

  ### Technical Benefits
  - **Encapsulation**: Camera state contained in single struct
  - **Tested Implementation**: Reduces manual calculation errors
  - **Clean API**: Simple function calls replace complex manual code
  - **Maintainability**: Changes to camera behavior centralized
  - **Mouse Sensitivity**: Automatically adjusted for natural first-person feel

  ## Controls

  - **W/A/S/D**: Move forward/left/backward/right
  - **Mouse Movement**: Look around (first-person view)
  - **Scroll Wheel**: Zoom in/out (field of view)
  - **ENTER**: Exit (when run with enter_to_exit: true)

  ## Camera Features Demonstrated

  - **Encapsulated Movement**: Simple function calls for complex movement logic
  - **Automatic Vector Management**: Front/right/up vectors maintained automatically
  - **Pitch Constraints**: Prevents camera flipping (±89° limit)
  - **Delta Time**: Frame-rate independent movement
  - **Zoom Control**: Field of view adjustment (1° to 45° range)

  ## Educational Value

  This example demonstrates fundamental software engineering principles:
  - **Abstraction**: Complex camera math hidden behind simple API
  - **Encapsulation**: Related functionality grouped in cohesive module
  - **Reusability**: Camera implementation can be used across multiple projects
  - **Maintainability**: Bug fixes and improvements centralized
  - **Focus**: Developers can focus on content rather than camera implementation details

  **Pedagogical Note**: While this example significantly improves code organization
  and reduces complexity, some advanced camera behaviors (like FPS ground constraints
  and mathematical understanding) are explored in exercises 7.5 and 7.6.

  The progression from manual implementation (7.1-7.3) to camera class (7.4) to
  specialized exercises (7.5-7.6) demonstrates both practical software development
  and deeper understanding of 3D camera systems.
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
      "LearnOpenGL 7.4 - Camera Class",
      Keyword.merge([depth_testing: true, enter_to_exit: true], opts)
    )
  end

  @impl true
  def setup do
    IO.puts("""

    === LearnOpenGL 7.4: Camera Class ===
    This example demonstrates the benefits of camera abstraction and
    code organisation using the EAGL.Camera module.

    Learning Focus:
      • Camera abstraction and encapsulation
      • Code organisation and maintainability
      • Clean API design for complex functionality
      • Reducing manual camera implementation complexity

    ✅ Improvements over 7.3:
      • Simplified code: Camera.process_keyboard() vs manual calculations
      • Encapsulated state: Single camera struct vs scattered variables
      • Tested implementation: Reduced bugs from manual math errors
      • Cleaner rendering: Camera.get_view_matrix() vs manual matrix building

    Technical Benefits:
      • Mouse sensitivity automatically adjusted for natural first-person feel
      • Pitch constraints prevent camera flipping (±89° limit)
      • Frame-rate independent movement with delta time
      • Orthonormal camera vectors maintained automatically

    Controls: WASD to move, mouse to look around, scroll wheel to zoom
    ==========================================
    """)

    # Compile shaders
    {:ok, vertex} =
      create_shader(
        @gl_vertex_shader,
        "learnopengl/1_getting_started/7_4_camera_class/vertex_shader.glsl"
      )

    {:ok, fragment} =
      create_shader(
        @gl_fragment_shader,
        "learnopengl/1_getting_started/7_4_camera_class/fragment_shader.glsl"
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

    # Create camera using EAGL.Camera module
    # This encapsulates the manual camera state from example 7.3
    camera =
      Camera.new(
        position: vec3(0.0, 0.0, 3.0),
        yaw: -90.0,
        pitch: 0.0,
        movement_speed: 2.5,
        mouse_sensitivity: 0.05,
        zoom: 45.0
      )

    # Initialize timing for delta time calculation
    current_time = :erlang.monotonic_time(:millisecond) / 1000.0

    {:ok,
     %{
       program: program,
       vao: vao,
       vbo: vbo,
       texture_id: texture_id,
       cube_positions: cube_positions,
       # Simple camera state - just the camera struct
       camera: camera,
       # Timing for frame-rate independent movement
       current_time: current_time,
       last_frame_time: current_time,
       # Mouse state for tracking movement
       last_mouse_x: 400.0,
       last_mouse_y: 300.0,
       first_mouse: true,
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

    # Get matrices from camera - much cleaner than manual calculation
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

    # Process camera movement using the Camera module
    # This demonstrates cleaner code organisation compared to 7.3's manual processing
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

    # Clear keys pressed (they'll be re-added if still pressed)
    new_keys = %{}

    {:ok,
     %{
       state
       | current_time: current_time,
         last_frame_time: current_time,
         camera: updated_camera,
         keys_pressed: new_keys
     }}
  end

  # Handle keyboard input for camera movement (WASD)
  def handle_event({:key, key_code}, state) do
    case key_code do
      # W - forward
      87 -> {:ok, %{state | keys_pressed: Map.put(state.keys_pressed, :w, true)}}
      # S - backward
      83 -> {:ok, %{state | keys_pressed: Map.put(state.keys_pressed, :s, true)}}
      # A - strafe left
      65 -> {:ok, %{state | keys_pressed: Map.put(state.keys_pressed, :a, true)}}
      # D - strafe right
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
      x_offset = mouse_x - state.last_mouse_x
      # Reversed since y-coordinates go from bottom to top
      y_offset = state.last_mouse_y - mouse_y

      # Process mouse movement using Camera module
      # This encapsulates the yaw/pitch/front vector calculations from 7.3
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

  # Handle scroll wheel for zoom control
  def handle_event({:mouse_wheel, _x, _y, wheel_rotation, _wheel_delta}, state) do
    # wheel_rotation is typically -120 (scroll up) or +120 (scroll down)
    # Convert to a smaller zoom delta
    zoom_delta = wheel_rotation / 120.0 * 2.0

    # Process scroll using Camera module
    # This encapsulates the FOV calculation and clamping from 7.3
    updated_camera = Camera.process_mouse_scroll(state.camera, zoom_delta)

    {:ok, %{state | camera: updated_camera}}
  end

  # Ignore other events
  def handle_event(_event, state) do
    {:ok, state}
  end
end
