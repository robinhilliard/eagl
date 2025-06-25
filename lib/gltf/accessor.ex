defmodule GLTF.Accessor do
  @moduledoc """
  A typed view into a bufferView. A bufferView contains raw binary data.
  An accessor provides a typed view into a bufferView or a subset of a bufferView
  similar to how WebGL's vertexAttribPointer() defines an attribute in a buffer.
  """

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

  @type component_type :: 5120 | 5121 | 5122 | 5123 | 5125 | 5126
  @type accessor_type :: :scalar | :vec2 | :vec3 | :vec4 | :mat2 | :mat3 | :mat4

  # Component types
  @byte 5120
  @unsigned_byte 5121
  @short 5122
  @unsigned_short 5123
  @unsigned_int 5125
  @float 5126

  def component_types do
    %{
      @byte => {:signed_byte, 1},
      @unsigned_byte => {:unsigned_byte, 1},
      @short => {:signed_short, 2},
      @unsigned_short => {:unsigned_short, 2},
      @unsigned_int => {:unsigned_int, 4},
      @float => {:float, 4}
    }
  end

  def accessor_types do
    %{
      :scalar => 1,
      :vec2 => 2,
      :vec3 => 3,
      :vec4 => 4,
      :mat2 => 4,
      :mat3 => 9,
      :mat4 => 16
    }
  end

  @doc """
  Calculate the element size in bytes for this accessor.
  """
  def element_size(%__MODULE__{component_type: component_type, type: type}) do
    {_, component_size} = Map.get(component_types(), component_type)
    component_count = Map.get(accessor_types(), type)
    component_size * component_count
  end
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
