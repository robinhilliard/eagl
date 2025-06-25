defmodule EAGL.Examples.LearnOpenGL.Lighting.BasicLightingExercise2 do
  @moduledoc """
  LearnOpenGL 2.4 - Basic Lighting Exercise 2 (View Space Lighting)

  This exercise demonstrates lighting calculations performed in view space rather than
  world space. By transforming all lighting-related vectors to view space, we can
  simplify some calculations and understand different coordinate system approaches.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://learnopengl.com/code_viewer_gh.php?code=src/2.lighting/2.4.basic_lighting_exercise2/basic_lighting_exercise2.cpp>

  ## Framework Adaptation Notes

  This exercise demonstrates:
  - Lighting calculations in view space coordinate system
  - Matrix transformations for different coordinate spaces
  - Simplified view direction calculation in view space
  - Understanding of coordinate system transformations in graphics

  ## Key Learning Points

  - **Coordinate Spaces**: Different spaces (world, view, clip) serve different purposes
  - **View Space Benefits**: Simplifies some calculations (viewer always at origin)
  - **Matrix Transformations**: How to transform vectors between coordinate systems
  - **Shader Optimization**: View space can be more efficient for certain operations

  ## View Space Lighting Theory

  ### Coordinate System Differences

  **World Space** (previous exercises):
  - Light position: World coordinates
  - Fragment position: World coordinates
  - View direction: camera_position - fragment_position

  **View Space** (this exercise):
  - Light position: Transformed by view matrix
  - Fragment position: Transformed by view matrix
  - View direction: Simply -fragment_position (camera at origin)

  ### Transformation Details

  ```
  // In vertex shader:
  FragPos = vec3(view * model * vec4(aPos, 1.0))           // Transform to view space
  Normal = mat3(transpose(inverse(view * model))) * aNormal // Transform normal to view space
  LightPos = vec3(view * vec4(lightPos, 1.0))             // Transform light to view space

  // In fragment shader:
  vec3 viewDir = normalize(-FragPos)  // Camera is at (0,0,0) in view space
  ```

  ## Visual Effects

  The scene shows:
  - Identical visual results to previous exercises
  - The same coral-coloured cube with realistic shading
  - Demonstrates that coordinate space choice doesn't affect final appearance
  - Proves that mathematical equivalence holds across coordinate systems

  ## Technical Implementation

  - **Vertex Shader**: Transforms positions and normals to view space
  - **Fragment Shader**: Performs lighting calculations in view space
  - **View Direction**: Simplified to -FragPos (no camera position needed)
  - **Matrix Chain**: Uses (view * model) for transformations
  - **Batch Uniform Setting**: Uses `set_uniforms/2` for cleaner, more efficient uniform management

  ## Educational Value

  This exercise helps students understand:
  - Different coordinate systems in 3D graphics
  - When and why to choose different coordinate spaces
  - Matrix transformation chains and their applications
  - That lighting calculations can be done in any consistent coordinate system

  ## Advantages of View Space Lighting

  - **Simplified View Direction**: No need to pass camera position uniform
  - **Potential Optimization**: Fewer vector calculations in fragment shader
  - **Natural for Some Operations**: Post-processing effects often work in view space
  - **Understanding**: Builds foundation for advanced rendering techniques

  ## Controls

  - **W/A/S/D**: Move camera forward/left/backward/right
  - **Mouse Movement**: Look around (first-person view)
  - **Scroll Wheel**: Zoom in/out (field of view)
  - **ENTER**: Exit

  ## Usage

      EAGL.Examples.LearnOpenGL.Lighting.BasicLightingExercise2.run_example()

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

  # Light position in world space
  @light_pos vec3(1.2, 1.0, 2.0)
  @light_scale vec3(0.2, 0.2, 0.2)

  @spec run_example() :: :ok | {:error, term()}
  def run_example(opts \\ []) do
    default_opts = [depth_testing: true, enter_to_exit: true]
    merged_opts = Keyword.merge(default_opts, opts)

    EAGL.Window.run(
      __MODULE__,
      "LearnOpenGL - 2 Lighting - 2.4 Basic Lighting Exercise 2 (View Space)",
      merged_opts
    )
  end

  @impl true
  def setup do
    IO.puts("""

    === LearnOpenGL 2.4 - Basic Lighting Exercise 2 (View Space Lighting) ===
    This exercise demonstrates lighting calculations performed in view space rather
    than world space, showing how coordinate system choice affects implementation.

    Key Concepts:
    - View Space Coordinate System: Camera at origin, looking down negative Z
    - Matrix Transformations: Converting between coordinate spaces
    - Coordinate System Choice: Different spaces have different advantages
    - Mathematical Equivalence: Same results regardless of coordinate space used

    View Space Transformations:
    - Fragment Position: vec3(view * model * vec4(position, 1.0))
    - Normal Vector: mat3(transpose(inverse(view * model))) * normal
    - Light Position: vec3(view * vec4(lightPos, 1.0))
    - View Direction: normalize(-FragPos)  // Camera at origin in view space

    Coordinate Space Comparison:

    World Space (Previous Exercises):
    - Light position: World coordinates
    - Fragment position: World coordinates
    - View direction: normalize(cameraPos - fragPos)
    - Requires camera position uniform

    View Space (This Exercise):
    - Light position: Transformed by view matrix
    - Fragment position: Transformed by view matrix
    - View direction: normalize(-fragPos)
    - Camera implicitly at origin (0,0,0)

    Benefits of View Space Lighting:
    - Simplified view direction calculation (no camera position needed)
    - Potentially more efficient (fewer uniforms and calculations)
    - Natural for post-processing effects and screen-space techniques
    - Foundation for advanced rendering methods

    Technical Implementation:
    - Vertex shader transforms all vectors to view space using view matrix
    - Fragment shader performs lighting in view space coordinates
    - Light position transformed once per frame, not per fragment
    - View direction is simply the negated fragment position

    Visual Results:
    - Identical appearance to world space lighting
    - Same coral cube with realistic Phong shading
    - Proves mathematical equivalence of coordinate systems
    - Demonstrates that implementation choice doesn't affect final image

    Educational Value:
    - Understanding coordinate systems in 3D graphics
    - Learning when to choose different coordinate spaces
    - Foundation for advanced rendering techniques
    - Appreciation for mathematical elegance in graphics programming

    Next Steps:
    - Materials will add surface property variation
    - Light types will introduce directional and spot lights
    - Advanced lighting will build on coordinate system understanding

    Controls: WASD to move, mouse to look around, scroll wheel to zoom
    ========================================================================
    """)

    # Compile and link lighting shader (view space version)
    with {:ok, lighting_vertex_shader} <-
           create_shader(
             @gl_vertex_shader,
             "learnopengl/2_lighting/2_4_basic_lighting_exercise2/lighting_vertex_shader.glsl"
           ),
         {:ok, lighting_fragment_shader} <-
           create_shader(
             @gl_fragment_shader,
             "learnopengl/2_lighting/2_4_basic_lighting_exercise2/lighting_fragment_shader.glsl"
           ),
         {:ok, lighting_program} <-
           create_attach_link([lighting_vertex_shader, lighting_fragment_shader]) do
      IO.puts("Basic lighting exercise 2 (view space) shader program compiled and linked successfully")

      # Compile and link light cube shader
      {:ok, light_cube_vertex_shader} =
        create_shader(
          @gl_vertex_shader,
          "learnopengl/2_lighting/2_4_basic_lighting_exercise2/light_cube_vertex_shader.glsl"
        )

      {:ok, light_cube_fragment_shader} =
        create_shader(
          @gl_fragment_shader,
          "learnopengl/2_lighting/2_4_basic_lighting_exercise2/light_cube_fragment_shader.glsl"
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

      IO.puts("Ready to render - you should see lighting calculated in view space (identical appearance).")

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

    # Calculate view and projection matrices
    view = Camera.get_view_matrix(state.camera)
    aspect_ratio = viewport_width / viewport_height
    projection = mat4_perspective(radians(state.camera.zoom), aspect_ratio, 0.1, 100.0)

    # Render the lit object (coral cube with view space lighting)
    :gl.useProgram(state.lighting_program)

    # Set model matrix for the object
    model = mat4_identity()

    # Set all lighting uniforms efficiently using batch API
    set_uniforms(state.lighting_program, [
      objectColor: vec3(1.0, 0.5, 0.31),
      lightColor: vec3(1.0, 1.0, 1.0),
      lightPos: @light_pos,  # World space light position
      projection: projection,
      view: view,
      model: model
    ])

    # Render the object cube
    :gl.bindVertexArray(state.cube_vao)
    :gl.drawArrays(@gl_triangles, 0, 36)

    # Render the light source cube
    :gl.useProgram(state.light_cube_program)

    # Set model matrix for light cube
    light_model = mat4_scale(@light_scale) <~ mat4_translate(@light_pos) <~ mat4_identity()

    # Set light cube uniforms efficiently
    set_uniforms(state.light_cube_program, [
      projection: projection,
      view: view,
      model: light_model
    ])

    # Render the light cube
    :gl.bindVertexArray(state.light_cube_vao)
    :gl.drawArrays(@gl_triangles, 0, 36)

    check("After rendering basic lighting exercise 2")
    :ok
  end

  @impl true
  def cleanup(state) do
    IO.puts("""
    Cleaning up basic lighting exercise 2...
    - Demonstrated lighting calculations in view space coordinate system
    - Showed matrix transformations between coordinate spaces
    - Implemented simplified view direction calculation
    - Proved mathematical equivalence across coordinate systems
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
  def handle_event(:tick, state) do
    current_time = :erlang.monotonic_time(:millisecond) / 1000.0
    delta_time = current_time - state.last_frame_time

    # Process camera movement
    updated_camera = Camera.process_keyboard_input(state.camera, delta_time)

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
