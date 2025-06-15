defmodule EAGL.Examples.LearnOpenGL.GettingStarted.TexturesCombined do
  @moduledoc """
  LearnOpenGL 4.2 - Textures Combined

  This example demonstrates using multiple texture units to combine textures in a single
  fragment shader. It builds on the basic texture concepts from 4.1 and shows how to
  mix two textures together using GLSL's mix() function.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/src/1.getting_started/4.2.textures_combined>

  ## Framework Adaptation Notes

  In the original LearnOpenGL C++ tutorial, this example introduces:
  - Multiple texture units (GL_TEXTURE0, GL_TEXTURE1)
  - Binding textures to different texture units
  - Using multiple sampler2D uniforms in fragment shader
  - The GLSL mix() function for blending textures
  - Setting sampler uniform values to specify texture units

  EAGL's framework preserves all these concepts while providing enhanced functionality:
  - **Simplified texture loading**: Uses EAGL's texture helpers with fallback support
  - **Graceful degradation**: Works with or without external image dependencies
  - **Error handling**: Comprehensive error checking and user feedback
  - **Educational value**: Clear documentation of texture unit concepts

  ## EAGL vs Original Implementation

  **Original LearnOpenGL approach:** Manual texture unit management:
  ```c++
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, texture1);
  glActiveTexture(GL_TEXTURE1);
  glBindTexture(GL_TEXTURE_2D, texture2);
  glUniform1i(glGetUniformLocation(shaderProgram, "texture1"), 0);
  glUniform1i(glGetUniformLocation(shaderProgram, "texture2"), 1);
  ```

  **EAGL approach:** Texture helpers with explicit texture unit management:
  ```elixir
  # Load textures with fallback
  {:ok, texture1_id, _, _} = load_texture_from_file("image1.jpg")
  {:ok, texture2_id, _, _} = create_checkerboard_texture(256, 32)

  # Set shader uniforms
  set_uniforms(program, [
    texture1: 0,  # Texture unit 0
    texture2: 1   # Texture unit 1
  ])
  ```

  ## Key Learning Points

  - **Texture Units**: OpenGL provides multiple texture units (GL_TEXTURE0, GL_TEXTURE1, etc.)
  - **Sampler Uniforms**: Fragment shaders can have multiple sampler2D uniforms
  - **Texture Binding**: Each texture unit can have a different texture bound
  - **Mix Function**: GLSL's mix() function linearly interpolates between two values
  - **Uniform Assignment**: Sampler uniforms need to be set to the correct texture unit number

  ## Texture Mixing

  The fragment shader uses GLSL's mix() function:
  ```glsl
  FragColor = mix(texture(texture1, TexCoord), texture(texture2, TexCoord), 0.2);
  ```
  - First parameter: First texture sample
  - Second parameter: Second texture sample
  - Third parameter: Mix factor (0.2 = 80% first texture, 20% second texture)

  ## Usage

      EAGL.Examples.LearnOpenGL.GettingStarted.TexturesCombined.run_example()

  Press ENTER to exit the example.
  """

  use EAGL.Window
  use EAGL.Const

  import EAGL.Shader
  import EAGL.Buffer
  import EAGL.Texture
  import EAGL.Error

  # Rectangle vertex data with positions, colors, and texture coordinates
  # Format: [x, y, z, r, g, b, s, t] per vertex
  @vertices [
    # positions        # colors         # texture coords
     0.5,  0.5, 0.0,   1.0, 0.0, 0.0,   1.0, 1.0,   # top right
     0.5, -0.5, 0.0,   0.0, 1.0, 0.0,   1.0, 0.0,   # bottom right
    -0.5, -0.5, 0.0,   0.0, 0.0, 1.0,   0.0, 0.0,   # bottom left
    -0.5,  0.5, 0.0,   1.0, 1.0, 0.0,   0.0, 1.0    # top left
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
        "LearnOpenGL - 1 Getting Started - 4.2 Textures Combined",
        return_to_exit: true
      )

  @impl true
  def setup do
    IO.puts("""
    === LearnOpenGL 4.2 - Textures Combined ===
    This example demonstrates multiple texture units and texture mixing!

    Key Concepts:
    - Multiple texture units allow binding different textures
    - Fragment shaders can sample from multiple textures
    - GLSL mix() function blends textures with specified ratios
    - Sampler uniforms specify which texture unit to use
    - Texture units range from GL_TEXTURE0 to GL_TEXTURE15+

    Texture Mixing Process:
    - Texture 1: EAGL logo loaded from file
    - Texture 2: Procedural checkerboard pattern
    - Fragment shader: mix(texture1, texture2, 0.2) = 80% logo + 20% checkerboard
    - Result: Logo with subtle checkerboard overlay

    EAGL Framework Features:
    - Automatic texture loading with fallback support
    - Simplified uniform setting for multiple samplers
    - Same OpenGL concepts as original tutorial
    - Educational texture unit management

    Press ENTER to exit.
    """)

    # Compile and link shaders
    with {:ok, vertex_shader} <-
           create_shader(
             :vertex,
             "learnopengl/1_getting_started/4_2_textures_combined/vertex_shader.glsl"
           ),
         {:ok, fragment_shader} <-
           create_shader(
             :fragment,
             "learnopengl/1_getting_started/4_2_textures_combined/fragment_shader.glsl"
           ),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do
      IO.puts("Vertex and fragment shaders compiled and linked successfully")

      # Create VAO, VBO, and EBO for rectangle with texture coordinates
      stride = 8 * 4  # 8 floats per vertex * 4 bytes per float
      {vao, vbo, ebo} = create_indexed_array(@vertices, @indices, [
        {0, 3, @gl_float, @gl_false, stride, 0},         # position at location 0, offset 0
        {1, 3, @gl_float, @gl_false, stride, 3 * 4},     # color at location 1, offset 12
        {2, 2, @gl_float, @gl_false, stride, 6 * 4}      # texture coords at location 2, offset 24
      ])

      IO.puts("Created VAO, VBO, and EBO (rectangle with texture coordinates)")

      # Load first texture
      {:ok, texture1_id, width, height} = load_texture_from_file("priv/images/eagl_logo_black_on_white.jpg")
      IO.puts("Loaded texture 1: (#{width}x#{height})")

      # Load second texture - create a different pattern for contrast
      {:ok, texture2_id, width2, height2} = create_checkerboard_texture(128, 8)
      IO.puts("Created texture 2: fine checkerboard (#{width2}x#{height2})")

      # Set up shader uniforms
      :gl.useProgram(program)

      # Set sampler uniforms to specify texture units
      # texture1 will use texture unit 0 (GL_TEXTURE0)
      # texture2 will use texture unit 1 (GL_TEXTURE1)
      set_uniforms(program, [
        texture1: 0,  # GL_TEXTURE0
        texture2: 1   # GL_TEXTURE1
      ])

      IO.puts("Set texture uniforms: texture1=unit 0, texture2=unit 1")

      check("After texture setup")

      {:ok, %{
        program: program,
        vao: vao,
        vbo: vbo,
        ebo: ebo,
        texture1_id: texture1_id,
        texture2_id: texture2_id
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

    # Bind textures to their respective texture units
    # Texture 1 -> texture unit 0
    :gl.activeTexture(@gl_texture0)
    :gl.bindTexture(@gl_texture_2d, state.texture1_id)

    # Texture 2 -> texture unit 1
    :gl.activeTexture(@gl_texture1)
    :gl.bindTexture(@gl_texture_2d, state.texture2_id)

    # Render rectangle
    :gl.bindVertexArray(state.vao)
    :gl.drawElements(@gl_triangles, 6, @gl_unsigned_int, 0)

    check("After rendering")
    :ok
  end

  @impl true
  def cleanup(state) do
    IO.puts("""
    Cleaning up textures combined example...
    - Demonstrated texture combining with multiple texture units
    """)

    # Clean up textures
    :gl.deleteTextures([state.texture1_id, state.texture2_id])

    # Clean up buffers
    delete_vertex_array(state.vao, state.vbo)
    :gl.deleteBuffers([state.ebo])

    # Clean up shader program
    :gl.deleteProgram(state.program)

    check("After cleanup")
    :ok
  end
end
