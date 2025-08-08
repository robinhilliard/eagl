defmodule EAGL.Examples.LearnOpenGL.Lighting.MaterialsExercise1 do
  @moduledoc """
  LearnOpenGL 3.2 - Materials Exercise 1

  This exercise demonstrates how different material properties create completely different
  surface appearances, even under the same lighting conditions. It shows a cyan-like material
  with specific properties that create a distinctive appearance.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://learnopengl.com/code_viewer_gh.php?code=src/2.lighting/3.2.materials_exercise1/materials_exercise1.cpp>

  ## Framework Adaptation Notes

  This example demonstrates:
  - Different material properties creating unique surface appearance
  - Fixed white light allowing material properties to be clearly seen
  - Cyan-like material with specific ambient, diffuse, and specular values
  - How material properties define object identity more than shape

  ## Key Learning Points

  - **Material Definition**: How specific material values create recognisable surfaces
  - **Colour Perception**: How different components affect overall appearance
  - **Real Material Properties**: Values based on actual material measurements
  - **Material vs Light**: Separating material properties from lighting conditions

  ## Material Properties in This Exercise

  The material in this example represents a cyan plastic-like surface:
  - **Ambient**: (0.0, 0.1, 0.06) - Very dark cyan for shadows
  - **Diffuse**: (0.0, 0.50980392, 0.50980392) - Bright cyan for main surface colour
  - **Specular**: (0.50196078, 0.50196078, 0.50196078) - Grey highlights
  - **Shininess**: 32.0 - Moderately sharp highlights

  ## Light Properties (Fixed)

  Unlike the previous example, the light remains constant:
  - **Ambient**: (1.0, 1.0, 1.0) - Full white ambient light
  - **Diffuse**: (1.0, 1.0, 1.0) - Full white diffuse light
  - **Specular**: (1.0, 1.0, 1.0) - Full white specular light

  This allows the material properties to be seen clearly without colour interference.

  ## Visual Effects

  - **Cyan-coloured cube** with distinctive material appearance
  - **Consistent lighting** allowing material properties to be clearly observed
  - **No animation** - focus is on material appearance rather than light changes
  - **Realistic material response** showing how real cyan plastic might appear

  ## Comparison with Previous Example

  Compare this to the previous materials example:
  - Previous: Coral material with animated coloured lighting
  - This: Cyan material with fixed white lighting
  - Shows how different materials respond to the same lighting conditions

  ## Educational Value

  This exercise teaches:
  - How specific material values create recognisable surface types
  - The importance of material properties in defining object appearance
  - How to create realistic material definitions
  - Foundation for using material libraries and physically-based rendering

  ## Real-World Material Values

  The values used here are based on measurements of real materials and demonstrate
  how computer graphics can accurately represent physical surface properties.

  ## Technical Implementation

  - **Same shaders** as the previous materials example
  - **Fixed uniform values** for consistent material and light properties
  - **Structured uniforms** using quoted member names for GLSL structs
  - **Batch uniform setting** for efficient parameter management

  ## Controls

  - **W/A/S/D**: Move camera forward/left/backward/right
  - **Mouse Movement**: Look around (first-person view)
  - **Scroll Wheel**: Zoom in/out (field of view)
  - **ENTER**: Exit

  ## Usage

      EAGL.Examples.LearnOpenGL.Lighting.MaterialsExercise1.run_example()

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
      "LearnOpenGL - 2 Lighting - 3.2 Materials Exercise 1",
      merged_opts
    )
  end

  @impl true
  def setup do
    IO.puts("""

    === LearnOpenGL 3.2 - Materials Exercise 1 ===
    This exercise demonstrates how specific material properties create distinctive
    surface appearances. See how a cyan-like material looks under consistent white lighting.

    Key Concepts:
    - Material Definition: Specific values that create recognisable surface types
    - Fixed Lighting: White light allows material properties to be seen clearly
    - Real Material Values: Based on measurements of actual material properties
    - Material Identity: How materials define object appearance more than shape

    Exercise Focus:
    Unlike the previous example with animated coloured lighting, this exercise uses
    fixed white lighting to clearly show how material properties alone determine
    the appearance of the surface.

    Cyan Material Properties:
    - Ambient: (0.0, 0.1, 0.06) - Very dark cyan in shadows
    - Diffuse: (0.0, 0.50980392, 0.50980392) - Bright cyan main surface
    - Specular: (0.50196078, 0.50196078, 0.50196078) - Moderate grey highlights
    - Shininess: 32.0 - Moderately sharp highlights

    Fixed White Light Properties:
    - Ambient: (1.0, 1.0, 1.0) - Full white ambient illumination
    - Diffuse: (1.0, 1.0, 1.0) - Full white directional light
    - Specular: (1.0, 1.0, 1.0) - Full white specular highlights

    Why Fixed White Lighting?
    White light contains all colours equally, so any colour you see comes entirely
    from the material properties. This makes it easy to understand what each material
    component contributes to the final appearance.

    Visual Analysis:
    - The cyan colour comes from the material's diffuse property
    - Shadow areas show the dark cyan ambient component
    - Highlights appear grey because of the neutral specular component
    - The overall appearance is that of cyan plastic or painted metal

    Comparison with Previous Example:
    - Previous: Coral material with animated coloured lighting (dramatic colour changes)
    - This: Cyan material with fixed white lighting (stable, clear material appearance)
    - Shows how the same lighting setup can reveal very different materials

    Real-World Applications:
    - Material libraries use similar values for 3D rendering software
    - Game engines store material properties for realistic object appearance
    - Physically-based rendering extends these concepts with additional properties
    - CAD software uses materials to visualise product appearances

    Technical Notes:
    - Same shader structure as previous materials example
    - Fixed uniform values instead of animated calculations
    - Demonstrates consistent material appearance under stable lighting
    - Foundation for more complex material systems

    Educational Value:
    This exercise isolates material properties from lighting effects, making it easier
    to understand how each component (ambient, diffuse, specular, shininess) affects
    the final appearance.

    Controls: WASD to move, mouse to look around, scroll wheel to zoom
    Notice how the cyan material maintains its distinctive appearance from all angles!
    ========================================================================
    """)

    # Compile and link lighting shader (reusing the 3.1 materials shaders)
    with {:ok, lighting_vertex_shader} <-
           create_shader(
             @gl_vertex_shader,
             "learnopengl/2_lighting/3_2_materials_exercise1/lighting_vertex_shader.glsl"
           ),
         {:ok, lighting_fragment_shader} <-
           create_shader(
             @gl_fragment_shader,
             "learnopengl/2_lighting/3_2_materials_exercise1/lighting_fragment_shader.glsl"
           ),
         {:ok, lighting_program} <-
           create_attach_link([lighting_vertex_shader, lighting_fragment_shader]) do
      IO.puts("Materials exercise lighting shader program compiled and linked successfully")

      # Compile and link light cube shader
      {:ok, light_cube_vertex_shader} =
        create_shader(
          @gl_vertex_shader,
          "learnopengl/2_lighting/3_2_materials_exercise1/light_cube_vertex_shader.glsl"
        )

      {:ok, light_cube_fragment_shader} =
        create_shader(
          @gl_fragment_shader,
          "learnopengl/2_lighting/3_2_materials_exercise1/light_cube_fragment_shader.glsl"
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
        "Ready to render - you should see a cyan cube demonstrating specific material properties."
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

    # Render the lit object with cyan material properties
    :gl.useProgram(state.lighting_program)

    # Set model matrix for the object
    model = mat4_identity()

    # Set all uniforms using batch API with quoted struct member names
    set_uniforms(state.lighting_program,
      # Light properties (structured uniforms) - Fixed white light
      "light.position": @light_pos,
      # Full white ambient
      "light.ambient": vec3(1.0, 1.0, 1.0),
      # Full white diffuse
      "light.diffuse": vec3(1.0, 1.0, 1.0),
      # Full white specular
      "light.specular": vec3(1.0, 1.0, 1.0),

      # Material properties (structured uniforms) - Cyan material
      # Dark cyan
      "material.ambient": vec3(0.0, 0.1, 0.06),
      # Bright cyan
      "material.diffuse": vec3(0.0, 0.50980392, 0.50980392),
      # Grey highlights
      "material.specular": vec3(0.50196078, 0.50196078, 0.50196078),
      "material.shininess": 32.0,

      # Camera and transformation matrices
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

    # Set model matrix for light cube
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

    check("After rendering materials exercise 1")
    :ok
  end

  @impl true
  def cleanup(state) do
    IO.puts("""
    Cleaning up materials exercise 1...
    - Demonstrated specific material properties creating cyan surface appearance
    - Showed fixed white lighting allowing clear observation of material effects
    - Introduced realistic material values based on physical measurements
    - Foundation for understanding material definition in computer graphics
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
