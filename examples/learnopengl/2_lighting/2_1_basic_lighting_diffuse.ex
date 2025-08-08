defmodule EAGL.Examples.LearnOpenGL.Lighting.BasicLightingDiffuse do
  @moduledoc """
  LearnOpenGL 2.1 - Basic Lighting (Diffuse)

  This example introduces diffuse lighting by adding proper lighting calculations using
  surface normals and light direction. It builds upon the basic colours example by
  implementing the Phong lighting model's ambient and diffuse components.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://learnopengl.com/code_viewer_gh.php?code=src/2.lighting/2.1.basic_lighting_diffuse/basic_lighting_diffuse.cpp>

  ## Framework Adaptation Notes

  This example demonstrates:
  - Surface normal vectors for realistic lighting calculations
  - Ambient lighting (constant base illumination)
  - Diffuse lighting using dot product calculations
  - Per-fragment lighting computations
  - Foundation for the Phong lighting model

  ## Key Learning Points

  - **Surface Normals**: Vectors perpendicular to surfaces that determine lighting angles
  - **Ambient Lighting**: Constant base lighting that prevents completely dark areas
  - **Diffuse Lighting**: Light intensity based on angle between surface normal and light direction
  - **Dot Product**: Mathematical operation to calculate angle between vectors
  - **Per-Fragment Calculations**: Lighting computed for each pixel rather than per vertex

  ## Lighting Theory

  ### Ambient Component
  ```
  ambient = ambient_strength * light_colour
  ```
  Provides a constant base level of illumination to prevent completely black areas.
  Typical strength values range from 0.1 to 0.3.

  ### Diffuse Component
  ```
  diffuse_intensity = max(dot(normal, light_direction), 0.0)
  diffuse = diffuse_intensity * light_colour
  ```
  Calculates how much light hits the surface based on the angle between the surface
  normal and the direction from the surface to the light source.

  ### Final Colour
  ```
  result = (ambient + diffuse) * object_colour
  ```

  ## Visual Effect

  The scene shows:
  - A coral-coloured cube with realistic lighting that varies across surfaces
  - Surfaces facing the light appear brighter
  - Surfaces facing away from the light appear darker
  - No completely black areas due to ambient lighting
  - A small white cube representing the light source position

  ## Technical Implementation

  - Vertex data includes both positions and normal vectors (6 floats per vertex)
  - Fragment shader performs per-pixel lighting calculations
  - Light position passed as uniform for dynamic lighting calculations
  - Normal vectors define surface orientation for accurate lighting
  - **Batch Uniform Setting**: Uses `set_uniforms/2` for cleaner, more efficient uniform management

  ## Controls

  - **W/A/S/D**: Move camera forward/left/backward/right
  - **Mouse Movement**: Look around (first-person view)
  - **Scroll Wheel**: Zoom in/out (field of view)
  - **ENTER**: Exit

  ## Usage

      EAGL.Examples.LearnOpenGL.Lighting.BasicLightingDiffuse.run_example()

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
  # Each face has consistent normal vectors pointing outward from the cube
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

  # Light position in world space - ORIGINAL C++ TUTORIAL COORDINATES
  @light_pos vec3(1.2, 1.0, 2.0)
  @light_scale vec3(0.2, 0.2, 0.2)

  @spec run_example() :: :ok | {:error, term()}
  def run_example(opts \\ []) do
    default_opts = [depth_testing: true, enter_to_exit: true]
    merged_opts = Keyword.merge(default_opts, opts)

    EAGL.Window.run(
      __MODULE__,
      "LearnOpenGL - 2 Lighting - 2.1 Basic Lighting (Diffuse)",
      merged_opts
    )
  end

  @impl true
  def setup do
    IO.puts("""

    === LearnOpenGL 2.1 - Basic Lighting (Diffuse) ===
    This example introduces realistic lighting calculations using surface normals
    and implements the first two components of the Phong lighting model.

    Key Concepts:
    - Surface Normals: Vectors perpendicular to surfaces that define orientation
    - Ambient Lighting: Constant base illumination (prevents completely dark areas)
    - Diffuse Lighting: Light intensity based on surface angle relative to light source
    - Per-Fragment Lighting: Calculations performed for each pixel
    - Dot Product Mathematics: Used to calculate angles between vectors

    Lighting Components:
    1. Ambient = ambient_strength * light_colour (constant base lighting)
    2. Diffuse = max(dot(normal, light_direction), 0.0) * light_colour (angle-based lighting)
    3. Final = (ambient + diffuse) * object_colour

    Physical Interpretation:
    - Surfaces perpendicular to light direction receive maximum illumination
    - Surfaces parallel to light direction receive minimal illumination
    - The dot product gives us the cosine of the angle between vectors
    - max() function prevents negative lighting (surfaces can't emit negative light)
    - Ambient component ensures no surface is completely black

    Visual Effects You'll Notice:
    - The cube now has realistic shading with bright and dark faces
    - Faces pointing toward the light source appear brighter
    - Faces pointing away appear darker but not completely black
    - The lighting creates depth and three-dimensional appearance
    - Moving around shows how lighting changes with viewing angle

    Technical Implementation:
    - Vertex data now includes normal vectors (6 floats per vertex)
    - Vertex shader passes fragment position and normals to fragment shader
    - Fragment shader performs lighting calculations per pixel
    - Light position uniform allows for dynamic lighting calculations

    Next Steps:
    - Specular component will add shiny highlights
    - Materials will define how objects respond to light
    - Multiple light sources will create complex scenes
    - Normal mapping will add surface detail

    Controls: WASD to move, mouse to look around, scroll wheel to zoom
    ========================================================================
    """)

    # Compile and link lighting shader (for the object cube with diffuse lighting)
    with {:ok, lighting_vertex_shader} <-
           create_shader(
             @gl_vertex_shader,
             "learnopengl/2_lighting/2_1_basic_lighting_diffuse/lighting_vertex_shader.glsl"
           ),
         {:ok, lighting_fragment_shader} <-
           create_shader(
             @gl_fragment_shader,
             "learnopengl/2_lighting/2_1_basic_lighting_diffuse/lighting_fragment_shader.glsl"
           ),
         {:ok, lighting_program} <-
           create_attach_link([lighting_vertex_shader, lighting_fragment_shader]) do
      IO.puts("Basic lighting diffuse shader program compiled and linked successfully")

      # Compile and link light cube shader (for the light source cube)
      {:ok, light_cube_vertex_shader} =
        create_shader(
          @gl_vertex_shader,
          "learnopengl/2_lighting/2_1_basic_lighting_diffuse/light_cube_vertex_shader.glsl"
        )

      {:ok, light_cube_fragment_shader} =
        create_shader(
          @gl_fragment_shader,
          "learnopengl/2_lighting/2_1_basic_lighting_diffuse/light_cube_fragment_shader.glsl"
        )

      {:ok, light_cube_program} =
        create_attach_link([light_cube_vertex_shader, light_cube_fragment_shader])

      IO.puts("Light cube shader program compiled and linked successfully")

      # Create vertex array for the cube with position and normal attributes
      # Position (location 0): 3 floats, Normal (location 1): 3 floats
      attributes = vertex_attributes([:position, :normal])
      {cube_vao, vbo} = create_vertex_array(@vertices, attributes)

      # Create a second VAO for the light cube (same vertex data, but only position attribute)
      [light_cube_vao] = :gl.genVertexArrays(1)
      :gl.bindVertexArray(light_cube_vao)

      # Bind the same VBO (vertex data is identical)
      :gl.bindBuffer(@gl_array_buffer, vbo)

      # Set up vertex attributes for light cube (position only - skip normals)
      # Position data is first 3 floats, stride is 6 floats (pos + normal)
      :gl.vertexAttribPointer(0, 3, @gl_float, @gl_false, 6 * 4, 0)
      :gl.enableVertexAttribArray(0)

      IO.puts("Created VAOs and VBO (cube geometry with positions and normals)")

      # Create camera using EAGL.Camera module
      camera =
        Camera.new(
          position: vec3(0.0, 0.0, 3.0),
          yaw: -90.0,
          pitch: 0.0,
          movement_speed: 2.5,
          zoom: 45.0
        )

      # Initialize timing for delta time calculation
      current_time = :erlang.monotonic_time(:millisecond) / 1000.0

      IO.puts(
        "Ready to render - you should see a realistically lit coral cube with proper shading."
      )

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

    # Render the lit object (coral cube with diffuse lighting)
    :gl.useProgram(state.lighting_program)

    # Set model matrix for the object (identity - at origin)
    model = mat4_identity()

    # Set all lighting uniforms efficiently using batch API
    set_uniforms(state.lighting_program,
      objectColor: vec3(1.0, 0.5, 0.31),
      lightColor: vec3(1.0, 1.0, 1.0),
      lightPos: @light_pos,
      projection: projection,
      view: view,
      model: model
    )

    # Render the object cube
    :gl.bindVertexArray(state.cube_vao)
    :gl.drawArrays(@gl_triangles, 0, 36)

    # Render the light source cube
    :gl.useProgram(state.light_cube_program)

    # Set model matrix for light cube (translated to light position and scaled down)
    light_model = mat4_scale(@light_scale) <~ mat4_translate(@light_pos) <~ mat4_identity()

    # Set light cube uniforms efficiently
    set_uniforms(state.light_cube_program,
      projection: projection,
      view: view,
      model: light_model
    )

    # Render the light cube
    :gl.bindVertexArray(state.light_cube_vao)
    :gl.drawArrays(@gl_triangles, 0, 36)

    check("After rendering basic lighting diffuse example")
    :ok
  end

  @impl true
  def cleanup(state) do
    IO.puts("""
    Cleaning up basic lighting diffuse example...
    - Demonstrated surface normals and their role in lighting calculations
    - Implemented ambient and diffuse components of the Phong lighting model
    - Showed per-fragment lighting calculations for realistic shading
    - Introduced dot product mathematics for angle-based lighting intensity
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
