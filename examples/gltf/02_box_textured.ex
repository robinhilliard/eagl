defmodule EAGL.Examples.GLTF.BoxTextured do
  @moduledoc """
  GLTF Example 2: Load and display a textured Box using EAGL GLTF bridge.

  Builds on Example 1 by adding:
  - Texture coordinate extraction (VEC2 TEXCOORD_0)
  - Embedded texture loading from GLB binary data
  - Material property extraction via GLTF.EAGL.material_to_uniforms
  - PBR base colour texture binding

  Run with: mix run examples/gltf/02_box_textured.ex
  """

  use EAGL.Window
  use EAGL.Const

  import Bitwise
  import EAGL.{Shader, Math, Texture}
  alias EAGL.{Camera, Scene, Node}

  @glb_path "test/fixtures/samples/BoxTextured.glb"

  def run_example(opts \\ []) do
    default_opts = [depth_testing: true, size: {1024, 768}, enter_to_exit: true]
    merged_opts = Keyword.merge(default_opts, opts)
    EAGL.Window.run(__MODULE__, "EAGL GLTF Example 2: Textured Box", merged_opts)
  end

  @impl true
  def setup do
    with {:ok, program} <- create_shader_program(),
         {:ok, scene, textures, info} <- load_gltf_scene(program) do
      camera =
        Camera.new(
          position: vec3(2.0, 2.0, 5.0),
          yaw: -110.0,
          pitch: -20.0
        )

      IO.puts("Setup complete: #{info}")
      {:ok, %{program: program, scene: scene, camera: camera, textures: textures, time: 0.0, last_mouse: nil, mouse_down: false}}
    end
  end

  @impl true
  def render(width, height, %{program: program, scene: scene, camera: camera, textures: textures} = state) do
    :gl.viewport(0, 0, trunc(width), trunc(height))
    :gl.clearColor(0.15, 0.15, 0.2, 1.0)
    :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)
    :gl.enable(@gl_cull_face)
    :gl.cullFace(@gl_back)

    :gl.useProgram(program)

    view = Camera.get_view_matrix(camera)
    aspect = if height > 0, do: width / height, else: 1.0
    projection = mat4_perspective(radians(camera.zoom), aspect, 0.1, 100.0)

    # Bind base colour texture if available
    case Map.get(textures, :base_color) do
      nil ->
        set_uniform(program, "hasBaseColorTexture", false)

      tex_id ->
        :gl.activeTexture(@gl_texture0)
        :gl.bindTexture(@gl_texture_2d, tex_id)
        set_uniform(program, "baseColorTexture", 0)
        set_uniform(program, "hasBaseColorTexture", true)
    end

    set_uniforms(program,
      lightPos: vec3(3.0, 5.0, 4.0),
      lightColor: vec3(1.0, 1.0, 1.0),
      viewPos: camera.position
    )

    Scene.render(scene, view, projection)

    {:ok, state}
  end

  @impl true
  def handle_event({:tick, _dt}, %{camera: camera, time: time} = state) do
    updated_camera = Camera.process_keyboard_input(camera, 0.016)
    {:ok, %{state | camera: updated_camera, time: time + 0.016}}
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
  def cleanup(%{program: program, textures: textures}) do
    cleanup_program(program)
    tex_ids = Map.values(textures) |> Enum.filter(&is_integer/1)
    if tex_ids != [], do: :gl.deleteTextures(tex_ids)
    :ok
  end

  # --- Private ---

  defp create_shader_program do
    vs_source = """
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

    fs_source = """
    #version 330 core
    out vec4 FragColor;

    in vec3 FragPos;
    in vec3 Normal;
    in vec2 TexCoord;

    uniform vec3 lightPos;
    uniform vec3 lightColor;
    uniform vec3 viewPos;
    uniform sampler2D baseColorTexture;
    uniform bool hasBaseColorTexture;

    void main() {
        vec3 baseColor = vec3(0.8, 0.8, 0.8);
        if (hasBaseColorTexture) {
            vec4 texColor = texture(baseColorTexture, TexCoord);
            baseColor = pow(texColor.rgb, vec3(2.2));
        }

        vec3 norm = normalize(Normal);
        vec3 lightDir = normalize(lightPos - FragPos);
        float diff = max(dot(norm, lightDir), 0.0);
        vec3 viewDir = normalize(viewPos - FragPos);
        vec3 reflectDir = reflect(-lightDir, norm);
        float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32.0);

        vec3 ambient = 0.15 * lightColor;
        vec3 diffuse = diff * lightColor;
        vec3 specular = 0.3 * spec * lightColor;

        vec3 result = (ambient + diffuse + specular) * baseColor;
        result = pow(result, vec3(1.0/2.2));
        FragColor = vec4(result, 1.0);
    }
    """

    with {:ok, vs} <- create_shader_from_source(@gl_vertex_shader, vs_source, "btex_vs"),
         {:ok, fs} <- create_shader_from_source(@gl_fragment_shader, fs_source, "btex_fs"),
         {:ok, prog} <- create_attach_link([vs, fs]) do
      {:ok, prog}
    end
  end

  defp load_gltf_scene(program) do
    with {:ok, gltf, glb, data_store} <- load_glb_file(),
         {:ok, {scene, all_nodes}} <- GLTF.EAGL.to_scene(gltf, data_store),
         {:ok, textures} <- load_textures(gltf, glb, data_store) do
      updated_roots =
        Enum.map(scene.root_nodes, fn node ->
          attach_program_recursive(node, program)
        end)

      scene = %{scene | root_nodes: updated_roots}
      mesh_count = Enum.count(all_nodes, fn n -> Node.get_mesh(n) != nil end)
      tex_count = map_size(textures)
      {:ok, scene, textures, "#{mesh_count} mesh(es), #{tex_count} texture(s)"}
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

            {:ok, gltf, glb, data_store}

          {:error, reason} ->
            {:error, "Failed to load GLTF: #{inspect(reason)}"}
        end

      {:error, reason} ->
        {:error, "Failed to parse GLB: #{inspect(reason)}"}
    end
  end

  defp load_textures(gltf, _glb, data_store) do
    textures = %{}

    textures =
      case load_base_color_texture(gltf, data_store) do
        {:ok, tex_id} -> Map.put(textures, :base_color, tex_id)
        _ -> textures
      end

    {:ok, textures}
  end

  defp load_base_color_texture(gltf, data_store) do
    with material when not is_nil(material) <- Enum.at(gltf.materials || [], 0),
         pbr when not is_nil(pbr) <- material.pbr_metallic_roughness,
         tex_info when not is_nil(tex_info) <- pbr.base_color_texture,
         texture when not is_nil(texture) <- Enum.at(gltf.textures || [], tex_info.index),
         image when not is_nil(image) <- Enum.at(gltf.images || [], texture.source),
         {:ok, image_binary} <- load_image_data(image, gltf, data_store) do
      load_texture_from_binary(image_binary, mime_type: image.mime_type)
      |> case do
        {:ok, tex_id, _w, _h} -> {:ok, tex_id}
        error -> error
      end
    else
      _ -> {:error, :no_base_color_texture}
    end
  end

  defp load_image_data(image, gltf, data_store) do
    cond do
      image.buffer_view != nil ->
        bv = Enum.at(gltf.buffer_views, image.buffer_view)

        case GLTF.DataStore.get_buffer_slice(data_store, bv.buffer, bv.byte_offset, bv.byte_length) do
          nil -> {:error, :buffer_slice_failed}
          data -> {:ok, data}
        end

      true ->
        {:error, :no_image_source}
    end
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
