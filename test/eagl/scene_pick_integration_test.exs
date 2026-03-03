defmodule EAGL.ScenePickIntegrationTest do
  @moduledoc """
  Integration tests for Scene.pick/5 using the Box glTF example.

  Requires a display (uses @tag :external). Run with: mix test --include external

  Ensure Box.glb exists: mix glb.samples
  """
  use ExUnit.Case, async: false
  alias EAGL.{Scene, Node, OrbitCamera}
  import EAGL.Shader

  @glb_path "test/fixtures/samples/Box.glb"
  @pick_test_key {__MODULE__, :test_pid}

  def pick_test_key, do: @pick_test_key

  defp descendants(node), do: [node | Enum.flat_map(Node.get_children(node), &descendants/1)]

  @tag :external
  test "picks the Box node when picking at viewport center" do
    unless File.exists?(@glb_path) do
      raise "Box.glb not found. Run: mix glb.samples"
    end

    test_pid = self()
    :persistent_term.put(@pick_test_key, test_pid)

    task =
      Task.async(fn ->
        EAGL.Window.run(EAGL.ScenePickIntegrationTest.PickTestRunner, "Pick Integration Test",
          depth_testing: true,
          size: {400, 300},
          timeout: 3000
        )
      end)

    result =
      receive do
        {:pick_result, pick_result} -> pick_result
      after
        5000 -> nil
      end

    Task.await(task, 5000)
    :persistent_term.erase(@pick_test_key)

    assert {:ok, node} = result,
           "Expected {:ok, node} from pick at viewport center, got #{inspect(result)}"

    assert %Node{} = node
    assert Node.get_mesh(node) != nil
  end

  @tag :external
  test "picks at multiple points - center hits mesh, corners hit background" do
    unless File.exists?(@glb_path) do
      raise "Box.glb not found. Run: mix glb.samples"
    end

    # Box is 1x1 centered; fit_to_scene frames it with padding, so corners are background
    test_pid = self()
    :persistent_term.put(@pick_test_key, test_pid)

    :persistent_term.put({__MODULE__, :pick_points}, [
      :center,
      {0, 0},
      {399, 0},
      {399, 299},
      {0, 299}
    ])

    task =
      Task.async(fn ->
        EAGL.Window.run(EAGL.ScenePickIntegrationTest.PickTestRunner, "Pick Multi-Point Test",
          depth_testing: true,
          size: {400, 300},
          timeout: 3000
        )
      end)

    results =
      receive do
        {:pick_results, r} -> r
      after
        5000 -> []
      end

    Task.await(task, 5000)
    :persistent_term.erase(@pick_test_key)
    :persistent_term.erase({__MODULE__, :pick_points})

    assert length(results) == 5, "Expected 5 pick results, got #{length(results)}"

    # Center should hit the box (visible in rendered image)
    [center_result | corner_results] = results

    assert {:ok, node} = center_result,
           "Center pick (where box is visible) should hit the node, got #{inspect(center_result)}"

    assert %Node{} = node
    assert Node.get_mesh(node) != nil

    # Corners show background (clear color) - pick should return nil
    corner_coords = [{0, 0}, {399, 0}, {399, 299}, {0, 299}]

    for {{x, y}, result} <- Enum.zip(corner_coords, corner_results) do
      assert result == nil,
             "Corner (#{x}, #{y}) shows background in image, pick should return nil, got #{inspect(result)}"
    end
  end

  @tag :external
  test "two adjacent boxes - blue left, green right, grid samples return correct node IDs" do
    unless File.exists?(@glb_path) do
      raise "Box.glb not found. Run: mix glb.samples"
    end

    test_pid = self()
    :persistent_term.put(@pick_test_key, test_pid)
    :persistent_term.put({__MODULE__, :runner}, :two_boxes)

    task =
      Task.async(fn ->
        EAGL.Window.run(
          EAGL.ScenePickIntegrationTest.TwoBoxesPickTestRunner,
          "Two Boxes Pick Test",
          depth_testing: true,
          size: {400, 300},
          timeout: 3000
        )
      end)

    %{
      blue_node: blue_node,
      green_node: green_node,
      grid_results: grid_results,
      grid_points: grid_points
    } =
      receive do
        {:two_boxes_results, data} -> data
      after
        5000 -> raise "Timeout waiting for two-boxes pick results"
      end

    Task.await(task, 5000)
    :persistent_term.erase(@pick_test_key)
    :persistent_term.erase({__MODULE__, :runner})

    # First 3 = blue (left), next 3 = green (right), last 4 = corners (background)
    # Pick may return mesh child; check node is in expected subtree
    [p1, p2, p3, p4, p5, p6 | corners] = grid_points
    blue_points = [p1, p2, p3]
    green_points = [p4, p5, p6]
    background_points = corners

    blue_subtree = descendants(blue_node)
    green_subtree = descendants(green_node)

    for {x, y} <- blue_points do
      result = grid_results[{x, y}]
      assert result != nil, "Point (#{x}, #{y}) expected pick hit, got nil"
      {:ok, node} = result

      assert node in blue_subtree,
             "Point (#{x}, #{y}) is on blue box, expected node in blue subtree, got #{inspect(node)}"
    end

    for {x, y} <- green_points do
      result = grid_results[{x, y}]
      assert result != nil, "Point (#{x}, #{y}) expected pick hit, got nil"
      {:ok, node} = result

      assert node in green_subtree,
             "Point (#{x}, #{y}) is on green box, expected node in green subtree, got #{inspect(node)}"
    end

    for {x, y} <- background_points do
      result = grid_results[{x, y}]

      assert result == nil,
             "Point (#{x}, #{y}) is background, expected nil, got #{inspect(result)}"
    end
  end

  defmodule PickTestRunner do
    @moduledoc false
    use EAGL.Window
    use EAGL.Const

    @glb_path "test/fixtures/samples/Box.glb"

    @impl true
    def setup do
      test_pid = :persistent_term.get(EAGL.ScenePickIntegrationTest.pick_test_key(), nil)
      pick_points = :persistent_term.get({EAGL.ScenePickIntegrationTest, :pick_points}, [:center])

      with {:ok, program} <- GLTF.EAGL.create_phong_shader(),
           {:ok, scene, _gltf, _ds} <- GLTF.EAGL.load_scene(@glb_path, program) do
        orbit = OrbitCamera.fit_to_scene(scene)

        {:ok,
         %{
           program: program,
           scene: scene,
           orbit: orbit,
           test_pid: test_pid,
           pick_points: pick_points
         }}
      end
    end

    @impl true
    def render(
          w,
          h,
          %{
            program: prog,
            scene: scene,
            orbit: orbit,
            test_pid: test_pid,
            pick_points: pick_points
          } = state
        ) do
      import Bitwise

      :gl.viewport(0, 0, trunc(w), trunc(h))
      :gl.clearColor(0.15, 0.15, 0.2, 1.0)
      :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)
      :gl.enable(@gl_cull_face)
      :gl.cullFace(@gl_back)

      :gl.useProgram(prog)
      view = OrbitCamera.get_view_matrix(orbit)
      proj = OrbitCamera.get_projection_matrix(orbit, w / max(h, 1))

      GLTF.EAGL.set_phong_uniforms(prog,
        object_color: EAGL.Math.vec3(0.8, 0.3, 0.2),
        view_pos: OrbitCamera.get_position(orbit)
      )

      Scene.render(scene, view, proj)

      if test_pid do
        viewport = {0, 0, w, h}

        results =
          Enum.map(pick_points, fn
            :center -> Scene.pick(scene, orbit, viewport, w / 2, h / 2)
            {px, py} -> Scene.pick(scene, orbit, viewport, px, py)
          end)

        if length(pick_points) == 1 do
          send(test_pid, {:pick_result, hd(results)})
        else
          send(test_pid, {:pick_results, results})
        end
      end

      {:ok, %{state | test_pid: nil}}
    end

    @impl true
    def cleanup(%{program: p}) do
      cleanup_program(p)
      :ok
    end
  end

  defmodule TwoBoxesPickTestRunner do
    @moduledoc false
    use EAGL.Window
    use EAGL.Const
    import EAGL.Math

    @glb_path "test/fixtures/samples/Box.glb"

    @impl true
    def setup do
      test_pid = :persistent_term.get({EAGL.ScenePickIntegrationTest, :test_pid}, nil)

      is_two_boxes =
        :persistent_term.get({EAGL.ScenePickIntegrationTest, :runner}, nil) == :two_boxes

      with {:ok, program} <- GLTF.EAGL.create_flat_shader(),
           {:ok, scene1, _gltf1, _ds1} <- GLTF.EAGL.load_scene(@glb_path, program),
           {:ok, scene2, _gltf2, _ds2} <- GLTF.EAGL.load_scene(@glb_path, program) do
        [left_root] = scene1.root_nodes
        [right_root] = scene2.root_nodes

        blue_node = Node.set_position(left_root, vec3(-1.5, 0.0, 0.0))
        green_node = Node.set_position(right_root, vec3(1.5, 0.0, 0.0))

        # add_root_node prepends; add green first so blue ends up index 0, green index 1
        scene =
          Scene.new()
          |> Scene.add_root_node(green_node)
          |> Scene.add_root_node(blue_node)

        # Use explicit bounds for deterministic camera; boxes at ±1.5, each 0.5 radius
        orbit = OrbitCamera.fit_to_bounds({-2.0, -0.5, -0.5}, {2.0, 0.5, 0.5})

        {:ok,
         %{
           program: program,
           scene: scene,
           orbit: orbit,
           test_pid: test_pid,
           is_two_boxes: is_two_boxes,
           blue_node: blue_node,
           green_node: green_node,
           render_count: 0
         }}
      end
    end

    @impl true
    def render(
          w,
          h,
          %{
            program: prog,
            scene: scene,
            orbit: orbit,
            test_pid: test_pid,
            is_two_boxes: is_two_boxes,
            blue_node: blue_node,
            green_node: green_node,
            render_count: render_count
          } = state
        ) do
      import Bitwise

      :gl.viewport(0, 0, trunc(w), trunc(h))
      :gl.clearColor(0.15, 0.15, 0.2, 1.0)
      :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)
      :gl.enable(@gl_cull_face)
      :gl.cullFace(@gl_back)

      view = OrbitCamera.get_view_matrix(orbit)
      proj = OrbitCamera.get_projection_matrix(orbit, w / max(h, 1))
      identity = EAGL.Math.mat4_identity()

      # Flat colors: blue left, green right
      draw_node(prog, blue_node, identity, view, proj, EAGL.Math.vec3(0.2, 0.4, 0.9))
      draw_node(prog, green_node, identity, view, proj, EAGL.Math.vec3(0.2, 0.8, 0.3))

      # Defer pick until third render so layout has settled
      {new_test_pid, new_render_count} =
        if test_pid && is_two_boxes && render_count >= 2 do
          viewport = {0, 0, w, h}

          # Bounds (-2,-0.5,-0.5) to (2,0.5,0.5), aspect 4/3: view x ~ ±3.5, blue at -1.5 -> ~29% from left
          w_i = trunc(w)
          h_i = trunc(h)
          left_center_x = max(1, trunc(w * 0.29))
          right_center_x = min(w_i - 1, trunc(w * 0.71))
          center_y = trunc(h / 2)
          # Sample 3 points per box plus 4 corners; use ±15px spread for robustness
          spread = min(15, div(w_i, 8))

          grid_points = [
            {left_center_x - spread, center_y},
            {left_center_x, center_y},
            {left_center_x + spread, center_y},
            {right_center_x - spread, center_y},
            {right_center_x, center_y},
            {right_center_x + spread, center_y},
            {0, 0},
            {w_i - 1, 0},
            {w_i - 1, h_i - 1},
            {0, h_i - 1}
          ]

          grid_results =
            Map.new(grid_points, fn {px, py} ->
              {{px, py}, Scene.pick(scene, orbit, viewport, px, py)}
            end)

          send(
            test_pid,
            {:two_boxes_results,
             %{
               blue_node: blue_node,
               green_node: green_node,
               grid_results: grid_results,
               grid_points: grid_points
             }}
          )

          {nil, render_count + 1}
        else
          {test_pid, render_count + 1}
        end

      {:ok, %{state | test_pid: new_test_pid, render_count: new_render_count}}
    end

    defp draw_node(prog, node, parent_transform, view, proj, object_color) do
      local = Node.get_local_transform_matrix(node)
      world = EAGL.Math.mat4_mul(parent_transform, local)

      case Node.get_mesh(node) do
        nil ->
          :ok

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

        _ ->
          :ok
      end

      Enum.each(Node.get_children(node), fn child ->
        draw_node(prog, child, world, view, proj, object_color)
      end)
    end

    @impl true
    def cleanup(%{program: p}) do
      EAGL.Shader.cleanup_program(p)
      :ok
    end
  end
end
