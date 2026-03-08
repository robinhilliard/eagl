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

  alias EAGL.{Camera, Scene, Node, Buffer}
  import EAGL.Math
  use EAGL.Const

  # ============================================================================
  # STANDARD SHADERS
  # ============================================================================

  @doc """
  Create a standard Phong lighting shader for GLTF models without textures.

  The shader matches the GLTF attribute layout (position=0, normal=1) and
  accepts the following uniforms:
  - `model`, `view`, `projection` - transformation matrices (set by Scene.render)
  - `objectColor` - vec3 surface colour
  - `lightPos`, `lightColor` - vec3 point light position and colour
  - `viewPos` - vec3 camera position

      `{:ok, program}` = GLTF.EAGL.create_phong_shader()
  """
  @spec create_phong_shader() :: {:ok, non_neg_integer()} | {:error, String.t()}
  def create_phong_shader do
    import EAGL.Shader

    with {:ok, vs} <- create_shader(@gl_vertex_shader, "gltf/phong_vertex.glsl"),
         {:ok, fs} <- create_shader(@gl_fragment_shader, "gltf/phong_fragment.glsl"),
         {:ok, prog} <- create_attach_link([vs, fs]) do
      {:ok, prog}
    end
  end

  @doc """
  Create a flat (unlit) shader for GLTF models. Same vertex layout as Phong.
  Outputs uniform objectColor with no lighting - useful for pick testing.
  """
  @spec create_flat_shader() :: {:ok, non_neg_integer()} | {:error, String.t()}
  def create_flat_shader do
    import EAGL.Shader

    with {:ok, vs} <- create_shader(@gl_vertex_shader, "gltf/phong_vertex.glsl"),
         {:ok, fs} <- create_shader(@gl_fragment_shader, "gltf/flat_fragment.glsl"),
         {:ok, prog} <- create_attach_link([vs, fs]) do
      {:ok, prog}
    end
  end

  @doc """
  Create a standard PBR metallic-roughness shader for GLTF models.

  The shader matches the GLTF attribute layout (position=0, normal=1, texcoord=2)
  and implements the Cook-Torrance BRDF with optional textures.

  Uniforms:
  - `model`, `view`, `projection` - transformation matrices (set by Scene.render)
  - `material.baseColor`, `material.metallic`, `material.roughness`, `material.emissive`
  - `baseColorTexture`, `hasBaseColorTexture` - base colour texture (unit 0)
  - `metallicRoughnessTexture`, `hasMetallicRoughnessTexture` - packed MR texture (unit 1)
  - `normalTexture`, `hasNormalTexture` - normal map (unit 2)
  - `emissiveTexture`, `hasEmissiveTexture` - emissive texture (unit 3)
  - `lightPos`, `lightColor`, `viewPos` - lighting and camera

      `{:ok, program}` = GLTF.EAGL.create_pbr_shader()
  """
  @spec create_pbr_shader() :: {:ok, non_neg_integer()} | {:error, String.t()}
  def create_pbr_shader do
    import EAGL.Shader

    with {:ok, vs} <- create_shader(@gl_vertex_shader, "gltf/pbr_vertex.glsl"),
         {:ok, fs} <- create_shader(@gl_fragment_shader, "gltf/pbr_fragment.glsl"),
         {:ok, prog} <- create_attach_link([vs, fs]) do
      {:ok, prog}
    end
  end

  @doc """
  Set uniforms for the standard Phong shader created by `create_phong_shader/0`.

      GLTF.EAGL.set_phong_uniforms(program,
        object_color: vec3(0.8, 0.3, 0.2),
        light_pos: vec3(3.0, 5.0, 4.0),
        light_color: vec3(1.0, 1.0, 1.0),
        view_pos: camera.position
      )

  All options have defaults: white object, white light at (5, 5, 5), camera at origin.
  """
  @spec set_phong_uniforms(non_neg_integer(), keyword()) :: :ok
  def set_phong_uniforms(program, opts \\ []) do
    import EAGL.Shader

    set_uniforms(program,
      objectColor: Keyword.get(opts, :object_color, vec3(1.0, 1.0, 1.0)),
      lightPos: Keyword.get(opts, :light_pos, vec3(5.0, 5.0, 5.0)),
      lightColor: Keyword.get(opts, :light_color, vec3(1.0, 1.0, 1.0)),
      viewPos: Keyword.get(opts, :view_pos, vec3(0.0, 0.0, 0.0))
    )
  end

  @doc """
  Set uniforms for the standard PBR shader created by `create_pbr_shader/0`.

  Handles material properties, texture binding, and lighting in one call.

      GLTF.EAGL.set_pbr_uniforms(program,
        base_color: vec3(1.0, 1.0, 1.0),
        metallic: 0.0,
        roughness: 1.0,
        emissive: vec3(0.0, 0.0, 0.0),
        textures: textures,           # map from load_textures/3
        light_pos: vec3(5.0, 5.0, 5.0),
        light_color: vec3(1.0, 1.0, 1.0),
        view_pos: camera.position,
        ambient_color: vec3(0.03, 0.03, 0.03),
        skip_lights: false            # true when Scene.render manages lights
      )

  All options have defaults. Pass `:textures` from `load_textures/3` to
  automatically bind base_color, metallic_roughness, normal, and emissive
  textures to the correct units. Pass `skip_lights: true` when lights are
  managed by `EAGL.Scene.render` (which collects light nodes from the scene graph).
  """
  @spec set_pbr_uniforms(non_neg_integer(), keyword()) :: :ok
  def set_pbr_uniforms(program, opts \\ []) do
    import EAGL.Shader

    set_uniforms(program,
      "material.baseColor": Keyword.get(opts, :base_color, vec3(1.0, 1.0, 1.0)),
      "material.metallic": Keyword.get(opts, :metallic, 1.0),
      "material.roughness": Keyword.get(opts, :roughness, 1.0),
      "material.emissive": Keyword.get(opts, :emissive, vec3(0.0, 0.0, 0.0))
    )

    textures = Keyword.get(opts, :textures, %{})

    bind_pbr_texture(
      program,
      textures,
      :base_color,
      "baseColorTexture",
      "hasBaseColorTexture",
      @gl_texture0,
      0
    )

    bind_pbr_texture(
      program,
      textures,
      :metallic_roughness,
      "metallicRoughnessTexture",
      "hasMetallicRoughnessTexture",
      @gl_texture1,
      1
    )

    bind_pbr_texture(
      program,
      textures,
      :normal,
      "normalTexture",
      "hasNormalTexture",
      @gl_texture2,
      2
    )

    bind_pbr_texture(
      program,
      textures,
      :emissive,
      "emissiveTexture",
      "hasEmissiveTexture",
      @gl_texture3,
      3
    )

    :gl.activeTexture(@gl_texture0)

    set_uniform(program, "viewPos", Keyword.get(opts, :view_pos, vec3(0.0, 0.0, 0.0)))

    set_uniform(
      program,
      "ambientColor",
      Keyword.get(opts, :ambient_color, vec3(0.03, 0.03, 0.03))
    )

    unless Keyword.get(opts, :skip_lights, false) do
      light_pos = Keyword.get(opts, :light_pos, vec3(5.0, 5.0, 5.0))
      light_color = Keyword.get(opts, :light_color, vec3(1.0, 1.0, 1.0))

      set_uniform(program, "numLights", 1)
      set_uniform(program, "lights[0].type", 1)
      set_uniform(program, "lights[0].position", light_pos)
      set_uniform(program, "lights[0].direction", vec3(0.0, -1.0, 0.0))
      set_uniform(program, "lights[0].color", light_color)
      set_uniform(program, "lights[0].intensity", 1.0)
      set_uniform(program, "lights[0].range", 0.0)
      set_uniform(program, "lights[0].innerConeAngle", 0.0)
      set_uniform(program, "lights[0].outerConeAngle", 0.7854)
    end
  end

  defp bind_pbr_texture(program, textures, key, sampler_name, has_name, tex_unit, unit_idx) do
    import EAGL.Shader

    case Map.get(textures, key) do
      nil ->
        # Bind default texture so sampler has valid target (avoids "texture unloadable" on macOS)
        default = EAGL.Texture.get_default_texture()

        if default do
          :gl.activeTexture(tex_unit)
          :gl.bindTexture(@gl_texture_2d, default)
          set_uniform(program, sampler_name, unit_idx)
        end

        set_uniform(program, has_name, false)

      tex_id ->
        :gl.activeTexture(tex_unit)
        :gl.bindTexture(@gl_texture_2d, tex_id)
        set_uniform(program, sampler_name, unit_idx)
        set_uniform(program, has_name, true)
    end
  end

  # ============================================================================
  # HIGH-LEVEL LOADING HELPERS
  # ============================================================================

  @doc """
  Load a GLB file and return the parsed GLTF document with a ready-to-use DataStore.

  Handles GLB parsing, JSON decoding, and binary data store creation in one call.

      {:ok, gltf, data_store} = GLTF.EAGL.load_glb("model.glb")
      {:ok, gltf, data_store} = GLTF.EAGL.load_glb("https://example.com/model.glb", http_client: :req)
  """
  @spec load_glb(String.t(), keyword()) :: {:ok, GLTF.t(), GLTF.DataStore.t()} | {:error, term()}
  def load_glb(path_or_url, opts \\ []) do
    json_library = Keyword.get(opts, :json_library, :jason)

    with {:ok, glb} <- GLTF.GLBLoader.parse(path_or_url, opts),
         {:ok, gltf} <- GLTF.GLBLoader.load_gltf_from_glb(glb, json_library) do
      data_store = GLTF.DataStore.new()

      data_store =
        case GLTF.Binary.get_binary(glb) do
          nil -> data_store
          bin -> GLTF.DataStore.store_glb_buffer(data_store, 0, bin)
        end

      {:ok, gltf, data_store}
    end
  end

  @doc """
  Load a GLB file and convert it to a renderable EAGL scene in one call.

  Combines GLB loading, scene graph conversion, and shader program attachment.
  Returns the scene plus the GLTF document and DataStore for further use
  (e.g. texture loading).

      {:ok, scene, gltf, data_store} = GLTF.EAGL.load_scene("model.glb", shader_program)
  """
  @spec load_scene(String.t(), non_neg_integer(), keyword()) ::
          {:ok, Scene.t(), GLTF.t(), GLTF.DataStore.t()} | {:error, term()}
  def load_scene(path_or_url, shader_program, opts \\ []) do
    with {:ok, gltf, data_store} <- load_glb(path_or_url, opts),
         {:ok, {scene, _all_nodes}} <- to_scene(gltf, data_store, opts) do
      updated_roots =
        Enum.map(scene.root_nodes, fn node ->
          attach_program_recursive(node, shader_program)
        end)

      {:ok, %{scene | root_nodes: updated_roots}, gltf, data_store}
    end
  end

  @doc """
  Load textures from a GLTF document's materials.

  Walks the specified material (default: first material, index 0) and loads all
  available texture types from the GLB binary data. Returns a map of texture IDs
  keyed by type.

      {:ok, textures} = GLTF.EAGL.load_textures(gltf, data_store)
      # => {:ok, %{base_color: 1, metallic_roughness: 2, normal: 3}}

  Options:
  - `:material_index` - which material to load textures from (default: 0)
  """
  @spec load_textures(GLTF.t(), GLTF.DataStore.t(), keyword()) :: {:ok, map()}
  def load_textures(%GLTF{} = gltf, data_store, opts \\ []) do
    material_index = Keyword.get(opts, :material_index, 0)
    material = Enum.at(gltf.materials || [], material_index)

    if material do
      textures = %{}

      pbr = material.pbr_metallic_roughness

      textures =
        try_load_material_texture(
          textures,
          :base_color,
          pbr && pbr.base_color_texture,
          gltf,
          data_store
        )

      textures =
        try_load_material_texture(
          textures,
          :metallic_roughness,
          pbr && pbr.metallic_roughness_texture,
          gltf,
          data_store
        )

      textures =
        try_load_material_texture(textures, :normal, material.normal_texture, gltf, data_store)

      textures =
        try_load_material_texture(
          textures,
          :emissive,
          material.emissive_texture,
          gltf,
          data_store
        )

      {:ok, textures}
    else
      {:ok, %{}}
    end
  end

  # ============================================================================
  # BOUNDS
  # ============================================================================

  @doc """
  Compute the axis-aligned bounding box of a glTF document.

  Scans all POSITION accessors for min/max and merges them. Applies the root
  node's scale when present so bounds reflect the actual scene extent.

  Returns `{:ok, min_point, max_point}` as `{x, y, z}` tuples, or `:no_bounds`
  if no position data is available.

  Useful for camera setup (e.g. `OrbitCamera.fit_to_bounds/2`) and culling.
  """
  @spec bounds(GLTF.t()) ::
          {:ok, {float(), float(), float()}, {float(), float(), float()}} | :no_bounds
  def bounds(%GLTF{meshes: nil}), do: :no_bounds
  def bounds(%GLTF{meshes: []}), do: :no_bounds

  def bounds(%GLTF{
        meshes: meshes,
        accessors: accessors,
        nodes: nodes,
        scenes: scenes,
        scene: scene_idx
      }) do
    position_accessor_indices =
      meshes
      |> Enum.flat_map(fn mesh ->
        Enum.map(mesh.primitives, fn prim -> prim.attributes["POSITION"] end)
      end)
      |> Enum.filter(& &1)
      |> Enum.uniq()

    bounds =
      position_accessor_indices
      |> Enum.reduce(nil, fn idx, acc ->
        accessor = Enum.at(accessors || [], idx)

        if accessor && accessor.min && accessor.max do
          [min_x, min_y, min_z] = accessor.min
          [max_x, max_y, max_z] = accessor.max

          case acc do
            nil ->
              {{min_x, min_y, min_z}, {max_x, max_y, max_z}}

            {{ax, ay, az}, {bx, by, bz}} ->
              {{min(ax, min_x), min(ay, min_y), min(az, min_z)},
               {max(bx, max_x), max(by, max_y), max(bz, max_z)}}
          end
        else
          acc
        end
      end)

    case bounds do
      nil ->
        :no_bounds

      {min_point, max_point} ->
        scale = estimate_root_scale(nodes, scenes, scene_idx)
        {sx, sy, sz} = min_point
        {bx, by, bz} = max_point
        {:ok, {sx * scale, sy * scale, sz * scale}, {bx * scale, by * scale, bz * scale}}
    end
  end

  defp estimate_root_scale(nodes, scenes, scene_idx) when is_list(nodes) and is_list(scenes) do
    scene = Enum.at(scenes, scene_idx || 0)
    root_idx = scene && List.first(scene.nodes || [])
    root = root_idx && Enum.at(nodes, root_idx)

    cond do
      root == nil ->
        1.0

      root.matrix != nil ->
        [{m0, _, _, _, _, m5, _, _, _, _, m10, _, _, _, _, _}] = root.matrix
        (abs(m0) + abs(m5) + abs(m10)) / 3.0

      root.scale != nil ->
        [sx, sy, sz] = root.scale
        (abs(sx) + abs(sy) + abs(sz)) / 3.0

      true ->
        1.0
    end
  end

  defp estimate_root_scale(_, _, _), do: 1.0

  defp try_load_material_texture(textures, _key, nil, _gltf, _data_store), do: textures

  defp try_load_material_texture(textures, key, tex_info, gltf, data_store) do
    with texture when not is_nil(texture) <- Enum.at(gltf.textures || [], tex_info.index),
         image when not is_nil(image) <- Enum.at(gltf.images || [], texture.source),
         {:ok, image_binary} <- load_glb_image_data(image, gltf, data_store),
         {:ok, tex_id, _w, _h} <-
           EAGL.Texture.load_texture_from_binary(image_binary, mime_type: image.mime_type) do
      Map.put(textures, key, tex_id)
    else
      _ -> textures
    end
  end

  defp load_glb_image_data(image, gltf, data_store) do
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

  # ============================================================================
  # LOWER-LEVEL CONVERSION FUNCTIONS
  # ============================================================================

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

  Returns a keyword list suitable for `EAGL.Shader.set_uniforms/2`:

      uniforms = GLTF.EAGL.material_to_uniforms(material)
      EAGL.Shader.set_uniforms(program, uniforms)

  The returned uniforms use glTF-standard parameter names compatible with EAGL's PBR shaders.
  """
  @spec material_to_uniforms(GLTF.Material.t()) :: keyword()
  def material_to_uniforms(%GLTF.Material{} = material) do
    base_uniforms = []

    # PBR Metallic-Roughness workflow
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
  Convert a glTF node to an EAGL.Node.

  Handles both matrix and TRS transform representations.
  When the node references a camera, pass a camera_lookup map (node_index -> EAGL.Camera).
  """
  @spec node_to_eagl_node(GLTF.Node.t(), map(), non_neg_integer(), map()) :: Node.t()
  def node_to_eagl_node(%GLTF.Node{} = gltf_node, mesh_lookup, node_index, camera_lookup \\ %{}) do
    node_name = gltf_node.name || "node_#{node_index}"

    node =
      case gltf_node.matrix do
        nil ->
          Node.new(
            position: list_to_vec3(gltf_node.translation || [0.0, 0.0, 0.0]),
            rotation: list_to_quat(gltf_node.rotation || [0.0, 0.0, 0.0, 1.0]),
            scale: list_to_vec3(gltf_node.scale || [1.0, 1.0, 1.0]),
            name: node_name,
            properties: gltf_node.extras
          )

        matrix when is_list(matrix) ->
          Node.with_matrix(matrix, name: node_name, properties: gltf_node.extras)
      end

    # Attach mesh if present
    node =
      case gltf_node.mesh do
        nil ->
          node

        mesh_index ->
          mesh = Map.get(mesh_lookup, mesh_index)
          Node.set_mesh(node, mesh)
      end

    # Attach camera if present
    case gltf_node.camera do
      nil ->
        node

      camera_index ->
        case camera_lookup do
          %{^camera_index => eagl_camera} ->
            Node.set_camera(node, eagl_camera)

          _ ->
            node
        end
    end
  end

  @doc """
  Convert a glTF camera to EAGL.Camera, using the node's world matrix for position and orientation.

  glTF cameras look down -Z in node local space. The view matrix is the inverse of the
  node world matrix. We extract position (eye) and target (eye + forward) from the
  world matrix.
  """
  @spec gltf_camera_to_eagl(GLTF.Camera.t(), EAGL.Math.mat4()) :: Camera.t()
  def gltf_camera_to_eagl(%GLTF.Camera{type: type} = gltf_camera, node_world_matrix) do
    # Extract position and forward from world matrix
    # Position = translation (4th column): m12, m13, m14
    # Forward = -Z axis = negated 3rd column: -m8, -m9, -m10
    [{_m0, _m1, _m2, _m3, _m4, _m5, _m6, _m7, m8, m9, m10, _m11, m12, m13, m14, _m15}] =
      node_world_matrix

    position = vec3(m12, m13, m14)
    forward = vec3(-m8, -m9, -m10)
    target = vec_add(position, forward)

    base_opts = [
      position: position,
      target: target,
      up: vec3(0.0, 1.0, 0.0)
    ]

    case type do
      "perspective" ->
        perspective_to_eagl(gltf_camera, base_opts)

      "orthographic" ->
        orthographic_to_eagl(gltf_camera, base_opts)

      :perspective ->
        perspective_to_eagl(gltf_camera, base_opts)

      :orthographic ->
        orthographic_to_eagl(gltf_camera, base_opts)

      _ ->
        # Default to perspective
        perspective_to_eagl(gltf_camera, base_opts)
    end
  end

  defp perspective_to_eagl(%GLTF.Camera{perspective: p}, base_opts) when not is_nil(p) do
    yfov = p.yfov
    znear = p.znear
    zfar = p.zfar
    zfar = if zfar == nil, do: 1.0e6, else: zfar

    Camera.new(
      base_opts ++
        [
          type: :perspective,
          yfov: yfov,
          aspect_ratio: p.aspect_ratio,
          znear: znear,
          zfar: zfar
        ]
    )
  end

  defp perspective_to_eagl(_gltf_camera, base_opts) do
    Camera.new(base_opts ++ [type: :perspective, yfov: :math.pi() / 4, znear: 0.1, zfar: 1000.0])
  end

  defp orthographic_to_eagl(%GLTF.Camera{orthographic: o}, base_opts) when not is_nil(o) do
    Camera.new(
      base_opts ++
        [
          type: :orthographic,
          xmag: o.xmag,
          ymag: o.ymag,
          znear: o.znear,
          zfar: o.zfar
        ]
    )
  end

  defp orthographic_to_eagl(_gltf_camera, base_opts) do
    Camera.new(
      base_opts ++
        [
          type: :orthographic,
          xmag: 1.0,
          ymag: 1.0,
          znear: 0.1,
          zfar: 1000.0
        ]
    )
  end

  @doc """
  Convert a complete glTF asset to an EAGL.Scene.

  This creates a full scene graph with all nodes, meshes, and transforms.
  """
  @spec to_scene(GLTF.t(), GLTF.DataStore.t(), keyword()) ::
          {:ok, {Scene.t(), [Node.t()]}} | {:error, String.t()}
  def to_scene(%GLTF{} = gltf, data_store, opts \\ []) do
    material_lookup = build_material_lookup(gltf)
    light_lookup = build_light_lookup(gltf)

    with {:ok, mesh_lookup} <- create_mesh_lookup(gltf, data_store, opts),
         {:ok, node_lookup} <-
           create_node_lookup(gltf, mesh_lookup, material_lookup, light_lookup),
         {:ok, scene} <- build_scene_graph(gltf, node_lookup, opts) do
      all_nodes = Map.values(node_lookup)
      {:ok, {scene, all_nodes}}
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

  @doc """
  Extract vertex data from a GLTF primitive into a map ready for interleaving.

  Returns `{:ok, vertex_data}` where vertex_data contains:
  - `:position` - binary position data (required)
  - `"NORMAL"` - binary normal data (if present)
  - `"TEXCOORD_0"` - binary texcoord data (if present)
  - `:indices` - binary index data (if present)
  - `:index_component_type` - GL constant for index type (if indices present)
  """
  @spec extract_vertex_data(GLTF.t(), GLTF.DataStore.t(), GLTF.Mesh.Primitive.t()) ::
          {:ok, map()} | {:error, String.t()}
  def extract_vertex_data(gltf, data_store, primitive) do
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

  defp build_vertex_data(gltf, data_store, primitive, {pos_idx, pos_data}) do
    # Start with position data
    vertex_data = %{
      position: pos_data,
      attributes: [Buffer.position_attribute()],
      indices: nil
    }

    # Extract bounds from POSITION accessor for Scene.bounds (used by fit_to_scene)
    vertex_data =
      case Enum.at(gltf.accessors || [], pos_idx) do
        %{min: [min_x, min_y, min_z], max: [max_x, max_y, max_z]} ->
          Map.put(vertex_data, :bounds, {{min_x, min_y, min_z}, {max_x, max_y, max_z}})

        _ ->
          vertex_data
      end

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

    # Add indices if present, tracking the component type for correct parsing
    vertex_data =
      case primitive.indices do
        nil ->
          vertex_data

        indices_accessor_idx ->
          accessor = Enum.at(gltf.accessors, indices_accessor_idx)

          case GLTF.get_accessor_data(gltf, data_store, indices_accessor_idx) do
            {:ok, indices_data} ->
              vertex_data
              |> Map.put(:indices, indices_data)
              |> Map.put(:index_component_type, accessor.component_type)

            _ ->
              vertex_data
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

  defp create_vao_from_vertex_data(vertex_data, _opts) do
    with {:ok, vertices} <- interleave_vertex_data(vertex_data),
         {:ok, attributes} <- get_vertex_attributes(vertex_data) do
      base_bounds = vertex_data[:bounds]

      case vertex_data.indices do
        nil ->
          {vao, vbo} = Buffer.create_vertex_array(vertices, attributes)
          vertex_count = div(length(vertices), total_attribute_size(attributes))
          mesh = %{vao: vao, vbo: vbo, vertex_count: vertex_count}
          {:ok, maybe_add_bounds(mesh, base_bounds)}

        indices_data ->
          component_type = Map.get(vertex_data, :index_component_type, @gl_unsigned_int)

          case binary_to_index_list(indices_data, component_type) do
            {:ok, index_list} ->
              {vao, vbo, ebo} = Buffer.create_indexed_array(vertices, index_list, attributes)

              mesh = %{
                vao: vao,
                vbo: vbo,
                ebo: ebo,
                index_count: length(index_list),
                index_type: @gl_unsigned_int
              }

              {:ok, maybe_add_bounds(mesh, base_bounds)}

            {:error, reason} ->
              {:error, reason}
          end
      end
    end
  end

  defp maybe_add_bounds(mesh, nil), do: mesh
  defp maybe_add_bounds(mesh, bounds), do: Map.put(mesh, :bounds, bounds)

  defp create_mesh_lookup(gltf, data_store, opts) do
    case gltf.meshes do
      nil ->
        {:ok, %{}}

      meshes ->
        mesh_data =
          meshes
          |> Enum.with_index()
          |> Enum.map(fn {_mesh, mesh_index} ->
            case primitive_to_vao(gltf, data_store, mesh_index, 0, opts) do
              {:ok, vao_data} ->
                {mesh_index, vao_data}

              {:error, _reason} ->
                {mesh_index, nil}
            end
          end)
          |> Enum.into(%{})

        {:ok, mesh_data}
    end
  end

  defp create_node_lookup(gltf, mesh_lookup, material_lookup, light_lookup) do
    case gltf.nodes do
      nil ->
        {:ok, %{}}

      nodes ->
        world_matrices = compute_gltf_world_matrices(gltf)
        camera_lookup = build_camera_lookup(gltf, world_matrices)

        node_data =
          nodes
          |> Enum.with_index()
          |> Enum.map(fn {node, index} ->
            eagl_node = node_to_eagl_node(node, mesh_lookup, index, camera_lookup)

            eagl_node =
              case node.mesh do
                nil -> eagl_node
                mesh_idx -> apply_mesh_material(eagl_node, gltf, mesh_idx, material_lookup)
              end

            eagl_node = maybe_apply_gltf_light(eagl_node, node, light_lookup)

            {index, eagl_node}
          end)
          |> Enum.into(%{})

        # Establish parent-child relationships bottom-up so children
        # have their subtrees resolved before being added to parents
        node_data_with_children =
          nodes
          |> Enum.with_index()
          |> Enum.reverse()
          |> Enum.reduce(node_data, fn {gltf_node, parent_index}, acc_node_data ->
            case gltf_node.children do
              nil ->
                acc_node_data

              children when is_list(children) ->
                parent_node = Map.get(acc_node_data, parent_index)

                updated_parent =
                  Enum.reduce(children, parent_node, fn child_index, parent_acc ->
                    case Map.get(acc_node_data, child_index) do
                      nil -> parent_acc
                      child_node -> Node.add_child(parent_acc, child_node)
                    end
                  end)

                Map.put(acc_node_data, parent_index, updated_parent)
            end
          end)

        {:ok, node_data_with_children}
    end
  end

  defp build_material_lookup(%GLTF{materials: nil}), do: %{}

  defp build_material_lookup(%GLTF{materials: materials}) do
    materials
    |> Enum.with_index()
    |> Enum.map(fn {mat, index} -> {index, gltf_material_to_pbr_uniforms(mat)} end)
    |> Enum.into(%{})
  end

  defp gltf_material_to_pbr_uniforms(%GLTF.Material{} = mat) do
    pbr = mat.pbr_metallic_roughness

    base_color =
      case pbr && pbr.base_color_factor do
        [r, g, b | _] -> [{r * 1.0, g * 1.0, b * 1.0}]
        _ -> [{1.0, 1.0, 1.0}]
      end

    emissive =
      case mat.emissive_factor do
        [er, eg, eb | _] -> [{er * 1.0, eg * 1.0, eb * 1.0}]
        _ -> [{0.0, 0.0, 0.0}]
      end

    [
      "material.baseColor": base_color,
      "material.metallic": ((pbr && pbr.metallic_factor) || 1.0) * 1.0,
      "material.roughness": ((pbr && pbr.roughness_factor) || 1.0) * 1.0,
      "material.emissive": emissive
    ]
  end

  defp apply_mesh_material(eagl_node, gltf, mesh_idx, material_lookup) do
    case Enum.at(gltf.meshes || [], mesh_idx) do
      nil ->
        eagl_node

      mesh ->
        case List.first(mesh.primitives || []) do
          nil ->
            eagl_node

          prim ->
            case Map.get(material_lookup, prim.material) do
              nil -> eagl_node
              uniforms -> %{eagl_node | material_uniforms: uniforms}
            end
        end
    end
  end

  defp build_light_lookup(%GLTF{extensions: nil}), do: %{}

  defp build_light_lookup(%GLTF{extensions: extensions}) do
    case get_in(extensions, ["KHR_lights_punctual", "lights"]) do
      nil ->
        %{}

      lights when is_list(lights) ->
        lights
        |> Enum.with_index()
        |> Enum.map(fn {light, index} ->
          type =
            case light["type"] do
              "directional" -> :directional
              "point" -> :point
              "spot" -> :spot
              _ -> :point
            end

          color =
            case light["color"] do
              [r, g, b | _] -> {r * 1.0, g * 1.0, b * 1.0}
              _ -> {1.0, 1.0, 1.0}
            end

          spot = light["spot"] || %{}

          data = %{
            type: type,
            color: color,
            intensity: (light["intensity"] || 1.0) * 1.0,
            range: (light["range"] || 0.0) * 1.0,
            inner_cone_angle: (spot["innerConeAngle"] || 0.0) * 1.0,
            outer_cone_angle: (spot["outerConeAngle"] || 0.7854) * 1.0
          }

          {index, data}
        end)
        |> Enum.into(%{})

      _ ->
        %{}
    end
  end

  defp maybe_apply_gltf_light(eagl_node, gltf_node, light_lookup) do
    case get_in(gltf_node.extensions || %{}, ["KHR_lights_punctual", "light"]) do
      nil ->
        eagl_node

      light_index when is_integer(light_index) ->
        case Map.get(light_lookup, light_index) do
          nil -> eagl_node
          light_data -> %{eagl_node | light: light_data}
        end

      _ ->
        eagl_node
    end
  end

  defp compute_gltf_world_matrices(%GLTF{nodes: nil}), do: %{}

  defp compute_gltf_world_matrices(%GLTF{nodes: nodes}) do
    parent_map = build_parent_map(nodes)
    local_matrices = Enum.map(nodes, &gltf_node_local_matrix/1)
    traverse_order = topological_sort(nodes, parent_map)

    Enum.reduce(traverse_order, %{}, fn node_index, acc ->
      local = Enum.at(local_matrices, node_index)

      world =
        case Map.get(parent_map, node_index) do
          nil ->
            local

          parent_index ->
            parent_world = Map.get(acc, parent_index)
            mat4_mul(parent_world, local)
        end

      Map.put(acc, node_index, world)
    end)
  end

  defp build_parent_map(nodes) do
    nodes
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {gltf_node, parent_index}, acc ->
      case gltf_node.children do
        nil ->
          acc

        children when is_list(children) ->
          Enum.reduce(children, acc, fn child_index, a ->
            Map.put(a, child_index, parent_index)
          end)
      end
    end)
  end

  defp topological_sort(nodes, parent_map) do
    n = length(nodes)

    children =
      Enum.reduce(parent_map, %{}, fn {child, parent}, acc ->
        Map.update(acc, parent, [child], fn existing -> [child | existing] end)
      end)

    roots = Enum.filter(0..(n - 1), &(!Map.has_key?(parent_map, &1)))

    visit = fn visit, i, acc ->
      child_list = Map.get(children, i, [])
      acc_after_children = Enum.reduce(child_list, acc, fn c, a -> visit.(visit, c, a) end)
      [i | acc_after_children]
    end

    result =
      Enum.reduce(roots, [], fn root, acc ->
        visit.(visit, root, acc)
      end)
      |> List.flatten()
      |> Enum.uniq()

    # Keep parent-before-child order (visit yields [parent | children])
    # so world matrices are computed correctly
    result
  end

  defp gltf_node_local_matrix(%GLTF.Node{matrix: nil} = gltf_node) do
    # TRS
    t = list_to_vec3(gltf_node.translation || [0.0, 0.0, 0.0])
    r = list_to_quat(gltf_node.rotation || [0.0, 0.0, 0.0, 1.0])
    s = list_to_vec3(gltf_node.scale || [1.0, 1.0, 1.0])
    mat4_mul(mat4_mul(mat4_translate(t), quat_to_mat4(r)), mat4_scale(s))
  end

  defp gltf_node_local_matrix(%GLTF.Node{matrix: matrix}) when is_list(matrix) do
    matrix
  end

  defp build_camera_lookup(%GLTF{cameras: nil}, _world_matrices), do: %{}
  defp build_camera_lookup(%GLTF{nodes: nil}, _world_matrices), do: %{}

  defp build_camera_lookup(%GLTF{cameras: cameras, nodes: nodes}, world_matrices) do
    nodes
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {gltf_node, node_index}, acc ->
      case gltf_node.camera do
        nil ->
          acc

        camera_index ->
          gltf_camera = Enum.at(cameras, camera_index)
          world_matrix = Map.get(world_matrices, node_index)

          if gltf_camera && world_matrix do
            eagl_camera = gltf_camera_to_eagl(gltf_camera, world_matrix)
            Map.put(acc, node_index, eagl_camera)
          else
            acc
          end
      end
    end)
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

  @doc """
  Interleave vertex attributes into a flat list of floats for GPU upload.

  Takes a vertex_data map with binary attribute data and produces an interleaved
  list matching the layout: position | normal (if present) | texcoord (if present).

  Texture V coordinates are flipped (1.0 - v) to convert from GLTF convention
  (V=0 at top) to OpenGL convention (V=0 at bottom).
  """
  @spec interleave_vertex_data(map()) :: {:ok, [float()]} | {:error, String.t()}
  def interleave_vertex_data(vertex_data) do
    case binary_to_float_list(vertex_data.position) do
      {:ok, positions} ->
        vertex_count = div(length(positions), 3)

        normals = extract_attribute_data(vertex_data, "NORMAL", vertex_count, 3, [0.0, 0.0, 1.0])
        texcoords = extract_attribute_data(vertex_data, "TEXCOORD_0", vertex_count, 2, [0.0, 0.0])

        # Convert to tuples for O(1) indexed access instead of O(n) Enum.at
        pos_t = List.to_tuple(positions)
        norm_t = List.to_tuple(normals)
        tex_t = List.to_tuple(texcoords)

        has_normals = Map.has_key?(vertex_data, "NORMAL")
        has_texcoords = Map.has_key?(vertex_data, "TEXCOORD_0")

        vertices =
          for i <- 0..(vertex_count - 1) do
            pos_idx = i * 3
            tex_idx = i * 2

            vertex = [
              elem(pos_t, pos_idx),
              elem(pos_t, pos_idx + 1),
              elem(pos_t, pos_idx + 2)
            ]

            vertex =
              if has_normals do
                vertex ++
                  [
                    elem(norm_t, pos_idx),
                    elem(norm_t, pos_idx + 1),
                    elem(norm_t, pos_idx + 2)
                  ]
              else
                vertex
              end

            vertex =
              if has_texcoords do
                vertex ++
                  [
                    elem(tex_t, tex_idx),
                    1.0 - elem(tex_t, tex_idx + 1)
                  ]
              else
                vertex
              end

            vertex
          end

        {:ok, List.flatten(vertices)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Extract attribute data with defaults
  defp extract_attribute_data(
         vertex_data,
         attr_name,
         vertex_count,
         _component_count,
         default_value
       ) do
    case Map.get(vertex_data, attr_name) do
      nil ->
        # Generate default values
        List.duplicate(default_value, vertex_count) |> List.flatten()

      attr_data ->
        case binary_to_float_list(attr_data) do
          {:ok, floats} -> floats
          _ -> List.duplicate(default_value, vertex_count) |> List.flatten()
        end
    end
  end

  @doc """
  Build the EAGL vertex attribute list based on which attributes are present.

  Uses `EAGL.Buffer.vertex_attributes/1` for automatic stride/offset calculation.
  The layout order is: position (0), normal (1), texture_coordinate (2).
  This matches GLTF convention and produces sequential shader locations.
  """
  @spec get_vertex_attributes(map()) :: {:ok, [EAGL.Buffer.vertex_attribute()]}
  def get_vertex_attributes(vertex_data) do
    # Position is always required (location 0)
    attr_names = [:position]

    # Add normal if available (location 1) - matches web demo layout
    attr_names =
      if Map.has_key?(vertex_data, "NORMAL"), do: attr_names ++ [:normal], else: attr_names

    # Add texture coordinates if available (location 2) - matches web demo layout
    attr_names =
      if Map.has_key?(vertex_data, "TEXCOORD_0"),
        do: attr_names ++ [:texture_coordinate],
        else: attr_names

    attributes = Buffer.vertex_attributes(attr_names)
    {:ok, attributes}
  end

  # Calculate total size of all attributes in floats
  defp total_attribute_size(attributes) do
    Enum.reduce(attributes, 0, fn attr, acc ->
      acc + attr.size
    end)
  end

  @doc """
  Parse binary data as a list of little-endian float32 values.

  GLTF spec requires little-endian byte order for all binary data.
  """
  @spec binary_to_float_list(binary()) :: {:ok, [float()]} | {:error, String.t()}
  def binary_to_float_list(binary) when is_binary(binary) do
    floats = for <<f::little-float-32 <- binary>>, do: f
    {:ok, floats}
  end

  def binary_to_float_list(_), do: {:error, "Expected binary data for float parsing"}

  @doc """
  Parse binary index data according to the accessor's component type.

  GLTF indices can be UNSIGNED_BYTE (5121), UNSIGNED_SHORT (5123),
  or UNSIGNED_INT (5125). The component type determines how to interpret
  the binary data.
  """
  @spec binary_to_index_list(binary(), non_neg_integer()) ::
          {:ok, [non_neg_integer()]} | {:error, String.t()}
  def binary_to_index_list(binary, component_type) when is_binary(binary) do
    case component_type do
      @gl_unsigned_byte ->
        {:ok, for(<<i::unsigned-8 <- binary>>, do: i)}

      @gl_unsigned_short ->
        {:ok, for(<<i::little-unsigned-16 <- binary>>, do: i)}

      @gl_unsigned_int ->
        {:ok, for(<<i::little-unsigned-32 <- binary>>, do: i)}

      other ->
        {:error, "Unsupported index component type: #{other}"}
    end
  end

  def binary_to_index_list(_, _), do: {:error, "Expected binary data for index parsing"}

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
    output_accessor = Enum.at(gltf.accessors, sampler.output)
    component_count = GLTF.Accessor.type_component_count(output_accessor.type)

    with {:ok, input_data} <- GLTF.get_accessor_data(gltf, data_store, sampler.input),
         {:ok, output_data} <- GLTF.get_accessor_data(gltf, data_store, sampler.output),
         {:ok, input_times} <- binary_to_float_list(input_data),
         {:ok, output_values} <-
           convert_output_values(output_data, sampler.interpolation, component_count) do
      interpolation = convert_interpolation_mode(sampler.interpolation)

      eagl_sampler = EAGL.Animation.Sampler.new(input_times, output_values, interpolation)
      {:ok, eagl_sampler}
    end
  end

  defp convert_output_values(binary_data, interpolation, component_count) do
    with {:ok, floats} <- binary_to_float_list(binary_data) do
      case interpolation do
        :cubicspline ->
          {:ok, extract_cubic_spline_values(floats, component_count)}

        _ ->
          {:ok, group_floats_by_components(floats, component_count)}
      end
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
