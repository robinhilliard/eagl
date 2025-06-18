defmodule EAGL.Examples.LearnOpenGL.GettingStarted.CoordinateSystemsExercise do
  @moduledoc """
  LearnOpenGL 6.4 - Coordinate Systems (Exercise)

  This exercise demonstrates a dynamic camera that orbits around a scene of cubes,
  showing how the view matrix can be animated to create camera movement effects.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/src/1.getting_started/6.4.coordinate_systems_exercise3>

  ## Framework Adaptation Notes

  This exercise demonstrates:
  - Dynamic view matrix calculation for camera movement
  - Orbiting camera using trigonometric functions
  - Time-based camera animation
  - How view transformations affect the entire scene

  ## Key Learning Points

  - **Camera Movement**: How changing the view matrix moves the camera
  - **Orbital Motion**: Using sine and cosine for circular camera paths
  - **Look-At Matrix**: Dynamic camera target and position calculation
  - **Time-Based Animation**: Smooth camera movement over time

  ## Exercise Goals

  The exercise typically asks to:
  - Make the camera orbit around the scene of cubes
  - Keep the camera always looking at the center
  - Create smooth, continuous camera movement
  - Demonstrate view matrix manipulation

  ## Visual Effect

  Shows multiple cubes with an orbiting camera:
  - Camera moves in a circular path around the scene
  - Camera always points toward the center of the scene
  - Cubes have static rotations (20 degrees × index) and appear to move due to camera motion
  - Demonstrates the relationship between camera and world coordinates

  ## Usage

      EAGL.Examples.LearnOpenGL.GettingStarted.CoordinateSystemsExercise.run_example()

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

  # Positions for cubes in 3D space
  @cube_positions [
    vec3(0.0, 0.0, 0.0),
    vec3(2.0, 5.0, -15.0),
    vec3(-1.5, -2.2, -2.5),
    vec3(-3.8, -2.0, -12.3),
    vec3(2.4, -0.4, -3.5),
    vec3(-1.7, 3.0, -7.5),
    vec3(1.3, -2.0, -2.5),
    vec3(1.5, 2.0, -2.5),
    vec3(1.5, 0.2, -1.5),
    vec3(-1.3, 1.0, -1.5)
  ]

  @spec run_example() :: :ok | {:error, term()}
  def run_example(opts \\ []) do
    default_opts = [depth_testing: true, enter_to_exit: true]
    merged_opts = Keyword.merge(default_opts, opts)

    EAGL.Window.run(
      __MODULE__,
      "LearnOpenGL - 1 Getting Started - 6.4 Coordinate Systems (Exercise)",
      merged_opts
    )
  end

  @impl true
  def setup do
    IO.puts("""
    === LearnOpenGL 6.4 - Coordinate Systems (Exercise) ===
    This exercise demonstrates camera movement by orbiting around a scene of cubes

    Key Concepts:
    - Dynamic View Matrix: Calculating camera position and orientation over time
    - Orbital Camera Motion: Using trigonometry for circular camera movement
    - Look-At Transformation: Keeping camera pointed at scene center
    - Camera vs World Coordinates: Understanding relative motion

    Camera Animation Technique:
    1. Calculate camera position using sine and cosine functions
    2. Position camera at varying distances from scene center
    3. Use mat4_look_at to create view matrix pointing at center
    4. Camera orbits while always looking at the scene center
    5. Time-based animation creates smooth, continuous motion

    Mathematical Background:
    - Parametric circle equations: x = radius * cos(angle), z = radius * sin(angle)
    - Camera position varies in X and Z while Y remains constant
    - View matrix transforms world coordinates to camera space
    - Projection matrix remains constant during camera motion

    Exercise Learning Goals:
    - Understand how view matrix changes affect entire scene
    - Experience camera movement vs object movement
    - Learn orbital motion mathematics
    - Grasp camera space transformations

    Visual Experience:
    - Camera orbits around cubes positioned in 3D space
    - Cubes have static rotations but appear to move due to camera motion
    - Smooth, continuous camera animation
    - Scene center remains fixed while camera perspective changes

    Implementation Notes:
    - Uses EAGL.Math.mat4_look_at for view matrix calculation
    - Camera height and distance can be adjusted for different effects
    - Orbital speed controlled by time multiplier
    - Demonstrates practical camera control techniques

    Press ENTER to exit.
    """)

    # Compile and link shaders
    with {:ok, vertex_shader} <-
           create_shader(
             @gl_vertex_shader,
             "learnopengl/1_getting_started/6_4_coordinate_systems_exercise/vertex_shader.glsl"
           ),
         {:ok, fragment_shader} <-
           create_shader(
             @gl_fragment_shader,
             "learnopengl/1_getting_started/6_4_coordinate_systems_exercise/fragment_shader.glsl"
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

      IO.puts("Ready to render - you should see an orbiting camera around multiple cubes.")

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

    # Create orbiting camera using trigonometric functions
    # Camera orbits around origin at radius 10, height 2
    camera_radius = 10.0
    camera_height = 2.0
    orbit_speed = 0.5

    camera_x = :math.sin(state.current_time * orbit_speed) * camera_radius
    camera_z = :math.cos(state.current_time * orbit_speed) * camera_radius

    camera_pos = vec3(camera_x, camera_height, camera_z)
    # Look at scene center
    target_pos = vec3(0.0, 0.0, 0.0)
    # World up direction
    up_vector = vec3(0.0, 1.0, 0.0)

    # Create view matrix using look-at transformation
    view = mat4_look_at(camera_pos, target_pos, up_vector)

    # Projection matrix remains constant
    aspect_ratio = viewport_width / viewport_height
    projection = mat4_perspective(radians(45.0), aspect_ratio, 0.1, 100.0)

    set_uniform(state.program, "view", view)
    set_uniform(state.program, "projection", projection)

    # Bind vertex array
    :gl.bindVertexArray(state.vao)

    # Draw each cube with its own model transformation
    @cube_positions
    |> Enum.with_index()
    |> Enum.each(fn {position, index} ->
      # Create model matrix for this cube (matches original C++ tutorial)
      model =
        mat4_identity()
        |> mat4_mul(mat4_translate(position))
        |> mat4_mul(mat4_rotate(vec3(1.0, 0.3, 0.5), radians(20.0 * index)))

      set_uniform(state.program, "model", model)
      :gl.drawArrays(@gl_triangles, 0, 36)
    end)

    check("After rendering with orbiting camera")
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
    Cleaning up coordinate systems exercise...
    - Demonstrated orbiting camera with dynamic view matrix
    - Showed camera movement vs object movement concepts
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
