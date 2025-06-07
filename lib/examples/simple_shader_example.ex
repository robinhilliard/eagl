defmodule EZGL.Examples.SimpleShader do
  @moduledoc """
  Draw a blue point.
  """

  use GL.Window
  use GL.Const
  import GL.Shader

  @spec run_example() :: :ok | {:error, term()}
  def run_example, do: GL.Window.run(__MODULE__, "EZGL Simple Shader Example")

  @impl true
  def setup do
    with {:ok, vertex_shader} <- create_shader(@gl_vertex_shader, vertex_shader_source()),
         {:ok, fragment_shader} <- create_shader(@gl_fragment_shader, fragment_shader_source()),
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

  # Simple vertex shader source
  defp vertex_shader_source do
    """
    #version 330 core
    layout(location = 0) in vec3 position;
    void main() {gl_Position = vec4(0.0, 0.0, 0.0, 1.0);}
    """
  end

  # Simple fragment shader source
  defp fragment_shader_source do
    """
    #version 330 core
    out vec4 fragColor;
    void main() {fragColor = vec4(0.0, 0.0, 1.0, 1.0);}
    """
  end
end
