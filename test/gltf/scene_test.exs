defmodule GLTF.SceneTest do
  use ExUnit.Case, async: true
  doctest GLTF.Scene

  alias GLTF.Scene

  describe "load/1" do
    test "loads scene with nodes" do
      json_data = %{
        "nodes" => [0, 1, 2],
        "name" => "MainScene"
      }

      assert {:ok, scene} = Scene.load(json_data)
      assert scene.nodes == [0, 1, 2]
      assert scene.name == "MainScene"
    end

    test "loads scene without nodes" do
      json_data = %{
        "name" => "EmptyScene"
      }

      assert {:ok, scene} = Scene.load(json_data)
      assert scene.nodes == nil
      assert scene.name == "EmptyScene"
    end

    test "loads scene with minimal data" do
      json_data = %{}

      assert {:ok, scene} = Scene.load(json_data)
      assert scene.nodes == nil
      assert scene.name == nil
      assert scene.extensions == nil
      assert scene.extras == nil
    end

    test "preserves extensions and extras" do
      json_data = %{
        "nodes" => [0],
        "extensions" => %{"EXT_test" => %{"value" => 42}},
        "extras" => %{"custom_data" => "test"}
      }

      assert {:ok, scene} = Scene.load(json_data)
      assert scene.extensions["EXT_test"]["value"] == 42
      assert scene.extras["custom_data"] == "test"
    end
  end

  describe "edge cases" do
    test "handles empty nodes array" do
      json_data = %{
        "nodes" => []
      }

      assert {:ok, scene} = Scene.load(json_data)
      assert scene.nodes == []
    end

    test "handles invalid node indices gracefully" do
      # Note: The Scene module itself doesn't validate node indices
      # That's the responsibility of the containing GLTF structure
      json_data = %{
        # Invalid indices
        "nodes" => [-1, 999]
      }

      assert {:ok, scene} = Scene.load(json_data)
      # Stored as-is
      assert scene.nodes == [-1, 999]
    end

    test "handles non-list nodes field" do
      json_data = %{
        # Should be array
        "nodes" => "invalid"
      }

      # Scene load is simple and doesn't validate deeply
      assert {:ok, scene} = Scene.load(json_data)
      # Stored as-is, validation happens elsewhere
      assert scene.nodes == "invalid"
    end
  end

  describe "real-world patterns" do
    test "typical single-root scene" do
      json_data = %{
        # Single root node
        "nodes" => [0],
        "name" => "Scene"
      }

      assert {:ok, scene} = Scene.load(json_data)
      assert length(scene.nodes) == 1
      assert hd(scene.nodes) == 0
    end

    test "multi-root scene" do
      json_data = %{
        # Multiple root nodes
        "nodes" => [0, 1, 2, 3],
        "name" => "ComplexScene"
      }

      assert {:ok, scene} = Scene.load(json_data)
      assert length(scene.nodes) == 4
    end
  end
end
