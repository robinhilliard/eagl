defmodule GLTF.Node do
  @moduledoc """
  A node in the node hierarchy. When a node contains 'skin', all 'mesh' primitives must contain 'JOINTS_0' and 'WEIGHTS_0' attributes.
  """

  defstruct [
    :camera,
    :children,
    :skin,
    :matrix,
    :mesh,
    :rotation,
    :scale,
    :translation,
    :weights,
    :name,
    :extensions,
    :extras
  ]

  @type t :: %__MODULE__{
          camera: non_neg_integer() | nil,
          children: [non_neg_integer()] | nil,
          skin: non_neg_integer() | nil,
          matrix: [float()] | nil,
          mesh: non_neg_integer() | nil,
          rotation: [float()] | nil,
          scale: [float()] | nil,
          translation: [float()] | nil,
          weights: [float()] | nil,
          name: String.t() | nil,
          extensions: map() | nil,
          extras: any() | nil
        }

  @doc """
  Create a new node.
  """
  def new(opts \\ []) do
    %__MODULE__{
      camera: Keyword.get(opts, :camera),
      children: Keyword.get(opts, :children),
      skin: Keyword.get(opts, :skin),
      matrix: Keyword.get(opts, :matrix),
      mesh: Keyword.get(opts, :mesh),
      rotation: Keyword.get(opts, :rotation, [0.0, 0.0, 0.0, 1.0]),
      scale: Keyword.get(opts, :scale, [1.0, 1.0, 1.0]),
      translation: Keyword.get(opts, :translation, [0.0, 0.0, 0.0]),
      weights: Keyword.get(opts, :weights),
      name: Keyword.get(opts, :name),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end

  @doc """
  Create a node with transformation matrix.
  """
  def with_matrix(matrix, opts \\ []) when is_list(matrix) and length(matrix) == 16 do
    %__MODULE__{
      matrix: matrix,
      camera: Keyword.get(opts, :camera),
      children: Keyword.get(opts, :children),
      skin: Keyword.get(opts, :skin),
      mesh: Keyword.get(opts, :mesh),
      weights: Keyword.get(opts, :weights),
      name: Keyword.get(opts, :name),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end

  @doc """
  Create a node with TRS (Translation, Rotation, Scale) properties.
  """
  def with_trs(translation, rotation, scale, opts \\ []) do
    %__MODULE__{
      translation: translation || [0.0, 0.0, 0.0],
      rotation: rotation || [0.0, 0.0, 0.0, 1.0],
      scale: scale || [1.0, 1.0, 1.0],
      camera: Keyword.get(opts, :camera),
      children: Keyword.get(opts, :children),
      skin: Keyword.get(opts, :skin),
      mesh: Keyword.get(opts, :mesh),
      weights: Keyword.get(opts, :weights),
      name: Keyword.get(opts, :name),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end

  @doc """
  Check if node uses matrix transformation (mutually exclusive with TRS).
  """
  def uses_matrix?(%__MODULE__{matrix: matrix}) when is_list(matrix), do: true
  def uses_matrix?(%__MODULE__{}), do: false

  @doc """
  Check if node uses TRS transformation.
  """
  def uses_trs?(%__MODULE__{matrix: nil}), do: true
  def uses_trs?(%__MODULE__{}), do: false

  @doc """
  Validate that matrix and TRS are not both specified.
  """
  def validate_transform(%__MODULE__{matrix: matrix}) when is_list(matrix) do
    # When matrix is defined, TRS should not be present
    :ok
  end

  def validate_transform(%__MODULE__{}) do
    # TRS properties are allowed
    :ok
  end

  @doc """
  Check if this node has any children.
  """
  def has_children?(%__MODULE__{children: nil}), do: false
  def has_children?(%__MODULE__{children: []}), do: false
  def has_children?(%__MODULE__{children: _}), do: true

  @doc """
  Load a Node struct from JSON data.
  """
  def load(json_data) when is_map(json_data) do
    node = %__MODULE__{
      camera: json_data["camera"],
      children: json_data["children"],
      skin: json_data["skin"],
      matrix: json_data["matrix"],
      mesh: json_data["mesh"],
      rotation: json_data["rotation"],
      scale: json_data["scale"],
      translation: json_data["translation"],
      weights: json_data["weights"],
      name: json_data["name"],
      extensions: json_data["extensions"],
      extras: json_data["extras"]
    }

    # Validate that matrix and TRS are mutually exclusive
    case {node.matrix, has_trs_properties?(node)} do
      # No matrix, TRS is fine
      {nil, _} -> {:ok, node}
      # Has matrix, no TRS properties
      {_, false} -> {:ok, node}
      {_, true} -> {:error, :matrix_and_trs_both_defined}
    end
  end

  # Check if the node has any TRS (translation/rotation/scale) properties
  defp has_trs_properties?(%__MODULE__{translation: t, rotation: r, scale: s}) do
    t != nil or r != nil or s != nil
  end
end
