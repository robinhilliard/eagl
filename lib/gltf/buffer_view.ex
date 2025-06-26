defmodule GLTF.BufferView do
  @moduledoc """
  BufferView defines a view into a buffer's data, specifying the range and optional stride.

  Stores OpenGL constants directly rather than mapping to atoms,
  following EAGL's philosophy of thin wrapping.
  """

  use EAGL.Const

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
          target: target() | nil,
          name: String.t() | nil,
          extensions: map() | nil,
          extras: any() | nil
        }

  # OpenGL constants for buffer targets
  @type target :: 34962 | 34963  # GL_ARRAY_BUFFER | GL_ELEMENT_ARRAY_BUFFER

  @doc """
  Create a new buffer view.
  """
  def new(buffer_index, byte_offset, byte_length, opts \\ []) do
    %__MODULE__{
      buffer: buffer_index,
      byte_offset: byte_offset,
      byte_length: byte_length,
      byte_stride: Keyword.get(opts, :byte_stride),
      target: Keyword.get(opts, :target),
      name: Keyword.get(opts, :name),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end

  @doc """
  Load a BufferView struct from JSON data.
  """
  def load(json_data) when is_map(json_data) do
    # Parse target (store OpenGL constants directly)
    target = parse_target(json_data["target"])

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

    {:ok, buffer_view}
  end

  # Parse target constants - return OpenGL constants directly
  defp parse_target(nil), do: nil
  defp parse_target(@gl_array_buffer), do: @gl_array_buffer
  defp parse_target(@gl_element_array_buffer), do: @gl_element_array_buffer
  defp parse_target(_), do: nil

  @doc """
  Get the end offset (exclusive) of this buffer view.
  """
  def end_offset(%__MODULE__{byte_offset: offset, byte_length: length}) do
    offset + length
  end

  @doc """
  Check if this buffer view contains the given byte offset.
  """
  def contains?(%__MODULE__{} = buffer_view, byte_offset) do
    byte_offset >= buffer_view.byte_offset and byte_offset < end_offset(buffer_view)
  end

  @doc """
  Get the effective byte stride for this buffer view.

  Returns the explicitly set byte_stride, or calculates it based on the target type.
  """
  def effective_byte_stride(%__MODULE__{byte_stride: byte_stride}) when is_integer(byte_stride) do
    byte_stride
  end

  def effective_byte_stride(%__MODULE__{target: @gl_array_buffer}) do
    # For vertex attributes, stride is usually tightly packed
    # This should be calculated based on the accessor that uses this buffer view
    nil
  end

  def effective_byte_stride(%__MODULE__{target: @gl_element_array_buffer}) do
    # Element array buffers are always tightly packed
    nil
  end

  def effective_byte_stride(%__MODULE__{}) do
    # No target specified, assume tightly packed
    nil
  end
end
