defmodule EAGL.SceneTest do
  use ExUnit.Case, async: true
  import EAGL.Math
  alias EAGL.{Scene, Node, Camera}

  describe "bounds/1" do
    test "returns :no_bounds for empty scene" do
      scene = Scene.new()
      assert Scene.bounds(scene) == :no_bounds
    end

    test "returns :no_bounds for scene with nodes but no mesh bounds" do
      node = Node.new()
      scene = Scene.add_root_node(Scene.new(), node)
      assert Scene.bounds(scene) == :no_bounds
    end

    test "returns bounds from single node with mesh bounds" do
      mesh = %{bounds: {{-1.0, -1.0, -1.0}, {1.0, 1.0, 1.0}}}
      node = Node.new(mesh: mesh)
      scene = Scene.add_root_node(Scene.new(), node)

      assert {:ok, {-1.0, -1.0, -1.0}, {1.0, 1.0, 1.0}} = Scene.bounds(scene)
    end

    test "merges bounds from multiple root nodes" do
      mesh1 = %{bounds: {{0.0, 0.0, 0.0}, {1.0, 1.0, 1.0}}}
      mesh2 = %{bounds: {{-2.0, -2.0, -2.0}, {-1.0, -1.0, -1.0}}}
      node1 = Node.new(mesh: mesh1)
      node2 = Node.new(mesh: mesh2)
      scene = Scene.add_root_node(Scene.add_root_node(Scene.new(), node1), node2)

      assert {:ok, {-2.0, -2.0, -2.0}, {1.0, 1.0, 1.0}} = Scene.bounds(scene)
    end

    test "transforms bounds by node world matrix" do
      mesh = %{bounds: {{-1.0, -1.0, -1.0}, {1.0, 1.0, 1.0}}}
      node = Node.new(mesh: mesh, position: vec3(10.0, 0.0, 0.0))
      scene = Scene.add_root_node(Scene.new(), node)

      assert {:ok, {9.0, -1.0, -1.0}, {11.0, 1.0, 1.0}} = Scene.bounds(scene)
    end
  end

  describe "pick/5" do
    test "returns nil for empty scene" do
      scene = Scene.new()
      camera = Camera.new(position: vec3(0, 0, 5), target: vec3(0, 0, 0))
      viewport = {0, 0, 100, 100}

      assert Scene.pick(scene, camera, viewport, 50, 50) == nil
    end

    test "returns nil for scene with nodes but no meshes" do
      node = Node.new(position: vec3(0, 0, 0))
      scene = Scene.add_root_node(Scene.new(), node)
      camera = Camera.new(position: vec3(0, 0, 5), target: vec3(0, 0, 0))
      viewport = {0, 0, 100, 100}

      assert Scene.pick(scene, camera, viewport, 50, 50) == nil
    end

    test "returns nil for zero-size viewport" do
      mesh = %{vao: 0, vertex_count: 0}
      node = Node.new(mesh: mesh)
      scene = Scene.add_root_node(Scene.new(), node)
      camera = Camera.new(position: vec3(0, 0, 5), target: vec3(0, 0, 0))
      viewport = {0, 0, 0, 0}

      assert Scene.pick(scene, camera, viewport, 0, 0) == nil
    end
  end

  describe "raycast/2" do
    test "returns empty for empty scene" do
      scene = Scene.new()
      ray = ray_new(vec3(0.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0))
      assert Scene.raycast(scene, ray) == []
    end

    test "returns empty for scene with nodes but no mesh bounds" do
      node = Node.new(position: vec3(0, 0, 0))
      scene = Scene.add_root_node(Scene.new(), node)
      ray = ray_new(vec3(0.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0))
      assert Scene.raycast(scene, ray) == []
    end

    test "returns hits for scene with bounded mesh" do
      mesh = %{bounds: {{1.0, -0.5, -0.5}, {2.0, 0.5, 0.5}}}
      node = Node.new(mesh: mesh)
      scene = Scene.add_root_node(Scene.new(), node)
      ray = ray_new(vec3(0.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0))
      hits = Scene.raycast(scene, ray)
      assert length(hits) == 1
      [{hit_node, t}] = hits
      assert hit_node == node
      assert t >= 1.0 and t <= 2.0
    end

    test "transforms bounds by node position for raycast" do
      mesh = %{bounds: {{-0.5, -0.5, -0.5}, {0.5, 0.5, 0.5}}}
      node = Node.new(mesh: mesh, position: vec3(5.0, 0.0, 0.0))
      scene = Scene.add_root_node(Scene.new(), node)
      ray = ray_new(vec3(0.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0))
      hits = Scene.raycast(scene, ray)
      assert length(hits) == 1
      [{_, t}] = hits
      assert t >= 4.5 and t <= 5.5
    end
  end
end
