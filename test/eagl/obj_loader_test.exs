defmodule EAGL.ObjLoaderTest do
  use ExUnit.Case
  doctest EAGL.ObjLoader

  @app Mix.Project.config()[:app]

  describe "load_obj/1" do
    test "successfully loads a cube obj file" do
      model_path =
        Path.join([
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
      # 24 vertices * 3 coordinates each
      assert length(model_data.vertices) == 72
      # 24 vertices * 3 normal coordinates each
      assert length(model_data.normals) == 72
      # 24 vertices * 2 texture coordinates each
      assert length(model_data.tex_coords) == 48

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
        # Should reference one of our 24 unique vertex combinations
        assert index < 24
      end)
    end

    test "flip_normal_direction works for models with existing normals" do
      model_path =
        Path.join([
          :code.priv_dir(@app),
          "models",
          "cube.obj"
        ])

      # Load cube normally
      assert {:ok, normal_model} =
               EAGL.ObjLoader.load_obj(model_path, flip_normal_direction: false)

      # Load cube with flipped normals
      assert {:ok, flipped_model} =
               EAGL.ObjLoader.load_obj(model_path, flip_normal_direction: true)

      # Both should have the same structure
      assert length(normal_model.normals) == length(flipped_model.normals)
      assert length(normal_model.vertices) == length(flipped_model.vertices)

      # Normals should be flipped (negated)
      normal_normals = Enum.chunk_every(normal_model.normals, 3)
      flipped_normals = Enum.chunk_every(flipped_model.normals, 3)

      Enum.zip(normal_normals, flipped_normals)
      |> Enum.each(fn {[nx, ny, nz], [fx, fy, fz]} ->
        assert_in_delta nx, -fx, 0.0001
        assert_in_delta ny, -fy, 0.0001
        assert_in_delta nz, -fz, 0.0001
      end)
    end

    test "flip_normal_direction works for models without existing normals" do
      model_path =
        Path.join([
          :code.priv_dir(@app),
          "models",
          "teapot.obj"
        ])

      # Load teapot normally (generates normals)
      assert {:ok, normal_model} =
               EAGL.ObjLoader.load_obj(model_path, flip_normal_direction: false)

      # Load teapot with flipped normals (generates flipped normals)
      assert {:ok, flipped_model} =
               EAGL.ObjLoader.load_obj(model_path, flip_normal_direction: true)

      # Both should have the same structure
      assert length(normal_model.normals) == length(flipped_model.normals)
      assert length(normal_model.vertices) == length(flipped_model.vertices)

      # Normals should be flipped (negated)
      normal_normals = Enum.chunk_every(normal_model.normals, 3)
      flipped_normals = Enum.chunk_every(flipped_model.normals, 3)

      # Test a sample of normals to ensure they're flipped
      sample_pairs = Enum.zip(normal_normals, flipped_normals) |> Enum.take(10)

      Enum.each(sample_pairs, fn {[nx, ny, nz], [fx, fy, fz]} ->
        assert_in_delta nx, -fx, 0.0001
        assert_in_delta ny, -fy, 0.0001
        assert_in_delta nz, -fz, 0.0001
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
