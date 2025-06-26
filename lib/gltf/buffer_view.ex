defmodule GLTF.BufferView do
  @moduledoc """
  A view into a buffer generally representing a subset of the buffer.
  """

  defstruct [
    :buffer,
    :byte_offset,
    :byte_length,
    :byte_stride,
    :target,
    :name,
    :extensions,
    :extras
  ]

  @type t :: %__MODULE__{
          buffer: non_neg_integer(),
          byte_offset: non_neg_integer(),
          byte_length: pos_integer(),
          byte_stride: pos_integer() | nil,
          target: buffer_target() | nil,
          name: String.t() | nil,
          extensions: map() | nil,
          extras: any() | nil
        }

  @type buffer_target :: :array_buffer | :element_array_buffer

  # WebGL buffer targets
  @array_buffer 34962
  @element_array_buffer 34963

  def buffer_targets do
    %{
      @array_buffer => :array_buffer,
      @element_array_buffer => :element_array_buffer
    }
  end

  @doc """
  Create a new BufferView struct with required fields.
  """
  def new(buffer, byte_length, opts \\ [])
      when is_integer(buffer) and buffer >= 0 and is_integer(byte_length) and byte_length > 0 do
    %__MODULE__{
      buffer: buffer,
      byte_length: byte_length,
      byte_offset: Keyword.get(opts, :byte_offset, 0),
      byte_stride: Keyword.get(opts, :byte_stride),
      target: Keyword.get(opts, :target),
      name: Keyword.get(opts, :name),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end

  @doc """
  Get the WebGL constant for the buffer target.
  """
  def target_constant(:array_buffer), do: @array_buffer
  def target_constant(:element_array_buffer), do: @element_array_buffer
  def target_constant(nil), do: nil

  @doc """
  Get the buffer target type from WebGL constant.
  """
  def target_from_constant(constant) do
    Map.get(buffer_targets(), constant)
  end

  @doc """
  Load a BufferView struct from JSON data.
  """
  def load(json_data) when is_map(json_data) do
    # Parse target if provided
    target =
      case json_data["target"] do
        nil -> nil
        target_int when is_integer(target_int) -> target_from_constant(target_int)
        _ -> nil
      end

    buffer_view = %__MODULE__{
      buffer: json_data["buffer"],
      byte_offset: json_data["byteOffset"] || 0,
      byte_length: json_data["byteLength"],
      byte_stride: json_data["byteStride"],
      target: target,
      name: json_data["name"],
      extensions: json_data["extensions"],
      extras: json_data["extras"]
    }

    # Validate required fields
    case {buffer_view.buffer, buffer_view.byte_length} do
      {nil, _} ->
        {:error, :missing_buffer}

      {_, nil} ->
        {:error, :missing_byte_length}

      {buffer, byte_length}
      when is_integer(buffer) and buffer >= 0 and
             is_integer(byte_length) and byte_length > 0 ->
        {:ok, buffer_view}

      _ ->
        {:error, :invalid_fields}
    end
  end
end
