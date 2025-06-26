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

  @doc """
  Load an Accessor struct from JSON data.
  """
  def load(json_data) when is_map(json_data) do
    # Parse accessor type
    accessor_type =
      case json_data["type"] do
        "SCALAR" -> :scalar
        "VEC2" -> :vec2
        "VEC3" -> :vec3
        "VEC4" -> :vec4
        "MAT2" -> :mat2
        "MAT3" -> :mat3
        "MAT4" -> :mat4
        _ -> nil
      end

    accessor = %__MODULE__{
      buffer_view: json_data["bufferView"],
      byte_offset: json_data["byteOffset"] || 0,
      component_type: json_data["componentType"],
      normalized: json_data["normalized"] || false,
      count: json_data["count"],
      type: accessor_type,
      max: json_data["max"],
      min: json_data["min"],
      sparse: load_sparse(json_data["sparse"]),
      name: json_data["name"],
      extensions: json_data["extensions"],
      extras: json_data["extras"]
    }

    # Validate required fields
    case {accessor.component_type, accessor.count, accessor.type} do
      {nil, _, _} ->
        {:error, :missing_component_type}

      {_, nil, _} ->
        {:error, :missing_count}

      {_, _, nil} ->
        {:error, :invalid_accessor_type}

      {ct, count, _} when is_integer(ct) and is_integer(count) and count > 0 ->
        # Validate component type is supported
        if Map.has_key?(component_types(), ct) do
          {:ok, accessor}
        else
          {:error, {:unsupported_component_type, ct}}
        end

      _ ->
        {:error, :invalid_fields}
    end
  end

  # Load sparse accessor data if present
  defp load_sparse(nil), do: nil

  defp load_sparse(sparse_data) when is_map(sparse_data) do
    indices =
      case sparse_data["indices"] do
        nil -> nil
        indices_data -> load_sparse_indices(indices_data)
      end

    values =
      case sparse_data["values"] do
        nil -> nil
        values_data -> load_sparse_values(values_data)
      end

    # Create sparse struct using map syntax to avoid forward reference
    sparse_struct = %{
      __struct__: GLTF.Accessor.Sparse,
      count: sparse_data["count"],
      indices: indices,
      values: values,
      extensions: sparse_data["extensions"],
      extras: sparse_data["extras"]
    }

    sparse_struct
  end

  defp load_sparse_indices(indices_data) when is_map(indices_data) do
    # Create indices struct using map syntax to avoid forward reference
    %{
      __struct__: GLTF.Accessor.Sparse.Indices,
      buffer_view: indices_data["bufferView"],
      byte_offset: indices_data["byteOffset"] || 0,
      component_type: indices_data["componentType"],
      extensions: indices_data["extensions"],
      extras: indices_data["extras"]
    }
  end

  defp load_sparse_values(values_data) when is_map(values_data) do
    # Create values struct using map syntax to avoid forward reference
    %{
      __struct__: GLTF.Accessor.Sparse.Values,
      buffer_view: values_data["bufferView"],
      byte_offset: values_data["byteOffset"] || 0,
      extensions: values_data["extensions"],
      extras: values_data["extras"]
    }
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
