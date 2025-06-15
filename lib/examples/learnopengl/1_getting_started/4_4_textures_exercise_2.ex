defmodule EAGL.Examples.LearnOpenGL.GettingStarted.TexturesExercise2 do
  @moduledoc """
  LearnOpenGL 4.4 - Textures Exercise 2

  This exercise demonstrates texture wrapping modes by using texture coordinates
  outside the 0.0 to 1.0 range. It shows how different wrapping modes (repeat,
  mirrored repeat, clamp to edge, clamp to border) affect texture appearance.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial exercises:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/src/1.getting_started/4.4.textures_exercise2>

  ## Exercise Focus

  This exercise demonstrates:
  - **Texture Coordinates > 1.0**: Using coordinates like 0.0 to 2.0 instead of 0.0 to 1.0
  - **Texture Wrapping Modes**: Different ways OpenGL handles out-of-range coordinates
  - **Visual Patterns**: How wrapping creates repeating or clamped patterns
  - **Border Colors**: Setting custom colors for border clamping mode

  ## Texture Wrapping Modes

  - **GL_REPEAT**: Default - texture repeats infinitely (tiles)
  - **GL_MIRRORED_REPEAT**: Texture repeats but alternates mirrored
  - **GL_CLAMP_TO_EDGE**: Coordinates clamped to 0.0-1.0, edges stretched
  - **GL_CLAMP_TO_BORDER**: Out-of-range areas filled with border color

  ## EAGL Implementation

  This implementation uses texture coordinates from 0.0 to 2.0, causing the texture
  to repeat twice in each direction with GL_REPEAT mode:

  ```elixir
  @vertices [
    # positions      # colors       # texture coords (0.0 to 2.0)
     0.5,  0.5, 0.0, 1.0, 0.0, 0.0, 2.0, 2.0,  # top right
     0.5, -0.5, 0.0, 0.0, 1.0, 0.0, 2.0, 0.0,  # bottom right
    -0.5, -0.5, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0,  # bottom left
    -0.5,  0.5, 0.0, 1.0, 1.0, 0.0, 0.0, 2.0   # top left
  ]
  ```

  ## Key Learning Points

  - **Texture Wrapping**: How OpenGL handles coordinates outside 0.0-1.0
  - **Tiling Effects**: Creating repeating patterns with textures
  - **Border Control**: Using custom border colors for specific effects
  - **Pattern Variety**: Different wrapping modes create different visual patterns

  ## Visual Effect

  With GL_REPEAT mode and 2.0 coordinates, you'll see the texture repeated
  4 times (2x2 grid). This demonstrates how texture wrapping enables tiling
  patterns for surfaces like floors, walls, or repeating backgrounds.

  ## Usage

      EAGL.Examples.LearnOpenGL.GettingStarted.TexturesExercise2.run_example()

  Press ENTER to exit the example.
  """

  use EAGL.Window
  use EAGL.Const

  import EAGL.Shader
  import EAGL.Buffer
  import EAGL.Texture
  import EAGL.Error

  # Rectangle vertex data with extended texture coordinates for wrapping demonstration
  # Format: [x, y, z, r, g, b, s, t] per vertex
  # Texture coordinates go from 0.0 to 2.0 to show wrapping behavior
  @vertices [
    # positions        # colors         # texture coords (0.0 to 2.0)
     0.5,  0.5, 0.0,   1.0, 0.0, 0.0,   2.0, 2.0,   # top right
     0.5, -0.5, 0.0,   0.0, 1.0, 0.0,   2.0, 0.0,   # bottom right
    -0.5, -0.5, 0.0,   0.0, 0.0, 1.0,   0.0, 0.0,   # bottom left
    -0.5,  0.5, 0.0,   1.0, 1.0, 0.0,   0.0, 2.0    # top left
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
        "LearnOpenGL - 1 Getting Started - 4.4 Textures Exercise 2",
        return_to_exit: true
      )

  @impl true
  def setup do
    IO.puts("""
    === LearnOpenGL 4.4 - Textures Exercise 2 ===
    This exercise demonstrates texture wrapping modes!

    Exercise Focus:
    - Texture coordinates from 0.0 to 2.0 (beyond normal range)
    - GL_REPEAT wrapping mode creates tiling patterns
    - Demonstrates how OpenGL handles out-of-range coordinates
    - Shows texture repetition for creating tiled surfaces

    Expected Result:
    - Texture repeated 4 times in a 2x2 grid pattern
    - Demonstrates seamless texture tiling
    - Same texture appears 4 times with GL_REPEAT mode
    - Color mixing still applied from vertex colors

    Texture Wrapping Modes (this example uses GL_REPEAT):
    - GL_REPEAT: Texture tiles infinitely (demonstrated here)
    - GL_MIRRORED_REPEAT: Tiles with alternating mirroring
    - GL_CLAMP_TO_EDGE: Edges stretched to fill out-of-range areas
    - GL_CLAMP_TO_BORDER: Out-of-range filled with border color

    Press ENTER to exit.
    """)

    # Compile and link shaders
    with {:ok, vertex_shader} <-
           create_shader(
             :vertex,
             "learnopengl/1_getting_started/4_4_textures_exercise_2/vertex_shader.glsl"
           ),
         {:ok, fragment_shader} <-
           create_shader(
             :fragment,
             "learnopengl/1_getting_started/4_4_textures_exercise_2/fragment_shader.glsl"
           ),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do
      IO.puts("Vertex and fragment shaders compiled and linked successfully")

      # Create VAO, VBO, and EBO for rectangle with extended texture coordinates
      stride = 8 * 4  # 8 floats per vertex * 4 bytes per float
      {vao, vbo, ebo} = create_indexed_array(@vertices, @indices, [
        {0, 3, @gl_float, @gl_false, stride, 0},         # position at location 0, offset 0
        {1, 3, @gl_float, @gl_false, stride, 3 * 4},     # color at location 1, offset 12
        {2, 2, @gl_float, @gl_false, stride, 6 * 4}      # texture coords at location 2, offset 24
      ])

      IO.puts("Created VAO, VBO, and EBO (rectangle with extended texture coordinates)")

      # Load texture
      {:ok, texture_id, width, height} = load_texture_from_file("priv/images/eagl_logo_black_on_white.jpg")
      IO.puts("Loaded texture (#{width}x#{height}) - will repeat 2x2")

      # Bind texture and set parameters for wrapping demonstration
      :gl.bindTexture(@gl_texture_2d, texture_id)
      set_texture_parameters([
        wrap_s: :repeat,        # Enable texture repetition on S axis
        wrap_t: :repeat,        # Enable texture repetition on T axis
        min_filter: :linear,    # Smooth filtering for better visual quality
        mag_filter: :linear     # Smooth filtering for better visual quality
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

    # Render rectangle with extended texture coordinates
    :gl.bindVertexArray(state.vao)
    :gl.drawElements(@gl_triangles, 6, @gl_unsigned_int, 0)

    check("After rendering")
    :ok
  end

  @impl true
  def cleanup(state) do
    IO.puts("""
    Cleaning up textures exercise 2...
    - Demonstrated GL_REPEAT wrapping mode
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
