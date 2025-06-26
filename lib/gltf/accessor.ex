defmodule GLTF.Accessor do
  @moduledoc """
  Accessor defines how to access binary data from a buffer view.

  Uses OpenGL constants directly for component types while keeping
  accessor types as atoms since they are glTF spec strings.
  """

  use EAGL.Const

  defstruct [
    :buffer_view,
    :byte_offset,
    :component_type,
    :normalized,
    :count,
    :type,
    :max,
    :min,
    :sparse,
    :name,
    :extensions,
    :extras
  ]

  # OpenGL constants for component types
  @type component_type :: 5120 | 5121 | 5122 | 5123 | 5125 | 5126
  # GL_BYTE | GL_UNSIGNED_BYTE | GL_SHORT | GL_UNSIGNED_SHORT | GL_UNSIGNED_INT | GL_FLOAT

  # glTF spec accessor types (not OpenGL constants)
  @type accessor_type ::
          :scalar | :vec2 | :vec3 | :vec4 | :mat2 | :mat3 | :mat4

  @type t :: %__MODULE__{
          buffer_view: non_neg_integer() | nil,
          byte_offset: non_neg_integer(),
          component_type: component_type(),
          normalized: boolean(),
          count: pos_integer(),
          type: accessor_type(),
          max: [number()] | nil,
          min: [number()] | nil,
          sparse: GLTF.Accessor.Sparse.t() | nil,
          name: String.t() | nil,
          extensions: map() | nil,
          extras: any() | nil
        }

  @doc """
  Get the byte size of a component type.
  """
  def component_size(@gl_byte), do: 1
  def component_size(@gl_unsigned_byte), do: 1
  def component_size(@gl_short), do: 2
  def component_size(@gl_unsigned_short), do: 2
  def component_size(@gl_unsigned_int), do: 4
  def component_size(@gl_float), do: 4

  @doc """
  Get the number of components for an accessor type.
  """
  def type_component_count(:scalar), do: 1
  def type_component_count(:vec2), do: 2
  def type_component_count(:vec3), do: 3
  def type_component_count(:vec4), do: 4
  def type_component_count(:mat2), do: 4
  def type_component_count(:mat3), do: 9
  def type_component_count(:mat4), do: 16

  @doc """
  Calculate the byte size of a single element for this accessor.
  """
  def element_byte_size(%__MODULE__{component_type: component_type, type: type}) do
    component_size(component_type) * type_component_count(type)
  end

  @doc """
  Calculate the total byte size of all elements in this accessor.
  """
  def total_byte_size(%__MODULE__{count: count} = accessor) do
    element_byte_size(accessor) * count
  end

  @doc """
  Create a new accessor.
  """
  def new(opts \\ []) do
    %__MODULE__{
      buffer_view: Keyword.get(opts, :buffer_view),
      byte_offset: Keyword.get(opts, :byte_offset, 0),
      component_type: Keyword.fetch!(opts, :component_type),
      normalized: Keyword.get(opts, :normalized, false),
      count: Keyword.fetch!(opts, :count),
      type: Keyword.fetch!(opts, :type),
      max: Keyword.get(opts, :max),
      min: Keyword.get(opts, :min),
      sparse: Keyword.get(opts, :sparse),
      name: Keyword.get(opts, :name),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end

  @doc """
  Load an Accessor struct from JSON data.
  """
  def load(json_data) when is_map(json_data) do
    # Parse component type (store OpenGL constants directly)
    component_type = parse_component_type(json_data["componentType"])
    # Parse accessor type (keep as atoms since they're glTF spec strings)
    type = parse_type(json_data["type"])

    if component_type && type do
      accessor = %__MODULE__{
        buffer_view: json_data["bufferView"],
        byte_offset: json_data["byteOffset"] || 0,
        component_type: component_type,
        normalized: json_data["normalized"] || false,
        count: json_data["count"],
        type: type,
        max: json_data["max"],
        min: json_data["min"],
        sparse: parse_sparse(json_data["sparse"]),
        name: json_data["name"],
        extensions: json_data["extensions"],
        extras: json_data["extras"]
      }

      {:ok, accessor}
    else
      {:error, :invalid_component_type_or_type}
    end
  end

  # Parse component type constants - return OpenGL constants directly
  defp parse_component_type(@gl_byte), do: @gl_byte
  defp parse_component_type(@gl_unsigned_byte), do: @gl_unsigned_byte
  defp parse_component_type(@gl_short), do: @gl_short
  defp parse_component_type(@gl_unsigned_short), do: @gl_unsigned_short
  defp parse_component_type(@gl_unsigned_int), do: @gl_unsigned_int
  defp parse_component_type(@gl_float), do: @gl_float
  defp parse_component_type(_), do: nil

  # Parse type strings (keep as atoms since they're glTF spec strings)
  defp parse_type("SCALAR"), do: :scalar
  defp parse_type("VEC2"), do: :vec2
  defp parse_type("VEC3"), do: :vec3
  defp parse_type("VEC4"), do: :vec4
  defp parse_type("MAT2"), do: :mat2
  defp parse_type("MAT3"), do: :mat3
  defp parse_type("MAT4"), do: :mat4
  defp parse_type(_), do: nil

  # Parse sparse accessor data (placeholder for now)
  defp parse_sparse(nil), do: nil

  defp parse_sparse(_sparse_data) do
    # TODO: Implement sparse accessor parsing
    nil
  end

  @doc """
  Check if this accessor points to valid buffer view data.
  """
  def valid_buffer_view?(%__MODULE__{buffer_view: nil}), do: false

  def valid_buffer_view?(%__MODULE__{buffer_view: buffer_view})
      when is_integer(buffer_view) and buffer_view >= 0,
      do: true

  def valid_buffer_view?(_), do: false

  @doc """
  Get the absolute byte offset within the underlying buffer.
  """
  def absolute_byte_offset(%__MODULE__{byte_offset: accessor_offset}, buffer_view_offset) do
    accessor_offset + buffer_view_offset
  end

  @doc """
  Check if this accessor uses normalized integer values.
  """
  def normalized?(%__MODULE__{normalized: normalized}), do: !!normalized

  @doc """
  Check if this accessor uses floating-point components.
  """
  def float_components?(%__MODULE__{component_type: @gl_float}), do: true
  def float_components?(_), do: false

  @doc """
  Check if this accessor represents matrix data.
  """
  def matrix?(%__MODULE__{type: type}) when type in [:mat2, :mat3, :mat4], do: true
  def matrix?(_), do: false

  @doc """
  Check if this accessor represents vector data.
  """
  def vector?(%__MODULE__{type: type}) when type in [:vec2, :vec3, :vec4], do: true
  def vector?(_), do: false

  @doc """
  Check if this accessor represents scalar data.
  """
  def scalar?(%__MODULE__{type: :scalar}), do: true
  def scalar?(_), do: false
end

defmodule GLTF.Accessor.Sparse do
  @moduledoc """
  Sparse storage of attributes that deviate from their initialization value.
  """

  defstruct [
    :count,
    :indices,
    :values,
    :extensions,
    :extras
  ]

  @type t :: %__MODULE__{
          count: pos_integer(),
          indices: GLTF.Accessor.Sparse.Indices.t(),
          values: GLTF.Accessor.Sparse.Values.t(),
          extensions: map() | nil,
          extras: any() | nil
        }
end

defmodule GLTF.Accessor.Sparse.Indices do
  @moduledoc """
  Indices of sparse accessors.
  """

  defstruct [
    :buffer_view,
    :byte_offset,
    :component_type,
    :extensions,
    :extras
  ]

  @type t :: %__MODULE__{
          buffer_view: non_neg_integer(),
          byte_offset: non_neg_integer(),
          component_type: GLTF.Accessor.component_type(),
          extensions: map() | nil,
          extras: any() | nil
        }
end

defmodule GLTF.Accessor.Sparse.Values do
  @moduledoc """
  Array of displaced elements corresponding to the indices.
  """

  defstruct [
    :buffer_view,
    :byte_offset,
    :extensions,
    :extras
  ]

  @type t :: %__MODULE__{
          buffer_view: non_neg_integer(),
          byte_offset: non_neg_integer(),
          extensions: map() | nil,
          extras: any() | nil
        }
end
