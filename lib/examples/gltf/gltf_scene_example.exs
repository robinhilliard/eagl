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
  @test_glb_url "https://github.com/KhronosGroup/glTF-Sample-Assets/raw/refs/heads/main/Models/Box/glTF-Binary/Box.glb"

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

    # Set up matrices
    view_matrix = Camera.get_view_matrix(camera)
    projection_matrix = mat4_perspective(radians(camera.zoom), width / height, 0.1, 100.0)

    # Render scene graph
    Scene.render(scene, view_matrix, projection_matrix)

    {:ok, state}
  end

  @impl true
  def handle_event(:tick, %{camera: camera} = state) do
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
        position: vec3(0.0, 0.0, 5.0),
        world_up: vec3(0.0, 1.0, 0.0),
        yaw: -90.0,
        pitch: 0.0
      )

    {:ok, camera}
  end

  defp setup_scene(%{program: program}) do
    scene = Scene.new(name: "Mixed Content Demo")

    # Try to load glTF content
    scene =
      case load_gltf_content(program) do
        {:ok, gltf_nodes} ->
          Enum.reduce(gltf_nodes, scene, fn node, acc ->
            Scene.add_root_node(acc, node)
          end)

        {:error, reason} ->
          IO.puts("⚠️  glTF loading failed: #{reason}")
          IO.puts("🔧 Creating manual scene content instead...")
          create_manual_scene_content(scene, program)
      end

    {:ok, scene}
  end

  defp load_gltf_content(program) do
    IO.puts("🌐 Attempting to load glTF content from: #{@test_glb_url}")

    case GLTF.GLBLoader.parse_url(@test_glb_url, timeout: 15_000) do
      {:ok, glb_binary} ->
        case GLTF.load_from_glb(glb_binary) do
          {:ok, gltf} ->
            IO.puts("✅ glTF loaded successfully")
            create_data_store = fn -> GLTF.DataStore.new() end

            case GLTF.EAGL.to_scene(gltf, create_data_store.()) do
              {:ok, gltf_scene} ->
                # Add shader program to all meshes
                nodes_with_shaders =
                  Scene.get_all_nodes(gltf_scene)
                  |> Enum.map(fn node ->
                    case Node.get_mesh(node) do
                      nil -> node
                      mesh -> Node.set_mesh(node, Map.put(mesh, :program, program))
                    end
                  end)

                {:ok, nodes_with_shaders}

              {:error, reason} ->
                {:error, reason}
            end

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp create_manual_scene_content(scene, program) do
    # Create some manual geometry using existing EAGL.Buffer APIs
    cube_vertices = ~v"""
    # position     color
    -0.5 -0.5 -0.5  1.0  0.0  0.0  # red
     0.5 -0.5 -0.5  0.0  1.0  0.0  # green
     0.5  0.5 -0.5  0.0  0.0  1.0  # blue
    -0.5  0.5 -0.5  1.0  1.0  0.0  # yellow
    -0.5 -0.5  0.5  1.0  0.0  1.0  # magenta
     0.5 -0.5  0.5  0.0  1.0  1.0  # cyan
     0.5  0.5  0.5  1.0  1.0  1.0  # white
    -0.5  0.5  0.5  0.5  0.5  0.5  # gray
    """

    cube_indices = ~i"""
    0 1 3  1 2 3  # front
    1 5 2  5 6 2  # right
    5 4 6  4 7 6  # back
    4 0 7  0 3 7  # left
    3 2 7  2 6 7  # top
    4 5 0  5 1 0  # bottom
    """

    attributes = EAGL.Buffer.vertex_attributes([:position, :color])
    {vao, vbo, ebo} = EAGL.Buffer.create_indexed_array(cube_vertices, cube_indices, attributes)

    cube_mesh = %{
      vao: vao,
      vbo: vbo,
      ebo: ebo,
      index_count: length(cube_indices),
      program: program
    }

    # Create a simple scene hierarchy
    root_node = Node.new(name: "Root")

    # Main cube
    main_cube =
      Node.new(
        mesh: cube_mesh,
        position: vec3(0.0, 0.0, 0.0),
        name: "Main Cube"
      )

    # Child cubes with different transforms
    child1 =
      Node.new(
        mesh: cube_mesh,
        position: vec3(2.0, 1.0, 0.0),
        scale: vec3(0.5, 0.5, 0.5),
        name: "Child 1"
      )

    child2 =
      Node.new(
        mesh: cube_mesh,
        position: vec3(-2.0, -1.0, 0.0),
        scale: vec3(0.3, 0.3, 0.3),
        name: "Child 2"
      )

    # Build hierarchy
    root_with_main = Node.add_child(root_node, main_cube)

    root_with_children =
      root_with_main
      |> Node.add_child(child1)
      |> Node.add_child(child2)

    Scene.add_root_node(scene, root_with_children)
  end
end

# Run the example
GLTFSceneExample.run_example()
