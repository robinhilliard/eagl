#!/usr/bin/env elixir

# GLB Web Demo - Phase 5
# ======================
#
# Phase 5: Scene Hierarchy and Node Transformations from GLB files
# Shows the complete pipeline: Web → HTTP Download → GLB Parse → Scene Graph → Transform Hierarchy → Render
#
# Run with: elixir examples/glb_web_demo.exs

# Add the current project to the code path
Code.append_path("_build/dev/lib/eagl/ebin")
Code.append_path("_build/dev/lib/poison/ebin")
Code.append_path("_build/dev/lib/jason/ebin")
Code.append_path("_build/dev/lib/stb_image/ebin")

defmodule GLBWebDemo do
  @moduledoc """
  Phase 5 GLB web loading demo using EAGL.

  Demonstrates:
  - Loading GLB files from Khronos Sample Assets
  - Parsing glTF JSON and binary data
  - Processing scene graphs with node hierarchies and transformations
  - Extracting vertex geometry, textures, and spatial relationships
  - Loading embedded texture images from GLB binary data
  - Creating OpenGL textures and binding to material properties
  - Rendering complete scenes with proper node transformations and hierarchy
  """

  use EAGL.Window
  use EAGL.Const
  import EAGL.{Shader, Buffer, Math, Error, Texture}
  alias EAGL.Camera

  @sample_models %{
    "box" => "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/Box/glTF-Binary/Box.glb",
    "duck" => "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/Duck/glTF-Binary/Duck.glb",
    "avocado" => "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/Avocado/glTF-Binary/Avocado.glb",
    "damaged_helmet" => "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/DamagedHelmet/glTF-Binary/DamagedHelmet.glb",
    "flight_helmet" => "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/FlightHelmet/glTF-Binary/FlightHelmet.glb",
    "barramundi" => "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/BarramundiFish/glTF-Binary/BarramundiFish.glb"
  }

  @default_model "duck"

  def run_example(model_name \\ @default_model, opts \\ []) do
    # Parse command line arguments
    model_name = case System.argv() do
      [model_arg | _] when model_arg in ["--help", "-h"] ->
        show_help()
        System.halt(0)
      [model_arg | _] ->
        if Map.has_key?(@sample_models, model_arg) do
          model_arg
        else
          IO.puts("❌ Unknown model '#{model_arg}'. Available models:")
          Enum.each(@sample_models, fn {name, _url} ->
            IO.puts("   - #{name}")
          end)
          IO.puts("Using default: #{@default_model}")
          @default_model
        end
      [] ->
        model_name
    end

    model_url = @sample_models[model_name]

    IO.puts("""
    ╔═══════════════════════════════════════════════════════════════════════════════╗
    ║                         GLB Web Loading Demo - Phase 5                       ║
    ╠═══════════════════════════════════════════════════════════════════════════════╣
    ║ Loading GLB: #{model_url}
    ║                                                                               ║
    ║ Pipeline: Web → HTTP → GLB Parse → Scene Graph → Transforms → PBR Render     ║
    ║ Phase 5: Scene Hierarchy & Node Transformations (TRS matrices & hierarchy)  ║
    ║ Controls: WASD to move, mouse to look around, scroll to zoom, ENTER to exit ║
    ║ Features: Scene graphs, node transforms, multi-mesh scenes, spatial layout   ║
    ╚═══════════════════════════════════════════════════════════════════════════════╝
    """)

    EAGL.Window.run(__MODULE__, "GLB Web Demo - Phase 5 - #{String.upcase(model_name)}",
      Keyword.merge([size: {1200, 800}, depth_testing: true, enter_to_exit: true], opts)
    )
  end

  defp show_help do
    IO.puts("""
    GLB Web Demo - Phase 5

    Usage: elixir examples/glb_web_demo.exs [model_name]

    Available models:
    """)

    Enum.each(@sample_models, fn {name, url} ->
      IO.puts("  #{name}")
      IO.puts("    #{url}")
      IO.puts("")
    end)

    IO.puts("""
    Examples:
      elixir examples/glb_web_demo.exs box
      elixir examples/glb_web_demo.exs duck
      elixir examples/glb_web_demo.exs avocado
      elixir examples/glb_web_demo.exs damaged_helmet

    Default model: #{@default_model}
    """)
  end

  @impl true
  def setup do
    IO.puts("📋 GLB Demo Setup - Phase 5:")

    with :ok <- check_json_library(),
         {:ok, shader_program} <- setup_shaders(),
         {:ok, camera} <- setup_camera(),
         {:ok, scene_data, source} <- attempt_glb_loading() do

      IO.puts("✅ Setup complete! Loaded scene from #{source}")
      IO.puts("  📊 Scene info:")
      IO.puts("     - Scenes: #{length(scene_data.scenes)}")
      IO.puts("     - Nodes: #{length(scene_data.nodes)}")
      IO.puts("     - Mesh instances: #{length(scene_data.mesh_instances)}")
      IO.puts("🎮 Controls: WASD + mouse + scroll + ENTER to exit")

      {:ok, %{
        shader_program: shader_program,
        camera: camera,
        scene_data: scene_data,
        source: source,
        last_mouse: {600, 400},
        first_mouse: true
      }}
    else
      {:error, reason} ->
        IO.puts("❌ Setup failed: #{reason}")
        {:error, reason}
    end
  end

  @impl true
  def render(width, height, %{shader_program: program, camera: camera, scene_data: scene_data} = state) do
    # Clear and setup 3D rendering
    :gl.viewport(0, 0, trunc(width), trunc(height))
    :gl.clearColor(0.1, 0.1, 0.2, 1.0)
    :gl.clear(@gl_color_buffer_bit + @gl_depth_buffer_bit)

    # Enable 3D rendering with glTF conventions
    :gl.enable(@gl_depth_test)
    :gl.enable(@gl_cull_face)
    :gl.cullFace(@gl_back)  # glTF: counter-clockwise = front-facing

    :gl.useProgram(program)

    # Setup matrices
    view_matrix = Camera.get_view_matrix(camera)
    projection_matrix = mat4_perspective(radians(camera.zoom), width / height, 0.1, 100.0)

    # Set common shader uniforms (non-model-specific)
    set_uniforms(program, [
      {"view", view_matrix},
      {"projection", projection_matrix},
      {"lightPos", vec3(5.0, 5.0, 5.0)},
      {"lightColor", vec3(1.0, 1.0, 1.0)},
      {"viewPos", camera.position}
    ])

    # Render all mesh instances with their individual transformations (Phase 5)
    Enum.each(scene_data.mesh_instances, fn mesh_instance ->
      render_mesh_instance(mesh_instance, program)
    end)

    check("After render")
    {:ok, state}
  end

  @impl true
  def handle_event(:tick, %{camera: camera} = state) do
    updated_camera = Camera.process_keyboard_input(camera, 0.016)
    {:ok, %{state | camera: updated_camera}}
  end

  def handle_event({:mouse_motion, x, y}, %{camera: camera, last_mouse: {last_x, last_y}, first_mouse: first_mouse} = state) do
    if first_mouse do
      {:ok, %{state | last_mouse: {x, y}, first_mouse: false}}
    else
      dx = x - last_x
      dy = last_y - y
      updated_camera = Camera.process_mouse_movement(camera, dx, dy, true)
      {:ok, %{state | camera: updated_camera, last_mouse: {x, y}}}
    end
  end

  def handle_event({:mouse_wheel, _x, _y, wheel_rotation, _wheel_delta}, %{camera: camera} = state) do
    # wheel_rotation is typically -120 (scroll up) or +120 (scroll down)
    # Convert to a smaller zoom delta - scroll up should zoom in (reduce FOV)
    zoom_delta = wheel_rotation / 120.0 * 2.0
    updated_camera = Camera.process_mouse_scroll(camera, zoom_delta)
    {:ok, %{state | camera: updated_camera}}
  end

  def handle_event(_event, state), do: {:ok, state}

    @impl true
  def cleanup(%{scene_data: scene_data}) do
    IO.puts("🧹 Cleaning up GLB resources...")

    # Clean up mesh instances (which contain the mesh data)
    Enum.each(scene_data.mesh_instances, fn %{mesh: mesh} ->
      %{vao: vao, vbo: vbo, ebo: ebo, material: material} = mesh

      # Clean up buffers
      if ebo do
        delete_indexed_array(vao, vbo, ebo)
      else
        delete_vertex_array(vao, vbo)
      end

      # Clean up textures (Phase 4)
      textures = material.textures || %{}
      texture_ids = Map.values(textures) |> Enum.filter(&is_integer/1)
      if length(texture_ids) > 0 do
        :gl.deleteTextures(texture_ids)
        IO.puts("  🖼️  Cleaned up #{length(texture_ids)} texture(s)")
      end
    end)
    :ok
  end

  # Private implementation

  defp safe_round(nil), do: "nil"
  defp safe_round(val) when is_number(val), do: Float.round(val, 3)
  defp safe_round(val), do: inspect(val)

  defp check_json_library do
    IO.puts("  🔍 Checking JSON libraries...")

    # Try to load libraries more explicitly
    poison_available = try do
      Code.ensure_loaded?(Poison) and function_exported?(Poison, :decode, 1)
    rescue
      _ -> false
    end

    jason_available = try do
      Code.ensure_loaded?(Jason) and function_exported?(Jason, :decode, 1)
    rescue
      _ -> false
    end

    cond do
      poison_available ->
        IO.puts("  ✓ JSON library: Poison available")
        :ok
      jason_available ->
        IO.puts("  ✓ JSON library: Jason available")
        :ok
      true ->
        IO.puts("  ⚠️  No JSON library found - will use demo cube only")
        :ok  # Don't fail, just use demo cube
    end
  end

  defp attempt_glb_loading do
    IO.puts("  🌐 Attempting GLB download and scene extraction...")

    case load_glb_scene() do
      {:ok, scene_data} when scene_data.mesh_instances != [] ->
        IO.puts("  ✅ GLB scene loaded successfully!")
        {:ok, scene_data, :glb}

      {:error, reason} ->
        IO.puts("  ❌ GLB scene loading failed: #{reason}")
        IO.puts("      Phase 5 requires successful scene loading - no fallback")
        {:error, reason}
    end
  end

  defp load_glb_scene do
    # Get the model name from command line or use default
    model_name = case System.argv() do
      [model_arg | _] ->
        if Map.has_key?(@sample_models, model_arg) do
          model_arg
        else
          @default_model
        end
      _ ->
        @default_model
    end
    model_url = @sample_models[model_name]

    # Check if we have JSON libraries
    has_json = (Code.ensure_loaded?(Poison) and function_exported?(Poison, :decode, 1)) or
               (Code.ensure_loaded?(Jason) and function_exported?(Jason, :decode, 1))

    unless has_json do
      {:error, "No JSON library available"}
    else
      download_and_parse_glb(model_url)
    end
  end

  defp download_and_parse_glb(model_url) do
    IO.puts("    📥 Downloading from #{model_url}...")

    # Ensure SSL and crypto applications are started
    :ok = Application.ensure_started(:crypto)
    :ok = Application.ensure_started(:asn1)
    :ok = Application.ensure_started(:public_key)
    :ok = Application.ensure_started(:ssl)
    :ok = Application.ensure_started(:inets)

    case GLTF.GLBLoader.parse_url(model_url, http_client: :httpc, timeout: 30_000) do
      {:ok, glb_binary} ->
        IO.puts("    ✓ GLB downloaded and parsed successfully")
        parse_gltf_content(glb_binary)

      {:error, reason} ->
        {:error, "Download failed: #{inspect(reason)}"}
    end
  end

  defp parse_gltf_content(glb_binary) do
    IO.puts("    🔍 Loading glTF document...")

    # Determine which JSON library to use
    json_library = cond do
      Code.ensure_loaded?(Poison) and function_exported?(Poison, :decode, 1) ->
        :poison
      Code.ensure_loaded?(Jason) and function_exported?(Jason, :decode, 1) ->
        :jason
      true ->
        :poison  # fallback, will likely fail but gives better error message
    end

    case GLTF.GLBLoader.load_gltf_from_glb(glb_binary, json_library) do
      {:ok, gltf} ->
        IO.puts("    ✓ glTF document loaded")
        IO.puts("      - Version: #{gltf.asset.version}")
        IO.puts("      - Generator: #{gltf.asset.generator || "Unknown"}")

        if gltf.meshes do
          IO.puts("      - Meshes: #{length(gltf.meshes)}")
        end

        if gltf.materials do
          IO.puts("      - Materials: #{length(gltf.materials)}")
        end

        # Setup data store with binary data
        binary_data = GLTF.Binary.get_binary(glb_binary)
        data_store = GLTF.DataStore.new()
        data_store = case binary_data do
          nil ->
            IO.puts("      - No binary data found")
            data_store
          data ->
            IO.puts("      - Binary data: #{byte_size(data)} bytes")
            GLTF.DataStore.store_glb_buffer(data_store, 0, data)
        end

        extract_scene_graph(gltf, data_store)

      {:error, reason} ->
        {:error, "glTF loading failed: #{inspect(reason)}"}
    end
  end

  defp extract_scene_graph(gltf, data_store) do
    IO.puts("    🌳 Extracting scene graph...")

    # First extract all meshes as before
    case extract_all_meshes(gltf, data_store) do
      {:ok, meshes_map} ->
        # Then extract scene hierarchy and create mesh instances
        case extract_scene_hierarchy(gltf, meshes_map) do
          {:ok, scene_data} ->
            IO.puts("      ✅ Scene graph extracted successfully")
            {:ok, scene_data}
          {:error, reason} ->
            {:error, "Failed to extract scene hierarchy: #{reason}"}
        end
      {:error, reason} ->
        {:error, "Failed to extract meshes: #{reason}"}
    end
  end

  defp extract_all_meshes(gltf, data_store) do
    IO.puts("      📦 Extracting mesh data...")

    case gltf.meshes do
      nil ->
        {:error, "No meshes found in GLB"}

      meshes ->
        IO.puts("        Processing #{length(meshes)} mesh(es)...")

        # Extract all meshes and create a map: mesh_index -> mesh_data
        results = Enum.with_index(meshes)
        |> Enum.map(fn {mesh, index} ->
          case extract_mesh_geometry(mesh, gltf, data_store, index) do
            {:ok, gpu_mesh} ->
              IO.puts("          ✓ Mesh #{index}: Extracted successfully")
              {index, gpu_mesh}
            {:error, reason} ->
              IO.puts("          ❌ Mesh #{index}: #{inspect(reason)}")
              {:error, {index, reason}}
          end
        end)

        # Collect successful mesh extractions into a map
        extracted_meshes = results
        |> Enum.reduce(%{}, fn
          {index, gpu_mesh}, acc when is_integer(index) -> Map.put(acc, index, gpu_mesh)
          {:error, _}, acc -> acc
        end)

        if map_size(extracted_meshes) > 0 do
          IO.puts("        ✅ #{map_size(extracted_meshes)} mesh(es) extracted successfully")
          {:ok, extracted_meshes}
        else
          {:error, "No valid meshes could be extracted"}
        end
    end
  end

  defp extract_scene_hierarchy(gltf, meshes_map) do
    IO.puts("      🌳 Processing scene hierarchy...")

    # Get the default scene or first scene
    scene_index = gltf.scene || 0
    scene = case Enum.at(gltf.scenes || [], scene_index) do
      nil ->
        IO.puts("        ⚠️  No scenes found, creating default scene")
        %{nodes: Enum.to_list(0..(length(gltf.nodes || []) - 1))}
      scene ->
        IO.puts("        📋 Using scene #{scene_index}: #{scene.name || "Unnamed"}")
        scene
    end

    # Process all nodes and build the transformation hierarchy
    case process_scene_nodes(scene, gltf, meshes_map) do
      {:ok, mesh_instances, nodes} ->
        scene_data = %{
          scenes: [scene],
          nodes: nodes,
          mesh_instances: mesh_instances
        }
        {:ok, scene_data}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp process_scene_nodes(scene, gltf, meshes_map) do
    IO.puts("        🔗 Processing #{length(scene.nodes || [])} root node(s)...")

    nodes = gltf.nodes || []

    # Build a transformation hierarchy by traversing the scene graph
    case traverse_nodes(scene.nodes || [], nodes, meshes_map, mat4_identity(), []) do
      {:ok, all_mesh_instances} ->
        processed_nodes = Enum.map(nodes, &process_node_info/1)
        {:ok, all_mesh_instances, processed_nodes}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp traverse_nodes([], _nodes, _meshes_map, _parent_transform, acc) do
    {:ok, acc}
  end

  defp traverse_nodes([node_index | rest], nodes, meshes_map, parent_transform, acc) do
    case Enum.at(nodes, node_index) do
      nil ->
        IO.puts("          ⚠️  Node #{node_index} not found")
        traverse_nodes(rest, nodes, meshes_map, parent_transform, acc)

      node ->
        # Calculate this node's world transformation
        node_transform = extract_node_transform(node)

        # Debug: Check matrix values
        if node_transform == nil do
          IO.puts("          ❌ Node #{node_index}: extract_node_transform returned nil")
        end
        if parent_transform == nil do
          IO.puts("          ❌ Node #{node_index}: parent_transform is nil")
        end

        world_transform = mat4_mul(parent_transform, node_transform)

        # Create mesh instance if this node has a mesh
        new_mesh_instances = case node.mesh do
          nil -> []
          mesh_index ->
            case Map.get(meshes_map, mesh_index) do
              nil ->
                IO.puts("          ⚠️  Node #{node_index} references missing mesh #{mesh_index}")
                []
              mesh_data ->
                IO.puts("          ✓ Node #{node_index}: mesh #{mesh_index} with transform")
                mesh_instance = %{
                  node_index: node_index,
                  mesh_index: mesh_index,
                  mesh: mesh_data,
                  world_transform: world_transform,
                  node_name: node.name || "Node#{node_index}"
                }
                [mesh_instance]
            end
        end

        # Recursively process child nodes
        case traverse_nodes(node.children || [], nodes, meshes_map, world_transform, []) do
          {:ok, child_mesh_instances} ->
            all_instances = new_mesh_instances ++ child_mesh_instances ++ acc
            traverse_nodes(rest, nodes, meshes_map, parent_transform, all_instances)
          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  defp extract_node_transform(node) do
    cond do
      # Matrix transformation (takes precedence)
      node.matrix != nil ->
        # Convert from glTF column-major array to EAGL matrix format
        case node.matrix do
          [m00, m01, m02, m03, m10, m11, m12, m13, m20, m21, m22, m23, m30, m31, m32, m33] ->
            # glTF matrix is already in column-major order, convert to EAGL format
            [
              {
                m00, m01, m02, m03,
                m10, m11, m12, m13,
                m20, m21, m22, m23,
                m30, m31, m32, m33
              }
            ]
          _ ->
            IO.puts("            ⚠️  Invalid matrix format, using identity")
            mat4_identity()
        end

      # TRS transformation (Translation, Rotation, Scale)
      true ->
        # Extract TRS components
        translation = case node.translation do
          [x, y, z] -> vec3(x, y, z)
          _ -> vec3(0.0, 0.0, 0.0)
        end

        rotation = case node.rotation do
          [x, y, z, w] -> [x, y, z, w]  # quaternion [x, y, z, w]
          _ -> [0.0, 0.0, 0.0, 1.0]      # identity quaternion
        end

        scale = case node.scale do
          [x, y, z] -> vec3(x, y, z)
          _ -> vec3(1.0, 1.0, 1.0)
        end

        # Build transformation matrix: T * R * S
        scale_matrix = mat4_scale(scale)
        rotation_matrix = quaternion_to_mat4(rotation)
        translation_matrix = mat4_translate(translation)

        mat4_mul(mat4_mul(translation_matrix, rotation_matrix), scale_matrix)
    end
  end

  defp quaternion_to_mat4([x, y, z, w]) do
    # Convert quaternion to rotation matrix (EAGL format)
    # See: https://en.wikipedia.org/wiki/Quaternions_and_spatial_rotation
    x2 = x * 2.0
    y2 = y * 2.0
    z2 = z * 2.0
    xx = x * x2
    xy = x * y2
    xz = x * z2
    yy = y * y2
    yz = y * z2
    zz = z * z2
    wx = w * x2
    wy = w * y2
    wz = w * z2

    # Return in EAGL mat4 format: list with single 16-element tuple (column-major)
    [
      {
        1.0 - (yy + zz), xy + wz,         xz - wy,         0.0,
        xy - wz,         1.0 - (xx + zz), yz + wx,         0.0,
        xz + wy,         yz - wx,         1.0 - (xx + yy), 0.0,
        0.0,             0.0,             0.0,             1.0
      }
    ]
  end

  defp process_node_info(node) do
    %{
      name: node.name || "Unnamed",
      mesh_index: node.mesh,
      children_count: length(node.children || []),
      has_transform: node.matrix != nil or node.translation != nil or node.rotation != nil or node.scale != nil
    }
  end

  defp extract_mesh_geometry(mesh, gltf, data_store, mesh_index) do
    case mesh.primitives do
      [] ->
        {:error, :no_primitives}
      [primitive | _] ->
        # For now, extract just the first primitive of each mesh
        extract_primitive_geometry(primitive, gltf, data_store, mesh_index)
    end
  end

  defp extract_primitive_geometry(primitive, gltf, data_store, _mesh_index) do
    # Extract position data (required)
    position_accessor = primitive.attributes["POSITION"]

    if position_accessor do
              case extract_vertex_data(primitive, gltf, data_store) do
        {:ok, vertex_data, index_data, vertex_count} ->
          case create_gpu_buffers(vertex_data, index_data) do
            {:ok, vao, vbo, ebo} ->
              # Extract material information and textures for Phase 4
              case extract_material_info(primitive, gltf, data_store) do
                {:ok, material_info} ->
                  mesh = %{
                    vao: vao,
                    vbo: vbo,
                    ebo: ebo,
                    index_count: vertex_count,
                    has_indices: index_data != nil,
                    material: material_info
                  }
                  {:ok, mesh}
                {:error, reason} ->
                  # Clean up buffers if material extraction fails
                  if ebo do
                    delete_indexed_array(vao, vbo, ebo)
                  else
                    delete_vertex_array(vao, vbo)
                  end
                  {:error, "Failed to extract material: #{reason}"}
              end
            {:error, reason} ->
              {:error, "Failed to create GPU buffers: #{reason}"}
          end
        {:error, reason} ->
          {:error, "Failed to extract vertex data: #{reason}"}
      end
    else
      {:error, "No POSITION attribute found"}
    end
  end

    defp extract_material_info(primitive, gltf, data_store) do
    case primitive.material do
      nil ->
        IO.puts("          - No material specified, using default PBR material")
        {:ok, %{
          base_color_factor: [1.0, 1.0, 1.0, 1.0],  # White
          metallic_factor: 1.0,                       # Default metallic
          roughness_factor: 1.0,                      # Default roughness
          emissive_factor: [0.0, 0.0, 0.0],          # No emission
          material_type: :default,
          textures: %{}
        }}

      material_index ->
        case Enum.at(gltf.materials || [], material_index) do
          nil ->
            IO.puts("          - Material #{material_index} not found, using default")
            {:ok, %{
              base_color_factor: [1.0, 1.0, 1.0, 1.0],
              metallic_factor: 1.0,
              roughness_factor: 1.0,
              emissive_factor: [0.0, 0.0, 0.0],
              material_type: :default,
              textures: %{}
            }}

          material ->
            IO.puts("          - Material #{material_index}: #{material.name || "Unnamed"}")
            extract_pbr_material_properties(material, gltf, data_store)
        end
    end
  end

  defp extract_pbr_material_properties(material, gltf, data_store) do
    # Extract PBR metallic-roughness properties
    pbr = material.pbr_metallic_roughness || %{}

    base_color = pbr.base_color_factor || [1.0, 1.0, 1.0, 1.0]
    metallic = pbr.metallic_factor || 1.0
    roughness = pbr.roughness_factor || 1.0
    emissive = material.emissive_factor || [0.0, 0.0, 0.0]

    IO.puts("            Base color: [#{Float.round(Enum.at(base_color, 0), 3)}, #{Float.round(Enum.at(base_color, 1), 3)}, #{Float.round(Enum.at(base_color, 2), 3)}, #{Float.round(Enum.at(base_color, 3), 3)}]")
    IO.puts("            Metallic: #{Float.round(metallic, 3)}")
    IO.puts("            Roughness: #{Float.round(roughness, 3)}")

    # Extract textures for Phase 4
    case extract_material_textures(material, gltf, data_store) do
      {:ok, textures} ->
        {:ok, %{
          base_color_factor: base_color,
          metallic_factor: metallic,
          roughness_factor: roughness,
          emissive_factor: emissive,
          material_type: :pbr_metallic_roughness,
          textures: textures
        }}
      {:error, reason} ->
        {:error, "Failed to extract textures: #{reason}"}
    end
  end

  defp extract_material_textures(material, gltf, data_store) do
    IO.puts("            🖼️  Extracting textures...")
    textures = %{}

    # Extract base color texture (albedo/diffuse)
    textures = try do
      case get_texture_from_material(material, :base_color_texture, gltf, data_store) do
        {:ok, texture_id} ->
          IO.puts("              ✓ Base color texture loaded (ID: #{texture_id})")
          Map.put(textures, :base_color, texture_id)
        {:error, :not_found} ->
          IO.puts("              - No base color texture found, using factor only")
          textures
        {:error, reason} ->
          IO.puts("              ⚠️  Base color texture failed: #{reason}")
          textures
      end
    rescue
      error ->
        IO.puts("              ❌ Base color texture extraction crashed: #{inspect(error)}")
        textures
    end

    # Extract metallic-roughness texture (packed: G=roughness, B=metallic)
    textures = try do
      case get_texture_from_material(material, :metallic_roughness_texture, gltf, data_store) do
        {:ok, texture_id} ->
          IO.puts("              ✓ Metallic-roughness texture loaded (ID: #{texture_id})")
          Map.put(textures, :metallic_roughness, texture_id)
        {:error, :not_found} ->
          IO.puts("              - No metallic-roughness texture found, using factors only")
          textures
        {:error, reason} ->
          IO.puts("              ⚠️  Metallic-roughness texture failed: #{reason}")
          textures
      end
    rescue
      error ->
        IO.puts("              ❌ Metallic-roughness texture extraction crashed: #{inspect(error)}")
        textures
    end

    # Extract normal texture
    textures = try do
      case get_texture_from_material(material, :normal_texture, gltf, data_store) do
        {:ok, texture_id} ->
          IO.puts("              ✓ Normal texture loaded (ID: #{texture_id})")
          Map.put(textures, :normal, texture_id)
        {:error, :not_found} ->
          IO.puts("              - No normal texture found")
          textures
        {:error, reason} ->
          IO.puts("              ⚠️  Normal texture failed: #{reason}")
          textures
      end
    rescue
      error ->
        IO.puts("              ❌ Normal texture extraction crashed: #{inspect(error)}")
        textures
    end

    # Extract emissive texture
    textures = try do
      case get_texture_from_material(material, :emissive_texture, gltf, data_store) do
        {:ok, texture_id} ->
          IO.puts("              ✓ Emissive texture loaded (ID: #{texture_id})")
          Map.put(textures, :emissive, texture_id)
        {:error, :not_found} ->
          IO.puts("              - No emissive texture found")
          textures
        {:error, reason} ->
          IO.puts("              ⚠️  Emissive texture failed: #{reason}")
          textures
      end
    rescue
      error ->
        IO.puts("              ❌ Emissive texture extraction crashed: #{inspect(error)}")
        textures
    end

    {:ok, textures}
  end

  defp get_texture_from_material(material, texture_type, gltf, data_store) do
    # Get texture info from material based on type
    texture_info = case texture_type do
      :base_color_texture ->
        case material.pbr_metallic_roughness do
          nil -> nil
          pbr -> pbr.base_color_texture
        end
      :metallic_roughness_texture ->
        case material.pbr_metallic_roughness do
          nil -> nil
          pbr -> pbr.metallic_roughness_texture
        end
      :normal_texture ->
        material.normal_texture
      :emissive_texture ->
        material.emissive_texture
      _ ->
        nil
    end

    case texture_info do
      nil ->
        {:error, :not_found}

      %{index: texture_index} ->
        load_texture_from_gltf(texture_index, gltf, data_store)

      _ ->
        {:error, :invalid_texture_info}
    end
  end

  defp load_texture_from_gltf(texture_index, gltf, data_store) do
    # Get texture definition
    case Enum.at(gltf.textures || [], texture_index) do
      nil ->
        {:error, "Texture #{texture_index} not found in glTF"}

      texture ->
        # Get image from texture
        case texture.source do
          nil ->
            {:error, "Texture #{texture_index} has no image source"}

          image_index ->
            load_image_to_texture(image_index, gltf, data_store)
        end
    end
  end

  defp load_image_to_texture(image_index, gltf, data_store) do
    # Get image definition
    case Enum.at(gltf.images || [], image_index) do
      nil ->
        {:error, "Image #{image_index} not found in glTF"}

      image ->
        # Load image data and create OpenGL texture directly
        case load_image_data(image, gltf, data_store) do
          {:ok, image_binary, mime_type} ->
            load_texture_from_glb_binary(image_binary, mime_type)
          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  defp load_image_data(image, gltf, data_store) do
    cond do
      # Embedded image in buffer view
      image.buffer_view != nil ->
        load_embedded_image(image, gltf, data_store)

      # External image URI
      image.uri != nil ->
        if String.starts_with?(image.uri, "data:") do
          load_data_uri_image(image.uri)
        else
          {:error, "External image URIs not supported yet: #{image.uri}"}
        end

      true ->
        {:error, "Image has no data source"}
    end
  end

  defp load_embedded_image(image, gltf, data_store) do
    # Get buffer view containing the image
    case Enum.at(gltf.buffer_views || [], image.buffer_view) do
      nil ->
        {:error, "Buffer view #{image.buffer_view} not found"}

      buffer_view ->
        # Get image data from buffer using the GLTF wrapper function
        case GLTF.get_buffer_data(gltf, data_store, buffer_view.buffer) do
          {:ok, buffer_data} ->
            offset = buffer_view.byte_offset || 0
            length = buffer_view.byte_length

            if byte_size(buffer_data) >= offset + length do
              image_binary = binary_part(buffer_data, offset, length)
              {:ok, image_binary, image.mime_type}
            else
              {:error, "Buffer too small for image data"}
            end

          {:error, reason} ->
            {:error, "Failed to get buffer data: #{reason}"}
        end
    end
  end

  defp load_data_uri_image(data_uri) do
    # Parse data URI format: data:image/png;base64,<data>
    case String.split(data_uri, ",", parts: 2) do
      [header, base64_data] ->
        case Base.decode64(base64_data) do
          {:ok, image_binary} ->
            mime_type = extract_mime_type_from_data_uri(header)
            {:ok, image_binary, mime_type}
          :error ->
            {:error, "Invalid base64 data in data URI"}
        end
      _ ->
        {:error, "Invalid data URI format"}
    end
  end

  defp extract_mime_type_from_data_uri(header) do
    case Regex.run(~r/data:([^;]+)/, header) do
      [_, mime_type] -> mime_type
      _ -> "image/png"  # default
    end
  end

  defp load_texture_from_glb_binary(image_binary, mime_type) do
    # Use the new EAGL.Texture.load_texture_from_binary function for real image decoding
    IO.puts("                📷 Loading real texture from #{mime_type || "unknown"} image (#{byte_size(image_binary)} bytes)")

    case load_texture_from_binary(image_binary, mime_type: mime_type) do
      {:ok, texture_id, width, height} ->
        IO.puts("                ✓ Successfully loaded #{width}x#{height} texture (ID: #{texture_id})")
        {:ok, texture_id}
      {:error, reason} ->
        IO.puts("                ⚠️  Failed to load texture: #{reason}")
        {:error, reason}
    end
  end

  defp extract_vertex_data(primitive, gltf, data_store) do
    # Extract positions (required)
    case extract_accessor_data(gltf, data_store, primitive.attributes["POSITION"]) do
      {:ok, positions} ->
        IO.puts("          - Extracted positions: #{length(positions) / 3} vertices")

                # Calculate bounding box
        {min_x, max_x} = positions |> Enum.take_every(3) |> Enum.min_max()
        {min_y, max_y} = positions |> Enum.drop(1) |> Enum.take_every(3) |> Enum.min_max()
        {min_z, max_z} = positions |> Enum.drop(2) |> Enum.take_every(3) |> Enum.min_max()
        IO.puts("          - Bounding box: X[#{Float.round(min_x, 3)}, #{Float.round(max_x, 3)}] Y[#{Float.round(min_y, 3)}, #{Float.round(max_y, 3)}] Z[#{Float.round(min_z, 3)}, #{Float.round(max_z, 3)}]")

        # Try to extract normals
        normals = case primitive.attributes["NORMAL"] do
          nil ->
            IO.puts("          - No normals found, generating defaults")
            generate_default_normals(length(positions) / 3)
          normal_accessor ->
                        case extract_accessor_data(gltf, data_store, normal_accessor) do
                            {:ok, normal_data} ->
                IO.puts("          - Extracted normals")
                normal_data
              _ ->
                IO.puts("          - Failed to extract normals, using defaults")
                generate_default_normals(length(positions) / 3)
            end
        end

        # Try to extract texture coordinates
        texcoords = case primitive.attributes["TEXCOORD_0"] do
          nil ->
            IO.puts("          - No texture coordinates found, generating defaults")
            generate_default_texcoords(length(positions) / 3)
          texcoord_accessor ->
            case extract_accessor_data(gltf, data_store, texcoord_accessor) do
              {:ok, texcoord_data} ->
                IO.puts("          - Extracted texture coordinates")
                texcoord_data
              _ ->
                IO.puts("          - Failed to extract texture coordinates, using defaults")
                generate_default_texcoords(length(positions) / 3)
            end
        end

        # Interleave vertex data: position(3) + normal(3) + texcoord(2) = 8 floats per vertex
        vertex_data = interleave_vertex_data(positions, normals, texcoords)

        # Extract indices if present
        index_data = case primitive.indices do
          nil ->
            IO.puts("          - No indices found, using vertex array")
            nil
          indices_accessor ->
            case extract_accessor_data(gltf, data_store, indices_accessor) do
                            {:ok, indices} ->
                IO.puts("          - Extracted indices: #{length(indices)} indices")
                # Convert to binary format for OpenGL
                for idx <- indices, into: <<>>, do: <<idx::little-unsigned-32>>
              _ ->
                IO.puts("          - Failed to extract indices, using vertex array")
                nil
            end
        end

        vertex_count = if index_data do
          byte_size(index_data) / 4  # 4 bytes per uint32 index
        else
          length(positions) / 3  # 3 floats per vertex
        end

        {:ok, vertex_data, index_data, trunc(vertex_count)}
      {:error, reason} ->
        {:error, "Failed to extract positions: #{reason}"}
    end
  end

  defp extract_accessor_data(gltf, data_store, accessor_index) do
    case GLTF.get_accessor_data(gltf, data_store, accessor_index) do
      {:ok, binary_data} ->
        # Get accessor to determine data format
        accessor = Enum.at(gltf.accessors, accessor_index)
        parse_accessor_data(binary_data, accessor)
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_accessor_data(binary_data, %{component_type: component_type, type: type, count: count}) do
    case {component_type, type} do
      # Float VEC3 (positions, normals)
      {@gl_float, :vec3} ->
        parse_float_vec3(binary_data, count)

      # Float VEC2 (texture coordinates)
      {@gl_float, :vec2} ->
        parse_float_vec2(binary_data, count)

      # Unsigned short indices (most common)
      {@gl_unsigned_short, :scalar} ->
        parse_unsigned_short_scalar(binary_data, count)

      # Unsigned int indices
      {@gl_unsigned_int, :scalar} ->
        parse_unsigned_int_scalar(binary_data, count)

      _ ->
        {:error, "Unsupported accessor format: component_type=#{component_type}, type=#{type}"}
    end
  end

  defp parse_float_vec3(binary_data, count) do
    floats = for <<f::little-float-32 <- binary_data>>, do: f

    if length(floats) == count * 3 do
      {:ok, floats}
    else
      {:error, "VEC3 data length mismatch: expected #{count * 3}, got #{length(floats)}"}
    end
  end

  defp parse_float_vec2(binary_data, count) do
    floats = for <<f::little-float-32 <- binary_data>>, do: f

    if length(floats) == count * 2 do
      {:ok, floats}
    else
      {:error, "VEC2 data length mismatch: expected #{count * 2}, got #{length(floats)}"}
    end
  end

  defp parse_unsigned_short_scalar(binary_data, count) do
    indices = for <<idx::little-unsigned-16 <- binary_data>>, do: idx

    if length(indices) == count do
      {:ok, indices}
    else
      {:error, "Scalar indices length mismatch: expected #{count}, got #{length(indices)}"}
    end
  end

  defp parse_unsigned_int_scalar(binary_data, count) do
    indices = for <<idx::little-unsigned-32 <- binary_data>>, do: idx

    if length(indices) == count do
      {:ok, indices}
    else
      {:error, "Scalar indices length mismatch: expected #{count}, got #{length(indices)}"}
    end
  end

  defp generate_default_normals(vertex_count) do
    # Generate upward-facing normals for all vertices
    for _ <- 1..trunc(vertex_count), do: [0.0, 1.0, 0.0]
    |> List.flatten()
  end

  defp generate_default_texcoords(vertex_count) do
    # Generate simple texture coordinates (0,0) for all vertices - need 2 values per vertex
    # Note: (0,0) in glTF coordinates becomes (0,1) in OpenGL after V-flipping
    texcoords = for _ <- 1..trunc(vertex_count) do
      [0.0, 0.0]  # Two float values per vertex (U, V in glTF coordinates)
    end
    |> List.flatten()
    IO.puts("          - Generated #{length(texcoords)} texcoord values for #{vertex_count} vertices (should be #{trunc(vertex_count) * 2})")
    texcoords
  end

    defp interleave_vertex_data(positions, normals, texcoords) do
    # Group into vertices: [x,y,z,nx,ny,nz,u,v, ...]
    vertex_count = length(positions) / 3

            # Debug: Check data lengths and verify interleaving will work correctly
        IO.puts("          - Positions length: #{length(positions)}")
        IO.puts("          - Normals length: #{length(normals)}")
        IO.puts("          - Texcoords length: #{length(texcoords)}")
        IO.puts("          - Vertex count: #{vertex_count}")

        # Verify data alignment for interleaving
        expected_pos = trunc(vertex_count) * 3
        expected_norm = trunc(vertex_count) * 3
        expected_tex = trunc(vertex_count) * 2

        if length(positions) != expected_pos do
          IO.puts("          - ⚠️  Position count mismatch: got #{length(positions)}, expected #{expected_pos}")
        end
        if length(normals) != expected_norm do
          IO.puts("          - ⚠️  Normal count mismatch: got #{length(normals)}, expected #{expected_norm}")
        end
        if length(texcoords) != expected_tex do
          IO.puts("          - ⚠️  Texcoord count mismatch: got #{length(texcoords)}, expected #{expected_tex}")
        end

    vertices = for i <- 0..(trunc(vertex_count) - 1) do
      pos_idx = i * 3
      tex_idx = i * 2

      # Flip V coordinate to convert from glTF (V=0 at top) to OpenGL (V=0 at bottom) convention
      v_coord = Enum.at(texcoords, tex_idx + 1) || 0.0
      flipped_v = 1.0 - v_coord

      [
        Enum.at(positions, pos_idx) || 0.0,     # x
        Enum.at(positions, pos_idx + 1) || 0.0, # y
        Enum.at(positions, pos_idx + 2) || 0.0, # z
        Enum.at(normals, pos_idx) || 0.0,       # nx
        Enum.at(normals, pos_idx + 1) || 1.0,   # ny (default up)
        Enum.at(normals, pos_idx + 2) || 0.0,   # nz
        Enum.at(texcoords, tex_idx) || 0.0,     # u
        flipped_v                               # v (flipped for OpenGL)
      ]
    end

        # Debug: Show first few interleaved vertices (V coordinate is flipped for OpenGL)
    IO.puts("          - First few interleaved vertices (V coordinates flipped for OpenGL):")
    vertices
    |> Enum.take(3)
    |> Enum.with_index()
    |> Enum.each(fn {vertex, i} ->
      case vertex do
        [x, y, z, nx, ny, nz, u, v] when length(vertex) == 8 ->
          # Safe rounding with nil checks
          pos_str = "(#{safe_round(x)}, #{safe_round(y)}, #{safe_round(z)})"
          norm_str = "(#{safe_round(nx)}, #{safe_round(ny)}, #{safe_round(nz)})"
          tex_str = "(#{safe_round(u)}, #{safe_round(v)})"
          IO.puts("            Vertex #{i}: pos#{pos_str} norm#{norm_str} tex#{tex_str}")
        _ ->
          IO.puts("            Vertex #{i}: unexpected format - #{inspect(vertex)}")
      end
    end)

    # Convert to binary format for OpenGL, with safety checks
    vertex_binary = vertices
    |> List.flatten()
    |> Enum.reduce(<<>>, fn
      float_val, acc when is_number(float_val) ->
        acc <> <<float_val::little-float-32>>
      nil, acc ->
        IO.puts("          - Warning: nil value found, using 0.0")
        acc <> <<0.0::little-float-32>>
      invalid, acc ->
        IO.puts("          - Warning: invalid value #{inspect(invalid)}, using 0.0")
        acc <> <<0.0::little-float-32>>
    end)

    IO.puts("          - Final vertex binary size: #{byte_size(vertex_binary)} bytes")
    vertex_binary
  end

  defp setup_shaders do
    IO.puts("  ✓ Compiling PBR metallic-roughness shaders with scene graph support...")

    vertex_shader = """
    #version 330 core
    layout (location = 0) in vec3 aPos;
    layout (location = 1) in vec3 aNormal;
    layout (location = 2) in vec2 aTexCoord;

    uniform mat4 model;
    uniform mat4 view;
    uniform mat4 projection;

    out vec3 FragPos;
    out vec3 Normal;
    out vec2 TexCoord;

    void main() {
        FragPos = vec3(model * vec4(aPos, 1.0));
        Normal = mat3(transpose(inverse(model))) * aNormal;
        TexCoord = aTexCoord;
        gl_Position = projection * view * vec4(FragPos, 1.0);
    }
    """

    # PBR metallic-roughness fragment shader with texture support (Phase 4)
    fragment_shader = """
    #version 330 core
    out vec4 FragColor;

    in vec3 FragPos;
    in vec3 Normal;
    in vec2 TexCoord;

    // Lighting
    uniform vec3 lightPos;
    uniform vec3 lightColor;
    uniform vec3 viewPos;

    // PBR Material properties (glTF metallic-roughness model)
    struct Material {
        vec3 baseColor;      // Base color factor
        float metallic;      // Metallic factor [0,1]
        float roughness;     // Roughness factor [0,1]
        vec3 emissive;       // Emissive factor
    };
    uniform Material material;

    // Texture uniforms
    uniform sampler2D baseColorTexture;
    uniform sampler2D metallicRoughnessTexture;
    uniform sampler2D normalTexture;
    uniform sampler2D emissiveTexture;

    // Texture availability flags
    uniform bool hasBaseColorTexture;
    uniform bool hasMetallicRoughnessTexture;
    uniform bool hasNormalTexture;
    uniform bool hasEmissiveTexture;

    const float PI = 3.14159265359;

    // Fresnel-Schlick approximation
    vec3 fresnelSchlick(float cosTheta, vec3 F0) {
        return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
    }

    // GGX distribution function
    float distributionGGX(vec3 N, vec3 H, float roughness) {
        float a = roughness * roughness;
        float a2 = a * a;
        float NdotH = max(dot(N, H), 0.0);
        float NdotH2 = NdotH * NdotH;

        float num = a2;
        float denom = (NdotH2 * (a2 - 1.0) + 1.0);
        denom = PI * denom * denom;

        return num / denom;
    }

    // Smith masking-shadowing function
    float geometrySchlickGGX(float NdotV, float roughness) {
        float r = (roughness + 1.0);
        float k = (r * r) / 8.0;

        float num = NdotV;
        float denom = NdotV * (1.0 - k) + k;

        return num / denom;
    }

    float geometrySmith(vec3 N, vec3 V, vec3 L, float roughness) {
        float NdotV = max(dot(N, V), 0.0);
        float NdotL = max(dot(N, L), 0.0);
        float ggx2 = geometrySchlickGGX(NdotV, roughness);
        float ggx1 = geometrySchlickGGX(NdotL, roughness);

        return ggx1 * ggx2;
    }

    void main() {
        vec3 N = normalize(Normal);
        vec3 V = normalize(viewPos - FragPos);
        vec3 L = normalize(lightPos - FragPos);
        vec3 H = normalize(V + L);

        // Sample material properties from textures (Phase 4)
        vec3 baseColor = material.baseColor;
        if (hasBaseColorTexture) {
            vec4 baseColorSample = texture(baseColorTexture, TexCoord);
            // Apply sRGB to linear conversion for base color texture
            baseColorSample.rgb = pow(baseColorSample.rgb, vec3(2.2));
            baseColor *= baseColorSample.rgb;  // Multiply with factor
        }

        float metallic = material.metallic;
        float roughness = material.roughness;
        if (hasMetallicRoughnessTexture) {
            vec3 metallicRoughnessSample = texture(metallicRoughnessTexture, TexCoord).rgb;
            // glTF: G channel = roughness, B channel = metallic
            roughness *= metallicRoughnessSample.g;
            metallic *= metallicRoughnessSample.b;
        }

        vec3 emissive = material.emissive;
        if (hasEmissiveTexture) {
            vec3 emissiveSample = texture(emissiveTexture, TexCoord).rgb;
            // Apply sRGB to linear conversion for emissive texture
            emissiveSample = pow(emissiveSample, vec3(2.2));
            emissive *= emissiveSample;  // Multiply with factor
        }

        // Normal mapping (if available)
        if (hasNormalTexture) {
            // For now, use geometric normal (normal mapping requires tangent space)
            // In a full implementation, you'd calculate TBN matrix and transform normal
        }

        // Calculate base reflectivity (F0)
        vec3 F0 = vec3(0.04);  // Dielectric base reflectivity
        F0 = mix(F0, baseColor, metallic);

        // Cook-Torrance BRDF
        float NDF = distributionGGX(N, H, roughness);
        float G = geometrySmith(N, V, L, roughness);
        vec3 F = fresnelSchlick(max(dot(H, V), 0.0), F0);

        vec3 kS = F;
        vec3 kD = vec3(1.0) - kS;
        kD *= 1.0 - metallic;  // Metals have no diffuse lighting

        vec3 numerator = NDF * G * F;
        float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.001;
        vec3 specular = numerator / denominator;

        // Lambertian diffuse
        vec3 diffuse = baseColor / PI;

        float NdotL = max(dot(N, L), 0.0);
        vec3 Lo = (kD * diffuse + specular) * lightColor * NdotL;

        // Add ambient lighting and emissive
        vec3 ambient = vec3(0.03) * baseColor;
        vec3 color = ambient + Lo + emissive;

        // HDR tonemapping and gamma correction
        color = color / (color + vec3(1.0));
        color = pow(color, vec3(1.0/2.2));

        FragColor = vec4(color, 1.0);
    }
    """

    with {:ok, vs} <- create_shader_from_source(@gl_vertex_shader, vertex_shader, "vertex"),
         {:ok, fs} <- create_shader_from_source(@gl_fragment_shader, fragment_shader, "fragment"),
         {:ok, program} <- create_attach_link([vs, fs]) do
      :gl.deleteShader(vs)
      :gl.deleteShader(fs)
      {:ok, program}
    end
  end

  defp setup_camera do
    IO.puts("  ✓ First-person camera at (0, 0, 8)")
    camera = Camera.new(
      position: vec3(0.0, 0.0, 8.0),  # Move further back for better view of scaled cube
      world_up: vec3(0.0, 1.0, 0.0),
      yaw: -90.0,
      pitch: 0.0,
      movement_speed: 2.5,
      mouse_sensitivity: 0.1
    )
    {:ok, camera}
  end



  defp create_gpu_buffers(vertex_data, indices) do
    # Debug: Check what we're actually sending to OpenGL
    IO.puts("          - GPU Buffer Debug:")
    IO.puts("            Vertex data size: #{byte_size(vertex_data)} bytes")
    IO.puts("            Expected: #{byte_size(vertex_data) / 32} vertices (32 bytes per vertex)")

    if indices do
      IO.puts("            Index data size: #{byte_size(indices)} bytes")
      IO.puts("            Expected: #{byte_size(indices) / 4} indices (4 bytes per index)")
    end

    # Create VAO/VBO with proper glTF attribute layout
    [vao] = :gl.genVertexArrays(1)
    :gl.bindVertexArray(vao)

    [vbo] = :gl.genBuffers(1)
    :gl.bindBuffer(@gl_array_buffer, vbo)
    :gl.bufferData(@gl_array_buffer, byte_size(vertex_data), vertex_data, @gl_static_draw)

    # Vertex attributes: position(0), normal(1), texcoord(2)
    stride = 32  # 8 floats * 4 bytes
    IO.puts("            Setting up vertex attributes with stride=#{stride}")
    :gl.vertexAttribPointer(0, 3, @gl_float, @gl_false, stride, 0)   # position
    :gl.enableVertexAttribArray(0)
    :gl.vertexAttribPointer(1, 3, @gl_float, @gl_false, stride, 12)  # normal
    :gl.enableVertexAttribArray(1)
    :gl.vertexAttribPointer(2, 2, @gl_float, @gl_false, stride, 24)  # texcoord
    :gl.enableVertexAttribArray(2)

    # Create EBO if indices provided
    ebo = case indices do
      nil -> nil
      index_data ->
        [ebo] = :gl.genBuffers(1)
        :gl.bindBuffer(@gl_element_array_buffer, ebo)
        :gl.bufferData(@gl_element_array_buffer, byte_size(index_data), index_data, @gl_static_draw)
        ebo
    end

    :gl.bindVertexArray(0)
    {:ok, vao, vbo, ebo}
  end

  defp render_mesh_with_material(%{vao: vao, index_count: index_count, has_indices: has_indices, material: material}, program) do
    # Set material-specific uniforms for PBR rendering (Phase 4: with texture support)
    [r, g, b, _a] = material.base_color_factor
    base_color = vec3(r, g, b)

        # Safe emissive factor extraction (convert integers to floats)
    emissive_vec = case material.emissive_factor do
      [r, g, b] when is_number(r) and is_number(g) and is_number(b) ->
        vec3(r * 1.0, g * 1.0, b * 1.0)  # Convert to floats
      [r, g, b, _a] when is_number(r) and is_number(g) and is_number(b) ->
        vec3(r * 1.0, g * 1.0, b * 1.0)  # Convert to floats, ignore alpha
      nil ->
        vec3(0.0, 0.0, 0.0)
      _ ->
        vec3(0.0, 0.0, 0.0)  # Default fallback
    end

    set_uniforms(program, [
      {"material.baseColor", base_color},
      {"material.metallic", material.metallic_factor},
      {"material.roughness", material.roughness_factor},
      {"material.emissive", emissive_vec}
    ])

    # Bind textures and set availability flags (Phase 4)
    textures = material.textures || %{}

    # Base color texture (unit 0)
    case Map.get(textures, :base_color) do
      nil ->
        set_uniform(program, "hasBaseColorTexture", false)
      texture_id ->
        :gl.activeTexture(@gl_texture0)
        :gl.bindTexture(@gl_texture_2d, texture_id)
        set_uniform(program, "baseColorTexture", 0)
        set_uniform(program, "hasBaseColorTexture", true)
    end

    # Metallic-roughness texture (unit 1)
    case Map.get(textures, :metallic_roughness) do
      nil ->
        set_uniform(program, "hasMetallicRoughnessTexture", false)
      texture_id ->
        :gl.activeTexture(@gl_texture1)
        :gl.bindTexture(@gl_texture_2d, texture_id)
        set_uniform(program, "metallicRoughnessTexture", 1)
        set_uniform(program, "hasMetallicRoughnessTexture", true)
    end

    # Normal texture (unit 2)
    case Map.get(textures, :normal) do
      nil ->
        set_uniform(program, "hasNormalTexture", false)
      texture_id ->
        :gl.activeTexture(@gl_texture2)
        :gl.bindTexture(@gl_texture_2d, texture_id)
        set_uniform(program, "normalTexture", 2)
        set_uniform(program, "hasNormalTexture", true)
    end

    # Emissive texture (unit 3)
    case Map.get(textures, :emissive) do
      nil ->
        set_uniform(program, "hasEmissiveTexture", false)
      texture_id ->
        :gl.activeTexture(@gl_texture3)
        :gl.bindTexture(@gl_texture_2d, texture_id)
        set_uniform(program, "emissiveTexture", 3)
        set_uniform(program, "hasEmissiveTexture", true)
    end

    # Reset to texture unit 0
    :gl.activeTexture(@gl_texture0)

    :gl.bindVertexArray(vao)

    if has_indices do
      :gl.drawElements(@gl_triangles, index_count, @gl_unsigned_int, 0)
    else
      :gl.drawArrays(@gl_triangles, 0, index_count)
    end

    :gl.bindVertexArray(0)
  end

  defp render_mesh_instance(%{mesh: mesh, world_transform: world_transform, node_name: _node_name}, program) do
    # Set the model matrix for this specific mesh instance (Phase 5)
    set_uniform(program, "model", world_transform)

    # Render the mesh with its material
    render_mesh_with_material(mesh, program)
  end


end

# Run the Phase 2 GLB demo
GLBWebDemo.run_example()
