defmodule EAGL.Examples.LearnOpenGL.GettingStarted.TexturesExercise3 do
  @moduledoc """
  LearnOpenGL 4.5 - Textures Exercise 3

  This exercise demonstrates texture flipping by manipulating texture coordinates.
  Common variations include horizontal flipping, vertical flipping, or rotating
  textures through coordinate transformation.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial exercises:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/src/1.getting_started/4.5.textures_exercise3>

  ## Exercise Focus

  This exercise demonstrates:
  - **Texture Flipping**: Inverting texture coordinates to flip images
  - **Coordinate Manipulation**: How to transform texture space
  - **Visual Transformations**: Creating mirrored or rotated effects
  - **Creative Control**: Using coordinates for artistic effects

  ## EAGL Implementation

  This implementation demonstrates horizontal flipping by reversing the S (horizontal)
  texture coordinates:

  ```elixir
  @vertices [
    # positions      # colors       # texture coords (horizontally flipped)
     0.5,  0.5, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0,  # top right -> top left
     0.5, -0.5, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0,  # bottom right -> bottom left
    -0.5, -0.5, 0.0, 0.0, 0.0, 1.0, 1.0, 0.0,  # bottom left -> bottom right
    -0.5,  0.5, 0.0, 1.0, 1.0, 0.0, 1.0, 1.0   # top left -> top right
  ]
  ```

  ## Key Learning Points

  - **Coordinate Transformation**: How to manipulate texture coordinates
  - **Flipping Techniques**: Horizontal and vertical texture flipping
  - **Visual Effects**: Creating mirrored or transformed appearances
  - **Creative Applications**: Using coordinate manipulation for artistic control

  ## Usage

      EAGL.Examples.LearnOpenGL.GettingStarted.TexturesExercise3.run_example()

  Press ENTER to exit the example.
  """

  use EAGL.Window
  use EAGL.Const

  import EAGL.Shader
  import EAGL.Buffer
  import EAGL.Texture
  import EAGL.Error

  # Rectangle vertex data with horizontally flipped texture coordinates
  # Format: [x, y, z, r, g, b, s, t] per vertex
  # S coordinates are flipped: 1.0 becomes 0.0 and vice versa
  @vertices [
    # positions        # colors         # texture coords (horizontally flipped)
     0.5,  0.5, 0.0,   1.0, 0.0, 0.0,   0.0, 1.0,   # top right -> top left
     0.5, -0.5, 0.0,   0.0, 1.0, 0.0,   0.0, 0.0,   # bottom right -> bottom left
    -0.5, -0.5, 0.0,   0.0, 0.0, 1.0,   1.0, 0.0,   # bottom left -> bottom right
    -0.5,  0.5, 0.0,   1.0, 1.0, 0.0,   1.0, 1.0    # top left -> top right
  ]

  # Indices for drawing the rectangle using two triangles
  @indices [
    0, 1, 3,  # first triangle
    1, 2, 3   # second triangle
  ]

  @spec run_example() :: :ok | {:error, term()}
  def run_example,
    do:
      EAGL.Window.run(
        __MODULE__,
        "LearnOpenGL - 1 Getting Started - 4.5 Textures Exercise 3",
        return_to_exit: true
      )

  @impl true
  def setup do
    IO.puts("""
    === LearnOpenGL 4.5 - Textures Exercise 3 ===
    This exercise demonstrates texture coordinate flipping

    Exercise Focus:
    - Horizontal Flipping: S coordinates reversed (1.0 <-> 0.0)
    - Texture appears mirrored horizontally
    - Demonstrates coordinate transformation techniques
    - Shows creative control over texture appearance

    Expected Result:
    - Texture appears flipped horizontally (mirrored left-to-right)
    - Right side of original texture appears on left side
    - Left side of original texture appears on right side
    - Color mixing still applied from vertex colors

    Coordinate Transformation:
    - Normal: (0,0) to (1,1) maps texture as-is
    - Flipped: (1,0) to (0,1) maps texture horizontally mirrored
    - Can also flip vertically by reversing T coordinates
    - Or both for 180-degree rotation

    Press ENTER to exit.
    """)

    # Compile and link shaders
    with {:ok, vertex_shader} <-
           create_shader(
             :vertex,
             "learnopengl/1_getting_started/4_5_textures_exercise_3/vertex_shader.glsl"
           ),
         {:ok, fragment_shader} <-
           create_shader(
             :fragment,
             "learnopengl/1_getting_started/4_5_textures_exercise_3/fragment_shader.glsl"
           ),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do
      IO.puts("Vertex and fragment shaders compiled and linked successfully")

      # Create indexed vertex array with texture coordinates
      # Each vertex: 3 position + 3 color + 2 texture = 8 floats (32 bytes)
      attributes = vertex_attributes(:position, :color, :texture_coordinate)

      {vao, vbo, ebo} = create_indexed_array(@vertices, @indices, attributes)

      IO.puts("Created VAO, VBO, and EBO (rectangle with flipped texture coordinates)")

      # Load texture
      {:ok, texture_id, width, height} = load_texture_from_file("priv/images/eagl_logo_black_on_white.jpg")
      IO.puts("Loaded texture (#{width}x#{height}) - will be horizontally flipped")

      # Bind texture and set parameters
      :gl.bindTexture(@gl_texture_2d, texture_id)
      set_texture_parameters([
        wrap_s: :clamp_to_edge,  # Prevent wrapping artifacts
        wrap_t: :clamp_to_edge,  # Prevent wrapping artifacts
        min_filter: :linear,     # Smooth filtering
        mag_filter: :linear      # Smooth filtering
      ])

      # Generate mipmaps
      :gl.generateMipmap(@gl_texture_2d)

      check("After texture setup")

      {:ok, %{
        program: program,
        vao: vao,
        vbo: vbo,
        ebo: ebo,
        texture_id: texture_id
      }}
    else
      error ->
        IO.puts("Failed to set up shaders: #{inspect(error)}")
        {:error, error}
    end
  end

  @impl true
  def render(_width, _height, state) do
    # Clear the screen
    :gl.clearColor(0.2, 0.3, 0.3, 1.0)
    :gl.clear(@gl_color_buffer_bit)

    # Use our shader program
    :gl.useProgram(state.program)

    # Bind texture
    :gl.activeTexture(@gl_texture0)
    :gl.bindTexture(@gl_texture_2d, state.texture_id)

    # Render rectangle with flipped texture coordinates
    :gl.bindVertexArray(state.vao)
    :gl.drawElements(@gl_triangles, 6, @gl_unsigned_int, 0)

    check("After rendering")
    :ok
  end

  @impl true
  def cleanup(state) do
    IO.puts("""
    Cleaning up textures exercise 3...
    - Demonstrated horizontal texture flipping
    """)

    # Clean up texture
    :gl.deleteTextures([state.texture_id])

    # Clean up buffers
    delete_vertex_array(state.vao, state.vbo)
    :gl.deleteBuffers([state.ebo])

    # Clean up shader program
    :gl.deleteProgram(state.program)

    check("After cleanup")
    :ok
  end


end
