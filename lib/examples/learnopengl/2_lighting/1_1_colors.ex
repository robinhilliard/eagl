defmodule EAGL.Examples.LearnOpenGL.Lighting.Colors do
  @moduledoc """
  LearnOpenGL 2.1 - Colors

  This example introduces the fundamental concepts of lighting in OpenGL by demonstrating
  how colors interact with light sources. It renders a coral-coloured cube illuminated by
  a white light source, showing the basic principle of colour reflection.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://learnopengl.com/code_viewer_gh.php?code=src/2.lighting/1.colors/colors.cpp>

  ## Framework Adaptation Notes

  This example demonstrates:
  - Basic lighting setup with object and light source
  - Colour multiplication for simple lighting effects
  - Dual shader programs for different object types
  - Foundation concepts for more advanced lighting models

  ## Key Learning Points

  - **Colour Theory**: How light colour affects object appearance
  - **Shader Organisation**: Using multiple shader programs in one scene
  - **Light Source Visualisation**: Rendering the light position as a visible object
  - **Basic Lighting Math**: Colour multiplication as light reflection

  ## Lighting Concepts

  ### Colour Reflection
  When light hits an object, the object absorbs some colours and reflects others.
  The colour we perceive is the combination of the light colour and the object's
  material properties.

  ### Mathematical Representation
  ```
  result_colour = light_colour * object_colour
  ```

  For example:
  - White light (1.0, 1.0, 1.0) × Coral object (1.0, 0.5, 0.31) = (1.0, 0.5, 0.31)
  - Green light (0.0, 1.0, 0.0) × Coral object (1.0, 0.5, 0.31) = (0.0, 0.5, 0.0)

  ## Visual Effect

  The scene shows:
  - A coral-coloured cube at the origin (object being lit)
  - A small white cube representing the light source position
  - Basic colour interaction demonstrating light reflection principles

  ## Controls

  - **W/A/S/D**: Move camera forward/left/backward/right
  - **Mouse Movement**: Look around (first-person view)
  - **Scroll Wheel**: Zoom in/out (field of view)
  - **ENTER**: Exit

  ## Usage

      EAGL.Examples.LearnOpenGL.Lighting.Colors.run_example()

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

  # 3D cube vertex data (positions only - no texture coordinates needed for basic lighting)
  @vertices ~v'''
  # positions
  -0.5 -0.5 -0.5
   0.5 -0.5 -0.5
   0.5  0.5 -0.5
   0.5  0.5 -0.5
  -0.5  0.5 -0.5
  -0.5 -0.5 -0.5

  -0.5 -0.5  0.5
   0.5 -0.5  0.5
   0.5  0.5  0.5
   0.5  0.5  0.5
  -0.5  0.5  0.5
  -0.5 -0.5  0.5

  -0.5  0.5  0.5
  -0.5  0.5 -0.5
  -0.5 -0.5 -0.5
  -0.5 -0.5 -0.5
  -0.5 -0.5  0.5
  -0.5  0.5  0.5

   0.5  0.5  0.5
   0.5  0.5 -0.5
   0.5 -0.5 -0.5
   0.5 -0.5 -0.5
   0.5 -0.5  0.5
   0.5  0.5  0.5

  -0.5 -0.5 -0.5
   0.5 -0.5 -0.5
   0.5 -0.5  0.5
   0.5 -0.5  0.5
  -0.5 -0.5  0.5
  -0.5 -0.5 -0.5

  -0.5  0.5 -0.5
   0.5  0.5 -0.5
   0.5  0.5  0.5
   0.5  0.5  0.5
  -0.5  0.5  0.5
  -0.5  0.5 -0.5
  '''

  # Light position in world space - ORIGINAL C++ TUTORIAL COORDINATES
  @light_pos vec3(1.2, 1.0, 2.0)

  @spec run_example() :: :ok | {:error, term()}
  def run_example(opts \\ []) do
    default_opts = [depth_testing: true, enter_to_exit: true]
    merged_opts = Keyword.merge(default_opts, opts)

    EAGL.Window.run(
      __MODULE__,
      "LearnOpenGL - 2 Lighting - 1.1 Colors",
      merged_opts
    )
  end

  @impl true
  def setup do
    IO.puts("""

    === LearnOpenGL 2.1 - Colors ===
    This example introduces fundamental lighting concepts by demonstrating
    how light colours interact with object colours.

    Key Concepts:
    - Colour Theory: How light affects object appearance
    - Light Source Visualisation: Showing where light comes from
    - Shader Organisation: Multiple shader programs for different purposes
    - Basic Lighting Math: result = light_colour * object_colour

    Understanding Colour Interaction:
    1. White light (1.0, 1.0, 1.0) allows objects to show their true colours
    2. Coloured light filters what colours objects can reflect
    3. The final colour is the component-wise multiplication of light and object colours

    Example Calculations:
    - Coral object (1.0, 0.5, 0.31) under white light = (1.0, 0.5, 0.31) coral
    - Coral object (1.0, 0.5, 0.31) under green light (0.0, 1.0, 0.0) = (0.0, 0.5, 0.0) dark green
    - This demonstrates why lighting is crucial for realistic rendering

    Scene Setup:
    - Large coral-coloured cube (the object being lit)
    - Small white cube showing the light source position
    - Simple colour multiplication shader for basic lighting effect

    Next Steps:
    - This basic model will be extended with ambient, diffuse, and specular components
    - More realistic lighting models (Phong, Blinn-Phong) build on these foundations
    - Advanced features: shadows, multiple lights, materials, textures

    Controls: WASD to move, mouse to look around, scroll wheel to zoom
    ========================================================================
    """)

    # Compile and link lighting shader (for the object cube)
    with {:ok, lighting_vertex_shader} <-
           create_shader(
             @gl_vertex_shader,
             "learnopengl/2_lighting/1_1_colors/lighting_vertex_shader.glsl"
           ),
         {:ok, lighting_fragment_shader} <-
           create_shader(
             @gl_fragment_shader,
             "learnopengl/2_lighting/1_1_colors/lighting_fragment_shader.glsl"
           ),
         {:ok, lighting_program} <-
           create_attach_link([lighting_vertex_shader, lighting_fragment_shader]) do
      IO.puts("Lighting shader program compiled and linked successfully")

      # Compile and link light cube shader (for the light source cube)
      {:ok, light_cube_vertex_shader} =
        create_shader(
          @gl_vertex_shader,
          "learnopengl/2_lighting/1_1_colors/light_cube_vertex_shader.glsl"
        )

      {:ok, light_cube_fragment_shader} =
        create_shader(
          @gl_fragment_shader,
          "learnopengl/2_lighting/1_1_colors/light_cube_fragment_shader.glsl"
        )

      {:ok, light_cube_program} =
        create_attach_link([light_cube_vertex_shader, light_cube_fragment_shader])

      IO.puts("Light cube shader program compiled and linked successfully")

      # Create vertex array for the cube (used by both object and light source)
      attributes = vertex_attributes([:position])
      {cube_vao, vbo} = create_vertex_array(@vertices, attributes)

      # Create a second VAO for the light cube (same vertex data, different VAO)
      # This follows the C++ tutorial pattern for organisational clarity
      [light_cube_vao] = :gl.genVertexArrays(1)
      :gl.bindVertexArray(light_cube_vao)

      # Bind the same VBO (vertex data is identical)
      :gl.bindBuffer(@gl_array_buffer, vbo)

      # Set up vertex attributes (position only)
      :gl.vertexAttribPointer(0, 3, @gl_float, @gl_false, 3 * 4, 0)
      :gl.enableVertexAttribArray(0)

      IO.puts("Created VAOs and VBO (cube geometry for both object and light source)")

      # Create camera using EAGL.Camera module
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

      IO.puts("Ready to render - you should see a coral cube lit by a white light source.")

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
         first_mouse: true,
         keys_pressed: %{}
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

    # Render the lit object (coral cube)
    :gl.useProgram(state.lighting_program)
    set_uniform(state.lighting_program, "objectColor", vec3(1.0, 0.5, 0.31))
    set_uniform(state.lighting_program, "lightColor", vec3(1.0, 1.0, 1.0))
    set_uniform(state.lighting_program, "projection", projection)
    set_uniform(state.lighting_program, "view", view)

    # Set model matrix for the object (identity - at origin)
    model = mat4_identity()
    set_uniform(state.lighting_program, "model", model)

    # Render the object cube
    :gl.bindVertexArray(state.cube_vao)
    :gl.drawArrays(@gl_triangles, 0, 36)

    # Render the light source cube
    :gl.useProgram(state.light_cube_program)
    set_uniform(state.light_cube_program, "projection", projection)
    set_uniform(state.light_cube_program, "view", view)

    # Set model matrix for light cube (translated to light position and scaled down)
    # Matrix: translate_matrix * scale_matrix (applies scale first, then translate to vertex)
    light_model =
      vec3(0.2, 0.2, 0.2)
      |> mat4_scale()
      |> mat4_mul(mat4_translate(@light_pos))
      |> mat4_mul(mat4_identity())

    set_uniform(state.light_cube_program, "model", light_model)

    # Render the light cube
    :gl.bindVertexArray(state.light_cube_vao)
    :gl.drawArrays(@gl_triangles, 0, 36)

    check("After rendering colors example")
    :ok
  end

  @impl true
  def cleanup(state) do
    IO.puts("""
    Cleaning up colors example...
    - Demonstrated basic colour theory and light interaction
    - Showed shader program organisation for multiple object types
    - Introduced foundation concepts for advanced lighting models
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
