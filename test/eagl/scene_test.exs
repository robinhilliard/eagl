defmodule EAGL.SceneTest do
  use ExUnit.Case, async: true
  import EAGL.Math
  alias EAGL.{Scene, Node}

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
end
