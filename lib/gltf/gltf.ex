defmodule GLTF do
  @moduledoc """
  The root object for a glTF asset.

  This represents the complete glTF document structure with all its components.
  """

  defstruct [
    :extensions_used,
    :extensions_required,
    :accessors,
    :animations,
    :asset,
    :buffers,
    :buffer_views,
    :cameras,
    :images,
    :materials,
    :meshes,
    :nodes,
    :samplers,
    :scene,
    :scenes,
    :skins,
    :textures,
    :extensions,
    :extras
  ]

  @type t :: %__MODULE__{
    extensions_used: [String.t()] | nil,
    extensions_required: [String.t()] | nil,
    accessors: [GLTF.Accessor.t()] | nil,
    animations: [GLTF.Animation.t()] | nil,
    asset: GLTF.Asset.t(),
    buffers: [GLTF.Buffer.t()] | nil,
    buffer_views: [GLTF.BufferView.t()] | nil,
    cameras: [GLTF.Camera.t()] | nil,
    images: [GLTF.Image.t()] | nil,
    materials: [GLTF.Material.t()] | nil,
    meshes: [GLTF.Mesh.t()] | nil,
    nodes: [GLTF.Node.t()] | nil,
    samplers: [GLTF.Sampler.t()] | nil,
    scene: non_neg_integer() | nil,
    scenes: [GLTF.Scene.t()] | nil,
    skins: [GLTF.Skin.t()] | nil,
    textures: [GLTF.Texture.t()] | nil,
    extensions: map() | nil,
    extras: any() | nil
  }

  @doc """
  Create a new glTF document with required asset information.
  """
  def new(version \\ "2.0", opts \\ []) do
    asset = GLTF.Asset.new(version, Keyword.take(opts, [:copyright, :generator, :min_version]))

    %__MODULE__{
      asset: asset,
      extensions_used: Keyword.get(opts, :extensions_used),
      extensions_required: Keyword.get(opts, :extensions_required),
      accessors: Keyword.get(opts, :accessors),
      animations: Keyword.get(opts, :animations),
      buffers: Keyword.get(opts, :buffers),
      buffer_views: Keyword.get(opts, :buffer_views),
      cameras: Keyword.get(opts, :cameras),
      images: Keyword.get(opts, :images),
      materials: Keyword.get(opts, :materials),
      meshes: Keyword.get(opts, :meshes),
      nodes: Keyword.get(opts, :nodes),
      samplers: Keyword.get(opts, :samplers),
      scene: Keyword.get(opts, :scene),
      scenes: Keyword.get(opts, :scenes),
      skins: Keyword.get(opts, :skins),
      textures: Keyword.get(opts, :textures),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end

  @doc """
  Validate the glTF document structure.
  """
  def validate(%__MODULE__{} = gltf) do
    with :ok <- validate_required_fields(gltf),
         :ok <- validate_indices(gltf),
         :ok <- validate_extensions(gltf) do
      :ok
    end
  end

  defp validate_required_fields(%__MODULE__{asset: nil}) do
    {:error, :missing_asset}
  end

  defp validate_required_fields(%__MODULE__{asset: %GLTF.Asset{version: nil}}) do
    {:error, :missing_asset_version}
  end

  defp validate_required_fields(_), do: :ok

  defp validate_indices(%__MODULE__{} = gltf) do
    # Validate that all array indices reference valid elements
    # This is a simplified validation - a full implementation would check all references
    with :ok <- validate_scene_index(gltf),
         :ok <- validate_scene_node_indices(gltf) do
      :ok
    end
  end

  defp validate_scene_index(%__MODULE__{scene: nil}), do: :ok
  defp validate_scene_index(%__MODULE__{scene: index, scenes: scenes}) when is_list(scenes) do
    if index >= 0 and index < length(scenes) do
      :ok
    else
      {:error, {:invalid_scene_index, index}}
    end
  end
  defp validate_scene_index(%__MODULE__{scene: _}), do: {:error, :scene_index_without_scenes}

  defp validate_scene_node_indices(%__MODULE__{scenes: nil}), do: :ok
  defp validate_scene_node_indices(%__MODULE__{scenes: scenes, nodes: nodes}) when is_list(scenes) do
    node_count = if is_list(nodes), do: length(nodes), else: 0

    scenes
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {scene, scene_idx}, :ok ->
      case validate_node_indices(scene.nodes, node_count) do
        :ok -> {:cont, :ok}
        error -> {:halt, {:error, {:scene, scene_idx, error}}}
      end
    end)
  end

  defp validate_node_indices(nil, _), do: :ok
  defp validate_node_indices(node_indices, node_count) when is_list(node_indices) do
    invalid = Enum.find(node_indices, fn idx -> idx < 0 or idx >= node_count end)

    case invalid do
      nil -> :ok
      idx -> {:invalid_node_index, idx}
    end
  end

  defp validate_extensions(%__MODULE__{extensions_used: nil}), do: :ok
  defp validate_extensions(%__MODULE__{extensions_used: used, extensions_required: required}) do
    # All required extensions must be in used extensions
    case required do
      nil -> :ok
      req_list when is_list(req_list) ->
        used_list = used || []
        missing = req_list -- used_list

        case missing do
          [] -> :ok
          _ -> {:error, {:required_extensions_not_in_used, missing}}
        end
    end
  end

  @doc """
  Get the default scene, if specified.
  """
  def default_scene(%__MODULE__{scene: nil}), do: nil
  def default_scene(%__MODULE__{scene: index, scenes: scenes}) when is_list(scenes) do
    Enum.at(scenes, index)
  end
  def default_scene(%__MODULE__{}), do: nil

  @doc """
  Check if this glTF uses any extensions.
  """
  def uses_extensions?(%__MODULE__{extensions_used: nil}), do: false
  def uses_extensions?(%__MODULE__{extensions_used: []}), do: false
  def uses_extensions?(%__MODULE__{extensions_used: _}), do: true

  @doc """
  Check if this glTF requires specific extensions for loading.
  """
  def requires_extensions?(%__MODULE__{extensions_required: nil}), do: false
  def requires_extensions?(%__MODULE__{extensions_required: []}), do: false
  def requires_extensions?(%__MODULE__{extensions_required: _}), do: true
end
