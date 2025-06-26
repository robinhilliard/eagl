defmodule EAGL.Examples.LearnOpenGL.Lighting.BasicLightingSpecular do
  @moduledoc """
  LearnOpenGL 2.2 - Basic Lighting (Specular)

  This example completes the Phong lighting model by adding specular highlights,
  demonstrating how surfaces can appear shiny and reflective based on the viewing angle
  and light reflection direction.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://learnopengl.com/code_viewer_gh.php?code=src/2.lighting/2.2.basic_lighting_specular/basic_lighting_specular.cpp>

  ## Framework Adaptation Notes

  This example demonstrates:
  - Complete Phong lighting model (ambient + diffuse + specular)
  - Specular reflection calculations using reflection vectors
  - View-dependent lighting effects (highlights change with camera position)
  - Proper normal transformation with inverse transpose matrix
  - Per-fragment lighting with camera position uniform

  ## Key Learning Points

  - **Specular Reflection**: Light bounces off surfaces at predictable angles
  - **View Dependency**: Specular highlights depend on both light and camera position
  - **Reflection Vector**: Mathematical calculation of perfect light reflection
  - **Dot Product for Angles**: Measuring alignment between view and reflection directions
  - **Shininess Factor**: Controls the size and intensity of specular highlights
  - **Normal Transformation**: Proper handling of normals under model transformations

  ## Lighting Theory

  ### Complete Phong Model
  ```
  final_colour = (ambient + diffuse + specular) * object_colour
  ```

  ### Specular Component
  ```
  view_direction = normalize(camera_position - fragment_position)
  reflect_direction = reflect(-light_direction, surface_normal)
  specular_factor = pow(max(dot(view_direction, reflect_direction), 0.0), shininess)
  specular = specular_strength * specular_factor * light_colour
  ```

  ### Parameters
  - **Specular Strength**: Controls overall intensity of highlights (0.5 in this example)
  - **Shininess**: Controls highlight size and sharpness (32 in this example)
  - Higher shininess = smaller, sharper highlights (more mirror-like)
  - Lower shininess = larger, softer highlights (more plastic-like)

  ## Visual Effects

  The scene shows:
  - A coral-coloured cube with realistic shading and bright specular highlights
  - Highlights that move and change as you move the camera around
  - More pronounced lighting differences compared to diffuse-only lighting
  - Surfaces that appear more three-dimensional and material-like

  ## Technical Implementation

  - **Proper Normal Transformation**: `Normal = mat3(transpose(inverse(model))) * aNormal`
  - **View Position Uniform**: Camera position passed to fragment shader
  - **Reflection Calculation**: Uses GLSL's built-in `reflect()` function
  - **Power Function**: `pow()` creates the characteristic specular falloff curve
  - **Batch Uniform Setting**: Uses `set_uniforms/2` for cleaner, more efficient uniform management

  ## Physical Interpretation

  Specular reflection models how light bounces off smooth surfaces:
  - When light hits a surface, it reflects at an angle equal to the incident angle
  - Viewers see bright highlights when looking in the direction of reflected light
  - Real materials have varying degrees of shininess affecting highlight appearance
  - This creates the visual cues that help us identify material properties

  ## Controls

  - **W/A/S/D**: Move camera forward/left/backward/right
  - **Mouse Movement**: Look around (first-person view)
  - **Scroll Wheel**: Zoom in/out (field of view)
  - **ENTER**: Exit

  ## Usage

      EAGL.Examples.LearnOpenGL.Lighting.BasicLightingSpecular.run_example()

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
      "LearnOpenGL - 2 Lighting - 2.2 Basic Lighting (Specular)",
      merged_opts
    )
  end

  @impl true
  def setup do
    IO.puts("""

    === LearnOpenGL 2.2 - Basic Lighting (Specular) ===
    This example completes the Phong lighting model by adding specular reflection,
    creating realistic shiny surfaces with view-dependent highlights.

    Key Concepts:
    - Specular Reflection: Light bounces off surfaces following the law of reflection
    - View Dependency: Highlights change position as you move the camera
    - Reflection Vector: Mathematical representation of perfect light reflection
    - Shininess Factor: Controls the size and sharpness of specular highlights
    - Complete Phong Model: Ambient + Diffuse + Specular lighting components

    Lighting Components:
    1. Ambient = ambient_strength * light_colour (constant base lighting)
    2. Diffuse = max(dot(normal, light_direction), 0.0) * light_colour (angle-based lighting)
    3. Specular = pow(max(dot(view_direction, reflect_direction), 0.0), shininess) * light_colour

    Mathematical Details:
    - View Direction = normalize(camera_position - fragment_position)
    - Reflect Direction = reflect(-light_direction, surface_normal)
    - Specular Factor = pow(max(dot(view_dir, reflect_dir), 0.0), shininess)
    - Final = (ambient + diffuse + specular) * object_colour

    Parameters in This Example:
    - Ambient Strength: 0.1 (10% base illumination)
    - Specular Strength: 0.5 (50% highlight intensity)
    - Shininess: 32 (moderately sharp highlights)

    Physical Interpretation:
    - Higher shininess (64, 128, 256) = smaller, sharper highlights (mirror-like)
    - Lower shininess (2, 4, 8) = larger, softer highlights (plastic-like)
    - Specular strength controls how "metallic" vs "matte" the surface appears
    - The reflection vector follows physics: angle of incidence = angle of reflection

    Visual Effects You'll Notice:
    - Bright white highlights that move as you move the camera
    - The cube now looks much more three-dimensional and realistic
    - Different faces show different amounts of specular reflection
    - Moving around reveals how material properties affect appearance
    - Much more convincing simulation of a physical material

    Technical Implementation:
    - Proper normal transformation using inverse transpose matrix
    - Camera position passed as viewPos uniform for per-fragment calculations
    - GLSL reflect() function computes perfect reflection vector
    - Power function creates characteristic specular falloff curve

    Next Steps:
    - Materials will allow different objects to have unique surface properties
    - Light properties will let us simulate different types of light sources
    - Texture mapping will add surface detail to lighting calculations
    - Multiple lights will create complex, realistic scenes

    Controls: WASD to move, mouse to look around, scroll wheel to zoom
    ========================================================================
    """)

    # Compile and link lighting shader (for the object cube with specular lighting)
    with {:ok, lighting_vertex_shader} <-
           create_shader(
             @gl_vertex_shader,
             "learnopengl/2_lighting/2_2_basic_lighting_specular/lighting_vertex_shader.glsl"
           ),
         {:ok, lighting_fragment_shader} <-
           create_shader(
             @gl_fragment_shader,
             "learnopengl/2_lighting/2_2_basic_lighting_specular/lighting_fragment_shader.glsl"
           ),
         {:ok, lighting_program} <-
           create_attach_link([lighting_vertex_shader, lighting_fragment_shader]) do
      IO.puts("Basic lighting specular shader program compiled and linked successfully")

      # Compile and link light cube shader (for the light source cube)
      {:ok, light_cube_vertex_shader} =
        create_shader(
          @gl_vertex_shader,
          "learnopengl/2_lighting/2_2_basic_lighting_specular/light_cube_vertex_shader.glsl"
        )

      {:ok, light_cube_fragment_shader} =
        create_shader(
          @gl_fragment_shader,
          "learnopengl/2_lighting/2_2_basic_lighting_specular/light_cube_fragment_shader.glsl"
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

      IO.puts("Ready to render - you should see a coral cube with realistic specular highlights.")

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

    # Render the lit object (coral cube with specular lighting)
    :gl.useProgram(state.lighting_program)

    # Set model matrix for the object (identity - at origin)
    model = mat4_identity()

    # Set all lighting uniforms efficiently using batch API
    set_uniforms(state.lighting_program,
      objectColor: vec3(1.0, 0.5, 0.31),
      lightColor: vec3(1.0, 1.0, 1.0),
      lightPos: @light_pos,
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

    check("After rendering basic lighting specular example")
    :ok
  end

  @impl true
  def cleanup(state) do
    IO.puts("""
    Cleaning up basic lighting specular example...
    - Demonstrated complete Phong lighting model with specular reflection
    - Showed view-dependent lighting effects and specular highlights
    - Implemented proper normal transformation for accurate lighting
    - Introduced reflection vectors and shininess parameters
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

    # Process camera movement using simplified keyboard input function
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
