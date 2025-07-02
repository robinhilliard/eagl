defmodule GLTF.EAGL do
  @moduledoc """
  Bridge module between glTF and EAGL for seamless integration.

  This module provides conversion functions that translate glTF data structures
  into EAGL's existing APIs, enabling glTF assets to work with EAGL's rendering
  system without requiring changes to the core EAGL library.

  ## Design Philosophy

  Rather than extending EAGL's core scope, this module acts as a bridge that:
  - Converts glTF mesh primitives to EAGL VAO/VBO/EBO structures
  - Translates glTF materials to EAGL shader uniforms
  - Transforms glTF nodes into EAGL scene graph nodes
  - Maintains backward compatibility with existing EAGL APIs

  ## Usage

      # Load a glTF file
      {:ok, gltf} = GLTF.GLBLoader.parse("model.glb")
      {:ok, data_store} = create_data_store_for_glb(glb_binary)

      # Convert mesh primitive to EAGL VAO
      {:ok, vao_data} = GLTF.EAGL.primitive_to_vao(gltf, data_store, 0, 0)

      # Convert glTF scene to EAGL scene graph
      {:ok, scene} = GLTF.EAGL.to_scene(gltf, data_store)

      # Use with existing EAGL rendering
      EAGL.Scene.render(scene, view_matrix, projection_matrix)

  ## Backward Compatibility

  All functions return standard EAGL data structures that work with existing APIs:

      # Generated VAO works with existing rendering code
      :gl.bindVertexArray(vao_data.vao)
      :gl.drawElements(@gl_triangles, vao_data.index_count, @gl_unsigned_int, 0)
  """

  alias EAGL.{Scene, Node, Buffer}
  import EAGL.Math
  use EAGL.Const

  @doc """
  Convert a glTF mesh primitive to EAGL VAO/VBO structure.

  Returns a map compatible with existing EAGL rendering code:
  - For indexed primitives: `%{vao: vao, index_count: count, program: program}`
  - For array primitives: `%{vao: vao, vertex_count: count, program: program}`
  """
  @spec primitive_to_vao(
          GLTF.t(),
          GLTF.DataStore.t(),
          non_neg_integer(),
          non_neg_integer(),
          keyword()
        ) ::
          {:ok, map()} | {:error, String.t()}
  def primitive_to_vao(gltf, data_store, mesh_index, primitive_index, opts \\ []) do
    with {:ok, mesh} <- get_mesh(gltf, mesh_index),
         {:ok, primitive} <- get_primitive(mesh, primitive_index),
         {:ok, vertex_data} <- extract_vertex_data(gltf, data_store, primitive),
         {:ok, vao_data} <- create_vao_from_vertex_data(vertex_data, opts) do
      {:ok, vao_data}
    end
  end

  @doc """
  Convert a glTF material to EAGL shader uniforms.

  Returns a keyword list suitable for `EAGL.Shader.set_uniforms/2` or `EAGL.PBR.set_material/2`:

      uniforms = GLTF.EAGL.material_to_uniforms(material)
      EAGL.Shader.set_uniforms(program, uniforms)

  The returned uniforms use glTF-standard parameter names compatible with EAGL's PBR shaders.
  """
  @spec material_to_uniforms(GLTF.Material.t()) :: keyword()
  def material_to_uniforms(%GLTF.Material{} = material) do
    base_uniforms = []

    # PBR Metallic-Roughness workflow (compatible with EAGL.PBR)
    base_uniforms =
      case material.pbr_metallic_roughness do
        nil ->
          base_uniforms

        pbr ->
          base_color = pbr.base_color_factor || [1.0, 1.0, 1.0, 1.0]
          metallic = pbr.metallic_factor || 1.0
          roughness = pbr.roughness_factor || 1.0

          [
            baseColorFactor: list_to_vec4(base_color),
            metallicFactor: metallic,
            roughnessFactor: roughness
          ] ++ base_uniforms
      end

    # Emissive properties
    base_uniforms =
      case material.emissive_factor do
        nil -> base_uniforms
        emissive -> [emissiveFactor: list_to_vec3(emissive)] ++ base_uniforms
      end

    # Alpha properties
    base_uniforms =
      case material.alpha_mode do
        nil -> base_uniforms
        mode -> [alphaMode: atom_to_gl_constant(mode)] ++ base_uniforms
      end

    base_uniforms =
      case material.alpha_cutoff do
        nil -> base_uniforms
        cutoff -> [alphaCutoff: cutoff] ++ base_uniforms
      end

    # Double-sided
    base_uniforms =
      case material.double_sided do
        nil -> base_uniforms
        double_sided -> [doubleSided: if(double_sided, do: 1, else: 0)] ++ base_uniforms
      end

    base_uniforms
  end

  @doc """
  Convert a glTF material to an EAGL.PBR-compatible material map.

  Returns a map suitable for `EAGL.PBR.set_material/2`:

      material_map = GLTF.EAGL.material_to_pbr_material(gltf_material)
      EAGL.PBR.set_material(program, material_map)
  """
  @spec material_to_pbr_material(GLTF.Material.t()) :: map()
  def material_to_pbr_material(%GLTF.Material{} = material) do
    base_material = %{}

    # PBR Metallic-Roughness workflow
    base_material =
      case material.pbr_metallic_roughness do
        nil ->
          base_material

        pbr ->
          base_color = pbr.base_color_factor || [1.0, 1.0, 1.0, 1.0]
          metallic = pbr.metallic_factor || 1.0
          roughness = pbr.roughness_factor || 1.0

          Map.merge(base_material, %{
            base_color_factor: base_color,
            metallic_factor: metallic,
            roughness_factor: roughness
          })
      end

    # Emissive properties
    base_material =
      case material.emissive_factor do
        nil -> base_material
        emissive -> Map.put(base_material, :emissive_factor, emissive)
      end

    base_material
  end

  @doc """
  Convert a glTF node to an EAGL.Node.

  Handles both matrix and TRS transform representations.
  """
  @spec node_to_eagl_node(GLTF.Node.t(), map()) :: Node.t()
  def node_to_eagl_node(%GLTF.Node{} = gltf_node, mesh_lookup \\ %{}) do
    # Convert transforms
    node =
      case gltf_node.matrix do
        nil ->
          # Use TRS properties
          Node.new(
            position: list_to_vec3(gltf_node.translation || [0.0, 0.0, 0.0]),
            rotation: list_to_quat(gltf_node.rotation || [0.0, 0.0, 0.0, 1.0]),
            scale: list_to_vec3(gltf_node.scale || [1.0, 1.0, 1.0]),
            name: gltf_node.name
          )

        matrix when is_list(matrix) ->
          # Use matrix transform
          Node.with_matrix(matrix, name: gltf_node.name)
      end

    # Attach mesh if present
    case gltf_node.mesh do
      nil ->
        node

      mesh_index ->
        mesh = Map.get(mesh_lookup, mesh_index)
        Node.set_mesh(node, mesh)
    end
  end

  @doc """
  Convert a complete glTF asset to an EAGL.Scene.

  This creates a full scene graph with all nodes, meshes, and transforms.
  """
  @spec to_scene(GLTF.t(), GLTF.DataStore.t(), keyword()) ::
          {:ok, Scene.t()} | {:error, String.t()}
  def to_scene(%GLTF{} = gltf, data_store, opts \\ []) do
    with {:ok, mesh_lookup} <- create_mesh_lookup(gltf, data_store, opts),
         {:ok, node_lookup} <- create_node_lookup(gltf, mesh_lookup),
         {:ok, scene} <- build_scene_graph(gltf, node_lookup, opts) do
      {:ok, scene}
    end
  end

  @doc """
  Convert all glTF animations to EAGL animation timelines.

  Returns a list of animation timelines that can be loaded into an EAGL.Animator.
  """
  @spec convert_animations(GLTF.t(), GLTF.DataStore.t()) :: [EAGL.Animation.Timeline.t()]
  def convert_animations(%GLTF{animations: nil}, _data_store), do: []
  def convert_animations(%GLTF{animations: []}, _data_store), do: []

  def convert_animations(%GLTF{animations: animations} = gltf, data_store) do
    animations
    |> Enum.with_index()
    |> Enum.map(fn {animation, index} ->
      animation_to_timeline(gltf, data_store, animation, index)
    end)
    |> Enum.filter(&(&1 != nil))
  end

  @doc """
  Convert a single glTF animation to an EAGL animation timeline.
  """
  @spec animation_to_timeline(GLTF.t(), GLTF.DataStore.t(), GLTF.Animation.t(), integer()) ::
          EAGL.Animation.Timeline.t() | nil
  def animation_to_timeline(gltf, data_store, %GLTF.Animation{} = animation, index \\ 0) do
    timeline_name = animation.name || "Animation_#{index}"

    case convert_animation_channels(gltf, data_store, animation) do
      [] ->
        nil

      channels ->
        timeline = EAGL.Animation.Timeline.new(timeline_name)

        Enum.reduce(channels, timeline, fn channel, acc ->
          EAGL.Animation.Timeline.add_channel(acc, channel)
        end)
    end
  end

  # Private helper functions

  defp get_mesh(%GLTF{meshes: meshes}, mesh_index) when is_list(meshes) do
    case Enum.at(meshes, mesh_index) do
      nil -> {:error, "Mesh #{mesh_index} not found"}
      mesh -> {:ok, mesh}
    end
  end

  defp get_mesh(_, _), do: {:error, "No meshes in glTF"}

  defp get_primitive(%GLTF.Mesh{primitives: primitives}, primitive_index)
       when is_list(primitives) do
    case Enum.at(primitives, primitive_index) do
      nil -> {:error, "Primitive #{primitive_index} not found"}
      primitive -> {:ok, primitive}
    end
  end

  defp extract_vertex_data(gltf, data_store, primitive) do
    # Extract position data (required)
    with {:ok, positions} <- get_attribute_data(gltf, data_store, primitive, "POSITION"),
         {:ok, vertex_data} <- build_vertex_data(gltf, data_store, primitive, positions) do
      {:ok, vertex_data}
    end
  end

  defp get_attribute_data(gltf, data_store, primitive, attribute_name) do
    case Map.get(primitive.attributes, attribute_name) do
      nil ->
        {:error, "Missing required attribute: #{attribute_name}"}

      accessor_index ->
        case GLTF.get_accessor_data(gltf, data_store, accessor_index) do
          {:ok, data} -> {:ok, {accessor_index, data}}
          error -> error
        end
    end
  end

  defp build_vertex_data(gltf, data_store, primitive, {_pos_idx, pos_data}) do
    # Start with position data
    vertex_data = %{
      position: pos_data,
      attributes: [Buffer.position_attribute()],
      indices: nil
    }

    # Add other attributes if present
    vertex_data =
      add_optional_attribute(
        vertex_data,
        gltf,
        data_store,
        primitive,
        "NORMAL",
        &Buffer.normal_attribute/0
      )

    vertex_data =
      add_optional_attribute(
        vertex_data,
        gltf,
        data_store,
        primitive,
        "TEXCOORD_0",
        &Buffer.texture_coordinate_attribute/0
      )

    vertex_data =
      add_optional_attribute(
        vertex_data,
        gltf,
        data_store,
        primitive,
        "COLOR_0",
        &Buffer.color_attribute/0
      )

    # Add indices if present
    vertex_data =
      case primitive.indices do
        nil ->
          vertex_data

        indices_accessor ->
          case GLTF.get_accessor_data(gltf, data_store, indices_accessor) do
            {:ok, indices_data} -> %{vertex_data | indices: indices_data}
            _ -> vertex_data
          end
      end

    {:ok, vertex_data}
  end

  defp add_optional_attribute(vertex_data, gltf, data_store, primitive, attr_name, attr_func) do
    case get_attribute_data(gltf, data_store, primitive, attr_name) do
      {:ok, {_idx, data}} ->
        vertex_data
        |> Map.put(:attributes, [attr_func.() | vertex_data.attributes])
        |> Map.put(attr_name, data)

      _ ->
        vertex_data
    end
  end

  defp create_vao_from_vertex_data(
         %{position: pos_data, attributes: attributes, indices: indices},
         _opts
       ) do
    # Convert binary data to float list (simplified - real implementation would parse based on accessor type)
    vertices = binary_to_float_list(pos_data)

    case indices do
      nil ->
        # Non-indexed geometry
        {vao, vbo} = Buffer.create_vertex_array(vertices, attributes)
        # Assuming 3 floats per vertex for position
        vertex_count = div(length(vertices), 3)
        {:ok, %{vao: vao, vbo: vbo, vertex_count: vertex_count}}

      indices_data ->
        # Indexed geometry
        index_list = binary_to_int_list(indices_data)
        {vao, vbo, ebo} = Buffer.create_indexed_array(vertices, index_list, attributes)
        {:ok, %{vao: vao, vbo: vbo, ebo: ebo, index_count: length(index_list)}}
    end
  end

  defp create_mesh_lookup(gltf, data_store, opts) do
    case gltf.meshes do
      nil ->
        {:ok, %{}}

      meshes ->
        mesh_data =
          meshes
          |> Enum.with_index()
          |> Enum.map(fn {_mesh, mesh_index} ->
            # Convert first primitive of each mesh (simplified)
            case primitive_to_vao(gltf, data_store, mesh_index, 0, opts) do
              {:ok, vao_data} -> {mesh_index, vao_data}
              _ -> {mesh_index, nil}
            end
          end)
          |> Enum.into(%{})

        {:ok, mesh_data}
    end
  end

  defp create_node_lookup(gltf, mesh_lookup) do
    case gltf.nodes do
      nil ->
        {:ok, %{}}

      nodes ->
        node_data =
          nodes
          |> Enum.with_index()
          |> Enum.map(fn {node, index} ->
            eagl_node = node_to_eagl_node(node, mesh_lookup)
            {index, eagl_node}
          end)
          |> Enum.into(%{})

        {:ok, node_data}
    end
  end

  defp build_scene_graph(gltf, node_lookup, opts) do
    scene = Scene.new(name: Keyword.get(opts, :name, "glTF Scene"))

    # Get default scene or first scene
    target_scene =
      case gltf.scene do
        nil -> Enum.at(gltf.scenes || [], 0)
        scene_index -> Enum.at(gltf.scenes || [], scene_index)
      end

    case target_scene do
      nil ->
        {:ok, scene}

      %GLTF.Scene{nodes: root_node_indices} when is_list(root_node_indices) ->
        # Add root nodes to scene
        scene_with_roots =
          Enum.reduce(root_node_indices, scene, fn node_index, acc_scene ->
            case Map.get(node_lookup, node_index) do
              nil -> acc_scene
              node -> Scene.add_root_node(acc_scene, node)
            end
          end)

        {:ok, scene_with_roots}

      _ ->
        {:ok, scene}
    end
  end

  # Helper functions for data conversion

  defp list_to_vec3([x, y, z]), do: vec3(x, y, z)
  defp list_to_vec3(_), do: vec3(0.0, 0.0, 0.0)

  defp list_to_vec4([x, y, z, w]), do: vec4(x, y, z, w)
  defp list_to_vec4([x, y, z]), do: vec4(x, y, z, 1.0)
  defp list_to_vec4(_), do: vec4(1.0, 1.0, 1.0, 1.0)

  defp list_to_quat([x, y, z, w]), do: quat(x, y, z, w)
  defp list_to_quat(_), do: quat_identity()

  defp atom_to_gl_constant(:opaque), do: 0
  defp atom_to_gl_constant(:mask), do: 1
  defp atom_to_gl_constant(:blend), do: 2
  defp atom_to_gl_constant(_), do: 0

  # Simplified binary parsing (real implementation would use accessor specifications)
  defp binary_to_float_list(binary) when is_binary(binary) do
    for <<f::float-32-native <- binary>>, do: f
  end

  defp binary_to_int_list(binary) when is_binary(binary) do
    for <<i::unsigned-32-native <- binary>>, do: i
  end

  # Animation conversion helper functions

  defp convert_animation_channels(gltf, data_store, %GLTF.Animation{
         channels: channels,
         samplers: samplers
       }) do
    channels
    |> Enum.map(fn channel ->
      convert_animation_channel(gltf, data_store, channel, samplers)
    end)
    |> Enum.filter(&(&1 != nil))
  end

  defp convert_animation_channel(gltf, data_store, channel, samplers) do
    with {:ok, sampler} <- get_animation_sampler(samplers, channel.sampler),
         {:ok, eagl_sampler} <- convert_animation_sampler(gltf, data_store, sampler),
         {:ok, target_node_id} <- get_target_node_id(gltf, channel.target),
         {:ok, target_property} <- convert_target_property(channel.target) do
      EAGL.Animation.Channel.new(target_node_id, target_property, eagl_sampler)
    else
      _error -> nil
    end
  end

  defp get_animation_sampler(samplers, sampler_index) do
    case Enum.at(samplers, sampler_index) do
      nil -> {:error, "Sampler #{sampler_index} not found"}
      sampler -> {:ok, sampler}
    end
  end

  defp convert_animation_sampler(gltf, data_store, %GLTF.Animation.Sampler{} = sampler) do
    with {:ok, input_data} <- GLTF.get_accessor_data(gltf, data_store, sampler.input),
         {:ok, output_data} <- GLTF.get_accessor_data(gltf, data_store, sampler.output) do
      # Convert binary data to float lists
      input_times = binary_to_float_list(input_data)
      output_values = convert_output_values(output_data, sampler.interpolation)
      interpolation = convert_interpolation_mode(sampler.interpolation)

      eagl_sampler = EAGL.Animation.Sampler.new(input_times, output_values, interpolation)
      {:ok, eagl_sampler}
    end
  end

  defp convert_output_values(binary_data, interpolation) do
    # Convert based on data type - this is simplified
    # Real implementation would use accessor componentType and type
    case interpolation do
      :linear ->
        # Assume vec3 or quaternion data
        floats = binary_to_float_list(binary_data)
        group_floats_by_components(floats, 3)

      :step ->
        floats = binary_to_float_list(binary_data)
        group_floats_by_components(floats, 3)

      :cubicspline ->
        # Cubic spline has 3x more data (in-tangent, value, out-tangent)
        floats = binary_to_float_list(binary_data)
        # For now, extract just the middle values
        extract_cubic_spline_values(floats, 3)
    end
  end

  defp group_floats_by_components(floats, component_count) do
    floats
    |> Enum.chunk_every(component_count)
    |> Enum.map(fn chunk ->
      case chunk do
        [x, y, z] -> vec3(x, y, z)
        [x, y, z, w] -> quat(x, y, z, w)
        [single] -> single
        _ -> List.to_tuple(chunk)
      end
    end)
  end

  defp extract_cubic_spline_values(floats, component_count) do
    # Cubic spline: [in_tangent, value, out_tangent] per keyframe
    stride = component_count * 3

    floats
    |> Enum.chunk_every(stride)
    |> Enum.map(fn chunk ->
      # Extract just the middle values (skip tangents for now)
      value_start = component_count
      value_end = component_count * 2 - 1

      value_floats = Enum.slice(chunk, value_start..value_end)

      case value_floats do
        [x, y, z] -> vec3(x, y, z)
        [x, y, z, w] -> quat(x, y, z, w)
        [single] -> single
        _ -> List.to_tuple(value_floats)
      end
    end)
  end

  defp convert_interpolation_mode(:linear), do: :linear
  defp convert_interpolation_mode(:step), do: :step
  defp convert_interpolation_mode(:cubicspline), do: :cubicspline
  defp convert_interpolation_mode(_), do: :linear

  defp get_target_node_id(gltf, %GLTF.Animation.Channel.Target{node: node_index}) do
    case Enum.at(gltf.nodes || [], node_index) do
      nil -> {:error, "Target node #{node_index} not found"}
      node -> {:ok, node.name || "node_#{node_index}"}
    end
  end

  defp convert_target_property(%GLTF.Animation.Channel.Target{path: "translation"}),
    do: {:ok, :translation}

  defp convert_target_property(%GLTF.Animation.Channel.Target{path: "rotation"}),
    do: {:ok, :rotation}

  defp convert_target_property(%GLTF.Animation.Channel.Target{path: "scale"}), do: {:ok, :scale}

  defp convert_target_property(%GLTF.Animation.Channel.Target{path: "weights"}),
    do: {:ok, :weights}

  defp convert_target_property(_), do: {:error, "Unsupported target property"}
end
