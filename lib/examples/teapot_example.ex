defmodule EAGL.Examples.Teapot do
  @moduledoc """
  Draw a 3D teapot with Phong shading.
  Press ESC to quit
  """

  use EAGL.Window
  use EAGL.Const

  import Bitwise
  import EAGL.Shader
  import EAGL.Model
  import EAGL.Math

  @spec run_example() :: :ok | {:error, term()}
  def run_example, do: EAGL.Window.run(__MODULE__, "EAGL Utah Teapot Example")

  @impl true
  def setup do
    # Load all three shader programs
    with {:ok, vertex_phong} <- create_shader(@gl_vertex_shader, "vertex_shader_phong.glsl"),
         {:ok, fragment_phong} <- create_shader(@gl_fragment_shader, "fragment_shader_phong_porcelain.glsl"),
         {:ok, program} <- create_attach_link([vertex_phong, fragment_phong]),
         {:ok, model} <- load_model_to_vao("teapot.obj", clockwise_winding: true) do

      # State: {program, model, time}
      {:ok, {program, model, :erlang.monotonic_time(:millisecond)}}
    end
  end


  @impl true
  def render(viewport_width, viewport_height, {program, model, time}) do
    :gl.useProgram(program)

    # Set viewport to use the full window
    :gl.viewport(0, 0, trunc(viewport_width), trunc(viewport_height))

    # Enable depth testing and configure it properly
    :gl.enable(@gl_depth_test)
    :gl.depthFunc(@gl_less)
    :gl.clearDepth(1.0)
    :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)

    # Enable face culling to hide back faces
    :gl.enable(@gl_cull_face)
    :gl.cullFace(@gl_back)

    # The teapot uses non-standard clockwise winding for front faces
    :gl.frontFace(@gl_ccw)

    # Set polygon mode
    :gl.polygonMode(@gl_front_and_back, @gl_fill)

    # Common transformation matrices
    model_matrix =mat4_rotate_y(time / -5000.0)
    camera_position = vec3(0.0, 4.0, -8.0)
    view_matrix = mat4_look_at(
      camera_position,          # camera position
      vec3(0.0, 1.0, 0.0),     # camera target
      vec3(0.0, 1.0, 0.0)      # camera up vector
    )

    # Guard against division by zero
    aspect_ratio = if viewport_height > 0, do: viewport_width / viewport_height, else: 1.0
    projection_matrix = mat4_perspective(
      radians(45.0), aspect_ratio, 1.0, 20.0)

    # Set common uniforms
    :gl.getUniformLocation(program, ~c"model") |> :gl.uniformMatrix4fv(0, model_matrix)
    :gl.getUniformLocation(program, ~c"view") |> :gl.uniformMatrix4fv(0, view_matrix)
    :gl.getUniformLocation(program, ~c"projection") |> :gl.uniformMatrix4fv(0, projection_matrix)

    light_position = mat4_rotate_y(time / 1000.0) |> mat4_transform_point(vec3(4.0, 4.0, -4.0))
    light_color = vec3(1.0, 1.0, 1.0)  # White light

    [{cam_x, cam_y, cam_z}] = camera_position
    [{light_x, light_y, light_z}] = light_position
    [{light_r, light_g, light_b}] = light_color

    :gl.getUniformLocation(program, ~c"light_position") |> :gl.uniform3f(light_x, light_y, light_z)
    :gl.getUniformLocation(program, ~c"light_color") |> :gl.uniform3f(light_r, light_g, light_b)
    :gl.getUniformLocation(program, ~c"camera_position") |> :gl.uniform3f(cam_x, cam_y, cam_z)

    # Render the model
    :gl.bindVertexArray(model.vao)
    :gl.drawElements(@gl_triangles, model.vertex_count, @gl_unsigned_int, 0)

    :ok
  end

  @impl true
  def handle_event(:tick, {program, model, _time}) do
    {:ok, {program, model, :erlang.monotonic_time(:millisecond)}}
  end

  def handle_event({:key, key_code}, {program, model, time}) do
    if key_code == 27 do
      throw(:close_window)
    end
    {:ok, {program, model, time}}
  end

  @impl true
  def cleanup({program, model, _time}) do
    cleanup_program(program)
    delete_vao(model.vao)
    :ok
  end
end
