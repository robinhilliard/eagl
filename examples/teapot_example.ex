defmodule EAGL.Examples.Teapot do
  @moduledoc """
  Draw a 3D teapot with Phong shading.
  Press ENTER to quit
  """

  use EAGL.Window
  use EAGL.Const

  import Bitwise
  import EAGL.Shader
  import EAGL.Model
  import EAGL.Math

  @teapot_360_rotation_ms 5000.0
  @light_360_rotation_ms 1000.0
  @vertex_source_file "vertex_shader_phong.glsl"
  @fragment_source_file "fragment_shader_phong_porcelain.glsl"

  @spec run_example() :: :ok | {:error, term()}
  def run_example(opts \\ []) do
    default_opts = [depth_testing: true, enter_to_exit: true]
    merged_opts = Keyword.merge(default_opts, opts)

    EAGL.Window.run(__MODULE__, "EaGL Utah Teapot Example", merged_opts)
  end

  @impl true
  def setup do
    # Load all three shader programs
    with {:ok, vertex_phong} <- create_shader(@gl_vertex_shader, @vertex_source_file),
         {:ok, fragment_phong} <- create_shader(@gl_fragment_shader, @fragment_source_file),
         {:ok, program} <- create_attach_link([vertex_phong, fragment_phong]),
         {:ok, model} <- load_model_to_vao("teapot.obj") do
      # State: {program, model, time}
      {:ok, {program, model, :erlang.monotonic_time(:millisecond)}}
    end
  end

  @impl true
  def render(viewport_width, viewport_height, {program, model, time}) do
    :gl.useProgram(program)

    # Set viewport to use the full window
    :gl.viewport(0, 0, trunc(viewport_width), trunc(viewport_height))

    # Clear screen (depth testing is handled by window configuration)
    :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)

    # Enable face culling to hide back faces
    :gl.enable(@gl_cull_face)
    :gl.cullFace(@gl_back)

    # The teapot uses standard counter-clockwise winding for front faces
    :gl.frontFace(@gl_ccw)

    # Set polygon mode
    :gl.polygonMode(@gl_front_and_back, @gl_fill)

    # Common transformation matrices
    model_matrix = mat4_rotate_y(time / -@teapot_360_rotation_ms)
    camera_position = vec3(0.0, 4.0, -8.0)

    view_matrix =
      mat4_look_at(
        # camera position
        camera_position,
        # camera target
        vec3(0.0, 1.0, 0.0),
        # camera up vector
        vec3(0.0, 1.0, 0.0)
      )

    # Guard against division by zero
    aspect_ratio = if viewport_height > 0, do: viewport_width / viewport_height, else: 1.0
    projection_matrix = mat4_perspective(radians(45.0), aspect_ratio, 1.0, 20.0)

    light_position =
      mat4_rotate_y(time / @light_360_rotation_ms) |> mat4_transform_point(vec3(4.0, 4.0, -4.0))

    # White light
    light_color = vec3(1.0, 1.0, 1.0)

    # Set all uniforms at once using helper function
    set_uniforms(program,
      model: model_matrix,
      view: view_matrix,
      projection: projection_matrix,
      light_position: light_position,
      light_color: light_color,
      camera_position: camera_position
    )

    # Render the model
    :gl.bindVertexArray(model.vao)
    :gl.drawElements(@gl_triangles, model.vertex_count, @gl_unsigned_int, 0)
    :ok
  end

  @impl true
  def handle_event({:tick, _time_delta}, {program, model, _time}) do
    {:ok, {program, model, :erlang.monotonic_time(:millisecond)}}
  end

  @impl true
  def cleanup({program, model, _time}) do
    cleanup_program(program)
    delete_vao(model.vao)
    :ok
  end
end
