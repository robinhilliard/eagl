defmodule GLTF.Binary do
  @moduledoc """
  Represents a parsed GLB (Binary glTF) file.

  GLB files contain a 12-byte header followed by one or more chunks.
  The first chunk is always JSON, and there may be an optional binary chunk.

  Based on section 4 of the glTF 2.0 specification.
  """

  @enforce_keys [:magic, :version, :length, :json_chunk]
  defstruct [
    :magic,
    :version,
    :length,
    :json_chunk,
    :binary_chunk
  ]

  @type t :: %__MODULE__{
          magic: binary(),
          version: non_neg_integer(),
          length: non_neg_integer(),
          json_chunk: chunk(),
          binary_chunk: chunk() | nil
        }

  @type chunk :: %{
          length: non_neg_integer(),
          type: chunk_type(),
          data: binary()
        }

  @type chunk_type :: :json | :bin | :unknown

  # GLB constants
  @glb_magic "glTF"
  # "JSON"
  @json_chunk_type 0x4E4F534A
  # "BIN\0"
  @bin_chunk_type 0x004E4942

  @doc """
  Creates a new GLB binary structure.

  ## Examples

      iex> json_chunk = %{length: 100, type: :json, data: "{}"}
      iex> glb = GLTF.Binary.new("glTF", 2, 112, json_chunk)
      iex> glb.magic
      "glTF"
  """
  def new(magic, version, length, json_chunk, binary_chunk \\ nil) do
    %__MODULE__{
      magic: magic,
      version: version,
      length: length,
      json_chunk: json_chunk,
      binary_chunk: binary_chunk
    }
  end

  @doc """
  Creates a chunk structure.

  ## Examples

      iex> chunk = GLTF.Binary.chunk(100, :json, "{}")
      iex> chunk.type
      :json
  """
  def chunk(length, type, data) do
    %{
      length: length,
      type: type,
      data: data
    }
  end

  @doc """
  Converts a chunk type integer to an atom.

  ## Examples

      iex> GLTF.Binary.chunk_type_to_atom(0x4E4F534A)
      :json

      iex> GLTF.Binary.chunk_type_to_atom(0x004E4942)
      :bin

      iex> GLTF.Binary.chunk_type_to_atom(0x12345678)
      :unknown
  """
  def chunk_type_to_atom(@json_chunk_type), do: :json
  def chunk_type_to_atom(@bin_chunk_type), do: :bin
  def chunk_type_to_atom(_), do: :unknown

  @doc """
  Converts a chunk type atom to an integer.

  ## Examples

      iex> GLTF.Binary.chunk_type_to_int(:json)
      0x4E4F534A

      iex> GLTF.Binary.chunk_type_to_int(:bin)
      0x004E4942
  """
  def chunk_type_to_int(:json), do: @json_chunk_type
  def chunk_type_to_int(:bin), do: @bin_chunk_type

  @doc """
  Gets the expected GLB magic string.

  ## Examples

      iex> GLTF.Binary.magic()
      "glTF"
  """
  def magic, do: @glb_magic

  @doc """
  Validates that a GLB binary structure is well-formed.

  ## Examples

      iex> json_chunk = %{length: 4, type: :json, data: "{}"}
      iex> glb = GLTF.Binary.new("glTF", 2, 16, json_chunk)
      iex> GLTF.Binary.validate(glb)
      :ok
  """
  def validate(%__MODULE__{} = glb) do
    with :ok <- validate_magic(glb.magic),
         :ok <- validate_version(glb.version),
         :ok <- validate_json_chunk(glb.json_chunk),
         :ok <- validate_binary_chunk(glb.binary_chunk),
         :ok <- validate_total_length(glb) do
      :ok
    end
  end

  defp validate_magic(@glb_magic), do: :ok

  defp validate_magic(magic),
    do: {:error, "Invalid magic: expected '#{@glb_magic}', got '#{magic}'"}

  defp validate_version(2), do: :ok
  defp validate_version(version), do: {:error, "Unsupported version: #{version}"}

  defp validate_json_chunk(%{type: :json}), do: :ok
  defp validate_json_chunk(%{type: type}), do: {:error, "First chunk must be JSON, got #{type}"}
  defp validate_json_chunk(nil), do: {:error, "JSON chunk is required"}

  defp validate_binary_chunk(nil), do: :ok
  defp validate_binary_chunk(%{type: :bin}), do: :ok

  defp validate_binary_chunk(%{type: type}),
    do: {:error, "Binary chunk must be BIN type, got #{type}"}

  defp validate_total_length(%__MODULE__{
         length: total_length,
         json_chunk: json_chunk,
         binary_chunk: binary_chunk
       }) do
    header_size = 12
    json_size = 8 + json_chunk.length

    binary_size =
      case binary_chunk do
        nil -> 0
        chunk -> 8 + chunk.length
      end

    expected_length = header_size + json_size + binary_size

    if total_length >= expected_length do
      :ok
    else
      {:error, "Total length #{total_length} is less than expected minimum #{expected_length}"}
    end
  end

  @doc """
  Gets the parsed JSON data from the GLB file.

  Returns the JSON string that needs to be parsed separately.

  ## Examples

      iex> json_chunk = %{length: 4, type: :json, data: "{}"}
      iex> glb = GLTF.Binary.new("glTF", 2, 16, json_chunk)
      iex> GLTF.Binary.get_json(glb)
      "{}"
  """
  def get_json(%__MODULE__{json_chunk: %{data: data}}), do: data

  @doc """
  Gets the binary data from the GLB file, if present.

  Returns nil if there is no binary chunk.

  ## Examples

      iex> json_chunk = %{length: 4, type: :json, data: "{}"}
      iex> glb = GLTF.Binary.new("glTF", 2, 16, json_chunk)
      iex> GLTF.Binary.get_binary(glb)
      nil

      iex> binary_chunk = %{length: 8, type: :bin, data: <<1, 2, 3, 4, 5, 6, 7, 8>>}
      iex> glb = GLTF.Binary.new("glTF", 2, 28, json_chunk, binary_chunk)
      iex> GLTF.Binary.get_binary(glb)
      <<1, 2, 3, 4, 5, 6, 7, 8>>
  """
  def get_binary(%__MODULE__{binary_chunk: nil}), do: nil
  def get_binary(%__MODULE__{binary_chunk: %{data: data}}), do: data

  @doc """
  Checks if the GLB file has a binary chunk.

  ## Examples

      iex> json_chunk = %{length: 4, type: :json, data: "{}"}
      iex> glb = GLTF.Binary.new("glTF", 2, 16, json_chunk)
      iex> GLTF.Binary.has_binary?(glb)
      false
  """
  def has_binary?(%__MODULE__{binary_chunk: nil}), do: false
  def has_binary?(%__MODULE__{binary_chunk: _}), do: true
end
