defmodule EAGL.Scene do
  import EAGL.Math
  import EAGL.Const

  @moduledoc """
  Scene graph management for hierarchical 3D scenes.

  EAGL.Scene provides a higher-level abstraction for managing complex 3D scenes
  with transform hierarchies, while building on EAGL's existing buffer and shader APIs.

  ## Design Philosophy

  This module extends EAGL's scope to support fundamental 3D concepts like scene graphs
  and transform hierarchies, as represented in industry standards like glTF. The APIs
  are designed to be composable with existing EAGL functionality.

  ## Usage

      # Create a scene with hierarchical nodes
      scene = Scene.new()

      # Root node (car body)
      car_node = Node.new(position: vec3(0, 0, 0), mesh: car_mesh)

      # Child nodes (wheels) with local transforms
      wheel1 = Node.new(position: vec3(-2, -1, 2), mesh: wheel_mesh)
      wheel2 = Node.new(position: vec3(2, -1, 2), mesh: wheel_mesh)

      Node.add_child(car_node, wheel1)
      Node.add_child(car_node, wheel2)
      Scene.add_root_node(scene, car_node)

      # Render with automatic transform hierarchy
      Scene.render(scene, view_matrix, projection_matrix)

  ## Backward Compatibility

  Scene graphs can contain meshes created with existing EAGL.Buffer APIs:

      # Use existing EAGL buffer creation
      {vao, vbo} = EAGL.Buffer.create_vertex_array(vertices, attributes)
      mesh = %{vao: vao, vertex_count: length(vertices) / 3}

      # Use in scene graph
      node = Node.new(mesh: mesh)

  ## glTF Integration

  This module provides the foundation for loading glTF scenes:

      {:ok, gltf} = GLTF.GLBLoader.parse("model.glb")
      {:ok, scene} = GLTF.EAGL.to_scene(gltf)
      Scene.render(scene, view_matrix, projection_matrix)
  """

  alias EAGL.Node
  alias EAGL.Camera
  alias EAGL.OrbitCamera
  import Bitwise
  import EAGL.Math
  use EAGL.Const

  defstruct [
    :root_nodes,
    :name
  ]

  @type t :: %__MODULE__{
          root_nodes: [Node.t()],
          name: String.t() | nil
        }

  @doc """
  Create a new empty scene.
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    %__MODULE__{
      root_nodes: [],
      name: Keyword.get(opts, :name)
    }
  end

  @doc """
  Add a root node to the scene.
  """
  @spec add_root_node(t(), Node.t()) :: t()
  def add_root_node(%__MODULE__{root_nodes: roots} = scene, %Node{} = node) do
    %{scene | root_nodes: [node | roots]}
  end

  @doc """
  Render the entire scene with transform hierarchy.

  This function traverses the scene graph and renders each mesh with its
  accumulated transform matrix.
  """
  @max_lights 8

  @spec render(t(), EAGL.Math.mat4(), EAGL.Math.mat4()) :: :ok
  def render(%__MODULE__{root_nodes: roots}, view_matrix, projection_matrix) do
    identity_matrix = mat4_identity()

    lights = collect_lights(roots, identity_matrix)

    Enum.each(roots, fn root_node ->
      render_node_recursive(root_node, identity_matrix, view_matrix, projection_matrix, lights)
    end)

    :ok
  end

  @doc """
  Compute the axis-aligned bounding box of the scene in world space.

  Traverses the scene graph and merges bounds from all nodes with meshes that
  have `:bounds` (e.g. from glTF conversion). Transforms local bounds by each
  node's world matrix, so the result reflects current animated state.

  Returns `{:ok, min_point, max_point}` as `{x, y, z}` tuples, or `:no_bounds`
  when no nodes contribute bounds.
  """
  @spec bounds(t()) ::
          {:ok, {float(), float(), float()}, {float(), float(), float()}} | :no_bounds
  def bounds(%__MODULE__{root_nodes: roots}) do
    identity = mat4_identity()
    acc = Enum.reduce(roots, nil, fn root, acc -> merge_bounds_recursive(root, identity, acc) end)

    case acc do
      nil -> :no_bounds
      {min_pt, max_pt} -> {:ok, min_pt, max_pt}
    end
  end

  defp merge_bounds_recursive(%Node{} = node, parent_transform, acc) do
    local = Node.get_local_transform_matrix(node)
    world = mat4_mul(parent_transform, local)

    acc =
      case Node.get_mesh(node) do
        %{bounds: {{min_x, min_y, min_z}, {max_x, max_y, max_z}}} ->
          corners = [
            [{min_x, min_y, min_z}],
            [{max_x, min_y, min_z}],
            [{min_x, max_y, min_z}],
            [{max_x, max_y, min_z}],
            [{min_x, min_y, max_z}],
            [{max_x, min_y, max_z}],
            [{min_x, max_y, max_z}],
            [{max_x, max_y, max_z}]
          ]

          transformed =
            Enum.map(corners, fn v -> mat4_transform_point(world, v) end)
            |> Enum.flat_map(fn [{x, y, z}] -> [{x, y, z}] end)

          [{fx, fy, fz} | rest] = transformed

          {t_min_x, t_min_y, t_min_z} =
            Enum.reduce(rest, {fx, fy, fz}, fn {x, y, z}, {ax, ay, az} ->
              {min(ax, x), min(ay, y), min(az, z)}
            end)

          {t_max_x, t_max_y, t_max_z} =
            Enum.reduce(rest, {fx, fy, fz}, fn {x, y, z}, {ax, ay, az} ->
              {max(ax, x), max(ay, y), max(az, z)}
            end)

          merge_aabb(acc, {{t_min_x, t_min_y, t_min_z}, {t_max_x, t_max_y, t_max_z}})

        _ ->
          acc
      end

    Enum.reduce(Node.get_children(node), acc, fn child, child_acc ->
      merge_bounds_recursive(child, world, child_acc)
    end)
  end

  defp merge_aabb(nil, b), do: b

  defp merge_aabb(
         {{a_min_x, a_min_y, a_min_z}, {a_max_x, a_max_y, a_max_z}},
         {{b_min_x, b_min_y, b_min_z}, {b_max_x, b_max_y, b_max_z}}
       ) do
    {{min(a_min_x, b_min_x), min(a_min_y, b_min_y), min(a_min_z, b_min_z)},
     {max(a_max_x, b_max_x), max(a_max_y, b_max_y), max(a_max_z, b_max_z)}}
  end

  @doc """
  Update all animations in the scene.
  """
  @spec update(t(), float()) :: t()
  def update(%__MODULE__{root_nodes: roots} = scene, delta_time) do
    updated_roots =
      Enum.map(roots, fn node ->
        Node.update_animations(node, delta_time)
      end)

    %{scene | root_nodes: updated_roots}
  end

  @doc """
  Get all nodes in the scene (flattened).
  """
  @spec get_all_nodes(t()) :: [Node.t()]
  def get_all_nodes(%__MODULE__{root_nodes: roots}) do
    Enum.flat_map(roots, &Node.get_all_descendants/1)
  end

  @doc """
  Cast a ray against the scene and return hits in order.

  Uses `EAGL.Spatial` for ray–AABB traversal. Returns `[{node, distance}, ...]`
  sorted by distance (closest first). Distance is along the ray from origin.
  Direction should be normalized.

  For multiple raycasts, build `EAGL.Spatial.new(scene)` once and call
  `EAGL.Spatial.raycast/2` directly.

  ## Parameters

  - `scene` - The scene to raycast against
  - `ray` - `{origin, direction}` in `EAGL.Math.ray_new/2` format

  ## Returns

  - `[]` when no hits or no nodes have bounds
  - `[{node, distance}, ...]` sorted by distance
  """
  @spec raycast(t(), {EAGL.Math.vec3(), EAGL.Math.vec3()}) :: [{Node.t(), float()}]
  def raycast(%__MODULE__{} = scene, ray) do
    spatial = EAGL.Spatial.new(scene)
    EAGL.Spatial.raycast(spatial, ray)
  end

  @doc """
  Get all nodes with meshes that have bounds, paired with their world-space AABB.

  Returns `[{node, aabb}, ...]` where aabb is `{{min_x, min_y, min_z}, {max_x, max_y, max_z}}`.
  Used by `EAGL.Spatial` for ray-based queries.
  """
  @spec get_nodes_with_bounds(t()) ::
          [{Node.t(), {{float(), float(), float()}, {float(), float(), float()}}}]
  def get_nodes_with_bounds(%__MODULE__{root_nodes: roots}) do
    identity = mat4_identity()
    collect_nodes_with_bounds(roots, identity)
  end

  defp collect_nodes_with_bounds(nodes, parent_transform) do
    Enum.flat_map(nodes, fn node ->
      local = Node.get_local_transform_matrix(node)
      world = mat4_mul(parent_transform, local)

      acc =
        case Node.get_mesh(node) do
          %{bounds: {{min_x, min_y, min_z}, {max_x, max_y, max_z}}} ->
            corners = [
              [{min_x, min_y, min_z}],
              [{max_x, min_y, min_z}],
              [{min_x, max_y, min_z}],
              [{max_x, max_y, min_z}],
              [{min_x, min_y, max_z}],
              [{max_x, min_y, max_z}],
              [{min_x, max_y, max_z}],
              [{max_x, max_y, max_z}]
            ]

            transformed =
              Enum.map(corners, fn v -> mat4_transform_point(world, v) end)
              |> Enum.flat_map(fn [{x, y, z}] -> [{x, y, z}] end)

            [{fx, fy, fz} | rest] = transformed

            {t_min_x, t_min_y, t_min_z} =
              Enum.reduce(rest, {fx, fy, fz}, fn {x, y, z}, {ax, ay, az} ->
                {min(ax, x), min(ay, y), min(az, z)}
              end)

            {t_max_x, t_max_y, t_max_z} =
              Enum.reduce(rest, {fx, fy, fz}, fn {x, y, z}, {ax, ay, az} ->
                {max(ax, x), max(ay, y), max(az, z)}
              end)

            world_aabb = {{t_min_x, t_min_y, t_min_z}, {t_max_x, t_max_y, t_max_z}}
            [{node, world_aabb}]

          _ ->
            []
        end

      child_acc = collect_nodes_with_bounds(Node.get_children(node), world)
      acc ++ child_acc
    end)
  end

  @doc """
  Find a node in the scene by ID.

  Searches recursively through the scene graph to find a node with the given ID.
  """
  @spec find_node(t(), String.t() | atom()) :: Node.t() | nil
  def find_node(%__MODULE__{root_nodes: root_nodes}, node_id) do
    Enum.find_value(root_nodes, fn node ->
      find_node_recursive(node, node_id)
    end)
  end

  @doc """
  Update a node in the scene.

  Replaces the node with the given ID with the updated node.
  """
  @spec update_node(t(), String.t() | atom(), Node.t()) :: t()
  def update_node(%__MODULE__{} = scene, node_id, updated_node) do
    new_root_nodes =
      Enum.map(scene.root_nodes, fn node ->
        update_node_recursive(node, node_id, updated_node)
      end)

    %{scene | root_nodes: new_root_nodes}
  end

  @doc """
  Render the pick buffer to the current framebuffer for debugging.

  Performs the same pick pass as `pick/5` but displays the result as a fullscreen
  image instead of reading a pixel. Node IDs are amplified so they're visible
  (background=black, node 1=red, node 2=green-ish, etc.). Press 'p' in examples
  to toggle this view.

  Call after setting up the viewport. Uses the current framebuffer.
  """
  @spec visualize_pick_buffer(
          t(),
          Camera.t() | OrbitCamera.t(),
          {number(), number(), number(), number()}
        ) ::
          :ok
  def visualize_pick_buffer(%__MODULE__{root_nodes: roots}, camera, viewport) do
    {_vp_x, _vp_y, vp_w, vp_h} = viewport

    if vp_w >= 1 and vp_h >= 1 do
      view_matrix = get_view_matrix(camera)
      aspect = vp_w / max(vp_h, 1)
      proj_matrix = get_projection_matrix(camera, aspect)
      nodes_with_meshes = collect_nodes_with_meshes(roots, mat4_identity())

      if nodes_with_meshes != [] do
        do_visualize_pick_buffer(nodes_with_meshes, view_matrix, proj_matrix, viewport)
      end
    end

    :ok
  end

  @doc """
  Pick a node at screen coordinates using GPU object-ID rendering.

  Renders the scene to an offscreen framebuffer with each mesh outputting its
  node index as a color. Reads the pixel at (screen_x, screen_y) and returns
  the corresponding node.

  ## Parameters

  - `scene` - The scene to pick from
  - `camera` - EAGL.Camera or EAGL.OrbitCamera for view/projection
  - `viewport` - `{x, y, width, height}` in pixels
  - `screen_x`, `screen_y` - Screen coordinates (top-left origin, e.g. from mouse)

  ## Returns

  - `{:ok, node}` when a node with a mesh is picked
  - `nil` when picking empty space or no nodes have meshes

  ## Example

      case Scene.pick(scene, orbit, {0, 0, 1024, 768}, mouse_x, mouse_y) do
        {:ok, node} -> IO.puts("Picked: \#{Node.get_id(node)}")
        nil -> :ok
      end
  """
  @spec pick(
          t(),
          Camera.t() | OrbitCamera.t(),
          {number(), number(), number(), number()},
          number(),
          number()
        ) ::
          {:ok, Node.t()} | nil
  def pick(%__MODULE__{root_nodes: roots}, camera, viewport, screen_x, screen_y) do
    {_vp_x, _vp_y, vp_w, vp_h} = viewport

    if vp_w < 1 or vp_h < 1 do
      nil
    else
      view_matrix = get_view_matrix(camera)
      aspect = vp_w / max(vp_h, 1)
      proj_matrix = get_projection_matrix(camera, aspect)

      nodes_with_meshes = collect_nodes_with_meshes(roots, mat4_identity())

      if nodes_with_meshes == [] do
        nil
      else
        case do_pick_pass(
               nodes_with_meshes,
               view_matrix,
               proj_matrix,
               viewport,
               screen_x,
               screen_y
             ) do
          nil ->
            nil

          idx when is_integer(idx) and idx >= 0 ->
            case Enum.at(nodes_with_meshes, idx) do
              {node, _world} -> {:ok, node}
              _ -> nil
            end
        end
      end
    end
  end

  defp get_view_matrix(%Camera{} = cam), do: Camera.get_view_matrix(cam)
  defp get_view_matrix(%OrbitCamera{} = orbit), do: OrbitCamera.get_view_matrix(orbit)

  defp get_projection_matrix(%Camera{} = cam, aspect),
    do: Camera.get_projection_matrix(cam, aspect)

  defp get_projection_matrix(%OrbitCamera{} = orbit, aspect),
    do: OrbitCamera.get_projection_matrix(orbit, aspect)

  defp collect_nodes_with_meshes(nodes, parent_transform) do
    Enum.flat_map(nodes, fn node ->
      local = Node.get_local_transform_matrix(node)
      world = mat4_mul(parent_transform, local)

      acc =
        case Node.get_mesh(node) do
          nil -> []
          _mesh -> [{node, world}]
        end

      child_acc = collect_nodes_with_meshes(Node.get_children(node), world)
      acc ++ child_acc
    end)
  end

  defp do_visualize_pick_buffer(nodes, view_matrix, proj_matrix, {_vp_x, _vp_y, vp_w, vp_h}) do
    program = get_pick_program()
    prev_fbo = :gl.getIntegerv(@gl_framebuffer_binding) |> List.first()
    prev_viewport = :gl.getIntegerv(@gl_viewport)

    {fbo, tex, rbo} = create_pick_fbo(trunc(vp_w), trunc(vp_h))

    try do
      :gl.bindFramebuffer(@gl_framebuffer, fbo)
      :gl.viewport(0, 0, trunc(vp_w), trunc(vp_h))
      :gl.clearColor(0.0, 0.0, 0.0, 0.0)
      :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)
      :gl.enable(@gl_depth_test)

      :gl.useProgram(program)

      Enum.each(Enum.with_index(nodes), fn {{node, world}, idx} ->
        mesh = Node.get_mesh(node)
        render_mesh_pick(mesh, world, view_matrix, proj_matrix, program, idx)
      end)

      :gl.finish()
    after
      :gl.bindFramebuffer(@gl_framebuffer, prev_fbo)
      [vx, vy, vw, vh] = Enum.take(prev_viewport, 4)
      :gl.viewport(vx, vy, vw, vh)
    end

    # Display pick texture as fullscreen quad
    {display_prog, quad_vao} = get_pick_display_resources()
    :gl.disable(@gl_depth_test)
    :gl.useProgram(display_prog)
    :gl.activeTexture(@gl_texture0)
    :gl.bindTexture(@gl_texture_2d, tex)
    EAGL.Shader.set_uniform(display_prog, "pickTexture", 0)
    :gl.bindVertexArray(quad_vao)
    :gl.drawArrays(@gl_triangle_strip, 0, 4)
    :gl.bindTexture(@gl_texture_2d, 0)
    :gl.bindVertexArray(0)

    delete_pick_fbo(fbo, tex, rbo)
  end

  defp get_pick_display_resources do
    case Process.get(:eagl_pick_display) do
      nil ->
        {:ok, vs} = EAGL.Shader.create_shader(@gl_vertex_shader, "pick_debug_vertex.glsl")
        {:ok, fs} = EAGL.Shader.create_shader(@gl_fragment_shader, "pick_debug_fragment.glsl")
        {:ok, prog} = EAGL.Shader.create_attach_link([vs, fs])

        # Fullscreen quad: pos (x,y) + texcoord (u,v)
        # (-1,-1),(1,-1),(-1,1),(1,1) with texcoords (0,0),(1,0),(0,1),(1,1)
        vertices = [
          -1.0,
          -1.0,
          0.0,
          0.0,
          1.0,
          -1.0,
          1.0,
          0.0,
          -1.0,
          1.0,
          0.0,
          1.0,
          1.0,
          1.0,
          1.0,
          1.0
        ]

        attrs = [
          EAGL.Buffer.vertex_attribute(location: 0, size: 2, type: :float, stride: 16, offset: 0),
          EAGL.Buffer.vertex_attribute(location: 1, size: 2, type: :float, stride: 16, offset: 8)
        ]

        {vao, _vbo} = EAGL.Buffer.create_vertex_array(vertices, attrs)
        Process.put(:eagl_pick_display, {prog, vao})
        {prog, vao}

      {prog, vao} ->
        {prog, vao}
    end
  end

  defp do_pick_pass(nodes, view_matrix, proj_matrix, {vp_x, vp_y, vp_w, vp_h}, screen_x, screen_y) do
    program = get_pick_program()
    prev_fbo = :gl.getIntegerv(@gl_framebuffer_binding) |> List.first()
    prev_viewport = :gl.getIntegerv(@gl_viewport)

    {fbo, tex, rbo} = create_pick_fbo(trunc(vp_w), trunc(vp_h))

    try do
      :gl.bindFramebuffer(@gl_framebuffer, fbo)
      :gl.viewport(0, 0, trunc(vp_w), trunc(vp_h))
      :gl.clearColor(0.0, 0.0, 0.0, 0.0)
      :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)
      :gl.enable(@gl_depth_test)

      :gl.useProgram(program)

      Enum.each(Enum.with_index(nodes), fn {{node, world}, idx} ->
        mesh = Node.get_mesh(node)
        render_mesh_pick(mesh, world, view_matrix, proj_matrix, program, idx)
      end)

      gl_x = trunc(screen_x - vp_x)
      gl_y = trunc(vp_h - 1 - (screen_y - vp_y))

      result =
        if gl_x < 0 or gl_x >= vp_w or gl_y < 0 or gl_y >= vp_h do
          nil
        else
          :gl.finish()
          :gl.pixelStorei(@gl_pack_alignment, 1)
          width = trunc(vp_w)
          height = trunc(vp_h)
          size = width * height * 4
          pixel_data = <<0::size(size)-unit(8)>>
          :gl.bindTexture(@gl_texture_2d, tex)
          :gl.getTexImage(@gl_texture_2d, 0, @gl_rgba, @gl_unsigned_byte, pixel_data)
          :gl.bindTexture(@gl_texture_2d, 0)
          offset = (gl_y * width + gl_x) * 4
          <<_::binary-size(offset), r, g, b, _a, _::binary>> = pixel_data
          decode_pick_color(<<r, g, b, 255>>)
        end

      result
    after
      :gl.bindFramebuffer(@gl_framebuffer, prev_fbo)
      [vx, vy, vw, vh] = Enum.take(prev_viewport, 4)
      :gl.viewport(vx, vy, vw, vh)
      delete_pick_fbo(fbo, tex, rbo)
    end
  end

  defp get_pick_program do
    case Process.get(:eagl_pick_program) do
      nil ->
        {:ok, vs} = EAGL.Shader.create_shader(@gl_vertex_shader, "pick_vertex.glsl")
        {:ok, fs} = EAGL.Shader.create_shader(@gl_fragment_shader, "pick_fragment.glsl")
        {:ok, program} = EAGL.Shader.create_attach_link([vs, fs])
        Process.put(:eagl_pick_program, program)
        program

      program ->
        program
    end
  end

  defp create_pick_fbo(width, height) do
    [tex] = :gl.genTextures(1)
    :gl.bindTexture(@gl_texture_2d, tex)
    :gl.texParameteri(@gl_texture_2d, @gl_texture_min_filter, @gl_linear)
    :gl.texParameteri(@gl_texture_2d, @gl_texture_mag_filter, @gl_linear)
    pixel_data = <<0::size(width * height * 4)-unit(8)>>

    :gl.texImage2D(
      @gl_texture_2d,
      0,
      @gl_rgba8,
      width,
      height,
      0,
      @gl_rgba,
      @gl_unsigned_byte,
      pixel_data
    )

    [rbo] = :gl.genRenderbuffers(1)
    :gl.bindRenderbuffer(@gl_renderbuffer, rbo)
    :gl.renderbufferStorage(@gl_renderbuffer, @gl_depth_component24, width, height)

    [fbo] = :gl.genFramebuffers(1)
    :gl.bindFramebuffer(@gl_framebuffer, fbo)
    :gl.framebufferTexture2D(@gl_framebuffer, @gl_color_attachment0, @gl_texture_2d, tex, 0)
    :gl.framebufferRenderbuffer(@gl_framebuffer, @gl_depth_attachment, @gl_renderbuffer, rbo)

    status = :gl.checkFramebufferStatus(@gl_framebuffer)

    if status != @gl_framebuffer_complete do
      raise "Pick FBO incomplete: #{status}"
    end

    :gl.bindTexture(@gl_texture_2d, 0)
    :gl.bindRenderbuffer(@gl_renderbuffer, 0)

    {fbo, tex, rbo}
  end

  defp delete_pick_fbo(fbo, tex, rbo) do
    :gl.deleteFramebuffers([fbo])
    :gl.deleteTextures([tex])
    :gl.deleteRenderbuffers([rbo])
  end

  defp render_mesh_pick(mesh, model_matrix, view_matrix, projection_matrix, program, node_id) do
    case mesh do
      %{vao: vao, vertex_count: count} ->
        :gl.useProgram(program)
        EAGL.Shader.set_uniform(program, "model", model_matrix)
        EAGL.Shader.set_uniform(program, "view", view_matrix)
        EAGL.Shader.set_uniform(program, "projection", projection_matrix)
        EAGL.Shader.set_uniform(program, "nodeId", node_id + 1.0)
        :gl.bindVertexArray(vao)
        :gl.drawArrays(@gl_triangles, 0, count)

      %{vao: vao, index_count: count} ->
        index_type = Map.get(mesh, :index_type, @gl_unsigned_int)
        :gl.useProgram(program)
        EAGL.Shader.set_uniform(program, "model", model_matrix)
        EAGL.Shader.set_uniform(program, "view", view_matrix)
        EAGL.Shader.set_uniform(program, "projection", projection_matrix)
        EAGL.Shader.set_uniform(program, "nodeId", node_id + 1.0)
        :gl.bindVertexArray(vao)
        :gl.drawElements(@gl_triangles, count, index_type, 0)

      _ ->
        :ok
    end
  end

  defp decode_pick_color(<<r, g, b, _a>>) do
    id = r + g * 256 + b * 65536
    if id == 0, do: nil, else: id - 1
  end

  # Private functions

  defp find_node_recursive(%Node{} = node, target_id) do
    cond do
      Node.get_id(node) == target_id ->
        node

      true ->
        # Search children
        Enum.find_value(Node.get_children(node), fn child ->
          find_node_recursive(child, target_id)
        end)
    end
  end

  defp update_node_recursive(%Node{} = node, target_id, updated_node) do
    cond do
      Node.get_id(node) == target_id ->
        updated_node

      true ->
        # Update children recursively
        updated_children =
          Enum.map(Node.get_children(node), fn child ->
            update_node_recursive(child, target_id, updated_node)
          end)

        Node.set_children(node, updated_children)
    end
  end

  defp render_node_recursive(
         %Node{} = node,
         parent_transform,
         view_matrix,
         projection_matrix,
         lights
       ) do
    local_transform = Node.get_local_transform_matrix(node)
    world_transform = mat4_mul(parent_transform, local_transform)

    case Node.get_mesh(node) do
      nil ->
        :ok

      mesh ->
        render_mesh(
          mesh,
          node.material_uniforms,
          world_transform,
          view_matrix,
          projection_matrix,
          lights
        )
    end

    Enum.each(Node.get_children(node), fn child ->
      render_node_recursive(child, world_transform, view_matrix, projection_matrix, lights)
    end)
  end

  defp render_mesh(mesh, material_uniforms, model_matrix, view_matrix, projection_matrix, lights) do
    case mesh do
      %{vao: vao, vertex_count: count, program: program} ->
        :gl.useProgram(program)
        apply_light_uniforms(program, lights)
        apply_material_uniforms(program, material_uniforms)
        EAGL.Shader.set_uniform(program, "model", model_matrix)
        EAGL.Shader.set_uniform(program, "view", view_matrix)
        EAGL.Shader.set_uniform(program, "projection", projection_matrix)
        :gl.bindVertexArray(vao)
        :gl.drawArrays(@gl_triangles, 0, count)

      %{vao: vao, index_count: count, program: program} ->
        index_type = Map.get(mesh, :index_type, @gl_unsigned_int)
        :gl.useProgram(program)
        apply_light_uniforms(program, lights)
        apply_material_uniforms(program, material_uniforms)
        EAGL.Shader.set_uniform(program, "model", model_matrix)
        EAGL.Shader.set_uniform(program, "view", view_matrix)
        EAGL.Shader.set_uniform(program, "projection", projection_matrix)
        :gl.bindVertexArray(vao)
        :gl.drawElements(@gl_triangles, count, index_type, 0)

      _ ->
        :ok
    end
  end

  defp apply_material_uniforms(_program, nil), do: :ok

  defp apply_material_uniforms(program, uniforms) when is_list(uniforms) do
    Enum.each(uniforms, fn {name, value} ->
      EAGL.Shader.set_uniform(program, to_string(name), value)
    end)
  end

  @default_light %{
    type: :point,
    position: [{5.0, 5.0, 5.0}],
    direction: [{0.0, -1.0, 0.0}],
    color: [{1.0, 1.0, 1.0}],
    intensity: 1.0,
    range: 0.0,
    inner_cone_angle: 0.0,
    outer_cone_angle: 0.7854
  }

  defp collect_lights(roots, identity) do
    lights =
      Enum.flat_map(roots, fn root ->
        collect_lights_recursive(root, identity)
      end)

    case lights do
      [] -> [@default_light]
      list -> Enum.take(list, @max_lights)
    end
  end

  defp collect_lights_recursive(%Node{} = node, parent_transform) do
    local_transform = Node.get_local_transform_matrix(node)
    world_transform = mat4_mul(parent_transform, local_transform)

    light_data =
      case node.light do
        nil ->
          []

        light ->
          world_pos = mat4_transform_point(world_transform, vec3(0.0, 0.0, 0.0))
          world_dir = mat4_transform_vector(world_transform, vec3(0.0, 0.0, -1.0))
          [{dx, dy, dz}] = world_dir
          len = :math.sqrt(dx * dx + dy * dy + dz * dz)

          norm_dir =
            if len > 0.0001, do: [{dx / len, dy / len, dz / len}], else: [{0.0, -1.0, 0.0}]

          {cr, cg, cb} = Map.get(light, :color, {1.0, 1.0, 1.0})

          [
            %{
              type: Map.get(light, :type, :point),
              position: world_pos,
              direction: norm_dir,
              color: [{cr * 1.0, cg * 1.0, cb * 1.0}],
              intensity: (Map.get(light, :intensity, 1.0) || 1.0) * 1.0,
              range: (Map.get(light, :range, 0.0) || 0.0) * 1.0,
              inner_cone_angle: (Map.get(light, :inner_cone_angle, 0.0) || 0.0) * 1.0,
              outer_cone_angle: (Map.get(light, :outer_cone_angle, 0.7854) || 0.7854) * 1.0
            }
          ]
      end

    child_lights =
      Enum.flat_map(Node.get_children(node), fn child ->
        collect_lights_recursive(child, world_transform)
      end)

    light_data ++ child_lights
  end

  defp apply_light_uniforms(program, lights) do
    EAGL.Shader.set_uniform(program, "numLights", length(lights))
    EAGL.Shader.set_uniform(program, "ambientColor", vec3(0.03, 0.03, 0.03))

    lights
    |> Enum.with_index()
    |> Enum.each(fn {light, i} ->
      prefix = "lights[#{i}]"

      type_int =
        case light.type do
          :directional -> 0
          :point -> 1
          :spot -> 2
          _ -> 1
        end

      EAGL.Shader.set_uniform(program, "#{prefix}.type", type_int)
      EAGL.Shader.set_uniform(program, "#{prefix}.position", light.position)
      EAGL.Shader.set_uniform(program, "#{prefix}.direction", light.direction)
      EAGL.Shader.set_uniform(program, "#{prefix}.color", light.color)
      EAGL.Shader.set_uniform(program, "#{prefix}.intensity", light.intensity)
      EAGL.Shader.set_uniform(program, "#{prefix}.range", light.range)
      EAGL.Shader.set_uniform(program, "#{prefix}.innerConeAngle", light.inner_cone_angle)
      EAGL.Shader.set_uniform(program, "#{prefix}.outerConeAngle", light.outer_cone_angle)
    end)
  end
end
