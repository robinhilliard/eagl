defmodule EAGL.Node do
  @moduledoc """
  Hierarchical transform nodes for scene graphs.

  EAGL.Node represents objects in a 3D scene with transform properties and
  parent-child relationships. Nodes can contain meshes, cameras, or just
  serve as transform anchors.

  ## Transform System

  Nodes support both matrix and TRS (Translation, Rotation, Scale) transforms,
  following glTF conventions:

      # TRS transforms (more intuitive)
      node = Node.new(
        position: vec3(5, 0, 0),
        rotation: quat_from_euler(0, 45, 0),
        scale: vec3(1, 1, 1)
      )

      # Matrix transform (when loaded from glTF)
      node = Node.with_matrix(some_4x4_matrix)

  ## Hierarchy

  Nodes form parent-child relationships:

      parent = Node.new()
      child1 = Node.new(position: vec3(2, 0, 0))
      child2 = Node.new(position: vec3(-2, 0, 0))

      parent
      |> Node.add_child(child1)
      |> Node.add_child(child2)

  ## Integration with Existing EAGL

  Nodes can contain meshes created with existing EAGL.Buffer APIs:

      {vao, vbo} = EAGL.Buffer.create_vertex_array(vertices, attributes)
      mesh = %{vao: vao, vertex_count: vertex_count, program: shader_program}

      node = Node.new(mesh: mesh, position: vec3(0, 5, 0))
  """

  import EAGL.Math

  defstruct [
    # Transform properties (TRS or matrix)
    :position,
    :rotation,
    :scale,
    :matrix,

    # Hierarchy
    :children,
    :parent,

    # Content
    :mesh,
    :camera,
    :name,

    # Animation
    :animations
  ]

  @type t :: %__MODULE__{
          position: list(float()) | nil,
          rotation: list(float()) | nil,
          scale: list(float()) | nil,
          matrix: list(float()) | nil,
          children: [t()],
          parent: t() | nil,
          mesh: map() | nil,
          camera: map() | nil,
          name: String.t() | nil,
          animations: map() | nil
        }

  @doc """
  Create a new node with TRS transforms.
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    %__MODULE__{
      position: Keyword.get(opts, :position, vec3(0, 0, 0)),
      rotation: Keyword.get(opts, :rotation, quat_identity()),
      scale: Keyword.get(opts, :scale, vec3(1, 1, 1)),
      matrix: nil,
      children: [],
      parent: nil,
      mesh: Keyword.get(opts, :mesh),
      camera: Keyword.get(opts, :camera),
      name: Keyword.get(opts, :name),
      animations: %{}
    }
  end

  @doc """
  Create a node with a transformation matrix.
  """
  @spec with_matrix(list(float()), keyword()) :: t()
  def with_matrix(matrix, opts \\ []) when is_list(matrix) do
    %__MODULE__{
      position: nil,
      rotation: nil,
      scale: nil,
      matrix: matrix,
      children: [],
      parent: nil,
      mesh: Keyword.get(opts, :mesh),
      camera: Keyword.get(opts, :camera),
      name: Keyword.get(opts, :name),
      animations: %{}
    }
  end

  @doc """
  Add a child node to this node.
  """
  @spec add_child(t(), t()) :: t()
  def add_child(%__MODULE__{children: children} = parent, %__MODULE__{} = child) do
    updated_child = %{child | parent: parent}
    %{parent | children: [updated_child | children]}
  end

  @doc """
  Remove a child node from this node.
  """
  @spec remove_child(t(), t()) :: t()
  def remove_child(%__MODULE__{children: children} = parent, child) do
    updated_children = Enum.reject(children, fn c -> c.name == child.name end)
    %{parent | children: updated_children}
  end

  @doc """
  Get the local transformation matrix for this node.
  """
  @spec get_local_transform_matrix(t()) :: list(float())
  def get_local_transform_matrix(%__MODULE__{matrix: matrix}) when is_list(matrix) do
    matrix
  end

  def get_local_transform_matrix(%__MODULE__{position: pos, rotation: rot, scale: scale}) do
    # Follow glTF spec: T * R * S order
    translation_matrix = mat4_translate(pos || vec3(0, 0, 0))
    rotation_matrix = quat_to_mat4(rot || quat_identity())
    scale_matrix = mat4_scale(scale || vec3(1, 1, 1))

    translation_matrix
    |> mat4_mul(rotation_matrix)
    |> mat4_mul(scale_matrix)
  end

  @doc """
  Get the world transformation matrix for this node.
  """
  @spec get_world_transform_matrix(t()) :: list(float())
  def get_world_transform_matrix(%__MODULE__{parent: nil} = node) do
    get_local_transform_matrix(node)
  end

  def get_world_transform_matrix(%__MODULE__{parent: parent} = node) do
    parent_world = get_world_transform_matrix(parent)
    local = get_local_transform_matrix(node)
    mat4_mul(parent_world, local)
  end

  @doc """
  Set the position of this node.
  """
  @spec set_position(t(), list(float())) :: t()
  def set_position(%__MODULE__{} = node, position) do
    %{node | position: position, matrix: nil}
  end

  @doc """
  Set the rotation of this node.
  """
  @spec set_rotation(t(), list(float())) :: t()
  def set_rotation(%__MODULE__{} = node, rotation) do
    %{node | rotation: rotation, matrix: nil}
  end

  @doc """
  Set the scale of this node.
  """
  @spec set_scale(t(), list(float())) :: t()
  def set_scale(%__MODULE__{} = node, scale) do
    %{node | scale: scale, matrix: nil}
  end

  @doc """
  Get all children of this node.
  """
  @spec get_children(t()) :: [t()]
  def get_children(%__MODULE__{children: children}), do: children

  @doc """
  Set the children of this node.
  """
  @spec set_children(t(), [t()]) :: t()
  def set_children(%__MODULE__{} = node, children) do
    %{node | children: children}
  end

  @doc """
  Get the ID of this node (uses name as ID).
  """
  @spec get_id(t()) :: String.t() | atom() | nil
  def get_id(%__MODULE__{name: name}), do: name

  @doc """
  Get the mesh attached to this node.
  """
  @spec get_mesh(t()) :: map() | nil
  def get_mesh(%__MODULE__{mesh: mesh}), do: mesh

  @doc """
  Set the mesh for this node.
  """
  @spec set_mesh(t(), map()) :: t()
  def set_mesh(%__MODULE__{} = node, mesh) do
    %{node | mesh: mesh}
  end

  @doc """
  Get all descendant nodes (recursive).
  """
  @spec get_all_descendants(t()) :: [t()]
  def get_all_descendants(%__MODULE__{children: children} = node) do
    direct_children = children
    nested_children = Enum.flat_map(children, &get_all_descendants/1)
    [node | direct_children ++ nested_children]
  end

  @doc """
  Update animations for this node and all children.
  """
  @spec update_animations(t(), float()) :: t()
  def update_animations(%__MODULE__{children: children} = node, delta_time) do
    # Update this node's animations
    updated_node = update_node_animations(node, delta_time)

    # Recursively update children
    updated_children =
      Enum.map(children, fn child ->
        update_animations(child, delta_time)
      end)

    %{updated_node | children: updated_children}
  end

  @doc """
  Find a node by name in this subtree.
  """
  @spec find_by_name(t(), String.t()) :: t() | nil
  def find_by_name(%__MODULE__{name: name} = node, target_name) when name == target_name do
    node
  end

  def find_by_name(%__MODULE__{children: children}, target_name) do
    Enum.find_value(children, fn child ->
      find_by_name(child, target_name)
    end)
  end

  # Private functions

  defp update_node_animations(%__MODULE__{animations: animations} = node, _delta_time)
       when map_size(animations) == 0 do
    node
  end

  defp update_node_animations(%__MODULE__{} = node, _delta_time) do
    # Animation system will be implemented separately
    # For now, just return the node unchanged
    node
  end
end
