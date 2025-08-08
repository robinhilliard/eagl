defmodule EAGL.Examples.LearnOpenGL.GettingStarted.CoordinateSystemsDepth do
  @moduledoc """
  LearnOpenGL 6.2 - Coordinate Systems (Depth)

  This example demonstrates depth testing and Z-buffer concepts. It SOLVES the visual artifacts
  shown in example 6.1 by properly enabling depth testing for correct 3D rendering.

  **Key Difference from 6.1**: This example enables depth testing, eliminating the face
  ordering problems you saw in 6.1 where back faces appeared in front of front faces.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/src/1.getting_started/6.2.coordinate_systems_depth>

  ## Framework Adaptation Notes

  This example demonstrates:
  - Depth testing enabled for proper 3D rendering
  - Z-buffer clearing each frame for correct depth comparisons
  - Multiple objects at different depths to show depth sorting
  - Overlapping geometry to emphasize depth testing importance

  ## Key Learning Points

  - **Depth Testing**: Understanding how the Z-buffer works
  - **Depth Buffer**: Clearing and using the depth buffer
  - **Z-Fighting**: What happens when depths are too close
  - **Depth Function**: How OpenGL compares depth values
  - **3D Visualization**: Proper rendering of overlapping 3D objects

  ## Visual Effect

  Shows two overlapping cubes at different depths:
  - One cube closer to the camera
  - One cube further from the camera
  - Demonstrates proper depth sorting with Z-buffer

  ## Usage

      EAGL.Examples.LearnOpenGL.GettingStarted.CoordinateSystemsDepth.run_example()

  Press ENTER to exit.
  """

  use EAGL.Window
  use EAGL.Const

  import Bitwise
  import EAGL.Shader
  import EAGL.Buffer
  import EAGL.Texture
  import EAGL.Error
  import EAGL.Math

  # 3D cube vertex data with positions and texture coordinates
  @vertices ~v'''
  # positions        # texture coords
  -0.5 -0.5 -0.5     0.0 0.0
   0.5 -0.5 -0.5     1.0 0.0
   0.5  0.5 -0.5     1.0 1.0
   0.5  0.5 -0.5     1.0 1.0
  -0.5  0.5 -0.5     0.0 1.0
  -0.5 -0.5 -0.5     0.0 0.0

  -0.5 -0.5  0.5     0.0 0.0
   0.5 -0.5  0.5     1.0 0.0
   0.5  0.5  0.5     1.0 1.0
   0.5  0.5  0.5     1.0 1.0
  -0.5  0.5  0.5     0.0 1.0
  -0.5 -0.5  0.5     0.0 0.0

  -0.5  0.5  0.5     1.0 0.0
  -0.5  0.5 -0.5     1.0 1.0
  -0.5 -0.5 -0.5     0.0 1.0
  -0.5 -0.5 -0.5     0.0 1.0
  -0.5 -0.5  0.5     0.0 0.0
  -0.5  0.5  0.5     1.0 0.0

   0.5  0.5  0.5     1.0 0.0
   0.5  0.5 -0.5     1.0 1.0
   0.5 -0.5 -0.5     0.0 1.0
   0.5 -0.5 -0.5     0.0 1.0
   0.5 -0.5  0.5     0.0 0.0
   0.5  0.5  0.5     1.0 0.0

  -0.5 -0.5 -0.5     0.0 1.0
   0.5 -0.5 -0.5     1.0 1.0
   0.5 -0.5  0.5     1.0 0.0
   0.5 -0.5  0.5     1.0 0.0
  -0.5 -0.5  0.5     0.0 0.0
  -0.5 -0.5 -0.5     0.0 1.0

  -0.5  0.5 -0.5     0.0 1.0
   0.5  0.5 -0.5     1.0 1.0
   0.5  0.5  0.5     1.0 0.0
   0.5  0.5  0.5     1.0 0.0
  -0.5  0.5  0.5     0.0 0.0
  -0.5  0.5 -0.5     0.0 1.0
  '''

  @spec run_example() :: :ok | {:error, term()}
  def run_example(opts \\ []) do
    default_opts = [depth_testing: true, enter_to_exit: true]
    merged_opts = Keyword.merge(default_opts, opts)

    EAGL.Window.run(
      __MODULE__,
      "LearnOpenGL - 1 Getting Started - 6.2 Coordinate Systems (Depth)",
      merged_opts
    )
  end

  @impl true
  def setup do
    IO.puts("""
    === LearnOpenGL 6.2 - Coordinate Systems (Depth) ===
    This example FIXES the visual artifacts from 6.1 by enabling depth testing

    🔧 Solution to 6.1 Problems:
    If you ran example 6.1, you saw faces rendering in wrong order (visual confusion).
    This example solves that by enabling depth testing for proper 3D rendering.

    Key Concepts:
    - Depth Testing: Determining which pixels are in front of others
    - Z-Buffer: Per-pixel depth storage for depth comparisons
    - Depth Function: How OpenGL compares depth values (GL_LESS by default)
    - Depth Clearing: Clearing depth buffer each frame for fresh depth tests
    - Depth Range: How depth values are mapped from clip space to depth buffer

    Depth Testing Process:
    1. Fragment shader outputs final fragment color
    2. OpenGL performs depth test against Z-buffer value
    3. If fragment passes depth test, color and depth are written
    4. If fragment fails depth test, it's discarded (not rendered)
    5. Depth buffer stores closest depth value for each pixel

    3D Rendering Benefits:
    - Proper occlusion of distant objects by near objects
    - No need to sort geometry by depth manually
    - Handles complex overlapping geometry automatically
    - Works with transparent and opaque objects (with care)

    Technical Details:
    - Depth values range from 0.0 (near) to 1.0 (far)
    - Linear depth in view space becomes non-linear in screen space
    - Z-fighting occurs when depth values are too close
    - Depth buffer precision affects rendering quality

    Visual Demonstration:
    - Two cubes at different depths show proper depth sorting
    - Closer cube occludes parts of farther cube
    - Rotation shows how depth relationships change over time
    - Without depth testing, rendering order would matter

    Press ENTER to exit.
    """)

    # Compile and link shaders
    with {:ok, vertex_shader} <-
           create_shader(
             @gl_vertex_shader,
             "learnopengl/1_getting_started/6_2_coordinate_systems_depth/vertex_shader.glsl"
           ),
         {:ok, fragment_shader} <-
           create_shader(
             @gl_fragment_shader,
             "learnopengl/1_getting_started/6_2_coordinate_systems_depth/fragment_shader.glsl"
           ),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do
      IO.puts("Vertex and fragment shaders compiled and linked successfully")

      # Create vertex array with position and texture coordinates
      attributes = vertex_attributes(:position, :texture_coordinate)
      {vao, vbo} = create_vertex_array(@vertices, attributes)

      IO.puts("Created VAO and VBO (cube with position and texture coordinates)")

      # Load texture
      {:ok, texture_id, width, height} =
        load_texture_from_file("priv/images/eagl_logo_black_on_white.jpg")

      IO.puts("Created texture (#{width}x#{height})")

      # Set up shader uniforms for texture
      :gl.useProgram(program)
      set_uniform(program, "texture1", 0)

      IO.puts(
        "Ready to render - you should see two overlapping rotating cubes demonstrating depth."
      )

      IO.puts(
        "✅ Notice: NO visual artifacts. Faces now render in correct order thanks to depth testing."
      )

      # Initialize current time for animation
      current_time = :erlang.monotonic_time(:millisecond) / 1000.0

      {:ok,
       %{
         program: program,
         vao: vao,
         vbo: vbo,
         texture_id: texture_id,
         current_time: current_time
       }}
    else
      {:error, reason} ->
        IO.puts("Failed to create shader program or texture: #{reason}")
        {:error, reason}
    end
  end

  @impl true
  def render(viewport_width, viewport_height, state) do
    # Set viewport
    :gl.viewport(0, 0, trunc(viewport_width), trunc(viewport_height))

    # Set clear color and clear screen AND depth buffer (essential for depth testing)
    :gl.clearColor(0.2, 0.3, 0.3, 1.0)
    :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)

    # Bind texture
    :gl.activeTexture(@gl_texture0)
    :gl.bindTexture(@gl_texture_2d, state.texture_id)

    # Use the shader program
    :gl.useProgram(state.program)

    # Create view and projection matrices (same for both cubes)
    view =
      mat4_identity()
      |> mat4_mul(mat4_translate(vec3(0.0, 0.0, -3.0)))

    aspect_ratio = viewport_width / viewport_height
    projection = mat4_perspective(radians(45.0), aspect_ratio, 0.1, 100.0)

    set_uniform(state.program, "view", view)
    set_uniform(state.program, "projection", projection)

    # Bind vertex array
    :gl.bindVertexArray(state.vao)

    # Draw first cube at closer position
    model1 =
      mat4_identity()
      |> mat4_mul(mat4_translate(vec3(-0.5, 0.0, -1.0)))
      |> mat4_mul(mat4_rotate(vec3(1.0, 0.0, 0.0), state.current_time * radians(50.0)))

    set_uniform(state.program, "model", model1)
    :gl.drawArrays(@gl_triangles, 0, 36)

    # Draw second cube at farther position (should be partially occluded)
    model2 =
      mat4_identity()
      |> mat4_mul(mat4_translate(vec3(0.5, 0.0, -2.0)))
      |> mat4_mul(mat4_rotate(vec3(0.0, 1.0, 0.0), state.current_time * radians(30.0)))

    set_uniform(state.program, "model", model2)
    :gl.drawArrays(@gl_triangles, 0, 36)

    check("After rendering with depth testing")
    :ok
  end

  @impl true
  def handle_event({:tick, _time_delta}, state) do
    current_time = :erlang.monotonic_time(:millisecond) / 1000.0
    {:ok, %{state | current_time: current_time}}
  end

  @impl true
  def cleanup(state) do
    IO.puts("""
    Cleaning up coordinate systems depth example...
    - Demonstrated depth testing and Z-buffer usage
    - Showed proper 3D occlusion with overlapping objects
    - SOLVED the visual artifacts from example 6.1 with depth testing
    - Key lesson: Always enable depth testing for 3D rendering.
    """)

    # Clean up texture
    :gl.deleteTextures([state.texture_id])

    # Clean up buffers
    delete_vertex_array(state.vao, state.vbo)

    # Clean up shader program
    :gl.deleteProgram(state.program)

    check("After cleanup")
    :ok
  end
end
