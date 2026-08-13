defmodule EAGL.Mesh do
  @moduledoc """
  GPU mesh handle used by `EAGL.Scene` and `EAGL.Node`.

  A mesh is the drawable result of `EAGL.Buffer` helpers (and of `GLTF.EAGL`
  conversion): a VAO plus either a vertex count or an index count. Draw mode
  is an atom (`:triangles`, `:triangle_strip`, …); GL integers are also stored
  as-is.

  Plain maps with the same keys are still accepted via `from_map/1` so existing
  scene code keeps working.
  """

  use EAGL.Const

  @type primitive_mode ::
          :points
          | :lines
          | :line_loop
          | :line_strip
          | :triangles
          | :triangle_strip
          | :triangle_fan
          | non_neg_integer()

  @type index_type :: :unsigned_byte | :unsigned_short | :unsigned_int | non_neg_integer()

  @type bounds ::
          {{float(), float(), float()}, {float(), float(), float()}}

  defstruct [
    :vao,
    :vbo,
    :ebo,
    :vertex_count,
    :index_count,
    :index_type,
    :program,
    :bounds,
    mode: :triangles
  ]

  @type t :: %__MODULE__{
          vao: non_neg_integer() | nil,
          vbo: non_neg_integer() | nil,
          ebo: non_neg_integer() | nil,
          vertex_count: non_neg_integer() | nil,
          index_count: non_neg_integer() | nil,
          index_type: index_type() | nil,
          program: non_neg_integer() | nil,
          bounds: bounds() | nil,
          mode: primitive_mode()
        }

  @doc """
  Build a mesh from keyword options. Same keys as the struct fields.
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    struct(__MODULE__, opts)
  end

  @doc """
  Normalise a mesh map or struct. `nil` stays `nil`.
  """
  @spec from_map(t() | map() | nil) :: t() | nil
  def from_map(nil), do: nil
  def from_map(%__MODULE__{} = mesh), do: mesh

  def from_map(map) when is_map(map) do
    %__MODULE__{
      vao: Map.get(map, :vao),
      vbo: Map.get(map, :vbo),
      ebo: Map.get(map, :ebo),
      vertex_count: Map.get(map, :vertex_count),
      index_count: Map.get(map, :index_count),
      index_type: Map.get(map, :index_type),
      program: Map.get(map, :program),
      bounds: Map.get(map, :bounds),
      mode: Map.get(map, :mode, :triangles)
    }
  end

  @doc """
  Attach a shader program to a mesh.
  """
  @spec with_program(t() | map(), non_neg_integer()) :: t()
  def with_program(mesh, program) do
    %{from_map(mesh) | program: program}
  end

  @doc """
  True when the mesh should be drawn with `glDrawElements`.
  """
  @spec indexed?(t()) :: boolean()
  def indexed?(%__MODULE__{index_count: count}) when is_integer(count) and count > 0, do: true
  def indexed?(%__MODULE__{}), do: false

  @doc """
  GL primitive mode for `:gl.drawArrays` / `:gl.drawElements`.
  """
  @spec gl_mode(t()) :: non_neg_integer()
  def gl_mode(%__MODULE__{mode: mode}), do: mode_to_gl(mode)

  @doc """
  GL index type for `:gl.drawElements`. Defaults to unsigned int.
  """
  @spec gl_index_type(t()) :: non_neg_integer()
  def gl_index_type(%__MODULE__{index_type: type}), do: index_type_to_gl(type)

  defp mode_to_gl(:points), do: @gl_points
  defp mode_to_gl(:lines), do: @gl_lines
  defp mode_to_gl(:line_loop), do: @gl_line_loop
  defp mode_to_gl(:line_strip), do: @gl_line_strip
  defp mode_to_gl(:triangles), do: @gl_triangles
  defp mode_to_gl(:triangle_strip), do: @gl_triangle_strip
  defp mode_to_gl(:triangle_fan), do: @gl_triangle_fan
  defp mode_to_gl(mode) when is_integer(mode), do: mode
  defp mode_to_gl(_), do: @gl_triangles

  defp index_type_to_gl(:unsigned_byte), do: @gl_unsigned_byte
  defp index_type_to_gl(:unsigned_short), do: @gl_unsigned_short
  defp index_type_to_gl(:unsigned_int), do: @gl_unsigned_int
  defp index_type_to_gl(nil), do: @gl_unsigned_int
  defp index_type_to_gl(type) when is_integer(type), do: type
end
