defmodule GLTF.Buffer do
  @moduledoc """
  A buffer points to binary geometry, animation, or skins.
  Binary blobs allow efficient creation of GPU buffers and textures since they require no additional parsing.
  """

  defstruct [
    :uri,
    :byte_length,
    :name,
    :extensions,
    :extras
  ]

  @type t :: %__MODULE__{
    uri: String.t() | nil,
    byte_length: pos_integer(),
    name: String.t() | nil,
    extensions: map() | nil,
    extras: any() | nil
  }

  @doc """
  Create a new Buffer struct with required byte_length.
  """
  def new(byte_length, opts \\ []) when is_integer(byte_length) and byte_length > 0 do
    %__MODULE__{
      byte_length: byte_length,
      uri: Keyword.get(opts, :uri),
      name: Keyword.get(opts, :name),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end

  @doc """
  Check if this buffer uses embedded data (data URI).
  """
  def embedded?(%__MODULE__{uri: uri}) do
    case uri do
      "data:" <> _ -> true
      _ -> false
    end
  end

  @doc """
  Check if this buffer refers to GLB-stored data (no URI defined).
  """
  def glb_stored?(%__MODULE__{uri: nil}), do: true
  def glb_stored?(%__MODULE__{}), do: false
end
