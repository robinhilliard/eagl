defmodule GLTF.Texture do
  @moduledoc """
  A texture and its sampler.
  """

  defstruct [
    :sampler,
    :source,
    :name,
    :extensions,
    :extras
  ]

  @type t :: %__MODULE__{
          sampler: non_neg_integer() | nil,
          source: non_neg_integer() | nil,
          name: String.t() | nil,
          extensions: map() | nil,
          extras: any() | nil
        }

  @doc """
  Create a new texture.
  """
  def new(opts \\ []) do
    %__MODULE__{
      sampler: Keyword.get(opts, :sampler),
      source: Keyword.get(opts, :source),
      name: Keyword.get(opts, :name),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end

  @doc """
  Create a texture with image source.
  """
  def with_source(source_index, opts \\ []) when is_integer(source_index) and source_index >= 0 do
    %__MODULE__{
      source: source_index,
      sampler: Keyword.get(opts, :sampler),
      name: Keyword.get(opts, :name),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end

  @doc """
  Create a texture with both image and sampler.
  """
  def with_source_and_sampler(source_index, sampler_index, opts \\ [])
      when is_integer(source_index) and source_index >= 0 and is_integer(sampler_index) and
             sampler_index >= 0 do
    %__MODULE__{
      source: source_index,
      sampler: sampler_index,
      name: Keyword.get(opts, :name),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end

  @doc """
  Check if texture has an image source.
  """
  def has_source?(%__MODULE__{source: nil}), do: false
  def has_source?(%__MODULE__{source: _}), do: true

  @doc """
  Check if texture has a sampler.
  """
  def has_sampler?(%__MODULE__{sampler: nil}), do: false
  def has_sampler?(%__MODULE__{sampler: _}), do: true

  @doc """
  Load a Texture struct from JSON data.
  """
  def load(json_data) when is_map(json_data) do
    texture = %__MODULE__{
      sampler: json_data["sampler"],
      source: json_data["source"],
      name: json_data["name"],
      extensions: json_data["extensions"],
      extras: json_data["extras"]
    }

    # Validate that source is specified
    case texture.source do
      nil -> {:error, :missing_texture_source}
      source when is_integer(source) and source >= 0 -> {:ok, texture}
      _ -> {:error, :invalid_texture_source}
    end
  end
end
