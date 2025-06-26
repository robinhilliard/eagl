defmodule EAGL.Scene do
  @moduledoc """
  Scene graph management for hierarchical 3D scenes.

  EAGL.Scene provides a higher-level abstraction for managing complex 3D scenes
  with transform hierarchies, while building on EAGL's existing buffer and shader APIs.

  ## Design Philosophy

  This module extends EAGL's scope to support fundamental 3D concepts like scene graphs
  and transform hierarchies, as represented in industry standards like glTF. The APIs
  are designed to be composable with existing EAGL functionality.

  ## Usage

      # Create a scene with hierarchical nodes
      scene = Scene.new()

      # Root node (car body)
      car_node = Node.new(position: vec3(0, 0, 0), mesh: car_mesh)

      # Child nodes (wheels) with local transforms
      wheel1 = Node.new(position: vec3(-2, -1, 2), mesh: wheel_mesh)
      wheel2 = Node.new(position: vec3(2, -1, 2), mesh: wheel_mesh)

      Node.add_child(car_node, wheel1)
      Node.add_child(car_node, wheel2)
      Scene.add_root_node(scene, car_node)

      # Render with automatic transform hierarchy
      Scene.render(scene, view_matrix, projection_matrix)

  ## Backward Compatibility

  Scene graphs can contain meshes created with existing EAGL.Buffer APIs:

      # Use existing EAGL buffer creation
      {vao, vbo} = EAGL.Buffer.create_vertex_array(vertices, attributes)
      mesh = %{vao: vao, vertex_count: length(vertices) / 3}

      # Use in scene graph
      node = Node.new(mesh: mesh)

  ## glTF Integration

  This module provides the foundation for loading glTF scenes:

      {:ok, gltf} = GLTF.GLBLoader.parse("model.glb")
      {:ok, scene} = GLTF.EAGL.to_scene(gltf)
      Scene.render(scene, view_matrix, projection_matrix)
  """

  alias EAGL.Node
  import EAGL.Math
  use EAGL.Const

  defstruct [
    :root_nodes,
    :name
  ]

  @type t :: %__MODULE__{
          root_nodes: [Node.t()],
          name: String.t() | nil
        }

  @doc """
  Create a new empty scene.
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    %__MODULE__{
      root_nodes: [],
      name: Keyword.get(opts, :name)
    }
  end

  @doc """
  Add a root node to the scene.
  """
  @spec add_root_node(t(), Node.t()) :: t()
  def add_root_node(%__MODULE__{root_nodes: roots} = scene, %Node{} = node) do
    %{scene | root_nodes: [node | roots]}
  end

  @doc """
  Render the entire scene with transform hierarchy.

  This function traverses the scene graph and renders each mesh with its
  accumulated transform matrix.
  """
  @spec render(t(), list(float()), list(float())) :: :ok
  def render(%__MODULE__{root_nodes: roots}, view_matrix, projection_matrix) do
    identity_matrix = mat4_identity()

    Enum.each(roots, fn root_node ->
      render_node_recursive(root_node, identity_matrix, view_matrix, projection_matrix)
    end)

    :ok
  end

  @doc """
  Update all animations in the scene.
  """
  @spec update(t(), float()) :: t()
  def update(%__MODULE__{root_nodes: roots} = scene, delta_time) do
    updated_roots =
      Enum.map(roots, fn node ->
        Node.update_animations(node, delta_time)
      end)

    %{scene | root_nodes: updated_roots}
  end

  @doc """
  Get all nodes in the scene (flattened).
  """
  @spec get_all_nodes(t()) :: [Node.t()]
  def get_all_nodes(%__MODULE__{root_nodes: roots}) do
    Enum.flat_map(roots, &Node.get_all_descendants/1)
  end

  @doc """
  Find a node in the scene by ID.

  Searches recursively through the scene graph to find a node with the given ID.
  """
  @spec find_node(t(), String.t() | atom()) :: Node.t() | nil
  def find_node(%__MODULE__{root_nodes: root_nodes}, node_id) do
    Enum.find_value(root_nodes, fn node ->
      find_node_recursive(node, node_id)
    end)
  end

  @doc """
  Update a node in the scene.

  Replaces the node with the given ID with the updated node.
  """
  @spec update_node(t(), String.t() | atom(), Node.t()) :: t()
  def update_node(%__MODULE__{} = scene, node_id, updated_node) do
    new_root_nodes =
      Enum.map(scene.root_nodes, fn node ->
        update_node_recursive(node, node_id, updated_node)
      end)

    %{scene | root_nodes: new_root_nodes}
  end

  # Private functions

  defp find_node_recursive(%Node{} = node, target_id) do
    cond do
      Node.get_id(node) == target_id ->
        node

      true ->
        # Search children
        Enum.find_value(Node.get_children(node), fn child ->
          find_node_recursive(child, target_id)
        end)
    end
  end

  defp update_node_recursive(%Node{} = node, target_id, updated_node) do
    cond do
      Node.get_id(node) == target_id ->
        updated_node

      true ->
        # Update children recursively
        updated_children =
          Enum.map(Node.get_children(node), fn child ->
            update_node_recursive(child, target_id, updated_node)
          end)

        Node.set_children(node, updated_children)
    end
  end

  defp render_node_recursive(%Node{} = node, parent_transform, view_matrix, projection_matrix) do
    # Calculate this node's world transform
    local_transform = Node.get_local_transform_matrix(node)
    world_transform = mat4_mul(parent_transform, local_transform)

    # Render this node's mesh if it has one
    case Node.get_mesh(node) do
      nil -> :ok
      mesh -> render_mesh(mesh, world_transform, view_matrix, projection_matrix)
    end

    # Recursively render children
    children = Node.get_children(node)

    Enum.each(children, fn child ->
      render_node_recursive(child, world_transform, view_matrix, projection_matrix)
    end)
  end

  defp render_mesh(mesh, model_matrix, view_matrix, projection_matrix) do
    # Use existing EAGL shader system
    case mesh do
      %{vao: vao, vertex_count: count, program: program} ->
        :gl.useProgram(program)

        # Set standard matrices
        EAGL.Shader.set_uniforms(program,
          model: model_matrix,
          view: view_matrix,
          projection: projection_matrix
        )

        # Render using existing OpenGL calls
        :gl.bindVertexArray(vao)
        :gl.drawArrays(@gl_triangles, 0, count)

      %{vao: vao, index_count: count, program: program} ->
        :gl.useProgram(program)

        EAGL.Shader.set_uniforms(program,
          model: model_matrix,
          view: view_matrix,
          projection: projection_matrix
        )

        :gl.bindVertexArray(vao)
        :gl.drawElements(@gl_triangles, count, @gl_unsigned_int, 0)

      _ ->
        # Fallback for meshes without shader programs
        :ok
    end
  end
end
