defmodule EAGL.SpatialTest do
  use ExUnit.Case, async: true
  import EAGL.Math
  alias EAGL.{Scene, Node, Spatial}

  describe "new_from_entries/1" do
    test "empty list returns empty spatial" do
      spatial = Spatial.new_from_entries([])
      assert spatial.root == nil
      assert spatial.entries == []
    end

    test "single entry builds leaf" do
      node = Node.new(name: "box")
      aabb = {{0.0, 0.0, 0.0}, {1.0, 1.0, 1.0}}
      spatial = Spatial.new_from_entries([{node, aabb}])
      assert spatial.root == {:leaf, aabb, node}
    end

    test "multiple entries build BVH" do
      n1 = Node.new(name: "a")
      n2 = Node.new(name: "b")
      e1 = {n1, {{0.0, 0.0, 0.0}, {1.0, 1.0, 1.0}}}
      e2 = {n2, {{2.0, 2.0, 2.0}, {3.0, 3.0, 3.0}}}
      spatial = Spatial.new_from_entries([e1, e2])
      assert match?({:inner, _, _, _}, spatial.root)
    end
  end

  describe "raycast/2" do
    test "empty spatial returns no hits" do
      spatial = Spatial.new_from_entries([])
      ray = ray_new(vec3(0.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0))
      assert Spatial.raycast(spatial, ray) == []
    end

    test "ray hits single box" do
      node = Node.new(name: "box")
      aabb = {{1.0, -0.5, -0.5}, {2.0, 0.5, 0.5}}
      spatial = Spatial.new_from_entries([{node, aabb}])
      # Ray from origin along +X
      ray = ray_new(vec3(0.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0))
      hits = Spatial.raycast(spatial, ray)
      assert length(hits) == 1
      [{hit_node, t}] = hits
      assert hit_node == node
      assert t >= 1.0 and t <= 2.0
    end

    test "ray misses returns empty" do
      node = Node.new(name: "box")
      aabb = {{1.0, -0.5, -0.5}, {2.0, 0.5, 0.5}}
      spatial = Spatial.new_from_entries([{node, aabb}])
      # Ray in opposite direction
      ray = ray_new(vec3(0.0, 0.0, 0.0), vec3(-1.0, 0.0, 0.0))
      assert Spatial.raycast(spatial, ray) == []
    end

    test "ray hits multiple boxes, returns sorted by distance" do
      n1 = Node.new(name: "near")
      n2 = Node.new(name: "far")
      e1 = {n1, {{2.0, -0.5, -0.5}, {3.0, 0.5, 0.5}}}
      e2 = {n2, {{5.0, -0.5, -0.5}, {6.0, 0.5, 0.5}}}
      spatial = Spatial.new_from_entries([e1, e2])
      ray = ray_new(vec3(0.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0))
      hits = Spatial.raycast(spatial, ray)
      assert length(hits) == 2
      [{_, t1}, {_, t2}] = hits
      assert t1 < t2
    end
  end

  describe "new/1 from scene" do
    test "builds from scene with nodes that have bounds" do
      mesh = %{bounds: {{-1.0, -1.0, -1.0}, {1.0, 1.0, 1.0}}}
      node = Node.new(mesh: mesh)
      scene = Scene.add_root_node(Scene.new(), node)
      spatial = Spatial.new(scene)
      assert spatial.entries != []
      assert length(spatial.entries) == 1
    end

    test "empty scene gives empty spatial" do
      scene = Scene.new()
      spatial = Spatial.new(scene)
      assert spatial.root == nil
      assert spatial.entries == []
    end
  end
end
