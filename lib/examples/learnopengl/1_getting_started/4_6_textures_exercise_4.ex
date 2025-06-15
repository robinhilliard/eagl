defmodule EAGL.Examples.LearnOpenGL.GettingStarted.TexturesExercise4 do
  @moduledoc """
  LearnOpenGL 4.6 - Textures Exercise 4

  This exercise demonstrates dynamic texture mixing with animated mix ratios.
  Instead of a fixed mix value, the blend between textures changes over time,
  creating an animated transition effect.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial exercises:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/src/1.getting_started/4.6.textures_exercise4>

  ## Exercise Focus

  This exercise demonstrates:
  - **Dynamic Uniforms**: Updating uniform values each frame
  - **Time-based Animation**: Using time to create smooth transitions
  - **Interactive Effects**: Creating animated visual effects with textures
  - **Mix Function Control**: Real-time control of texture blending

  ## EAGL Implementation

  This implementation uses time-based animation to cycle the mix ratio between
  two textures, creating a smooth transition effect:

  ```glsl
  # In the fragment shader:
  mix_factor = sin(time * 2.0) * 0.5 + 0.5  # Oscillates between 0.0 and 1.0
  FragColor = mix(texture1, texture2, mix_factor)
  ```

  ## Key Learning Points

  - **Dynamic Uniforms**: How to update shader uniforms each frame
  - **Time Animation**: Using time to create smooth, cyclic animations
  - **Visual Effects**: Creating engaging animated transitions
  - **Interactive Graphics**: Real-time parameter control in shaders

  ## Visual Effect

  The example shows two textures that smoothly blend back and forth over time.
  The mix ratio oscillates between 0.0 (first texture only) and 1.0 (second
  texture only), creating a rhythmic fade effect.

  ## Usage

      EAGL.Examples.LearnOpenGL.GettingStarted.TexturesExercise4.run_example()

  Press ENTER to exit the example.
  """

  use EAGL.Window
  use EAGL.Const

  import EAGL.Shader
  import EAGL.Buffer
  import EAGL.Texture
  import EAGL.Error
  import EAGL.Math

  # Rectangle vertex data with standard texture coordinates
  # Format: [x, y, z, r, g, b, s, t] per vertex
  @vertices ~v'''
  # positions        # colors         # texture coords
   0.5  0.5 0.0  1.0 0.0 0.0  1.0 1.0   # top right
   0.5 -0.5 0.0  0.0 1.0 0.0  1.0 0.0   # bottom right
  -0.5 -0.5 0.0  0.0 0.0 1.0  0.0 0.0   # bottom left
  -0.5  0.5 0.0  1.0 1.0 0.0  0.0 1.0   # top left
  '''

  # Indices for drawing the rectangle using two triangles
  @indices ~i'''
  0 1 3  # first triangle
  1 2 3  # second triangle
  '''

  @spec run_example() :: :ok | {:error, term()}
  def run_example,
    do:
      EAGL.Window.run(
        __MODULE__,
        "LearnOpenGL - 1 Getting Started - 4.6 Textures Exercise 4",
        return_to_exit: true
      )

  @impl true
  def setup do
    IO.puts("""
    === LearnOpenGL 4.6 - Textures Exercise 4 ===
    This exercise demonstrates animated texture mixing

    Exercise Focus:
    - Dynamic texture mixing with time-based animation
    - Mix ratio oscillates between 0.0 and 1.0 over time
    - Demonstrates real-time uniform updates
    - Creates smooth animated transitions between textures

    Expected Result:
    - Two textures blend back and forth smoothly
    - Mix ratio changes continuously based on time
    - Smooth sine wave transition creates rhythmic effect
    - Color mixing still applied from vertex colors

    Animation Details:
    - Mix factor: sin(time * 2.0) * 0.5 + 0.5
    - Range: 0.0 to 1.0 (0% to 100% second texture)
    - Period: Approximately π seconds for full cycle
    - Smooth transitions using sine wave function

    Press ENTER to exit.
    """)

    # Compile and link shaders
    with {:ok, vertex_shader} <-
           create_shader(
             :vertex,
             "learnopengl/1_getting_started/4_6_textures_exercise_4/vertex_shader.glsl"
           ),
         {:ok, fragment_shader} <-
           create_shader(
             :fragment,
             "learnopengl/1_getting_started/4_6_textures_exercise_4/fragment_shader.glsl"
           ),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do
      IO.puts("Vertex and fragment shaders compiled and linked successfully")

      # Create indexed vertex array with texture coordinates
      # Each vertex: 3 position + 3 color + 2 texture = 8 floats (32 bytes)
      attributes = vertex_attributes(:position, :color, :texture_coordinate)

      {vao, vbo, ebo} = create_indexed_array(@vertices, @indices, attributes)

      IO.puts("Created VAO, VBO, and EBO (rectangle with texture coordinates)")

      # Load first texture
      {:ok, texture1_id, width, height} =
        load_texture_from_file("priv/images/eagl_logo_black_on_white.jpg")

      IO.puts("Loaded texture 1: (#{width}x#{height})")

      # Create second texture - gradient pattern for contrast
      {:ok, texture2_id} = create_texture()
      :gl.bindTexture(@gl_texture_2d, texture2_id)

      set_texture_parameters(
        wrap_s: :repeat,
        wrap_t: :repeat,
        min_filter: :linear,
        mag_filter: :linear
      )

      # Create gradient pattern for second texture
      pattern_size = 128

      load_texture_data(pattern_size, pattern_size, create_gradient_pattern(pattern_size),
        internal_format: :rgb,
        format: :rgb,
        type: :unsigned_byte
      )

      :gl.generateMipmap(@gl_texture_2d)

      IO.puts("Created texture 2: gradient pattern (#{pattern_size}x#{pattern_size})")

      # Set up shader uniforms
      :gl.useProgram(program)

      # Set texture unit assignments
      set_uniforms(program,
        # GL_TEXTURE0
        texture1: 0,
        # GL_TEXTURE1
        texture2: 1
      )

      IO.puts("Set texture uniforms and initialized animation")

      check("After texture setup")

      # Initialize current time for animation (following 3.1 shaders uniform pattern)
      current_time = :erlang.monotonic_time(:millisecond) / 1000.0

      {:ok,
       %{
         program: program,
         vao: vao,
         vbo: vbo,
         ebo: ebo,
         texture1_id: texture1_id,
         texture2_id: texture2_id,
         current_time: current_time
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

    # Calculate animated mix factor using sine wave (following 3.1 shaders uniform pattern)
    # EAGL Framework Pattern: Use time from state updated by tick handler
    # This differs from calculating time directly in render loop
    # Benefits: Separates state updates from rendering, cleaner architecture
    # sin returns -1 to 1, so we map it to 0 to 1
    mix_factor = :math.sin(state.current_time * 2.0) * 0.5 + 0.5

    # Use our shader program
    :gl.useProgram(state.program)

    # Update the mix factor uniform
    set_uniform(state.program, "mixFactor", mix_factor)

    # Bind textures to their respective texture units
    :gl.activeTexture(@gl_texture0)
    :gl.bindTexture(@gl_texture_2d, state.texture1_id)

    :gl.activeTexture(@gl_texture1)
    :gl.bindTexture(@gl_texture_2d, state.texture2_id)

    # Render rectangle
    :gl.bindVertexArray(state.vao)
    :gl.drawElements(@gl_triangles, 6, @gl_unsigned_int, 0)

    check("After rendering")
    :ok
  end

  @impl true
  def handle_event(:tick, state) do
    # EAGL Framework Pattern: Update time state on each tick (following 3.1 shaders uniform pattern)
    # This separates state updates from rendering logic
    # Benefits:
    #   - Cleaner architecture and better testability
    #   - Fixed frames per second instead of animating as fast as possible
    #   - Consistent with other EAGL animation examples
    current_time = :erlang.monotonic_time(:millisecond) / 1000.0
    {:ok, %{state | current_time: current_time}}
  end

  @impl true
  def cleanup(state) do
    IO.puts("""
    Cleaning up textures exercise 4...
    - Demonstrated animated texture mixing
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

  # Helper function to create gradient pattern for second texture
  # Good example of rolling your own texture data
  defp create_gradient_pattern(size) do
    for _y <- 0..(size - 1), x <- 0..(size - 1) do
      # Create horizontal gradient from blue to yellow
      factor = x / (size - 1)
      red = trunc(factor * 255)
      green = trunc(factor * 255)
      blue = trunc((1.0 - factor) * 255)
      [red, green, blue]
    end
    |> List.flatten()
    |> :erlang.list_to_binary()
  end
end
