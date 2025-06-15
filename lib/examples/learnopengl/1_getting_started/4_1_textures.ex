defmodule EAGL.Examples.LearnOpenGL.GettingStarted.Textures do
  @moduledoc """
  LearnOpenGL 4.1 - Textures

  This example demonstrates basic texture mapping in OpenGL - applying 2D images to 3D geometry.
  It corresponds to the Textures tutorial in the LearnOpenGL series and showcases EAGL's
  comprehensive texture loading capabilities.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/src/1.getting_started/4.1.textures>

  ## Framework Adaptation Notes

  In the original LearnOpenGL C++ tutorial, this example introduces textures:
  - Loading image files using stb_image.h library
  - Creating OpenGL texture objects
  - Setting texture parameters (wrapping, filtering)
  - Texture coordinates and sampling
  - Binding textures before rendering

  EAGL's framework preserves all these concepts while providing enhanced functionality:
  - **Real Image Loading**: Uses the same stb_image library as the original tutorial
  - **Graceful Degradation**: Automatic fallback to checkerboard patterns when images unavailable
  - **Pixel Alignment Handling**: Proper handling of non-4-byte-aligned image widths
  - **Y-Axis Correction**: Automatic Y-flip to match OpenGL coordinate conventions
  - **Format Detection**: Automatic channel detection (RGB, RGBA) and format selection

  ## EAGL vs Original Implementation

  **Original LearnOpenGL approach:** Uses stb_image.h to load container.jpg:
  ```c++
  int width, height, nrChannels;
  unsigned char *data = stbi_load("container.jpg", &width, &height, &nrChannels, 0);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, data);
  stbi_image_free(data);
  ```

  **EAGL approach:** Enhanced image loading with comprehensive error handling:
  ```elixir
  {:ok, texture_id, width, height} = load_texture_from_file("priv/images/eagl_logo_black_on_white.png")
  ```
  - **Same underlying library**: Uses stb_image (optional dependency)
  - **Enhanced error handling**: `{:ok, result}` tuples and comprehensive fallbacks
  - **Pixel alignment fix**: `glPixelStorei(GL_UNPACK_ALIGNMENT, 1)` for arbitrary image widths
  - **Coordinate system handling**: Automatic Y-flip for OpenGL convention
  - **Educational value**: Works with or without external dependencies

  ## Technical Improvements

  This implementation includes several technical enhancements over basic texture loading:

  1. **Pixel Alignment**: Handles images whose width × channels isn't 4-byte aligned
     - The 418×418 EAGL logo tests this fix (418 × 4 = 1672 bytes per row)
     - Prevents diagonal texture skewing common with arbitrary image dimensions

  2. **Y-Axis Handling**: Proper coordinate system conversion
     - Images typically have (0,0) at top-left
     - OpenGL expects (0,0) at bottom-left
     - Automatic Y-flip ensures textures appear right-side up

  3. **Format Detection**: Automatic channel count handling
     - 1 channel → GL_RED
     - 2 channels → GL_RG
     - 3 channels → GL_RGB
     - 4 channels → GL_RGBA

  ## Original Tutorial Concepts Demonstrated

  1. **Texture Objects**: Creating texture IDs with `create_texture()`
  2. **Texture Binding**: Binding textures with `:gl.bindTexture()`
  3. **Texture Parameters**: Setting wrap and filter modes with `set_texture_parameters()`
  4. **Texture Data**: Loading pixel data with `load_texture_data()`
  5. **Mipmaps**: Generating mipmaps with `:gl.generateMipmap()`
  6. **Texture Coordinates**: Adding texture coordinates to vertex data
  7. **Texture Sampling**: Using `sampler2D` and `texture()` in fragment shader

  ## Key Learning Points

  - Understanding texture coordinates (0,0 to 1,1 mapping)
  - Texture wrapping modes (repeat, clamp, etc.)
  - Texture filtering (nearest vs linear)
  - The relationship between vertex attributes and fragment shader inputs
  - How textures are sampled and interpolated across triangles
  - **Pixel alignment considerations** for arbitrary image dimensions
  - **Coordinate system differences** between image formats and OpenGL

  ## State Management Evolution

  This example marks change in the LearnOpenGL series implementation.
  Starting with textures, our OpenGL state becomes more complex as we need to track
  multiple resources: shader programs, vertex arrays, buffers, and now texture objects.

  **From 4.1 forward**, we transition to map-based state management for better
  maintainability and readability as examples grow in complexity.

  ## Vertex Data Structure

  The rectangle uses interleaved vertex data:
  - Position (3 floats): x, y, z coordinates
  - Color (3 floats): r, g, b values (for potential mixing)
  - Texture coordinates (2 floats): s, t coordinates

  ## Texture Mapping

  The rectangle is mapped with texture coordinates:
  - Bottom-left: (0.0, 0.0)
  - Bottom-right: (1.0, 0.0)
  - Top-right: (1.0, 1.0)
  - Top-left: (0.0, 1.0)

  ## Dependencies

  - **Optional**: `{:stb_image, "~> 0.6"}` for real image loading
  - **Fallback**: Procedural checkerboard generation when stb_image unavailable
  - **Educational**: Works in both scenarios with helpful guidance

  ## Usage

      EAGL.Examples.LearnOpenGL.GettingStarted.Textures.run_example()

  Press ENTER to exit the example.
  """

  use EAGL.Window
  use EAGL.Const

  import EAGL.Shader
  import EAGL.Buffer
  import EAGL.Texture

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
        "LearnOpenGL - 1 Getting Started - 4.1 Textures",
        return_to_exit: true
      )

  @impl true
  def setup do
    IO.puts("""
    === LearnOpenGL 4.1 - Textures ===
    This example demonstrates basic texture mapping

    Key Concepts:
    - Texture objects store 2D image data on the GPU
    - Texture coordinates (s,t) map from 0.0 to 1.0
    - Texture parameters control wrapping and filtering
    - Fragment shaders sample textures using texture() function
    - Mipmaps provide optimized rendering at different distances

    Texture Mapping:
    - Rectangle corners mapped to texture corners
    - GPU interpolates texture coordinates across surface
    - EAGL logo demonstrates real image texture sampling

    EAGL Framework Features:
    - Loads EAGL logo (eagl_logo_black_on_white.jpg) using stb_image
    - Automatic fallback to checkerboard if stb_image not available
    - Same OpenGL concepts as original tutorial
    - Graceful degradation with helpful error messages

    Press ENTER to exit.
    """)

    # Compile and link shaders
    with {:ok, vertex_shader} <-
           create_shader(
             :vertex,
             "learnopengl/1_getting_started/4_1_textures/vertex_shader.glsl"
           ),
         {:ok, fragment_shader} <-
           create_shader(
             :fragment,
             "learnopengl/1_getting_started/4_1_textures/fragment_shader.glsl"
           ),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do
      IO.puts("Vertex and fragment shaders compiled and linked successfully")

      # Create complex vertex attribute setup with indexed rendering
      # Each vertex: 3 position + 3 color + 2 texture = 8 floats (32 bytes)
      attributes = vertex_attributes(:position, :color, :texture_coordinate)

      {vao, vbo, ebo} = create_indexed_array(@vertices, @indices, attributes)

      IO.puts("Created VAO, VBO, and EBO (rectangle with texture coordinates)")

      # Load texture using EAGL.Texture abstraction
      {:ok, texture_id, width, height} = load_texture_from_file("priv/images/eagl_logo_black_on_white.jpg")
      IO.puts("Created texture (#{width}x#{height})")

      IO.puts("Ready to render - you should see an eagle attacking a teapot.")

      # Note: Starting with textures, our state becomes more complex with multiple
      # OpenGL resources to track. From this example forward, we'll use maps for
      # state management instead of tuples to make the code more readable and
      # maintainable as examples grow in complexity.
      {:ok, %{
        program: program,
        vao: vao,
        vbo: vbo,
        ebo: ebo,
        texture_id: texture_id
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

    # Set clear color (dark gray-blue) and clear screen
    :gl.clearColor(0.2, 0.3, 0.3, 1.0)
    :gl.clear(@gl_color_buffer_bit)

    # Bind texture
    :gl.bindTexture(@gl_texture_2d, state.texture_id)

    # Use the shader program
    :gl.useProgram(state.program)

    # Draw the rectangle
    :gl.bindVertexArray(state.vao)
    :gl.drawElements(@gl_triangles, 6, @gl_unsigned_int, 0)

    :ok
  end

  @impl true
  def cleanup(state) do
    # Clean up OpenGL resources
    :gl.deleteTextures([state.texture_id])
    delete_vertex_array(state.vao, [state.vbo, state.ebo])
    cleanup_program(state.program)
    IO.puts("Cleaned up all OpenGL resources")
    :ok
  end
end
