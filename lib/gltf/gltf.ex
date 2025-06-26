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

  defp validate_scene_node_indices(%__MODULE__{scenes: scenes, nodes: nodes})
       when is_list(scenes) do
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
      nil ->
        :ok

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

  @doc """
  Load a GLTF document from parsed JSON data and optional binary data store.

  This function recursively constructs the GLTF struct tree from JSON data,
  delegating to individual module load functions as needed.
  """
  def load(json_data, binary_data_store \\ nil) when is_map(json_data) do
    with {:ok, asset} <- load_asset(json_data),
         {:ok, buffers} <- load_buffers(json_data, binary_data_store),
         {:ok, buffer_views} <- load_buffer_views(json_data),
         {:ok, accessors} <- load_accessors(json_data),
         {:ok, scenes} <- load_scenes(json_data),
         {:ok, nodes} <- load_nodes(json_data),
         {:ok, meshes} <- load_meshes(json_data),
         {:ok, materials} <- load_materials(json_data),
         {:ok, textures} <- load_textures(json_data),
         {:ok, images} <- load_images(json_data),
         {:ok, samplers} <- load_samplers(json_data),
         {:ok, cameras} <- load_cameras(json_data),
         {:ok, skins} <- load_skins(json_data),
         {:ok, animations} <- load_animations(json_data) do
      gltf = %__MODULE__{
        asset: asset,
        extensions_used: json_data["extensionsUsed"],
        extensions_required: json_data["extensionsRequired"],
        accessors: accessors,
        animations: animations,
        buffers: buffers,
        buffer_views: buffer_views,
        cameras: cameras,
        images: images,
        materials: materials,
        meshes: meshes,
        nodes: nodes,
        samplers: samplers,
        scene: json_data["scene"],
        scenes: scenes,
        skins: skins,
        textures: textures,
        extensions: json_data["extensions"],
        extras: json_data["extras"]
      }

      {:ok, gltf}
    end
  end

  @doc """
  Load a GLTF document from a GLB binary structure.

  This function extracts the JSON chunk, parses it, and creates a binary data store
  for managing GLB-embedded buffer data.
  """
  def load_from_glb(%GLTF.Binary{} = glb_binary) do
    with {:ok, json_data} <- parse_json_from_glb(glb_binary),
         {:ok, data_store} <- create_data_store_from_glb(glb_binary) do
      load(json_data, data_store)
    end
  end

  # Private helper functions

  defp parse_json_from_glb(glb_binary) do
    json_string = GLTF.Binary.get_json(glb_binary)

    case Poison.decode(json_string) do
      {:ok, json_data} -> {:ok, json_data}
      {:error, reason} -> {:error, {:json_parse_error, reason}}
    end
  rescue
    UndefinedFunctionError ->
      {:error, :poison_not_available}
  end

  defp create_data_store_from_glb(glb_binary) do
    binary_data = GLTF.Binary.get_binary(glb_binary)
    data_store = GLTF.DataStore.new()

    # GLB buffer (index 0) points to the binary chunk
    case binary_data do
      nil -> {:ok, data_store}
      data -> {:ok, GLTF.DataStore.store_glb_buffer(data_store, 0, data)}
    end
  end

  defp load_asset(%{"asset" => asset_data}) do
    GLTF.Asset.load(asset_data)
  end

  defp load_asset(_), do: {:error, :missing_asset}

  defp load_buffers(%{"buffers" => buffers_data}, data_store) when is_list(buffers_data) do
    buffers_data
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {buffer_data, index}, {:ok, acc} ->
      case GLTF.Buffer.load(buffer_data, index, data_store) do
        {:ok, buffer} -> {:cont, {:ok, [buffer | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, buffers} -> {:ok, Enum.reverse(buffers)}
      error -> error
    end
  end

  defp load_buffers(_, _), do: {:ok, nil}

  defp load_buffer_views(%{"bufferViews" => buffer_views_data}) when is_list(buffer_views_data) do
    load_array(buffer_views_data, &GLTF.BufferView.load/1)
  end

  defp load_buffer_views(_), do: {:ok, nil}

  defp load_accessors(%{"accessors" => accessors_data}) when is_list(accessors_data) do
    load_array(accessors_data, &GLTF.Accessor.load/1)
  end

  defp load_accessors(_), do: {:ok, nil}

  defp load_scenes(%{"scenes" => scenes_data}) when is_list(scenes_data) do
    load_array(scenes_data, &GLTF.Scene.load/1)
  end

  defp load_scenes(_), do: {:ok, nil}

  defp load_nodes(%{"nodes" => nodes_data}) when is_list(nodes_data) do
    load_array(nodes_data, &GLTF.Node.load/1)
  end

  defp load_nodes(_), do: {:ok, nil}

  defp load_meshes(%{"meshes" => meshes_data}) when is_list(meshes_data) do
    load_array(meshes_data, &GLTF.Mesh.load/1)
  end

  defp load_meshes(_), do: {:ok, nil}

  defp load_materials(%{"materials" => materials_data}) when is_list(materials_data) do
    load_array(materials_data, &GLTF.Material.load/1)
  end

  defp load_materials(_), do: {:ok, nil}

  defp load_textures(%{"textures" => textures_data}) when is_list(textures_data) do
    load_array(textures_data, &GLTF.Texture.load/1)
  end

  defp load_textures(_), do: {:ok, nil}

  defp load_images(%{"images" => images_data}) when is_list(images_data) do
    load_array(images_data, &GLTF.Image.load/1)
  end

  defp load_images(_), do: {:ok, nil}

  defp load_samplers(%{"samplers" => samplers_data}) when is_list(samplers_data) do
    load_array(samplers_data, &GLTF.Sampler.load/1)
  end

  defp load_samplers(_), do: {:ok, nil}

  defp load_cameras(%{"cameras" => cameras_data}) when is_list(cameras_data) do
    load_array(cameras_data, &GLTF.Camera.load/1)
  end

  defp load_cameras(_), do: {:ok, nil}

  defp load_skins(%{"skins" => skins_data}) when is_list(skins_data) do
    load_array(skins_data, &GLTF.Skin.load/1)
  end

  defp load_skins(_), do: {:ok, nil}

  defp load_animations(%{"animations" => animations_data}) when is_list(animations_data) do
    load_array(animations_data, &GLTF.Animation.load/1)
  end

  defp load_animations(_), do: {:ok, nil}

  # Helper function to load arrays of objects
  defp load_array(data_list, load_func) do
    data_list
    |> Enum.reduce_while({:ok, []}, fn data, {:ok, acc} ->
      case load_func.(data) do
        {:ok, item} -> {:cont, {:ok, [item | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, items} -> {:ok, Enum.reverse(items)}
      error -> error
    end
  end

  @doc """
  Get buffer data from the glTF asset using a data store.

  This function is intended to be used with a data store that was used
  during loading to access the actual binary data for buffers.
  """
  def get_buffer_data(%__MODULE__{buffers: buffers}, data_store, buffer_index)
      when is_integer(buffer_index) and buffer_index >= 0 do
    case Enum.at(buffers || [], buffer_index) do
      nil ->
        {:error, :buffer_not_found}

      _buffer ->
        case GLTF.DataStore.get_buffer_data(data_store, buffer_index) do
          nil -> {:error, :buffer_data_not_found}
          data -> {:ok, data}
        end
    end
  end

  @doc """
  Get buffer view data from the glTF asset using a data store.

  This function extracts the specific slice of buffer data that corresponds
  to a buffer view, making it easy to access vertex data, indices, etc.
  """
  def get_buffer_view_data(%__MODULE__{buffer_views: buffer_views}, data_store, buffer_view_index)
      when is_integer(buffer_view_index) and buffer_view_index >= 0 do
    case Enum.at(buffer_views || [], buffer_view_index) do
      nil ->
        {:error, :buffer_view_not_found}

      buffer_view ->
        case GLTF.DataStore.get_buffer_slice(
               data_store,
               buffer_view.buffer,
               buffer_view.byte_offset,
               buffer_view.byte_length
             ) do
          nil -> {:error, :buffer_view_data_not_found}
          data -> {:ok, data}
        end
    end
  end

  @doc """
  Get accessor data from the glTF asset using a data store.

  This function extracts typed data for an accessor, which is the most
  common way to access vertex attributes, indices, animation data, etc.

  Returns raw binary data that needs to be interpreted according to
  the accessor's component_type and type.
  """
  def get_accessor_data(%__MODULE__{accessors: accessors} = gltf, data_store, accessor_index)
      when is_integer(accessor_index) and accessor_index >= 0 do
    case Enum.at(accessors || [], accessor_index) do
      nil ->
        {:error, :accessor_not_found}

      accessor ->
        case accessor.buffer_view do
          nil ->
            # Accessor without buffer view (sparse or zero-filled)
            {:ok, :sparse_or_zero_filled}

          buffer_view_index ->
            # Get buffer view data and apply accessor offset
            case get_buffer_view_data(gltf, data_store, buffer_view_index) do
              {:ok, buffer_view_data} ->
                # Apply accessor byte offset within the buffer view
                accessor_offset = accessor.byte_offset
                data_size = calculate_accessor_byte_size(accessor)

                if accessor_offset + data_size <= byte_size(buffer_view_data) do
                  accessor_data = :binary.part(buffer_view_data, accessor_offset, data_size)
                  {:ok, accessor_data}
                else
                  {:error, :accessor_data_out_of_bounds}
                end

              error ->
                error
            end
        end
    end
  end

  @doc """
  Calculate the total byte size needed for an accessor.
  """
  def calculate_accessor_byte_size(%GLTF.Accessor{} = accessor) do
    element_size = GLTF.Accessor.element_size(accessor)
    element_size * accessor.count
  end

  @doc """
  Get all mesh primitive data for easy rendering.

  Returns a list of primitives with their associated data ready for GPU upload.
  """
  def get_mesh_primitives_data(%__MODULE__{meshes: meshes} = gltf, data_store, mesh_index)
      when is_integer(mesh_index) and mesh_index >= 0 do
    case Enum.at(meshes || [], mesh_index) do
      nil ->
        {:error, :mesh_not_found}

      mesh ->
        primitives_data =
          Enum.map(mesh.primitives, fn primitive ->
            %{
              primitive: primitive,
              attributes_data: get_primitive_attributes_data(gltf, data_store, primitive),
              indices_data: get_primitive_indices_data(gltf, data_store, primitive)
            }
          end)

        {:ok, primitives_data}
    end
  end

  defp get_primitive_attributes_data(gltf, data_store, primitive) do
    case primitive.attributes do
      nil ->
        %{}

      attributes ->
        Enum.reduce(attributes, %{}, fn {attr_name, accessor_index}, acc ->
          case get_accessor_data(gltf, data_store, accessor_index) do
            {:ok, data} -> Map.put(acc, attr_name, data)
            {:error, _} -> acc
          end
        end)
    end
  end

  defp get_primitive_indices_data(gltf, data_store, primitive) do
    case primitive.indices do
      nil ->
        nil

      indices_accessor_index ->
        case get_accessor_data(gltf, data_store, indices_accessor_index) do
          {:ok, data} -> data
          {:error, _} -> nil
        end
    end
  end
end
