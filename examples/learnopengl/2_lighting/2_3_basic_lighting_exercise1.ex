defmodule EAGL.Examples.LearnOpenGL.Lighting.BasicLightingExercise1 do
  @moduledoc """
  LearnOpenGL 2.3 - Basic Lighting Exercise 1 (Animated Light)

  This exercise demonstrates animated lighting by making the light source move over time.
  The light position changes dynamically using sine functions, creating a moving light
  that illuminates the cube from different angles as time progresses.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://learnopengl.com/code_viewer_gh.php?code=src/2.lighting/2.3.basic_lighting_exercise1/basic_lighting_exercise1.cpp>

  ## Framework Adaptation Notes

  This exercise demonstrates:
  - Dynamic light position animation using mathematical functions
  - Time-based lighting effects
  - How changing light position affects illumination across surfaces
  - The same Phong lighting model with a moving light source

  ## Key Learning Points

  - **Dynamic Lighting**: Light sources can move and change over time
  - **Temporal Effects**: Using time functions to create smooth animations
  - **Mathematical Animation**: Sine and cosine functions for smooth motion
  - **Lighting Behavior**: How light position affects surface illumination

  ## Animation Details

  The light position is animated using:
  ```
  light_pos.x = 1.0 + sin(time) * 2.0    # Oscillates between -1.0 and 3.0
  light_pos.y = sin(time / 2.0) * 1.0    # Oscillates between -1.0 and 1.0 (slower)
  light_pos.z = 2.0                      # Constant depth
  ```

  This creates a figure-8-like motion where the light moves:
  - Horizontally with a period of 2π seconds
  - Vertically with a period of 4π seconds (half the horizontal frequency)
  - The different frequencies create interesting lighting patterns

  ## Visual Effects

  The scene shows:
  - A coral-coloured cube with lighting that changes as the light moves
  - Specular highlights that shift position as the light travels
  - Different faces becoming brighter or darker as the light passes by
  - The light source cube moving in a smooth, predictable pattern
  - Dynamic shadows and illumination demonstrating light direction effects

  ## Technical Implementation

  - Uses the same Phong lighting shaders as Exercise 2.2
  - Light position is calculated in Elixir and passed as a uniform
  - Animation timing uses Erlang's monotonic time for smooth motion
  - Mathematical functions create predictable, smooth movement patterns
  - **Batch Uniform Setting**: Uses `set_uniforms/2` for cleaner, more efficient uniform management

  ## Educational Value

  This exercise helps students understand:
  - How light position affects surface illumination
  - The relationship between light movement and visual changes
  - Time-based animation in graphics programming
  - The practical effects of the Phong lighting model with moving sources

  ## Controls

  - **W/A/S/D**: Move camera forward/left/backward/right
  - **Mouse Movement**: Look around (first-person view)
  - **Scroll Wheel**: Zoom in/out (field of view)
  - **ENTER**: Exit

  ## Usage

      EAGL.Examples.LearnOpenGL.Lighting.BasicLightingExercise1.run_example()

  Press ENTER to exit.
  """

  use EAGL.Window
  use EAGL.Const

  import Bitwise
  import EAGL.Shader
  import EAGL.Buffer
  import EAGL.Error
  import EAGL.Math
  alias EAGL.Camera

  # 3D cube vertex data with positions and normals (6 floats per vertex)
  @vertices ~v'''
  # positions        normals
  -0.5 -0.5 -0.5    0.0  0.0 -1.0
   0.5 -0.5 -0.5    0.0  0.0 -1.0
   0.5  0.5 -0.5    0.0  0.0 -1.0
   0.5  0.5 -0.5    0.0  0.0 -1.0
  -0.5  0.5 -0.5    0.0  0.0 -1.0
  -0.5 -0.5 -0.5    0.0  0.0 -1.0

  -0.5 -0.5  0.5    0.0  0.0  1.0
   0.5 -0.5  0.5    0.0  0.0  1.0
   0.5  0.5  0.5    0.0  0.0  1.0
   0.5  0.5  0.5    0.0  0.0  1.0
  -0.5  0.5  0.5    0.0  0.0  1.0
  -0.5 -0.5  0.5    0.0  0.0  1.0

  -0.5  0.5  0.5   -1.0  0.0  0.0
  -0.5  0.5 -0.5   -1.0  0.0  0.0
  -0.5 -0.5 -0.5   -1.0  0.0  0.0
  -0.5 -0.5 -0.5   -1.0  0.0  0.0
  -0.5 -0.5  0.5   -1.0  0.0  0.0
  -0.5  0.5  0.5   -1.0  0.0  0.0

   0.5  0.5  0.5    1.0  0.0  0.0
   0.5  0.5 -0.5    1.0  0.0  0.0
   0.5 -0.5 -0.5    1.0  0.0  0.0
   0.5 -0.5 -0.5    1.0  0.0  0.0
   0.5 -0.5  0.5    1.0  0.0  0.0
   0.5  0.5  0.5    1.0  0.0  0.0

  -0.5 -0.5 -0.5    0.0 -1.0  0.0
   0.5 -0.5 -0.5    0.0 -1.0  0.0
   0.5 -0.5  0.5    0.0 -1.0  0.0
   0.5 -0.5  0.5    0.0 -1.0  0.0
  -0.5 -0.5  0.5    0.0 -1.0  0.0
  -0.5 -0.5 -0.5    0.0 -1.0  0.0

  -0.5  0.5 -0.5    0.0  1.0  0.0
   0.5  0.5 -0.5    0.0  1.0  0.0
   0.5  0.5  0.5    0.0  1.0  0.0
   0.5  0.5  0.5    0.0  1.0  0.0
  -0.5  0.5  0.5    0.0  1.0  0.0
  -0.5  0.5 -0.5    0.0  1.0  0.0
  '''

  @light_scale vec3(0.2, 0.2, 0.2)

  @spec run_example() :: :ok | {:error, term()}
  def run_example(opts \\ []) do
    default_opts = [depth_testing: true, enter_to_exit: true]
    merged_opts = Keyword.merge(default_opts, opts)

    EAGL.Window.run(
      __MODULE__,
      "LearnOpenGL - 2 Lighting - 2.3 Basic Lighting Exercise 1 (Animated Light)",
      merged_opts
    )
  end

  @impl true
  def setup do
    IO.puts("""

    === LearnOpenGL 2.3 - Basic Lighting Exercise 1 (Animated Light) ===
    This exercise demonstrates dynamic lighting effects by animating the light source
    position over time using mathematical functions.

    Key Concepts:
    - Dynamic Light Position: Light sources can move and change over time
    - Mathematical Animation: Using sine and cosine for smooth, predictable motion
    - Temporal Lighting Effects: How moving light affects surface illumination
    - Time-Based Graphics: Incorporating time into rendering calculations

    Animation Formula:
    - X Position: 1.0 + sin(time) * 2.0 (oscillates between -1.0 and 3.0)
    - Y Position: sin(time / 2.0) * 1.0 (oscillates between -1.0 and 1.0, half frequency)
    - Z Position: 2.0 (constant depth)

    Motion Pattern:
    - The light traces a figure-8-like pattern in 3D space
    - Horizontal motion has twice the frequency of vertical motion
    - This creates interesting, non-repetitive lighting effects
    - The pattern repeats every 4π seconds (approximately 12.6 seconds)

    Visual Effects You'll Notice:
    - Specular highlights move across the cube faces as the light travels
    - Different cube faces become brighter or darker as the light passes
    - The cube appears more three-dimensional due to changing shadows
    - The white light source cube follows a smooth, predictable path
    - Lighting intensity varies based on the light's distance from surfaces

    Technical Implementation:
    - Same Phong lighting shaders as previous exercises
    - Light position calculated in Elixir using time-based functions
    - Smooth animation using Erlang's monotonic time system
    - Position updates sent to GPU as uniform variables each frame

    Educational Benefits:
    - Demonstrates the relationship between light position and surface illumination
    - Shows how mathematical functions create smooth animations
    - Illustrates the dynamic nature of computer graphics
    - Provides foundation for more complex lighting animations

    Try This:
    - Move the camera to different positions to see how the lighting looks from various angles
    - Notice how the cube's appearance changes as the light moves behind or in front of it
    - Observe how specular highlights follow the light movement

    Controls: WASD to move, mouse to look around, scroll wheel to zoom
    ========================================================================
    """)

    # Compile and link lighting shader
    with {:ok, lighting_vertex_shader} <-
           create_shader(
             @gl_vertex_shader,
             "learnopengl/2_lighting/2_3_basic_lighting_exercise1/lighting_vertex_shader.glsl"
           ),
         {:ok, lighting_fragment_shader} <-
           create_shader(
             @gl_fragment_shader,
             "learnopengl/2_lighting/2_3_basic_lighting_exercise1/lighting_fragment_shader.glsl"
           ),
         {:ok, lighting_program} <-
           create_attach_link([lighting_vertex_shader, lighting_fragment_shader]) do
      IO.puts("Basic lighting exercise 1 shader program compiled and linked successfully")

      # Compile and link light cube shader
      {:ok, light_cube_vertex_shader} =
        create_shader(
          @gl_vertex_shader,
          "learnopengl/2_lighting/2_3_basic_lighting_exercise1/light_cube_vertex_shader.glsl"
        )

      {:ok, light_cube_fragment_shader} =
        create_shader(
          @gl_fragment_shader,
          "learnopengl/2_lighting/2_3_basic_lighting_exercise1/light_cube_fragment_shader.glsl"
        )

      {:ok, light_cube_program} =
        create_attach_link([light_cube_vertex_shader, light_cube_fragment_shader])

      IO.puts("Light cube shader program compiled and linked successfully")

      # Create vertex array for the cube with position and normal attributes
      attributes = vertex_attributes([:position, :normal])
      {cube_vao, vbo} = create_vertex_array(@vertices, attributes)

      # Create a second VAO for the light cube
      [light_cube_vao] = :gl.genVertexArrays(1)
      :gl.bindVertexArray(light_cube_vao)
      :gl.bindBuffer(@gl_array_buffer, vbo)
      :gl.vertexAttribPointer(0, 3, @gl_float, @gl_false, 6 * 4, 0)
      :gl.enableVertexAttribArray(0)

      IO.puts("Created VAOs and VBO (cube geometry with positions and normals)")

      # Create camera
      camera =
        Camera.new(
          position: vec3(0.0, 0.0, 3.0),
          yaw: -90.0,
          pitch: 0.0,
          movement_speed: 2.5,
          zoom: 45.0
        )

      # Initialize timing
      current_time = :erlang.monotonic_time(:millisecond) / 1000.0

      IO.puts("Ready to render - you should see an animated light moving around the cube.")

      {:ok,
       %{
         lighting_program: lighting_program,
         light_cube_program: light_cube_program,
         cube_vao: cube_vao,
         light_cube_vao: light_cube_vao,
         vbo: vbo,
         camera: camera,
         current_time: current_time,
         last_frame_time: current_time,
         last_mouse_x: 400.0,
         last_mouse_y: 300.0,
         first_mouse: true
       }}
    else
      {:error, reason} ->
        IO.puts("Failed to create shader programs: #{reason}")
        {:error, reason}
    end
  end

  @impl true
  def render(viewport_width, viewport_height, state) do
    # Set viewport
    :gl.viewport(0, 0, trunc(viewport_width), trunc(viewport_height))

    # Set clear color and clear screen and depth buffer
    :gl.clearColor(0.1, 0.1, 0.1, 1.0)
    :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)

    # Calculate animated light position
    time = state.current_time

    light_pos =
      vec3(
        # X oscillates between -1.0 and 3.0
        1.0 + :math.sin(time) * 2.0,
        # Y oscillates between -1.0 and 1.0 (half frequency)
        :math.sin(time / 2.0) * 1.0,
        # Z constant
        2.0
      )

    # Calculate view and projection matrices
    view = Camera.get_view_matrix(state.camera)
    aspect_ratio = viewport_width / viewport_height
    projection = mat4_perspective(radians(state.camera.zoom), aspect_ratio, 0.1, 100.0)

    # Render the lit object (coral cube with animated lighting)
    :gl.useProgram(state.lighting_program)

    # Set model matrix for the object
    model = mat4_identity()

    # Set all lighting uniforms efficiently using batch API
    set_uniforms(state.lighting_program,
      objectColor: vec3(1.0, 0.5, 0.31),
      lightColor: vec3(1.0, 1.0, 1.0),
      lightPos: light_pos,
      viewPos: state.camera.position,
      projection: projection,
      view: view,
      model: model
    )

    # Render the object cube
    :gl.bindVertexArray(state.cube_vao)
    :gl.drawArrays(@gl_triangles, 0, 36)

    # Render the light source cube
    :gl.useProgram(state.light_cube_program)

    # Set model matrix for light cube (translated to animated light position and scaled down)
    light_model = mat4_scale(@light_scale) <~ mat4_translate(light_pos) <~ mat4_identity()

    # Set light cube uniforms efficiently
    set_uniforms(state.light_cube_program,
      projection: projection,
      view: view,
      model: light_model
    )

    # Render the light cube
    :gl.bindVertexArray(state.light_cube_vao)
    :gl.drawArrays(@gl_triangles, 0, 36)

    check("After rendering basic lighting exercise 1")
    :ok
  end

  @impl true
  def cleanup(state) do
    IO.puts("""
    Cleaning up basic lighting exercise 1...
    - Demonstrated animated lighting effects using time-based functions
    - Showed how dynamic light position affects surface illumination
    - Implemented mathematical animation with sine functions
    - Provided foundation for understanding temporal graphics effects
    """)

    # Clean up vertex arrays and buffer
    :gl.deleteVertexArrays([state.cube_vao, state.light_cube_vao])
    :gl.deleteBuffers([state.vbo])

    # Clean up shader programs
    :gl.deleteProgram(state.lighting_program)
    :gl.deleteProgram(state.light_cube_program)

    check("After cleanup")
    :ok
  end

  @impl true
  def handle_event({:tick, time_delta}, state) do
    current_time = :erlang.monotonic_time(:millisecond) / 1000.0

    # Process camera movement using provided time_delta
    updated_camera = Camera.process_keyboard_input(state.camera, time_delta)

    {:ok,
     %{
       state
       | current_time: current_time,
         last_frame_time: current_time,
         camera: updated_camera
     }}
  end

  # Handle mouse movement for camera look around
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

  # Handle scroll wheel for zoom control
  def handle_event({:mouse_wheel, _x, _y, wheel_rotation, _wheel_delta}, state) do
    zoom_delta = wheel_rotation / 120.0 * 2.0
    updated_camera = Camera.process_mouse_scroll(state.camera, zoom_delta)
    {:ok, %{state | camera: updated_camera}}
  end

  # Ignore other events
  def handle_event(_event, state) do
    {:ok, state}
  end
end
