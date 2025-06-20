defmodule EAGL.Examples.LearnOpenGL.GettingStarted.CoordinateSystemsMultiple do
  @moduledoc """
  LearnOpenGL 6.3 - Coordinate Systems (Multiple)

  This example demonstrates rendering multiple objects with different transformations
  by drawing 10 cubes at various positions and rotations in 3D space.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/src/1.getting_started/6.3.coordinate_systems_multiple>

  ## Framework Adaptation Notes

  This example demonstrates:
  - Multiple objects with different model transformations
  - Efficient rendering with a single vertex array
  - Different transformation matrices for each object
  - 3D scene composition with multiple elements

  ## Key Learning Points

  - **Instanced Rendering Concept**: Multiple objects from one vertex array
  - **Matrix Variation**: Different transformations for each instance
  - **Scene Composition**: Arranging multiple objects in 3D space
  - **Rendering Loops**: Efficient multi-object rendering patterns

  ## Visual Effect

  Shows 10 cubes arranged in 3D space:
  - Each cube at a different position
  - Each cube with a unique static rotation (20 degrees × index)
  - Demonstrates scene complexity with coordinate systems

  ## Usage

      EAGL.Examples.LearnOpenGL.GettingStarted.CoordinateSystemsMultiple.run_example()

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

  # Positions for 10 cubes in 3D space
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
      "LearnOpenGL - 1 Getting Started - 6.3 Coordinate Systems (Multiple)",
      merged_opts
    )
  end

  @impl true
  def setup do
    IO.puts("""
    === LearnOpenGL 6.3 - Coordinate Systems (Multiple) ===
    This example demonstrates rendering multiple objects in 3D space

    Key Concepts:
    - Multiple Object Rendering: Drawing many objects from one vertex array
    - Transformation Variation: Different model matrix for each object
    - Scene Composition: Arranging objects to create a complex 3D scene
    - Rendering Efficiency: Reusing vertex data with different transformations

    Rendering Approach:
    1. Create one vertex array with cube geometry
    2. For each cube position, calculate unique model matrix
    3. Set model matrix uniform and draw the cube
    4. Repeat for all cube positions using same vertex data
    5. View and projection matrices remain constant

    Performance Considerations:
    - Single vertex array reduces GPU memory usage
    - Model matrix changes are relatively cheap uniform updates
    - This approach works well for moderate numbers of objects
    - For many objects, instanced rendering would be more efficient

    Mathematical Concepts:
    - Each cube has its own local-to-world transformation
    - Some cubes rotate to show animation over time
    - Camera remains fixed while objects move in world space
    - Depth testing handles occlusion between cubes automatically

    Visual Result:
    - 10 cubes scattered throughout 3D space
    - Each cube with unique static rotation (20° × index)
    - Proper depth sorting via Z-buffer
    - Demonstrates coordinate system transformations at scale

    Press ENTER to exit.
    """)

    # Compile and link shaders
    with {:ok, vertex_shader} <-
           create_shader(
             @gl_vertex_shader,
             "learnopengl/1_getting_started/6_3_coordinate_systems_multiple/vertex_shader.glsl"
           ),
         {:ok, fragment_shader} <-
           create_shader(
             @gl_fragment_shader,
             "learnopengl/1_getting_started/6_3_coordinate_systems_multiple/fragment_shader.glsl"
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

      IO.puts("Ready to render - you should see 10 cubes scattered in 3D space.")

      {:ok,
       %{
         program: program,
         vao: vao,
         vbo: vbo,
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

    # Set clear color and clear screen and depth buffer
    :gl.clearColor(0.2, 0.3, 0.3, 1.0)
    :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)

    # Bind texture
    :gl.activeTexture(@gl_texture0)
    :gl.bindTexture(@gl_texture_2d, state.texture_id)

    # Use the shader program
    :gl.useProgram(state.program)

    # Create view and projection matrices (same for all cubes)
    view =
      mat4_identity()
      |> mat4_mul(mat4_translate(vec3(0.0, 0.0, -3.0)))

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

    check("After rendering multiple cubes")
    :ok
  end

  @impl true
  def cleanup(state) do
    IO.puts("""
    Cleaning up coordinate systems multiple example...
    - Demonstrated multiple object rendering with single vertex array
    - Showed scene composition with various transformations
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
