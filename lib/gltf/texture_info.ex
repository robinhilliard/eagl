defmodule GLTF.TextureInfo do
  @moduledoc """
  Reference to a texture.
  """

  defstruct [
    :index,
    :tex_coord,
    :extensions,
    :extras
  ]

  @type t :: %__MODULE__{
          index: non_neg_integer(),
          tex_coord: non_neg_integer(),
          extensions: map() | nil,
          extras: any() | nil
        }

  @doc """
  Create a new texture info with required texture index.
  """
  def new(index, opts \\ []) when is_integer(index) and index >= 0 do
    %__MODULE__{
      index: index,
      tex_coord: Keyword.get(opts, :tex_coord, 0),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end

  @doc """
  Create texture info with specific texture coordinate set.
  """
  def with_tex_coord(index, tex_coord, opts \\ [])
      when is_integer(index) and index >= 0 and is_integer(tex_coord) and tex_coord >= 0 do
    %__MODULE__{
      index: index,
      tex_coord: tex_coord,
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end

  @doc """
  Get the TEXCOORD attribute name for this texture coordinate set.
  """
  def texcoord_attribute(%__MODULE__{tex_coord: 0}), do: "TEXCOORD_0"
  def texcoord_attribute(%__MODULE__{tex_coord: 1}), do: "TEXCOORD_1"
  def texcoord_attribute(%__MODULE__{tex_coord: n}), do: "TEXCOORD_#{n}"

  @doc """
  Check if this uses the default texture coordinate set (0).
  """
  def uses_default_texcoord?(%__MODULE__{tex_coord: 0}), do: true
  def uses_default_texcoord?(%__MODULE__{}), do: false
end
