defmodule EAGL.Examples.GLTF.BoxAnimated do
  @moduledoc """
  GLTF Example 4: Load and display the BoxAnimated model using EAGL GLTF bridge.

  Builds on Example 3 by testing:
  - GLTF animation channel/sampler extraction
  - EAGL.Animator timeline loading and playback
  - Scene graph animation updates per frame
  - Animated transforms applied through the scene hierarchy

  Run with: mix run examples/gltf/04_box_animated.ex
  """

  use EAGL.Window
  use EAGL.Const

  import Bitwise
  import EAGL.{Shader, Math}
  alias EAGL.{Camera, Scene, Node, Animator}

  @glb_path "test/fixtures/samples/BoxAnimated.glb"

  def run_example(opts \\ []) do
    default_opts = [depth_testing: true, size: {1024, 768}, enter_to_exit: true]
    merged_opts = Keyword.merge(default_opts, opts)
    EAGL.Window.run(__MODULE__, "EAGL GLTF Example 4: Animated Box", merged_opts)
  end

  @impl true
  def setup do
    with {:ok, program} <- create_shader_program(),
         {:ok, scene, animator, info} <- load_gltf_scene(program) do
      camera =
        Camera.new(
          position: vec3(3.0, 3.0, 6.0),
          yaw: -110.0,
          pitch: -20.0
        )

      IO.puts("Setup complete: #{info}")
      {:ok, %{program: program, scene: scene, camera: camera, animator: animator, time: 0.0, last_mouse: nil, mouse_down: false}}
    end
  end

  @impl true
  def render(width, height, %{program: program, scene: scene, camera: camera} = state) do
    :gl.viewport(0, 0, trunc(width), trunc(height))
    :gl.clearColor(0.15, 0.15, 0.2, 1.0)
    :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)
    :gl.enable(@gl_cull_face)
    :gl.cullFace(@gl_back)

    :gl.useProgram(program)

    view = Camera.get_view_matrix(camera)
    aspect = if height > 0, do: width / height, else: 1.0
    projection = mat4_perspective(radians(camera.zoom), aspect, 0.1, 100.0)

    set_uniforms(program,
      objectColor: vec3(0.6, 0.8, 0.3),
      lightPos: vec3(3.0, 5.0, 4.0),
      lightColor: vec3(1.0, 1.0, 1.0),
      viewPos: camera.position
    )

    Scene.render(scene, view, projection)

    {:ok, state}
  end

  @impl true
  def handle_event({:tick, _dt}, %{camera: camera, scene: scene, animator: animator, time: time} = state) do
    dt = 0.016
    updated_camera = Camera.process_keyboard_input(camera, dt)

    # Update animation
    :ok = Animator.update(animator, dt)
    animated_scene = Animator.apply_to_scene(animator, scene)

    {:ok, %{state | camera: updated_camera, scene: animated_scene, time: time + dt}}
  end

  def handle_event({:mouse_motion, x, y}, %{camera: camera, last_mouse: last_mouse, mouse_down: true} = state) do
    {lx, ly} = last_mouse || {x, y}
    updated_camera = Camera.process_mouse_movement(camera, x - lx, ly - y, true)
    {:ok, %{state | camera: updated_camera, last_mouse: {x, y}}}
  end

  def handle_event({:mouse_motion, x, y}, state) do
    {:ok, %{state | last_mouse: {x, y}}}
  end

  def handle_event({:mouse_down, _, _}, state), do: {:ok, %{state | mouse_down: true}}
  def handle_event({:mouse_up, _, _}, state), do: {:ok, %{state | mouse_down: false, last_mouse: nil}}

  def handle_event({:mouse_wheel, _, _, _, wd}, %{camera: camera} = state) do
    {:ok, %{state | camera: Camera.process_mouse_scroll(camera, wd)}}
  end

  def handle_event(_event, state), do: {:ok, state}

  @impl true
  def cleanup(%{program: program, animator: animator}) do
    cleanup_program(program)
    Animator.stop(animator)
    :ok
  end

  # --- Private ---

  defp create_shader_program do
    vs_source = """
    #version 330 core
    layout (location = 0) in vec3 aPos;
    layout (location = 1) in vec3 aNormal;

    uniform mat4 model;
    uniform mat4 view;
    uniform mat4 projection;

    out vec3 FragPos;
    out vec3 Normal;

    void main() {
        FragPos = vec3(model * vec4(aPos, 1.0));
        Normal = mat3(transpose(inverse(model))) * aNormal;
        gl_Position = projection * view * vec4(FragPos, 1.0);
    }
    """

    fs_source = """
    #version 330 core
    out vec4 FragColor;

    in vec3 FragPos;
    in vec3 Normal;

    uniform vec3 objectColor;
    uniform vec3 lightPos;
    uniform vec3 lightColor;
    uniform vec3 viewPos;

    void main() {
        vec3 norm = normalize(Normal);
        vec3 lightDir = normalize(lightPos - FragPos);
        float diff = max(dot(norm, lightDir), 0.0);
        vec3 viewDir = normalize(viewPos - FragPos);
        vec3 reflectDir = reflect(-lightDir, norm);
        float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32.0);

        vec3 ambient = 0.15 * lightColor;
        vec3 diffuse = diff * lightColor;
        vec3 specular = 0.5 * spec * lightColor;

        vec3 result = (ambient + diffuse + specular) * objectColor;
        FragColor = vec4(result, 1.0);
    }
    """

    with {:ok, vs} <- create_shader_from_source(@gl_vertex_shader, vs_source, "anim_vs"),
         {:ok, fs} <- create_shader_from_source(@gl_fragment_shader, fs_source, "anim_fs"),
         {:ok, prog} <- create_attach_link([vs, fs]) do
      {:ok, prog}
    end
  end

  defp load_gltf_scene(program) do
    with {:ok, gltf, data_store} <- load_glb_file(),
         {:ok, {scene, all_nodes}} <- GLTF.EAGL.to_scene(gltf, data_store),
         {:ok, animator} <- setup_animations(gltf, data_store) do
      updated_roots =
        Enum.map(scene.root_nodes, fn node ->
          attach_program_recursive(node, program)
        end)

      scene = %{scene | root_nodes: updated_roots}
      mesh_count = Enum.count(all_nodes, fn n -> Node.get_mesh(n) != nil end)
      anim_count = length(gltf.animations || [])
      {:ok, scene, animator, "#{mesh_count} mesh(es), #{anim_count} animation(s)"}
    end
  end

  defp load_glb_file do
    case GLTF.GLBLoader.parse_file(@glb_path) do
      {:ok, glb} ->
        case GLTF.GLBLoader.load_gltf(@glb_path, json_library: :poison) do
          {:ok, gltf} ->
            data_store = GLTF.DataStore.new()

            data_store =
              case GLTF.Binary.get_binary(glb) do
                nil -> data_store
                bin -> GLTF.DataStore.store_glb_buffer(data_store, 0, bin)
              end

            {:ok, gltf, data_store}

          {:error, reason} ->
            {:error, "Failed to load GLTF: #{inspect(reason)}"}
        end

      {:error, reason} ->
        {:error, "Failed to parse GLB: #{inspect(reason)}"}
    end
  end

  defp setup_animations(gltf, data_store) do
    timelines = GLTF.EAGL.convert_animations(gltf, data_store)
    {:ok, animator} = Animator.new(loop: true)

    Enum.each(timelines, fn timeline ->
      :ok = Animator.load_timeline(animator, timeline)
    end)

    case timelines do
      [first | _] ->
        :ok = Animator.play(animator, first.name)

      [] ->
        :ok
    end

    {:ok, animator}
  end

  defp attach_program_recursive(node, program) do
    updated_node =
      case Node.get_mesh(node) do
        nil -> node
        mesh -> Node.set_mesh(node, Map.put(mesh, :program, program))
      end

    updated_children =
      Enum.map(Node.get_children(updated_node), fn child ->
        attach_program_recursive(child, program)
      end)

    Node.set_children(updated_node, updated_children)
  end
end
