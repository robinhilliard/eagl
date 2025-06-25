defmodule GLTF.Asset do
  @moduledoc """
  Metadata about the glTF asset.
  """

  defstruct [
    :copyright,
    :generator,
    :version,
    :min_version,
    :extensions,
    :extras
  ]

  @type t :: %__MODULE__{
    copyright: String.t() | nil,
    generator: String.t() | nil,
    version: String.t(),
    min_version: String.t() | nil,
    extensions: map() | nil,
    extras: any() | nil
  }

  @doc """
  Create a new Asset struct with required version.
  """
  def new(version, opts \\ []) do
    %__MODULE__{
      version: version,
      copyright: Keyword.get(opts, :copyright),
      generator: Keyword.get(opts, :generator),
      min_version: Keyword.get(opts, :min_version),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end

  @doc """
  Check if this asset is compatible with a given glTF version.
  """
  def compatible?(%__MODULE__{version: version, min_version: min_version}, target_version) do
    case min_version do
      nil -> String.starts_with?(version, String.split(target_version, ".") |> hd())
      min_ver -> Version.match?(target_version, ">= #{min_ver}")
    end
  end
end
