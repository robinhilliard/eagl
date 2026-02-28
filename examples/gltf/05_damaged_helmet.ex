defmodule EAGL.Examples.GLTF.DamagedHelmet do
  @moduledoc """
  GLTF Example 5: Load and display the DamagedHelmet using EAGL GLTF bridge.

  This is the complex PBR model test. It validates the full pipeline:
  - Complex mesh geometry (single mesh, many triangles)
  - Multiple PBR textures (base colour, metallic-roughness, normal, emissive)
  - Full PBR metallic-roughness material workflow
  - Scene graph with proper transform application

  Run with: mix run examples/gltf/05_damaged_helmet.ex
  """

  use EAGL.Window
  use EAGL.Const

  import Bitwise
  import EAGL.{Shader, Math, Texture}
  alias EAGL.{Camera, Scene, Node}

  @glb_path "test/fixtures/samples/DamagedHelmet.glb"

  def run_example(opts \\ []) do
    default_opts = [depth_testing: true, size: {1024, 768}, enter_to_exit: true]
    merged_opts = Keyword.merge(default_opts, opts)
    EAGL.Window.run(__MODULE__, "EAGL GLTF Example 5: Damaged Helmet (PBR)", merged_opts)
  end

  @impl true
  def setup do
    with {:ok, program} <- create_shader_program(),
         {:ok, scene, textures, material, info} <- load_gltf_scene(program) do
      camera =
        Camera.new(
          position: vec3(0.0, 0.0, 4.0),
          yaw: -90.0,
          pitch: 0.0
        )

      IO.puts("Setup complete: #{info}")

      {:ok, %{
        program: program,
        scene: scene,
        camera: camera,
        textures: textures,
        material: material,
        time: 0.0,
        last_mouse: nil,
        mouse_down: false
      }}
    end
  end

  @impl true
  def render(width, height, state) do
    %{program: program, scene: scene, camera: camera, textures: textures, material: material} = state

    :gl.viewport(0, 0, trunc(width), trunc(height))
    :gl.clearColor(0.1, 0.1, 0.15, 1.0)
    :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)
    :gl.enable(@gl_cull_face)
    :gl.cullFace(@gl_back)

    :gl.useProgram(program)

    view = Camera.get_view_matrix(camera)
    aspect = if height > 0, do: width / height, else: 1.0
    projection = mat4_perspective(radians(camera.zoom), aspect, 0.1, 100.0)

    # Set PBR material properties
    [r, g, b, _a] = material.base_color_factor
    set_uniforms(program,
      "material.baseColor": vec3(r, g, b),
      "material.metallic": material.metallic_factor,
      "material.roughness": material.roughness_factor
    )

    emissive = material.emissive_factor || [0.0, 0.0, 0.0]
    [er, eg, eb | _] = emissive
    set_uniform(program, "material.emissive", vec3(er * 1.0, eg * 1.0, eb * 1.0))

    # Bind textures
    bind_texture(program, textures, :base_color, "baseColorTexture", "hasBaseColorTexture", @gl_texture0, 0)
    bind_texture(program, textures, :metallic_roughness, "metallicRoughnessTexture", "hasMetallicRoughnessTexture", @gl_texture1, 1)
    bind_texture(program, textures, :normal, "normalTexture", "hasNormalTexture", @gl_texture2, 2)
    bind_texture(program, textures, :emissive, "emissiveTexture", "hasEmissiveTexture", @gl_texture3, 3)

    :gl.activeTexture(@gl_texture0)

    set_uniforms(program,
      lightPos: vec3(5.0, 5.0, 5.0),
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

  defp bind_texture(program, textures, key, sampler_name, has_name, tex_unit, unit_idx) do
    case Map.get(textures, key) do
      nil ->
        set_uniform(program, has_name, false)

      tex_id ->
        :gl.activeTexture(tex_unit)
        :gl.bindTexture(@gl_texture_2d, tex_id)
        set_uniform(program, sampler_name, unit_idx)
        set_uniform(program, has_name, true)
    end
  end

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

    struct Material {
        vec3 baseColor;
        float metallic;
        float roughness;
        vec3 emissive;
    };
    uniform Material material;

    uniform sampler2D baseColorTexture;
    uniform sampler2D metallicRoughnessTexture;
    uniform sampler2D normalTexture;
    uniform sampler2D emissiveTexture;
    uniform bool hasBaseColorTexture;
    uniform bool hasMetallicRoughnessTexture;
    uniform bool hasNormalTexture;
    uniform bool hasEmissiveTexture;

    const float PI = 3.14159265359;

    vec3 fresnelSchlick(float cosTheta, vec3 F0) {
        return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
    }

    float distributionGGX(vec3 N, vec3 H, float roughness) {
        float a = roughness * roughness;
        float a2 = a * a;
        float NdotH = max(dot(N, H), 0.0);
        float denom = (NdotH * NdotH * (a2 - 1.0) + 1.0);
        return a2 / (PI * denom * denom);
    }

    float geometrySchlickGGX(float NdotV, float roughness) {
        float r = (roughness + 1.0);
        float k = (r * r) / 8.0;
        return NdotV / (NdotV * (1.0 - k) + k);
    }

    float geometrySmith(vec3 N, vec3 V, vec3 L, float roughness) {
        return geometrySchlickGGX(max(dot(N, V), 0.0), roughness)
             * geometrySchlickGGX(max(dot(N, L), 0.0), roughness);
    }

    void main() {
        vec3 N = normalize(Normal);
        vec3 V = normalize(viewPos - FragPos);
        vec3 L = normalize(lightPos - FragPos);
        vec3 H = normalize(V + L);

        vec3 baseColor = material.baseColor;
        if (hasBaseColorTexture) {
            baseColor *= pow(texture(baseColorTexture, TexCoord).rgb, vec3(2.2));
        }

        float metallic = material.metallic;
        float roughness = material.roughness;
        if (hasMetallicRoughnessTexture) {
            vec3 mr = texture(metallicRoughnessTexture, TexCoord).rgb;
            roughness *= mr.g;
            metallic *= mr.b;
        }

        vec3 emissive = material.emissive;
        if (hasEmissiveTexture) {
            emissive *= pow(texture(emissiveTexture, TexCoord).rgb, vec3(2.2));
        }

        vec3 F0 = mix(vec3(0.04), baseColor, metallic);
        float NDF = distributionGGX(N, H, roughness);
        float G = geometrySmith(N, V, L, roughness);
        vec3 F = fresnelSchlick(max(dot(H, V), 0.0), F0);

        vec3 kD = (vec3(1.0) - F) * (1.0 - metallic);
        float denom = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.001;
        vec3 specular = (NDF * G * F) / denom;

        float NdotL = max(dot(N, L), 0.0);
        vec3 Lo = (kD * baseColor / PI + specular) * lightColor * NdotL;

        vec3 color = vec3(0.03) * baseColor + Lo + emissive;
        color = color / (color + vec3(1.0));
        color = pow(color, vec3(1.0/2.2));

        FragColor = vec4(color, 1.0);
    }
    """

    with {:ok, vs} <- create_shader_from_source(@gl_vertex_shader, vs_source, "pbr_vs"),
         {:ok, fs} <- create_shader_from_source(@gl_fragment_shader, fs_source, "pbr_fs"),
         {:ok, prog} <- create_attach_link([vs, fs]) do
      {:ok, prog}
    end
  end

  defp load_gltf_scene(program) do
    with {:ok, gltf, data_store} <- load_glb_file(),
         {:ok, {scene, all_nodes}} <- GLTF.EAGL.to_scene(gltf, data_store),
         {:ok, textures} <- load_all_textures(gltf, data_store),
         {:ok, material} <- extract_material(gltf) do
      updated_roots =
        Enum.map(scene.root_nodes, fn node ->
          attach_program_recursive(node, program)
        end)

      scene = %{scene | root_nodes: updated_roots}
      mesh_count = Enum.count(all_nodes, fn n -> Node.get_mesh(n) != nil end)
      tex_count = map_size(textures)
      {:ok, scene, textures, material, "#{mesh_count} mesh(es), #{tex_count} texture(s)"}
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

  defp extract_material(gltf) do
    case Enum.at(gltf.materials || [], 0) do
      nil ->
        {:ok, %{
          base_color_factor: [1.0, 1.0, 1.0, 1.0],
          metallic_factor: 1.0,
          roughness_factor: 1.0,
          emissive_factor: [0.0, 0.0, 0.0]
        }}

      mat ->
        pbr = mat.pbr_metallic_roughness || %{}
        {:ok, %{
          base_color_factor: Map.get(pbr, :base_color_factor, [1.0, 1.0, 1.0, 1.0]),
          metallic_factor: Map.get(pbr, :metallic_factor, 1.0),
          roughness_factor: Map.get(pbr, :roughness_factor, 1.0),
          emissive_factor: mat.emissive_factor || [0.0, 0.0, 0.0]
        }}
    end
  end

  defp load_all_textures(gltf, data_store) do
    textures = %{}
    material = Enum.at(gltf.materials || [], 0)

    if material do
      textures = try_load_texture(textures, :base_color, material.pbr_metallic_roughness && material.pbr_metallic_roughness.base_color_texture, gltf, data_store)
      textures = try_load_texture(textures, :metallic_roughness, material.pbr_metallic_roughness && material.pbr_metallic_roughness.metallic_roughness_texture, gltf, data_store)
      textures = try_load_texture(textures, :normal, material.normal_texture, gltf, data_store)
      textures = try_load_texture(textures, :emissive, material.emissive_texture, gltf, data_store)
      {:ok, textures}
    else
      {:ok, textures}
    end
  end

  defp try_load_texture(textures, _key, nil, _gltf, _data_store), do: textures

  defp try_load_texture(textures, key, tex_info, gltf, data_store) do
    with texture when not is_nil(texture) <- Enum.at(gltf.textures || [], tex_info.index),
         image when not is_nil(image) <- Enum.at(gltf.images || [], texture.source),
         {:ok, image_binary} <- load_image_data(image, gltf, data_store),
         {:ok, tex_id, _w, _h} <- load_texture_from_binary(image_binary, mime_type: image.mime_type) do
      Map.put(textures, key, tex_id)
    else
      _ -> textures
    end
  end

  defp load_image_data(image, gltf, data_store) do
    if image.buffer_view do
      bv = Enum.at(gltf.buffer_views, image.buffer_view)

      case GLTF.DataStore.get_buffer_slice(data_store, bv.buffer, bv.byte_offset, bv.byte_length) do
        nil -> {:error, :buffer_slice_failed}
        data -> {:ok, data}
      end
    else
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
