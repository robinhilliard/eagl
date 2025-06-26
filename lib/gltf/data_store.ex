defmodule GLTF.DataStore do
  @moduledoc """
  Manages binary data for glTF assets.

  The DataStore provides a unified interface for accessing buffer data regardless
  of whether it comes from:
  - GLB binary chunks (embedded in the GLB file)
  - External .bin files (referenced by URI)
  - Data URIs (base64-encoded embedded data)

  This separation allows buffer structs to remain as metadata while keeping
  the actual binary data managed separately for better memory efficiency and
  uniform access patterns.
  """

  defstruct [
    :glb_buffers,
    :external_buffers,
    :data_uri_buffers
  ]

  @type t :: %__MODULE__{
          glb_buffers: %{non_neg_integer() => binary()},
          external_buffers: %{non_neg_integer() => binary()},
          data_uri_buffers: %{non_neg_integer() => binary()}
        }

  @doc """
  Create a new empty data store.
  """
  def new do
    %__MODULE__{
      glb_buffers: %{},
      external_buffers: %{},
      data_uri_buffers: %{}
    }
  end

  @doc """
  Store GLB binary chunk data for a buffer index.

  GLB files store buffer data in the binary chunk, with buffer index 0
  typically pointing to this data.
  """
  def store_glb_buffer(%__MODULE__{} = store, buffer_index, binary_data)
      when is_integer(buffer_index) and buffer_index >= 0 and is_binary(binary_data) do
    %{store | glb_buffers: Map.put(store.glb_buffers, buffer_index, binary_data)}
  end

  @doc """
  Store external buffer data for a buffer index.

  External buffers are loaded from .bin files referenced by URI.
  """
  def store_external_buffer(%__MODULE__{} = store, buffer_index, binary_data)
      when is_integer(buffer_index) and buffer_index >= 0 and is_binary(binary_data) do
    %{store | external_buffers: Map.put(store.external_buffers, buffer_index, binary_data)}
  end

  @doc """
  Store data URI buffer data for a buffer index.

  Data URI buffers contain base64-encoded data embedded in the JSON.
  """
  def store_data_uri_buffer(%__MODULE__{} = store, buffer_index, binary_data)
      when is_integer(buffer_index) and buffer_index >= 0 and is_binary(binary_data) do
    %{store | data_uri_buffers: Map.put(store.data_uri_buffers, buffer_index, binary_data)}
  end

  @doc """
  Get buffer data by index.

  Looks up data in GLB buffers first, then external buffers, then data URI buffers.
  Returns nil if the buffer is not found in any store.
  """
  def get_buffer_data(%__MODULE__{} = store, buffer_index)
      when is_integer(buffer_index) and buffer_index >= 0 do
    store.glb_buffers[buffer_index] ||
      store.external_buffers[buffer_index] ||
      store.data_uri_buffers[buffer_index]
  end

  @doc """
  Get a slice of buffer data using byte offset and length.

  This is useful for buffer views that represent portions of buffer data.
  Returns nil if the buffer doesn't exist or the slice is out of bounds.
  Zero-length slices return nil (invalid per glTF spec).
  """
  def get_buffer_slice(%__MODULE__{} = store, buffer_index, byte_offset, byte_length)
      when is_integer(buffer_index) and buffer_index >= 0 and
             is_integer(byte_offset) and byte_offset >= 0 and
             is_integer(byte_length) and byte_length >= 0 do
    cond do
      # Zero-length slices are invalid
      byte_length == 0 ->
        nil

      true ->
        case get_buffer_data(store, buffer_index) do
          nil ->
            nil

          binary_data ->
            if byte_offset + byte_length <= byte_size(binary_data) do
              :binary.part(binary_data, byte_offset, byte_length)
            else
              nil
            end
        end
    end
  end

  @doc """
  Check if buffer data exists for the given index.
  """
  def has_buffer?(%__MODULE__{} = store, buffer_index)
      when is_integer(buffer_index) and buffer_index >= 0 do
    Map.has_key?(store.glb_buffers, buffer_index) ||
      Map.has_key?(store.external_buffers, buffer_index) ||
      Map.has_key?(store.data_uri_buffers, buffer_index)
  end

  @doc """
  Get the total number of buffers stored.
  """
  def buffer_count(%__MODULE__{} = store) do
    glb_keys = Map.keys(store.glb_buffers)
    external_keys = Map.keys(store.external_buffers)
    data_uri_keys = Map.keys(store.data_uri_buffers)

    (glb_keys ++ external_keys ++ data_uri_keys)
    |> Enum.uniq()
    |> length()
  end

  @doc """
  Load external buffer data from a file URI.

  This function can be used to populate the data store with external buffer files.
  """
  def load_external_buffer(%__MODULE__{} = store, buffer_index, uri, base_path \\ ".")
      when is_integer(buffer_index) and buffer_index >= 0 and is_binary(uri) do
    full_path = Path.join(base_path, uri)

    case File.read(full_path) do
      {:ok, binary_data} ->
        {:ok, store_external_buffer(store, buffer_index, binary_data)}

      {:error, reason} ->
        {:error, {:file_read_error, reason, full_path}}
    end
  end

  @doc """
  Load data URI buffer data from a base64-encoded data URI.

  Parses "data:application/octet-stream;base64,<data>" URIs.
  """
  def load_data_uri_buffer(%__MODULE__{} = store, buffer_index, data_uri)
      when is_integer(buffer_index) and buffer_index >= 0 and is_binary(data_uri) do
    case parse_data_uri(data_uri) do
      {:ok, binary_data} ->
        {:ok, store_data_uri_buffer(store, buffer_index, binary_data)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Parse data URI and extract base64 content
  defp parse_data_uri("data:" <> rest) do
    case String.split(rest, ",", parts: 2) do
      [_media_type, base64_data] ->
        case Base.decode64(base64_data) do
          {:ok, binary_data} -> {:ok, binary_data}
          :error -> {:error, :invalid_base64}
        end

      _ ->
        {:error, :invalid_data_uri_format}
    end
  end

  defp parse_data_uri(_), do: {:error, :not_data_uri}
end
