defmodule EAGL.Examples.LearnOpenGL.Lighting.Materials do
  @moduledoc """
  LearnOpenGL 3.1 - Materials

  This example introduces the concept of materials in lighting calculations, demonstrating
  how different material properties affect the appearance of objects under varying light
  conditions. It showcases the use of structured uniforms and animated light colours.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://learnopengl.com/code_viewer_gh.php?code=src/2.lighting/3.1.materials/materials.cpp>

  ## Framework Adaptation Notes

  This example demonstrates:
  - Material properties using structured uniforms
  - Light properties with structured uniforms
  - Animated light colours that change over time
  - Proper material-light interaction calculations
  - Use of GLSL structs for organised shader code

  ## Key Learning Points

  - **Material Properties**: How ambient, diffuse, and specular components define surface appearance
  - **Light Properties**: Ambient, diffuse, and specular light intensities
  - **Structured Uniforms**: Using GLSL structs for organised shader parameters
  - **Material-Light Interaction**: How materials respond differently to various light colours
  - **Animation**: Time-based colour changes to demonstrate material behaviour

  ## Material Theory

  ### Material Components
  ```
  struct Material {
      vec3 ambient;    // How much ambient light the surface reflects
      vec3 diffuse;    // Colour of the surface under diffuse lighting
      vec3 specular;   // Colour of specular highlights
      float shininess; // Size/sharpness of specular highlights
  };
  ```

  ### Light Components
  ```
  struct Light {
      vec3 position;   // Light position in world space
      vec3 ambient;    // Ambient light intensity/colour
      vec3 diffuse;    // Diffuse light intensity/colour
      vec3 specular;   // Specular light intensity/colour
  };
  ```

  ### Final Lighting Calculation
  ```
  vec3 ambient = light.ambient * material.ambient;
  vec3 diffuse = light.diffuse * (diff * material.diffuse);
  vec3 specular = light.specular * (spec * material.specular);
  vec3 result = ambient + diffuse + specular;
  ```

  ## Material Properties in This Example

  - **Ambient**: (1.0, 0.5, 0.31) - Coral colour for base illumination
  - **Diffuse**: (1.0, 0.5, 0.31) - Same coral colour for main surface colour
  - **Specular**: (0.5, 0.5, 0.5) - Grey highlights (not full white = less metallic)
  - **Shininess**: 32.0 - Moderately sharp highlights

  ## Light Animation

  The light colour changes over time using sine functions:
  - **Red**: `sin(time * 2.0)` - Changes quickly
  - **Green**: `sin(time * 0.7)` - Changes slowly
  - **Blue**: `sin(time * 1.3)` - Medium speed

  The diffuse colour is 50% of the light colour, and ambient is 20% of diffuse.

  ## Visual Effects

  - **Coral cube** that changes appearance as light colour shifts
  - **Smooth colour transitions** showing how materials respond to different lights
  - **Consistent specular highlights** that remain white regardless of light colour
  - **Small white light cube** showing the current light position

  ## Technical Implementation

  - **Structured Uniforms**: Uses `"material.ambient"`, `"light.position"` etc. (quoted in batch setting)
  - **Proper Normal Transformation**: `mat3(transpose(inverse(model))) * aNormal`
  - **Per-Fragment Lighting**: Full Phong calculation in fragment shader
  - **Time-Based Animation**: Uses Erlang monotonic time for smooth, consistent animation
  - **Batch Uniform Setting**: Efficient uniform management with quoted struct member names

  ## Educational Value

  This example teaches fundamental material concepts:
  - How material properties define surface appearance
  - Why different materials look different under same lighting
  - The relationship between light colour and material response
  - Foundation for texture mapping and advanced materials

  ## Controls

  - **W/A/S/D**: Move camera forward/left/backward/right
  - **Mouse Movement**: Look around (first-person view)
  - **Scroll Wheel**: Zoom in/out (field of view)
  - **ENTER**: Exit

  ## Usage

      EAGL.Examples.LearnOpenGL.Lighting.Materials.run_example()

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

  # Light position in world space - ORIGINAL C++ TUTORIAL COORDINATES
  @light_pos vec3(1.2, 1.0, 2.0)
  @light_scale vec3(0.2, 0.2, 0.2)

  @spec run_example() :: :ok | {:error, term()}
  def run_example(opts \\ []) do
    default_opts = [depth_testing: true, enter_to_exit: true]
    merged_opts = Keyword.merge(default_opts, opts)

    EAGL.Window.run(
      __MODULE__,
      "LearnOpenGL - 2 Lighting - 3.1 Materials",
      merged_opts
    )
  end

  @impl true
  def setup do
    IO.puts("""

    === LearnOpenGL 3.1 - Materials ===
    This example introduces materials - the foundation of realistic object appearance
    in computer graphics. Learn how material properties define how surfaces respond to light.

    Key Concepts:
    - Material Properties: Ambient, diffuse, specular components and shininess
    - Light Properties: Ambient, diffuse, specular light intensities
    - Structured Uniforms: GLSL structs for organised shader parameters
    - Material-Light Interaction: How materials respond to different light colours
    - Animation: Time-based light colour changes to demonstrate material behaviour

    Material Components:
    1. Ambient: How much ambient light the surface reflects (base colour in shadow)
    2. Diffuse: Main surface colour under direct lighting (most important for appearance)
    3. Specular: Colour of shiny highlights (often white or tinted)
    4. Shininess: Controls size and sharpness of specular highlights

    Light Components:
    1. Ambient: Background illumination intensity and colour
    2. Diffuse: Main directional light intensity and colour
    3. Specular: Intensity and colour of specular highlights from the light

    Mathematical Model:
    final_colour = (light.ambient * material.ambient) +
                   (light.diffuse * material.diffuse * diffuse_factor) +
                   (light.specular * material.specular * specular_factor)

    Material in This Example (Coral-like):
    - Ambient: (1.0, 0.5, 0.31) - Coral colour in shadows
    - Diffuse: (1.0, 0.5, 0.31) - Same coral colour under direct light
    - Specular: (0.5, 0.5, 0.5) - Moderate grey highlights (not fully metallic)
    - Shininess: 32.0 - Moderately sharp highlights

    Light Animation:
    - Light colour changes over time using sine functions
    - Red component: sin(time * 2.0) - changes quickly
    - Green component: sin(time * 0.7) - changes slowly
    - Blue component: sin(time * 1.3) - medium speed
    - Diffuse = 50% light colour, Ambient = 20% diffuse

    Visual Effects You'll Notice:
    - Coral cube that dramatically changes appearance as light colour shifts
    - Smooth colour transitions showing material response to different lights
    - Specular highlights remain relatively consistent regardless of light colour
    - The cube never becomes completely one colour - materials filter light

    Technical Implementation:
    - GLSL structs define Material and Light uniform blocks
    - Structured uniforms use dot notation: "material.ambient", "light.position"
    - Proper normal matrix transformation for accurate lighting
    - Per-fragment Phong lighting calculations
    - Time-based animation using Erlang monotonic time

    Real-World Applications:
    - Different materials (plastic, metal, fabric, etc.) have different properties
    - This forms the foundation for physically-based rendering (PBR)
    - Material editors in 3D software use these same concepts
    - Game engines use materials to define object appearance

    Next Steps:
    - Lighting maps will add texture-based material variation
    - Multiple light sources will create complex lighting scenarios
    - Advanced materials will include properties like metallic, roughness, etc.

    Controls: WASD to move, mouse to look around, scroll wheel to zoom
    Watch how the cube's appearance changes as the light colour animates!
    ========================================================================
    """)

    # Compile and link lighting shader
    with {:ok, lighting_vertex_shader} <-
           create_shader(
             @gl_vertex_shader,
             "learnopengl/2_lighting/3_1_materials/lighting_vertex_shader.glsl"
           ),
         {:ok, lighting_fragment_shader} <-
           create_shader(
             @gl_fragment_shader,
             "learnopengl/2_lighting/3_1_materials/lighting_fragment_shader.glsl"
           ),
         {:ok, lighting_program} <-
           create_attach_link([lighting_vertex_shader, lighting_fragment_shader]) do
      IO.puts("Materials lighting shader program compiled and linked successfully")

      # Compile and link light cube shader
      {:ok, light_cube_vertex_shader} =
        create_shader(
          @gl_vertex_shader,
          "learnopengl/2_lighting/3_1_materials/light_cube_vertex_shader.glsl"
        )

      {:ok, light_cube_fragment_shader} =
        create_shader(
          @gl_fragment_shader,
          "learnopengl/2_lighting/3_1_materials/light_cube_fragment_shader.glsl"
        )

      {:ok, light_cube_program} =
        create_attach_link([light_cube_vertex_shader, light_cube_fragment_shader])

      IO.puts("Light cube shader program compiled and linked successfully")

      # Create vertex array for the cube with position and normal attributes
      attributes = vertex_attributes([:position, :normal])
      {cube_vao, vbo} = create_vertex_array(@vertices, attributes)

      # Create a second VAO for the light cube (same vertex data, but only position attribute)
      [light_cube_vao] = :gl.genVertexArrays(1)
      :gl.bindVertexArray(light_cube_vao)

      # Bind the same VBO (vertex data is identical)
      :gl.bindBuffer(@gl_array_buffer, vbo)

      # Set up vertex attributes for light cube (position only - skip normals)
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

      IO.puts(
        "Ready to render - you should see a coral cube with animated lighting and material effects."
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

    # Render the lit object with materials
    :gl.useProgram(state.lighting_program)

    # Calculate animated light colours using sine functions
    light_color_r = :math.sin(state.current_time * 2.0)
    light_color_g = :math.sin(state.current_time * 0.7)
    light_color_b = :math.sin(state.current_time * 1.3)
    light_color = vec3(light_color_r, light_color_g, light_color_b)

    # Calculate diffuse and ambient colours based on light colour
    diffuse_color = vec_scale(light_color, 0.5)  # Decrease the influence
    ambient_color = vec_scale(diffuse_color, 0.2)  # Low influence

    # Set model matrix for the object
    model = mat4_identity()

    # Set all uniforms using batch API with quoted struct member names
    set_uniforms(state.lighting_program, [
      # Light properties (structured uniforms)
      "light.position": @light_pos,
      "light.ambient": ambient_color,
      "light.diffuse": diffuse_color,
      "light.specular": vec3(1.0, 1.0, 1.0),

      # Material properties (structured uniforms)
      "material.ambient": vec3(1.0, 0.5, 0.31),
      "material.diffuse": vec3(1.0, 0.5, 0.31),
      "material.specular": vec3(0.5, 0.5, 0.5),
      "material.shininess": 32.0,

      # Camera and transformation matrices
      viewPos: state.camera.position,
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

    check("After rendering materials example")
    :ok
  end

  @impl true
  def cleanup(state) do
    IO.puts("""
    Cleaning up materials example...
    - Demonstrated material properties and structured uniforms
    - Showed animated light colours and material response
    - Introduced GLSL structs for organised shader parameters
    - Foundation for realistic material simulation
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
