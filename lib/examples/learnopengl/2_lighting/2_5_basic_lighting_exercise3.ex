defmodule EAGL.Examples.LearnOpenGL.Lighting.BasicLightingExercise3 do
  @moduledoc """
  LearnOpenGL 2.5 - Basic Lighting Exercise 3 (Gouraud Shading)

  This exercise demonstrates Gouraud shading by performing lighting calculations
  in the vertex shader rather than the fragment shader. This creates a distinct
  visual effect that highlights the difference between per-vertex and per-fragment
  lighting approaches.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://learnopengl.com/code_viewer_gh.php?code=src/2.lighting/2.5.basic_lighting_exercise3/basic_lighting_exercise3.cpp>

  ## Framework Adaptation Notes

  This exercise demonstrates:
  - Gouraud shading (per-vertex lighting) vs Phong shading (per-fragment lighting)
  - Lighting calculations performed in the vertex shader
  - Interpolation artifacts that occur with per-vertex lighting
  - Historical context and performance implications of different shading models

  ## Key Learning Points

  - **Gouraud vs Phong Shading**: Different approaches to lighting calculation timing
  - **Vertex vs Fragment Processing**: Where calculations occur in the pipeline
  - **Interpolation Effects**: How vertex colours are interpolated across triangles
  - **Visual Artifacts**: The characteristic "stripe" effect of Gouraud shading
  - **Performance Trade-offs**: Historical importance of vertex vs fragment operations

  ## Gouraud Shading Theory

  ### Calculation Timing

  **Phong Shading** (previous exercises):
  - Lighting calculated per-fragment (pixel) in fragment shader
  - Normals interpolated across triangle and lighting calculated for each pixel
  - Smooth, accurate lighting gradients

  **Gouraud Shading** (this exercise):
  - Lighting calculated per-vertex in vertex shader
  - Final lighting colours interpolated across triangle
  - Faster but less accurate lighting

  ### The Stripe Effect

  The most notable visual difference is the appearance of visible triangle edges:
  ```
  When a triangle has one brightly lit vertex and two dimly lit vertices,
  the interpolation creates a distinct boundary where triangles meet,
  especially visible where specular highlights occur.
  ```

  This happens because:
  - Specular highlights are calculated only at vertices
  - Interpolation spreads the highlight across the triangle
  - Adjacent triangles may have very different vertex lighting values
  - The interpolation creates visible seams between triangles

  ## Visual Effects

  The scene shows:
  - The same coral-coloured cube but with distinct lighting characteristics
  - Visible triangle boundaries, especially where specular highlights occur
  - A more "faceted" appearance compared to smooth Phong shading
  - Clear demonstration of per-vertex vs per-fragment lighting differences

  ## Technical Implementation

  - **Vertex Shader**: Performs complete Phong lighting calculation
  - **Fragment Shader**: Simply applies interpolated colour to object colour
  - **Higher Specular Strength**: Set to 1.0 to make the effect more visible
  - **Single Output**: Vertex shader outputs final lighting colour
  - **Batch Uniform Setting**: Uses `set_uniforms/2` for cleaner, more efficient uniform management

  ## Historical Context

  Gouraud shading was historically important because:
  - **Performance**: Vertex operations were cheaper than fragment operations
  - **Hardware Limitations**: Early GPUs had limited fragment processing power
  - **Quality vs Speed**: Acceptable quality for the performance gain
  - **Still Used**: Some applications still use it for performance-critical scenarios

  ## Educational Value

  This exercise helps students understand:
  - The evolution of real-time lighting techniques
  - How interpolation affects visual quality
  - The trade-offs between performance and visual fidelity
  - Why modern graphics prefer per-fragment lighting

  ## Modern Relevance

  While Phong shading is now standard, understanding Gouraud shading is valuable for:
  - **Performance Optimization**: When framerate is critical
  - **Mobile Graphics**: Resource-constrained environments
  - **Artistic Effects**: Intentional faceted appearance
  - **Educational Foundation**: Understanding graphics pipeline stages

  ## Controls

  - **W/A/S/D**: Move camera forward/left/backward/right
  - **Mouse Movement**: Look around (first-person view)
  - **Scroll Wheel**: Zoom in/out (field of view)
  - **ENTER**: Exit

  ## Usage

      EAGL.Examples.LearnOpenGL.Lighting.BasicLightingExercise3.run_example()

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
      "LearnOpenGL - 2 Lighting - 2.5 Basic Lighting Exercise 3 (Gouraud Shading)",
      merged_opts
    )
  end

  @impl true
  def setup do
    IO.puts("""

    === LearnOpenGL 2.5 - Basic Lighting Exercise 3 (Gouraud Shading) ===
    This exercise demonstrates Gouraud shading by performing lighting calculations
    in the vertex shader instead of the fragment shader.

    Key Concepts:
    - Gouraud Shading: Per-vertex lighting calculations
    - Phong Shading: Per-fragment lighting calculations (previous exercises)
    - Interpolation Artifacts: Visual effects of vertex-based lighting
    - Pipeline Stage Choice: Where calculations occur affects visual quality

    Shading Model Comparison:

    Phong Shading (Previous Exercises):
    - Lighting calculated per-fragment (pixel) in fragment shader
    - Normals interpolated across triangles
    - Lighting calculated for every pixel
    - Smooth, accurate lighting gradients
    - Higher computational cost

    Gouraud Shading (This Exercise):
    - Lighting calculated per-vertex in vertex shader
    - Final lighting colours interpolated across triangles
    - Each pixel gets interpolated colour value
    - Visible triangle boundaries and artifacts
    - Lower computational cost

    The Stripe Effect:
    You'll notice distinct lines where triangles meet, especially where specular
    highlights occur. This happens because:
    - Specular highlights are calculated only at vertices
    - The graphics hardware interpolates these vertex colours across the triangle
    - When adjacent triangles have different vertex lighting values, visible seams appear
    - This creates the characteristic "faceted" appearance of Gouraud shading

    Technical Implementation:
    - Vertex shader performs complete ambient + diffuse + specular calculation
    - Fragment shader simply applies the interpolated lighting colour
    - Specular strength increased to 1.0 to make the effect more visible
    - Position and normal transformations done in vertex shader

    Historical Context:
    - Gouraud shading was essential when fragment operations were expensive
    - Early GPUs had limited fragment processing capabilities
    - Still useful for performance-critical applications or mobile graphics
    - Demonstrates the evolution of real-time rendering techniques

    Visual Effects You'll Notice:
    - Clear triangle boundaries, especially on the cube faces
    - More "blocky" or "faceted" appearance compared to smooth Phong shading
    - Specular highlights that appear as distinct patches rather than smooth gradients
    - The lighting changes abruptly at triangle edges

    Educational Benefits:
    - Understanding the graphics pipeline and where calculations occur
    - Appreciation for the quality improvements of per-fragment lighting
    - Historical context of graphics development
    - Trade-offs between performance and visual quality

    Performance Considerations:
    - Vertex operations: Generally fewer vertices than fragments
    - Fragment operations: Can be millions of fragments per frame
    - Modern GPUs: Fragment operations are now highly optimized
    - Mobile/VR: Gouraud shading still relevant for performance

    Next Steps:
    - Materials will introduce surface property variation
    - Advanced lighting will build on per-fragment calculation understanding
    - Texture mapping will add surface detail to lighting

    Controls: WASD to move, mouse to look around, scroll wheel to zoom
    ========================================================================
    """)

    # Compile and link lighting shader (Gouraud shading version)
    with {:ok, lighting_vertex_shader} <-
           create_shader(
             @gl_vertex_shader,
             "learnopengl/2_lighting/2_5_basic_lighting_exercise3/lighting_vertex_shader.glsl"
           ),
         {:ok, lighting_fragment_shader} <-
           create_shader(
             @gl_fragment_shader,
             "learnopengl/2_lighting/2_5_basic_lighting_exercise3/lighting_fragment_shader.glsl"
           ),
         {:ok, lighting_program} <-
           create_attach_link([lighting_vertex_shader, lighting_fragment_shader]) do
      IO.puts(
        "Basic lighting exercise 3 (Gouraud shading) shader program compiled and linked successfully"
      )

      # Compile and link light cube shader
      {:ok, light_cube_vertex_shader} =
        create_shader(
          @gl_vertex_shader,
          "learnopengl/2_lighting/2_5_basic_lighting_exercise3/light_cube_vertex_shader.glsl"
        )

      {:ok, light_cube_fragment_shader} =
        create_shader(
          @gl_fragment_shader,
          "learnopengl/2_lighting/2_5_basic_lighting_exercise3/light_cube_fragment_shader.glsl"
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

      IO.puts(
        "Ready to render - you should see Gouraud shading with visible triangle boundaries."
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

    # Render the lit object (coral cube with Gouraud shading)
    :gl.useProgram(state.lighting_program)

    # Set model matrix for the object
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

    check("After rendering basic lighting exercise 3")
    :ok
  end

  @impl true
  def cleanup(state) do
    IO.puts("""
    Cleaning up basic lighting exercise 3...
    - Demonstrated Gouraud shading with per-vertex lighting calculations
    - Showed interpolation artifacts and the characteristic stripe effect
    - Compared vertex-based vs fragment-based lighting approaches
    - Provided historical context for graphics rendering evolution
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
