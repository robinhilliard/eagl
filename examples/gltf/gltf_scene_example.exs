#!/usr/bin/env elixir

# glTF Scene Graph Example
# ========================
#
# This example demonstrates EAGL's new scene graph capabilities with glTF integration.
# It shows how glTF assets can be loaded and rendered using EAGL's scene graph system
# while maintaining backward compatibility with existing EAGL APIs.
#
# Run with: elixir examples/gltf_scene_example.exs

# Add the current project to the code path
Code.append_path("_build/dev/lib/eagl/ebin")
Code.append_path("_build/dev/lib/req/ebin")
Code.append_path("_build/dev/lib/finch/ebin")
Code.append_path("_build/dev/lib/mint/ebin")
Code.append_path("_build/dev/lib/nimble_pool/ebin")
Code.append_path("_build/dev/lib/nimble_options/ebin")
Code.append_path("_build/dev/lib/telemetry/ebin")
Code.append_path("_build/dev/lib/hpax/ebin")
Code.append_path("_build/dev/lib/mime/ebin")
Code.append_path("_build/dev/lib/poison/ebin")
Code.append_path("_build/dev/lib/jason/ebin")

defmodule GLTFSceneExample do
  @moduledoc """
  Example demonstrating glTF to EAGL scene graph conversion.

  This example shows the complete workflow:
  1. Load a glTF/GLB file
  2. Convert it to an EAGL scene graph
  3. Render with hierarchical transforms
  4. Mix with manually created EAGL objects
  """

  use EAGL.Window
  use EAGL.Const

  import EAGL.{Shader, Math}
  alias EAGL.Camera
  alias EAGL.{Scene, Node}

  # Simple test GLB URL (Khronos sample)
  @test_glb_url "https://github.com/KhronosGroup/glTF-Sample-Assets/raw/refs/heads/main/Models/ChairDamaskPurplegold/glTF-Binary/ChairDamaskPurplegold.glb"

  @spec run_example(keyword()) :: :ok | {:error, term()}
  def run_example(opts \\ []) do
    default_opts = [
      depth_testing: true,
      size: {1024, 768},
      enter_to_exit: true
    ]

    merged_opts = Keyword.merge(default_opts, opts)

    EAGL.Window.run(
      __MODULE__,
      "EAGL glTF Scene Graph Example",
      merged_opts
    )
  end

  @impl true
  def setup do
    IO.puts("""
    === EAGL glTF Scene Graph Example ===

    This example demonstrates EAGL's extended scope to support fundamental 3D concepts:
    - Scene graphs with transform hierarchies
    - glTF asset loading and conversion
    - Mixed rendering (glTF + manual EAGL objects)
    - Backward compatibility with existing APIs

    Features shown:
    ✓ Scene graph management
    ✓ Hierarchical transforms
    ✓ glTF to EAGL conversion
    ✓ Mixed content rendering
    ✓ Camera movement (WASD + mouse)

    Controls:
    - WASD: Move camera
    - Mouse: Look around
    - Scroll: Zoom
    - ENTER: Exit
    """)

    with {:ok, shaders} <- setup_shaders(),
         {:ok, camera} <- setup_camera(),
         {:ok, scene} <- setup_scene(shaders) do
      IO.puts("✅ Scene graph setup complete")
      IO.puts("🎮 Use WASD to move, mouse to look around")

      {:ok,
       %{
         shaders: shaders,
         camera: camera,
         scene: scene,
         # Center of default 1024x768 window
         last_mouse: {512, 384},
         mouse_captured: false
       }}
    else
      {:error, reason} ->
        IO.puts("❌ Setup failed: #{reason}")
        {:error, reason}
    end
  end

  @impl true
  def render(width, height, %{shaders: _shaders, camera: camera, scene: scene} = state) do
    # Clear screen
    :gl.viewport(0, 0, trunc(width), trunc(height))
    :gl.clearColor(0.1, 0.1, 0.2, 1.0)
    :gl.clear(Bitwise.bor(@gl_color_buffer_bit, @gl_depth_buffer_bit))

    # Enable 3D rendering
    :gl.enable(@gl_depth_test)
    :gl.enable(@gl_cull_face)
    :gl.cullFace(@gl_back)

    # Set up matrices
    view_matrix = Camera.get_view_matrix(camera)
    projection_matrix = mat4_perspective(radians(camera.zoom), width / height, 0.1, 100.0)

    # Render scene graph with debugging
    all_nodes = Scene.get_all_nodes(scene)
    meshes_with_meshes = Enum.count(all_nodes, fn node -> Node.get_mesh(node) != nil end)

    if meshes_with_meshes > 0 do
      # IO.puts("🎬 Rendering #{meshes_with_meshes} nodes with meshes")
    end

    Scene.render(scene, view_matrix, projection_matrix)

    {:ok, state}
  end

  @impl true
  def handle_event({:tick, _time_delta}, %{camera: camera} = state) do
    # Update camera with smooth movement
    # 60 FPS
    updated_camera = Camera.process_keyboard_input(camera, 0.016)
    {:ok, %{state | camera: updated_camera}}
  end

  # Handled by process_keyboard_input
  def handle_event({:key, ?W}, state), do: {:ok, state}
  def handle_event({:key, ?A}, state), do: {:ok, state}
  def handle_event({:key, ?S}, state), do: {:ok, state}
  def handle_event({:key, ?D}, state), do: {:ok, state}

  def handle_event(
        {:mouse_motion, x, y},
        %{camera: camera, last_mouse: {last_x, last_y}, mouse_captured: true} = state
      ) do
    # Mouse look
    dx = x - last_x
    # Invert Y
    dy = last_y - y
    updated_camera = Camera.process_mouse_movement(camera, dx, dy, true)
    {:ok, %{state | camera: updated_camera, last_mouse: {x, y}}}
  end

  def handle_event({:mouse_motion, x, y}, state) do
    {:ok, %{state | last_mouse: {x, y}}}
  end

  def handle_event({:mouse_wheel, _, _, _, wheel_delta}, %{camera: camera} = state) do
    updated_camera = Camera.process_mouse_scroll(camera, wheel_delta)
    {:ok, %{state | camera: updated_camera}}
  end

  def handle_event(_event, state), do: {:ok, state}

  @impl true
  def cleanup(%{scene: scene}) do
    # Clean up scene graph resources
    Scene.get_all_nodes(scene)
    |> Enum.each(fn node ->
      case Node.get_mesh(node) do
        nil -> :ok
        %{vao: vao, vbo: vbo} -> EAGL.Buffer.delete_vertex_array(vao, vbo)
        %{vao: vao, vbo: vbo, ebo: ebo} -> EAGL.Buffer.delete_indexed_array(vao, vbo, ebo)
        _ -> :ok
      end
    end)

    :ok
  end

  # Private setup functions

  defp setup_shaders do
    vertex_shader_source = """
    #version 330 core
    layout (location = 0) in vec3 aPos;
    layout (location = 1) in vec3 aColor;

    uniform mat4 model;
    uniform mat4 view;
    uniform mat4 projection;

    out vec3 vertexColor;

    void main()
    {
        gl_Position = projection * view * model * vec4(aPos, 1.0);
        vertexColor = aColor;
    }
    """

    fragment_shader_source = """
    #version 330 core
    out vec4 FragColor;

    in vec3 vertexColor;
    uniform vec3 objectColor;

    void main()
    {
        FragColor = vec4(vertexColor * objectColor, 1.0);
    }
    """

    with {:ok, vertex_shader} <-
           create_shader_from_source(@gl_vertex_shader, vertex_shader_source, "vertex_shader"),
         {:ok, fragment_shader} <-
           create_shader_from_source(
             @gl_fragment_shader,
             fragment_shader_source,
             "fragment_shader"
           ),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do
      {:ok, %{program: program}}
    end
  end

  defp setup_camera do
    camera =
      Camera.new(
        # Move camera further back and higher up to see the chair better
        position: vec3(3.0, 2.0, 8.0),
        world_up: vec3(0.0, 1.0, 0.0),
        yaw: -90.0,
        # Look down slightly
        pitch: -15.0
      )

    {:ok, camera}
  end

  defp setup_scene(%{program: program}) do
    scene = Scene.new(name: "Mixed Content Demo")

    # Load glTF content - no fallback
    case load_gltf_content(program) do
      {:ok, gltf_nodes} ->
        IO.puts("✅ Using glTF nodes")
        scene = Enum.reduce(gltf_nodes, scene, fn node, acc ->
          Scene.add_root_node(acc, node)
        end)
        {:ok, scene}

      {:error, reason} ->
        IO.puts("❌ glTF loading failed: #{reason}")
        {:error, reason}
    end
  end

  defp load_gltf_content(program) do
    IO.puts("🌐 Attempting to load glTF content from: #{@test_glb_url}")

    # Start all required applications
    Application.ensure_all_started(:crypto)
    Application.ensure_all_started(:asn1)
    Application.ensure_all_started(:public_key)
    Application.ensure_all_started(:ssl)
    Application.ensure_all_started(:inets)
    Application.ensure_all_started(:telemetry)
    Application.ensure_all_started(:finch)
    Application.ensure_all_started(:req)

        IO.puts("🌍 Starting GLB download...")

    download_result = try do
      GLTF.GLBLoader.parse_url(@test_glb_url, timeout: 15_000, http_client: :req)
    rescue
      error ->
        IO.puts("❌ Download error: #{inspect(error)}")
        {:error, error}
    catch
      error ->
        IO.puts("❌ Download caught error: #{inspect(error)}")
        {:error, error}
    end

    case download_result do
      {:ok, glb_binary} ->
        IO.puts("📦 Downloaded and parsed GLB file successfully")

        # Load the glTF structure and set up data store properly
        json_library = if Code.ensure_loaded?(Poison), do: :poison, else: :jason
        IO.puts("📋 Using JSON library: #{json_library}")

        gltf_result = try do
          GLTF.GLBLoader.load_gltf_from_glb(glb_binary, json_library)
        rescue
          error ->
            IO.puts("❌ glTF loading error: #{inspect(error)}")
            {:error, error}
        catch
          error ->
            IO.puts("❌ glTF loading caught error: #{inspect(error)}")
            {:error, error}
        end

        case gltf_result do
          {:ok, gltf} ->
            IO.puts("✅ glTF document loaded successfully")
            IO.puts("  📊 Asset info:")
            IO.puts("    - Version: #{gltf.asset.version}")
            IO.puts("    - Generator: #{gltf.asset.generator || "Unknown"}")

            if gltf.meshes do
              IO.puts("    - Meshes: #{length(gltf.meshes)}")
            end

            if gltf.materials do
              IO.puts("    - Materials: #{length(gltf.materials)}")
            end

            if gltf.nodes do
              IO.puts("    - Nodes: #{length(gltf.nodes)}")
            end

                        # Create data store and load binary data
            data_store = GLTF.DataStore.new()

            data_store = case GLTF.Binary.get_binary(glb_binary) do
              nil ->
                IO.puts("    - No binary data found")
                data_store
              binary_data ->
                IO.puts("    - Binary data: #{byte_size(binary_data)} bytes")
                GLTF.DataStore.store_glb_buffer(data_store, 0, binary_data)
            end

            # Use the fixed GLTF.EAGL.to_scene function
            case GLTF.EAGL.to_scene(gltf, data_store, name: "Chair Scene") do
              {:ok, gltf_scene} ->
                IO.puts("✅ GLTF.EAGL.to_scene successful")

                # Add shader program to all meshes and get nodes
                nodes_with_shaders =
                  Scene.get_all_nodes(gltf_scene)
                  |> Enum.map(fn node ->
                    case Node.get_mesh(node) do
                      nil -> node
                      mesh -> Node.set_mesh(node, Map.put(mesh, :program, program))
                    end
                  end)

                IO.puts("  📦 Processed #{length(nodes_with_shaders)} nodes with shaders")
                {:ok, nodes_with_shaders}

              {:error, reason} ->
                IO.puts("❌ GLTF.EAGL.to_scene failed: #{reason}")
                {:error, reason}
            end

          {:error, reason} ->
            IO.puts("❌ glTF document loading failed: #{inspect(reason)}")
            {:error, reason}
        end

      {:error, reason} ->
        IO.puts("❌ GLB download failed: #{inspect(reason)}")
        {:error, reason}
    end
  end
end

# Run the example
GLTFSceneExample.run_example()
