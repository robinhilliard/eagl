defmodule EAGL.Examples.Teapot do
  @moduledoc """
  Draw a 3D teapot.
  """

  use EAGL.Window
  use EAGL.Const
  use EAGL.Math

  import EAGL.Shader
  import EAGL.Model

  @spec run_example() :: :ok | {:error, term()}
  def run_example, do: EAGL.Window.run(__MODULE__, "EAGL Utah Teapot Example")

  @impl true
  def setup do
    with {:ok, vertex_shader} <- create_shader(@gl_vertex_shader, "vertex_shader_3d_red.glsl"),
         {:ok, fragment_shader} <- create_shader(@gl_fragment_shader, "fragment_shader_3d_default.glsl"),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]),
         {:ok, model} <- load_model_to_vao("teapot.obj") do
      {:ok, {program, model}}
    end
  end

  @impl true
  def render(viewport_width, viewport_height, {program, model}) do
    :gl.useProgram(program)
    :gl.enable(@gl_depth_test)
    :gl.polygonMode(@gl_front_and_back, @gl_fill)

    # Model matrix (identity to leave the model as is)
    model_matrix = mat4_identity()

    # View matrix (translate world to move camera back)
    view_matrix = mat4_look_at(
      vec3(0.0, 1.0, -5.0), # camera position (x, y, z)
      vec3(0.0, 1.0, 0.0),  # camera target (x, y, z)
      vec3(0.0, 1.0, 0.0)   # camera up vector (x, y, z)
    )

    # Perspective projection matrix
    projection_matrix = mat4_perspective(
      45.0, viewport_width / viewport_height, 0.1, 100.0)

    # Set uniform matrices
    :gl.getUniformLocation(program, ~c"model") |> :gl.uniformMatrix4fv(0, model_matrix)
    :gl.getUniformLocation(program, ~c"view") |> :gl.uniformMatrix4fv(0, view_matrix)
    :gl.getUniformLocation(program, ~c"projection") |> :gl.uniformMatrix4fv(0, projection_matrix)
    :gl.bindVertexArray(model.vao)
    :gl.drawElements(@gl_triangles, model.vertex_count, @gl_unsigned_int, 0)
    :ok
  end

  @impl true
  def cleanup({program, model}) do
    cleanup_program(program)
    delete_vao(model.vao)
    :ok
  end

end
