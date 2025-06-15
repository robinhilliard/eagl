defmodule EAGL.Examples.LearnOpenGL.GettingStarted.TexturesExercise1 do
  @moduledoc """
  LearnOpenGL 4.3 - Textures Exercise 1

  This exercise demonstrates texture coordinate manipulation to show only part of a texture
  or flip its orientation. It's commonly used to show the center pixels of a texture or
  to flip textures horizontally/vertically.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial exercises:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/src/1.getting_started/4.3.textures_exercise1>

  ## Exercise Focus

  Common texture coordinate exercises include:
  - **Center Cropping**: Using texture coordinates like (0.25, 0.25) to (0.75, 0.75)
  - **Texture Flipping**: Reversing texture coordinates to flip images
  - **Coordinate Scaling**: Using coordinates > 1.0 to see texture wrapping effects
  - **Pixel Visibility**: Using GL_NEAREST filtering to see individual pixels

  ## EAGL Implementation

  This implementation demonstrates center cropping - showing only the central portion
  of the texture by using texture coordinates that map to the center 50% of the image:

  ```elixir
  # Instead of full texture coordinates (0.0 to 1.0)
  # Use center coordinates (0.25 to 0.75)
  @vertices [
    # positions      # colors       # texture coords (center crop)
     0.5,  0.5, 0.0, 1.0, 0.0, 0.0, 0.75, 0.75,  # top right
     0.5, -0.5, 0.0, 0.0, 1.0, 0.0, 0.75, 0.25,  # bottom right
    -0.5, -0.5, 0.0, 0.0, 0.0, 1.0, 0.25, 0.25,  # bottom left
    -0.5,  0.5, 0.0, 1.0, 1.0, 0.0, 0.25, 0.75   # top left
  ]
  ```

  ## Key Learning Points

  - **Texture Coordinates**: Don't have to span full 0.0 to 1.0 range
  - **Partial Sampling**: Can show only portions of textures
  - **Coordinate Mapping**: How vertex positions map to texture coordinates
  - **Filtering Effects**: How GL_NEAREST vs GL_LINEAR affects small texture regions
  - **Creative Control**: Texture coordinates provide artistic flexibility

  ## Visual Effect

  This exercise shows only the center portion of the texture, effectively cropping
  the image and scaling it to fill the rectangle. With GL_NEAREST filtering,
  individual pixels become more visible.

  ## Usage

      EAGL.Examples.LearnOpenGL.GettingStarted.TexturesExercise1.run_example()

  Press ENTER to exit the example.
  """

  use EAGL.Window
  use EAGL.Const

  import EAGL.Shader
  import EAGL.Buffer
  import EAGL.Texture
  import EAGL.Error

  # Rectangle vertex data with modified texture coordinates for center cropping
  # Format: [x, y, z, r, g, b, s, t] per vertex
  # Texture coordinates show center 50% of image (0.25 to 0.75 range)
  @vertices [
    # positions        # colors         # texture coords (center crop)
     0.5,  0.5, 0.0,   1.0, 0.0, 0.0,   0.75, 0.75,   # top right
     0.5, -0.5, 0.0,   0.0, 1.0, 0.0,   0.75, 0.25,   # bottom right
    -0.5, -0.5, 0.0,   0.0, 0.0, 1.0,   0.25, 0.25,   # bottom left
    -0.5,  0.5, 0.0,   1.0, 1.0, 0.0,   0.25, 0.75    # top left
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
        "LearnOpenGL - 1 Getting Started - 4.3 Textures Exercise 1",
        return_to_exit: true
      )

  @impl true
  def setup do
    IO.puts("""
    === LearnOpenGL 4.3 - Textures Exercise 1 ===
    This exercise demonstrates texture coordinate manipulation!

    Exercise Focus:
    - Center Cropping: Show only the center portion of textures
    - Texture coordinates range from 0.25 to 0.75 instead of 0.0 to 1.0
    - GL_NEAREST filtering makes individual pixels more visible
    - Demonstrates flexible texture coordinate mapping

    Expected Result:
    - Only the center 50% of the texture is shown
    - The center portion is scaled to fill the entire rectangle
    - Individual pixels are visible due to GL_NEAREST filtering
    - Color mixing still applied from vertex colors

    Learning Points:
    - Texture coordinates don't need to span full 0-1 range
    - Can crop, flip, or scale textures via coordinate manipulation
    - Filtering method affects appearance of scaled texture regions
    - Provides artistic control over texture appearance

    Press ENTER to exit.
    """)

    # Compile and link shaders (same as basic texture example)
    with {:ok, vertex_shader} <-
           create_shader(
             :vertex,
             "learnopengl/1_getting_started/4_3_textures_exercise_1/vertex_shader.glsl"
           ),
         {:ok, fragment_shader} <-
           create_shader(
             :fragment,
             "learnopengl/1_getting_started/4_3_textures_exercise_1/fragment_shader.glsl"
           ),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do
      IO.puts("Vertex and fragment shaders compiled and linked successfully")

      # Create indexed vertex array with texture coordinates
      # Each vertex: 3 position + 3 color + 2 texture = 8 floats (32 bytes)
      attributes = vertex_attributes(:position, :color, :texture_coordinate)

      {vao, vbo, ebo} = create_indexed_array(@vertices, @indices, attributes)

      IO.puts("Created VAO, VBO, and EBO (rectangle with center-crop texture coordinates)")

            # Load texture
      {:ok, texture_id, width, height} = load_texture_from_file("priv/images/eagl_logo_black_on_white.jpg")
      IO.puts("Loaded texture (#{width}x#{height}) - showing center crop")

      # Bind texture to configure parameters
      :gl.bindTexture(@gl_texture_2d, texture_id)

      # Set texture parameters - use GL_NEAREST to see individual pixels clearly
      set_texture_parameters([
        wrap_s: :clamp_to_edge,      # Prevent wrapping artifacts
        wrap_t: :clamp_to_edge,      # Prevent wrapping artifacts
        min_filter: :nearest,        # Show pixels clearly
        mag_filter: :nearest         # Show pixels clearly
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

    # Render rectangle with center-cropped texture coordinates
    :gl.bindVertexArray(state.vao)
    :gl.drawElements(@gl_triangles, 6, @gl_unsigned_int, 0)

    check("After rendering")
    :ok
  end

  @impl true
  def cleanup(state) do
    IO.puts("""
    Cleaning up textures exercise 1...
    - Demonstrated center cropping with texture coordinates
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
