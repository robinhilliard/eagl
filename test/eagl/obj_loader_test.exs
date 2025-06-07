defmodule EAGL.ObjLoaderTest do
  use ExUnit.Case
  doctest EAGL.ObjLoader

  @app Mix.Project.config()[:app]

  describe "load_obj/1" do
    test "successfully loads a cube obj file" do
      model_path = Path.join([
        :code.priv_dir(@app),
        "models",
        "cube.obj"
      ])

      assert {:ok, model_data} = EAGL.ObjLoader.load_obj(model_path)

      # Test the structure of returned data
      assert is_map(model_data)
      assert Map.has_key?(model_data, :vertices)
      assert Map.has_key?(model_data, :normals)
      assert Map.has_key?(model_data, :tex_coords)
      assert Map.has_key?(model_data, :indices)

      # Each vertex appears in 3 faces, and each face uses a different normal
      # So we end up with 24 unique vertex/normal combinations (8 vertices * 3 faces each)
      assert length(model_data.vertices) == 72  # 24 vertices * 3 coordinates each
      assert length(model_data.normals) == 72   # 24 vertices * 3 normal coordinates each
      assert length(model_data.tex_coords) == 48  # 24 vertices * 2 texture coordinates each

      # Test that vertices are valid floats
      Enum.each(model_data.vertices, fn vertex ->
        assert is_float(vertex)
        assert vertex >= -1.0 and vertex <= 1.0
      end)

      # Test that normals are unit vectors
      normals_grouped = Enum.chunk_every(model_data.normals, 3)
      Enum.each(normals_grouped, fn [x, y, z] ->
        # Check if it's a unit vector (length ≈ 1)
        length = :math.sqrt(x * x + y * y + z * z)
        assert_in_delta length, 1.0, 0.0001
      end)

      # Test texture coordinates are in range [0,1]
      Enum.each(model_data.tex_coords, fn coord ->
        assert is_float(coord)
        assert coord >= 0.0 and coord <= 1.0
      end)

      # Test indices (6 faces * 2 triangles * 3 vertices)
      assert length(model_data.indices) == 36
      Enum.each(model_data.indices, fn index ->
        assert is_integer(index)
        assert index >= 0
        assert index < 24  # Should reference one of our 24 unique vertex combinations
      end)
    end

    test "returns error for non-existent file" do
      assert {:error, _reason} = EAGL.ObjLoader.load_obj("nonexistent.obj")
    end

    test "returns error for invalid file path" do
      assert {:error, _reason} = EAGL.ObjLoader.load_obj("")
    end
  end
end
