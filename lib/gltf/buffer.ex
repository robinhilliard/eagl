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

  @doc """
  Load a Buffer struct from JSON data.

  If a data store is provided and the buffer references external files or data URIs,
  this function will attempt to load the binary data into the store.
  """
  def load(json_data, buffer_index, data_store \\ nil) when is_map(json_data) do
    buffer = %__MODULE__{
      byte_length: json_data["byteLength"],
      uri: json_data["uri"],
      name: json_data["name"],
      extensions: json_data["extensions"],
      extras: json_data["extras"]
    }

    # Validate required fields
    case buffer.byte_length do
      nil ->
        {:error, :missing_byte_length}

      n when is_integer(n) and n > 0 ->
        # Optionally load buffer data into the data store
        case load_buffer_data(buffer, buffer_index, data_store) do
          {:ok, _updated_store} -> {:ok, buffer}
          {:error, reason} -> {:error, reason}
          :no_store -> {:ok, buffer}
        end

      _ ->
        {:error, :invalid_byte_length}
    end
  end

  # Load buffer data into the data store based on buffer type
  defp load_buffer_data(%__MODULE__{uri: nil}, _buffer_index, nil), do: :no_store

  defp load_buffer_data(%__MODULE__{uri: nil}, _buffer_index, _data_store) do
    # GLB-stored buffer - data should already be in the store
    {:ok, :already_stored}
  end

  defp load_buffer_data(%__MODULE__{uri: "data:" <> _} = _buffer, _buffer_index, nil),
    do: :no_store

  defp load_buffer_data(%__MODULE__{uri: "data:" <> _} = buffer, buffer_index, data_store) do
    # Data URI buffer - decode and store
    case GLTF.DataStore.load_data_uri_buffer(data_store, buffer_index, buffer.uri) do
      {:ok, _updated_store} -> {:ok, :loaded}
      {:error, reason} -> {:error, {:data_uri_load_error, reason}}
    end
  end

  defp load_buffer_data(%__MODULE__{uri: uri}, _buffer_index, nil) when is_binary(uri),
    do: :no_store

  defp load_buffer_data(%__MODULE__{uri: uri}, buffer_index, data_store) when is_binary(uri) do
    # External file buffer - load from file
    case GLTF.DataStore.load_external_buffer(data_store, buffer_index, uri) do
      {:ok, _updated_store} -> {:ok, :loaded}
      {:error, reason} -> {:error, {:external_file_load_error, reason}}
    end
  end
end
