defmodule EAGL.Examples.GLTF.TwoBoxes do
  @moduledoc """
  GLTF Example 6: Two adjacent boxes (blue left, green right) for pick testing.

  Loads Box.glb twice so each box has its own mesh. Press **P** to toggle
  pick-buffer visualization (node IDs as colors).
  """

  use EAGL.Window
  use EAGL.Const
  use EAGL.OrbitCamera
  import Bitwise
  import EAGL.Shader
  import EAGL.Math
  alias EAGL.{Scene, Node}

  @glb_path "test/fixtures/samples/Box.glb"

  def run_example(opts \\ []) do
    default_opts = [depth_testing: true, size: {400, 300}, enter_to_exit: true]
    EAGL.Window.run(__MODULE__, "Two Boxes", Keyword.merge(default_opts, opts))
  end

  @impl true
  def setup do
    with {:ok, program} <- GLTF.EAGL.create_flat_shader(),
         {:ok, scene1, _gltf1, _ds1} <- GLTF.EAGL.load_scene(@glb_path, program),
         {:ok, scene2, _gltf2, _ds2} <- GLTF.EAGL.load_scene(@glb_path, program) do
      [left_root] = scene1.root_nodes
      [right_root] = scene2.root_nodes

      left_node = Node.set_position(left_root, vec3(-1.5, 0.0, 0.0))
      right_node = Node.set_position(right_root, vec3(1.5, 0.0, 0.0))

      # add_root_node prepends; add right first so left ends up index 0, right index 1
      scene =
        Scene.new()
        |> Scene.add_root_node(right_node)
        |> Scene.add_root_node(left_node)

      orbit = EAGL.OrbitCamera.fit_to_scene(scene)

      {:ok, %{program: program, scene: scene, orbit: orbit, left_node: left_node, right_node: right_node, show_pick: false}}
    end
  end

  @impl true
  def render(w, h, %{program: prog, scene: scene, orbit: orbit, left_node: left_node, right_node: right_node, show_pick: show_pick} = state) do
    :gl.viewport(0, 0, trunc(w), trunc(h))
    :gl.clearColor(0.15, 0.15, 0.2, 1.0)
    :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)
    :gl.enable(@gl_cull_face)
    :gl.cullFace(@gl_back)

    view = EAGL.OrbitCamera.get_view_matrix(orbit)
    proj = EAGL.OrbitCamera.get_projection_matrix(orbit, w / max(h, 1))
    identity = EAGL.Math.mat4_identity()

    if show_pick do
      Scene.visualize_pick_buffer(scene, orbit, {0, 0, w, h})
    else
      # Flat colors: blue left, green right (no lighting)
      draw_node(left_node, identity, view, proj, prog, vec3(0.2, 0.4, 0.9))
      draw_node(right_node, identity, view, proj, prog, vec3(0.2, 0.8, 0.3))
    end

    {:ok, state}
  end

  defp draw_node(node, parent_transform, view, proj, prog, object_color) do
    import EAGL.Math
    local = Node.get_local_transform_matrix(node)
    world = mat4_mul(parent_transform, local)

    case Node.get_mesh(node) do
      nil -> :ok
      %{vao: vao, vertex_count: count} ->
        :gl.useProgram(prog)
        EAGL.Shader.set_uniform(prog, "objectColor", object_color)
        EAGL.Shader.set_uniform(prog, "model", world)
        EAGL.Shader.set_uniform(prog, "view", view)
        EAGL.Shader.set_uniform(prog, "projection", proj)
        :gl.bindVertexArray(vao)
        :gl.drawArrays(@gl_triangles, 0, count)
      %{vao: vao, index_count: count} = mesh ->
        index_type = Map.get(mesh, :index_type, @gl_unsigned_int)
        :gl.useProgram(prog)
        EAGL.Shader.set_uniform(prog, "objectColor", object_color)
        EAGL.Shader.set_uniform(prog, "model", world)
        EAGL.Shader.set_uniform(prog, "view", view)
        EAGL.Shader.set_uniform(prog, "projection", proj)
        :gl.bindVertexArray(vao)
        :gl.drawElements(@gl_triangles, count, index_type, 0)
      _ -> :ok
    end

    Enum.each(Node.get_children(node), fn child ->
      draw_node(child, world, view, proj, prog, object_color)
    end)
  end

  @impl true
  def handle_event({:key, key}, %{show_pick: show_pick} = state)
      when key == ?p or key == ?P do
    {:ok, %{state | show_pick: not show_pick}}
  end

  def handle_event(event, state) do
    # Delegate to OrbitCamera for mouse/scroll
    super(event, state)
  end

  @impl true
  def cleanup(%{program: p}) do
    cleanup_program(p)
    :ok
  end
end
