defmodule EAGL.Examples.LearnOpenGL.GettingStarted.CoordinateSystems do
  @moduledoc """
  LearnOpenGL 6.1 - Coordinate Systems

  This example demonstrates the three coordinate systems in OpenGL - model, world, view,
  and clip space - by using model, view, and projection matrices to render a 3D cube.

  **IMPORTANT**: This example intentionally does NOT enable depth testing, which causes
  visual confusion where cube faces render in the wrong order. This demonstrates why
  depth testing is crucial for 3D rendering. See example 6.2 for the corrected version.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/src/1.getting_started/6.1.coordinate_systems>

  ## Framework Adaptation Notes

  In the original LearnOpenGL C++ tutorial, this example introduces:
  - The OpenGL coordinate system transformation pipeline
  - Model matrix: local to world space transformation
  - View matrix: world to view space transformation (camera positioning)
  - Projection matrix: view to clip space transformation (perspective projection)
  - Understanding the complete transformation: projection * view * model * vertex

  EAGL's framework preserves all these concepts while providing enhanced functionality:
  - **Comprehensive Math Library**: Uses EAGL.Math with GLM-compatible matrix functions
  - **Simplified Matrix Setup**: Enhanced matrix creation and uniform setting
  - **3D Rendering Issues**: Depth testing disabled to show visual problems without Z-buffer
  - **Camera Positioning**: Proper view matrix setup for 3D scene viewing
  - **Error Handling**: Comprehensive error checking throughout setup and rendering

  ## EAGL vs Original Implementation

  **Original LearnOpenGL approach:** Manual GLM matrix creation:
  ```c++
  glm::mat4 model = glm::mat4(1.0f);
  model = glm::rotate(model, (float)glfwGetTime() * glm::radians(50.0f), glm::vec3(0.5f, 1.0f, 0.0f));

  glm::mat4 view = glm::mat4(1.0f);
  view = glm::translate(view, glm::vec3(0.0f, 0.0f, -3.0f));

  glm::mat4 projection = glm::mat4(1.0f);
  projection = glm::perspective(glm::radians(45.0f), (float)SCR_WIDTH / (float)SCR_HEIGHT, 0.1f, 100.0f);
  ```

  **EAGL approach:** Streamlined matrix operations:
  ```elixir
  model = mat4_identity()
          |> mat4_mul(mat4_rotate(vec3(0.5, 1.0, 0.0), time * radians(50.0)))

  view = mat4_identity()
         |> mat4_mul(mat4_translate(vec3(0.0, 0.0, -3.0)))

  projection = mat4_perspective(radians(45.0), aspect_ratio, 0.1, 100.0)
  ```

  ## Key Learning Points

  - **Coordinate Systems**: Understanding local, world, view, and clip space
  - **Matrix Transformation Pipeline**: How vertices are transformed through the pipeline
  - **Model Matrix**: Positioning, rotating, and scaling objects in world space
  - **View Matrix**: Positioning and orienting the camera in the scene
  - **Projection Matrix**: Converting 3D coordinates to 2D screen coordinates
  - **Visual Artifacts**: See what happens WITHOUT depth testing (faces render incorrectly)

  ## Mathematical Background

  This example demonstrates the complete 3D rendering pipeline:
  - **Local Space**: Object's vertex positions relative to its origin
  - **World Space**: Positioning objects in the global 3D world using model matrix
  - **View Space**: Camera's perspective of the world using view matrix
  - **Clip Space**: Projection to screen coordinates using projection matrix
  - **Screen Space**: Final 2D coordinates for rasterization

  ## Visual Effect

  The example shows a textured 3D cube that:
  - **Rotates**: Around a diagonal axis using the model matrix
  - **Positioned**: At the world origin, viewed from a distance
  - **Projected**: Using perspective projection for realistic 3D appearance
  - **Visually Confusing**: Faces render in wrong order without depth testing!

  ## Usage

      EAGL.Examples.LearnOpenGL.GettingStarted.CoordinateSystems.run_example()

  Press ENTER to exit the example.
  """

  use EAGL.Window
  use EAGL.Const

  import EAGL.Shader
  import EAGL.Buffer
  import EAGL.Texture
  import EAGL.Error
  import EAGL.Math

  # 3D cube vertex data with positions and texture coordinates
  # Format: [x, y, z, s, t] per vertex
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
    default_opts = [enter_to_exit: true]
    merged_opts = Keyword.merge(default_opts, opts)

    EAGL.Window.run(
      __MODULE__,
      "LearnOpenGL - 1 Getting Started - 6.1 Coordinate Systems",
      merged_opts
    )
  end

  @impl true
  def setup do
    IO.puts("""
    === LearnOpenGL 6.1 - Coordinate Systems ===
    This example demonstrates the OpenGL coordinate system transformation pipeline

    ⚠️  IMPORTANT PEDAGOGICAL NOTE:
    This example intentionally DISABLES depth testing to show visual artifacts!
    You will see cube faces rendering in the wrong order, creating visual confusion.
    This demonstrates why depth testing is essential for 3D rendering.
    See example 6.2 for the solution with depth testing enabled.

    Key Concepts:
    - Local Space: Object vertices relative to object origin
    - World Space: Objects positioned in global 3D world (model matrix)
    - View Space: World as seen from camera perspective (view matrix)
    - Clip Space: 3D coordinates projected to 2D screen (projection matrix)
    - Screen Space: Final 2D pixel coordinates for rasterization

    Transformation Pipeline:
    - Model Matrix: Positions, rotates, scales objects in world space
    - View Matrix: Positions and orients the camera in the scene
    - Projection Matrix: Converts 3D world to 2D screen coordinates
    - Complete transformation: projection * view * model * vertex

    Visual Artifacts Demonstrated:
    - WITHOUT depth testing: faces render based on draw order, not depth
    - Back faces may appear in front of front faces (incorrect!)
    - Rotation makes the visual confusion very obvious
    - This is why all 3D applications need depth testing

    Mathematical Background:
    - Homogeneous coordinates (4D vectors) enable matrix transformations
    - Right-handed coordinate system (OpenGL standard)
    - Matrix multiplication order: right-to-left evaluation
    - Perspective division (w-component) creates depth perspective

    EAGL Framework Features:
    - EAGL.Math provides GLM-compatible matrix functions
    - Automatic uniform setting with type detection
    - Comprehensive error checking throughout rendering
    - Same concepts as original tutorial with enhanced usability

    Press ENTER to exit.
    """)

    # NOTE: Depth testing is intentionally DISABLED in this example!
    # This causes visual artifacts where faces render in wrong order.
    # See example 6.2 for the corrected version with depth testing enabled.

    # Compile and link shaders
    with {:ok, vertex_shader} <-
           create_shader(
             @gl_vertex_shader,
             "learnopengl/1_getting_started/6_1_coordinate_systems/vertex_shader.glsl"
           ),
         {:ok, fragment_shader} <-
           create_shader(
             @gl_fragment_shader,
             "learnopengl/1_getting_started/6_1_coordinate_systems/fragment_shader.glsl"
           ),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do
      IO.puts("Vertex and fragment shaders compiled and linked successfully")

      # Create vertex array with position and texture coordinates
      # Each vertex: 3 position + 2 texture = 5 floats (20 bytes)
      attributes = vertex_attributes(:position, :texture_coordinate)

      {vao, vbo} = create_vertex_array(@vertices, attributes)

      IO.puts("Created VAO and VBO (cube with position and texture coordinates)")

      # Load texture using EAGL.Texture abstraction
      {:ok, texture_id, width, height} =
        load_texture_from_file("priv/images/eagl_logo_black_on_white.jpg")

      IO.puts("Created texture (#{width}x#{height})")

      # Set up shader uniforms for texture
      :gl.useProgram(program)
      # Use texture unit 0
      set_uniform(program, "texture1", 0)

      IO.puts("Ready to render - you should see a rotating 3D textured cube.")

      IO.puts(
        "⚠️  WARNING: You will notice visual artifacts (wrong face order) - this is intentional!"
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

    # Set clear color and clear screen (no depth buffer since depth testing disabled)
    :gl.clearColor(0.2, 0.3, 0.3, 1.0)
    :gl.clear(@gl_color_buffer_bit)

    # Bind texture
    :gl.activeTexture(@gl_texture0)
    :gl.bindTexture(@gl_texture_2d, state.texture_id)

    # Use the shader program
    :gl.useProgram(state.program)

    # Create transformation matrices

    # Model matrix: rotate cube around diagonal axis
    model =
      mat4_identity()
      |> mat4_mul(mat4_rotate(vec3(0.5, 1.0, 0.0), state.current_time * radians(50.0)))

    # View matrix: move camera back to see the cube
    view =
      mat4_identity()
      |> mat4_mul(mat4_translate(vec3(0.0, 0.0, -3.0)))

    # Projection matrix: perspective projection
    aspect_ratio = viewport_width / viewport_height
    projection = mat4_perspective(radians(45.0), aspect_ratio, 0.1, 100.0)

    # Pass transformation matrices to shader
    set_uniform(state.program, "model", model)
    set_uniform(state.program, "view", view)
    set_uniform(state.program, "projection", projection)

    check("After setting transformation matrices")

    # Draw the cube
    :gl.bindVertexArray(state.vao)
    :gl.drawArrays(@gl_triangles, 0, 36)

    check("After rendering")
    :ok
  end

  @impl true
  def handle_event(:tick, state) do
    # Update animation time each tick
    current_time = :erlang.monotonic_time(:millisecond) / 1000.0
    {:ok, %{state | current_time: current_time}}
  end

  @impl true
  def cleanup(state) do
    IO.puts("""
    Cleaning up coordinate systems example...
    - Demonstrated model, view, and projection matrices
    - Showed 3D coordinate system transformations
    - Intentionally showed visual artifacts without depth testing
    - Next: Try example 6.2 to see the solution with depth testing enabled!
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
