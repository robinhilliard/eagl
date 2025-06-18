defmodule EAGL.Examples.LearnOpenGL.GettingStarted.CameraCircle do
  @moduledoc """
  LearnOpenGL 7.1 - Camera (Circle)

  This example introduces the camera system in OpenGL by demonstrating how the view matrix
  controls the camera position and orientation. It shows a simple circular camera movement
  around multiple textured cubes to illustrate basic camera concepts.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/src/1.getting_started/7.1.camera_circle>

  ## Framework Adaptation Notes

  This example introduces fundamental camera concepts:
  - The camera as a virtual viewpoint in 3D space
  - View matrix calculation using camera position and orientation
  - Circular camera movement using trigonometric functions
  - How camera movement affects the perspective of the scene

  ## Key Learning Points

  - **Camera Coordinate System**: Understanding camera position, target, and up vector
  - **View Matrix**: How the view matrix transforms world coordinates to camera space
  - **Camera Movement**: Moving the camera position while keeping the target fixed
  - **Smooth Animation**: Using time-based trigonometric functions for circular motion

  ## Camera Concepts Introduced

  - **Camera Position**: Where the camera is located in world space
  - **Camera Target**: What point the camera is looking at
  - **Camera Up Vector**: Which direction is "up" for the camera
  - **Look-At Matrix**: Mathematical transformation from camera parameters to view matrix

  ## Visual Effect

  Shows multiple textured cubes with a camera orbiting around them:
  - Camera moves in a circular path around the scene
  - Camera always points toward the center of the scene
  - Demonstrates how camera position affects the view of objects
  - Smooth, continuous circular motion
  - 10 cubes at different positions with individual rotations

  ## Usage

      EAGL.Examples.LearnOpenGL.GettingStarted.CameraCircle.run_example()

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

  # World space positions of our cubes (matches original C++ tutorial)
  @cube_positions [
    {0.0, 0.0, 0.0},
    {2.0, 5.0, -15.0},
    {-1.5, -2.2, -2.5},
    {-3.8, -2.0, -12.3},
    {2.4, -0.4, -3.5},
    {-1.7, 3.0, -7.5},
    {1.3, -2.0, -2.5},
    {1.5, 2.0, -2.5},
    {1.5, 0.2, -1.5},
    {-1.3, 1.0, -1.5}
  ]

  @spec run_example() :: :ok | {:error, term()}
  def run_example(opts \\ []) do
    default_opts = [depth_testing: true, enter_to_exit: true]
    merged_opts = Keyword.merge(default_opts, opts)

    EAGL.Window.run(
      __MODULE__,
      "LearnOpenGL - 1 Getting Started - 7.1 Camera (Circle)",
      merged_opts
    )
  end

  @impl true
  def setup do
    IO.puts("""
    === LearnOpenGL 7.1 - Camera (Circle) ===
    This example introduces basic camera concepts with circular camera movement

    Key Concepts:
    - Camera System: Virtual viewpoint that observes the 3D scene
    - View Matrix: Mathematical transformation that positions and orients the camera
    - Camera Position: Where the camera is located in world space
    - Camera Target: What point the camera is looking at (also called "center")
    - Camera Up Vector: Defines which direction is "up" for the camera

    Camera Mathematics:
    - Look-At Matrix: Calculated from position, target, and up vectors
    - Right-handed coordinate system with Y-axis pointing up
    - Camera moves in a circle while always looking at the center of the scene
    - Trigonometric functions (sin/cos) create smooth circular motion

    Implementation Details:
    - Camera orbits around multiple cubes positioned throughout the scene
    - Fixed target at world origin (0, 0, 0)
    - Camera height remains constant during circular motion
    - View matrix updates each frame based on camera position
    - 10 cubes with individual positions and rotations

    Learning Progression:
    - This is the first camera example in the LearnOpenGL series
    - Builds on coordinate systems knowledge from chapter 6
    - Introduces concepts needed for interactive camera controls (later examples)
    - Demonstrates separation between camera and object transformations

    Mathematical Background:
    - Parametric circle: x = radius * cos(angle), z = radius * sin(angle)
    - Look-at matrix automatically handles camera orientation calculations
    - View matrix is the inverse of the camera's world transformation
    - Right-hand rule determines coordinate system orientation

    Press ENTER to exit.
    """)

    # Compile and link shaders
    with {:ok, vertex_shader} <-
           create_shader(
             @gl_vertex_shader,
             "learnopengl/1_getting_started/7_1_camera_circle/vertex_shader.glsl"
           ),
         {:ok, fragment_shader} <-
           create_shader(
             @gl_fragment_shader,
             "learnopengl/1_getting_started/7_1_camera_circle/fragment_shader.glsl"
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

      IO.puts("Ready to render - you should see a camera orbiting around 10 textured cubes.")

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

    # Set clear color and clear screen and depth buffer
    :gl.clearColor(0.2, 0.3, 0.3, 1.0)
    :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)

    # Bind texture
    :gl.activeTexture(@gl_texture0)
    :gl.bindTexture(@gl_texture_2d, state.texture_id)

    # Use the shader program
    :gl.useProgram(state.program)

    # Camera setup for circular movement
    # Camera orbits around the scene at a fixed distance and height
    camera_radius = 10.0
    camera_height = 0.0
    orbit_speed = 1.0

    # Calculate camera position using parametric circle equations
    camera_x = :math.sin(state.current_time * orbit_speed) * camera_radius
    camera_z = :math.cos(state.current_time * orbit_speed) * camera_radius

    camera_pos = vec3(camera_x, camera_height, camera_z)
    # Look at the center of the scene
    target_pos = vec3(0.0, 0.0, 0.0)
    # World up direction
    up_vector = vec3(0.0, 1.0, 0.0)

    # Create view matrix using look-at transformation
    view = mat4_look_at(camera_pos, target_pos, up_vector)

    # Projection matrix with perspective
    aspect_ratio = viewport_width / viewport_height
    projection = mat4_perspective(radians(45.0), aspect_ratio, 0.1, 100.0)

    # Set view and projection matrices (these are the same for all cubes)
    set_uniform(state.program, "view", view)
    set_uniform(state.program, "projection", projection)

    # Bind vertex array once for all cubes
    :gl.bindVertexArray(state.vao)

    # Render all cubes
    @cube_positions
    |> Enum.with_index()
    |> Enum.each(fn {{x, y, z}, index} ->
      # Calculate the model matrix for each cube
      model =
        mat4_identity()
        |> mat4_mul(mat4_translate(vec3(x, y, z)))
        |> mat4_mul(mat4_rotate(vec3(1.0, 0.3, 0.5), radians(20.0 * index)))

      # Set the model matrix for this cube
      set_uniform(state.program, "model", model)

      # Draw this cube
      :gl.drawArrays(@gl_triangles, 0, 36)
    end)

    check("After rendering all cubes with circular camera")
    :ok
  end

  @impl true
  def handle_event(:tick, state) do
    current_time = :erlang.monotonic_time(:millisecond) / 1000.0
    {:ok, %{state | current_time: current_time}}
  end

  @impl true
  def cleanup(state) do
    IO.puts("""
    Cleaning up camera circle example...
    - Demonstrated basic camera concepts with circular movement
    - Introduced view matrix and look-at transformation
    - Rendered 10 cubes with individual transformations
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
