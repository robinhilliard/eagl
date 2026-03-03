defmodule EAGL.Line do
  @moduledoc """
  Line drawing primitive using GL_LINES.

  Provides `draw_line/5` and `draw_lines/4` for rendering lines in 3D space.
  Used by Lunity.Debug for draw_line, draw_ray, draw_bounds, and grids.

  ## Usage

      import EAGL.Line
      import EAGL.Math

      # Single line (white)
      EAGL.Line.draw_line(
        vec3(0, 0, 0),
        vec3(1, 1, 0),
        view_matrix,
        projection_matrix
      )

      # Batch of lines with color
      EAGL.Line.draw_lines(
        [{vec3(0, 0, 0), vec3(1, 0, 0)}, {vec3(0, 0, 0), vec3(0, 1, 0)}],
        view_matrix,
        projection_matrix,
        vec3(1, 1, 0)
      )
  """

  use EAGL.Const
  import EAGL.Math

  defp get_program do
    case Process.get(:eagl_line_program) do
      nil ->
        {:ok, vs} = EAGL.Shader.create_shader(@gl_vertex_shader, "line_vertex.glsl")
        {:ok, fs} = EAGL.Shader.create_shader(@gl_fragment_shader, "line_fragment.glsl")
        {:ok, program} = EAGL.Shader.create_attach_link([vs, fs])
        Process.put(:eagl_line_program, program)
        program

      program ->
        program
    end
  end

  @doc """
  Draw a single line from `from` to `to` in world space.

  `from` and `to` are vec3 `[{x, y, z}]`. `color` defaults to white.
  """
  @spec draw_line(
          EAGL.Math.vec3(),
          EAGL.Math.vec3(),
          EAGL.Math.mat4(),
          EAGL.Math.mat4(),
          EAGL.Math.vec3()
        ) :: :ok
  def draw_line(from, to, view_matrix, projection_matrix, color \\ vec3(1.0, 1.0, 1.0)) do
    draw_lines([{from, to}], view_matrix, projection_matrix, color)
  end

  @doc """
  Draw multiple lines. `lines` is a list of `{from, to}` tuples (each vec3).
  """
  @spec draw_lines(
          [{EAGL.Math.vec3(), EAGL.Math.vec3()}],
          EAGL.Math.mat4(),
          EAGL.Math.mat4(),
          EAGL.Math.vec3()
        ) :: :ok
  def draw_lines(lines, view_matrix, projection_matrix, color \\ vec3(1.0, 1.0, 1.0)) do
    if lines == [] do
      :ok
    else
      vertices =
        Enum.flat_map(lines, fn {[{fx, fy, fz}], [{tx, ty, tz}]} ->
          [{cx, cy, cz}] = color
          [fx, fy, fz, cx, cy, cz, tx, ty, tz, cx, cy, cz]
        end)

      {vao, vbo} =
        EAGL.Buffer.create_vertex_array(
          vertices,
          [
            EAGL.Buffer.position_attribute(stride: 24, offset: 0),
            EAGL.Buffer.color_attribute(stride: 24, offset: 12)
          ],
          usage: @gl_dynamic_draw
        )

      program = get_program()
      :gl.useProgram(program)
      EAGL.Shader.set_uniform(program, "view", view_matrix)
      EAGL.Shader.set_uniform(program, "projection", projection_matrix)

      :gl.bindVertexArray(vao)
      :gl.drawArrays(@gl_lines, 0, length(lines) * 2)
      :gl.bindVertexArray(0)

      EAGL.Buffer.delete_vertex_array(vao, vbo)
      :ok
    end
  end
end
