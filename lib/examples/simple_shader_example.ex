defmodule EAGL.Examples.SimpleShader do
  @moduledoc """
  Draw a blue point.
  """

  use EAGL.Window
  use EAGL.Const
  import EAGL.Shader

  @spec run_example() :: :ok | {:error, term()}
  def run_example, do: EAGL.Window.run(__MODULE__, "EAGL Simple Shader Example")

  @impl true
  def setup do
    with {:ok, vertex_shader} <- create_shader(@gl_vertex_shader, "vertex_shader_2d_default.glsl"),
         {:ok, fragment_shader} <- create_shader(@gl_fragment_shader, "fragment_shader_2d_default.glsl"),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do
      {:ok, program}
    else
      error -> error
    end
  end

  @impl true
  def render(_, _, program) do
    :gl.useProgram(program)
    :gl.enable(@gl_point_smooth)
    :gl.enable(@gl_point_size)
    :gl.pointSize(5.0)
    :gl.begin(@gl_points)
    :gl.vertex3f(0.0, 0.0, 0.0)
    :gl.end()
    :ok
  end

  @impl true
  def cleanup(program), do: cleanup_program(program)

end
