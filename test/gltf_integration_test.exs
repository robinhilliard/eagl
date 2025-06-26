defmodule GLTFIntegrationTest do
  use ExUnit.Case, async: true

  @moduletag :integration

  # Test with a variety of Khronos sample GLB files to ensure broad compatibility
  @sample_files [
    %{
      name: "Box",
      url:
        "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/Box/glTF-Binary/Box.glb",
      expected: %{
        version: "2.0",
        buffers: 1,
        meshes: 1,
        materials: 1,
        scenes: 1,
        generator: "COLLADA2GLTF"
      }
    },
    %{
      name: "Cube",
      url:
        "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/Cube/glTF-Binary/Cube.glb",
      expected: %{
        version: "2.0",
        buffers: 1,
        meshes: 1
      }
    },
    %{
      name: "Triangle",
      url:
        "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/Triangle/glTF-Binary/Triangle.glb",
      expected: %{
        version: "2.0",
        buffers: 1,
        meshes: 1
      }
    }
  ]

  setup_all do
    # Download sample files for testing
    sample_dir = "test/fixtures/samples"
    File.mkdir_p!(sample_dir)

    downloaded_files =
      @sample_files
      |> Enum.map(fn sample ->
        local_path = Path.join(sample_dir, "#{sample.name}.glb")

        unless File.exists?(local_path) do
          case download_file(sample.url, local_path) do
            :ok ->
              {sample.name, local_path, sample.expected}

            {:error, reason} ->
              IO.puts("Warning: Could not download #{sample.name}: #{reason}")
              nil
          end
        else
          {sample.name, local_path, sample.expected}
        end
      end)
      |> Enum.filter(&(&1 != nil))

    {:ok, samples: downloaded_files}
  end

  describe "end-to-end glTF loading" do
    test "loads simple GLB files successfully", %{samples: samples} do
      for {name, path, expected} <- samples do
        # Test complete loading pipeline
        assert {:ok, gltf} = GLTF.GLBLoader.load_gltf(path, json_library: :poison)

        # Verify basic structure
        assert gltf.asset.version == expected.version
        assert length(gltf.buffers || []) == expected.buffers
        assert length(gltf.meshes || []) == expected.meshes

        if expected[:materials] do
          assert length(gltf.materials || []) == expected.materials
        end

        if expected[:scenes] do
          assert length(gltf.scenes || []) == expected.scenes
        end

        if expected[:generator] do
          assert gltf.asset.generator == expected.generator
        end

        # Verify structure integrity
        assert_valid_gltf_structure(gltf, name)
      end
    end

    test "parses GLB structure correctly", %{samples: samples} do
      for {name, path, _expected} <- samples do
        assert {:ok, glb_binary} = GLTF.GLBLoader.parse_file(path)

        # Verify GLB structure
        assert glb_binary.magic == "glTF"
        assert glb_binary.version == 2
        assert glb_binary.length > 0
        assert glb_binary.json_chunk.length > 0

        # Verify JSON is parseable
        json_string = GLTF.Binary.get_json(glb_binary)
        assert {:ok, json_data} = Poison.decode(json_string)
        assert json_data["asset"]["version"] == "2.0"

        IO.puts("✓ #{name}: GLB structure valid")
      end
    end

    test "handles both JSON libraries", %{samples: samples} do
      [sample | _] = samples
      {_name, path, _expected} = sample

      # Test with Poison
      assert {:ok, gltf_poison} = GLTF.GLBLoader.load_gltf(path, json_library: :poison)

      # Test with Jason (if available)
      case GLTF.GLBLoader.load_gltf(path, json_library: :jason) do
        {:ok, gltf_jason} ->
          # Both should produce equivalent results
          assert gltf_poison.asset.version == gltf_jason.asset.version
          assert length(gltf_poison.buffers || []) == length(gltf_jason.buffers || [])

        {:error, :jason_not_available} ->
          # Jason not installed, that's fine
          :ok

        {:error, reason} ->
          flunk("Jason loading failed unexpectedly: #{inspect(reason)}")
      end
    end
  end

  describe "error handling" do
    test "handles invalid GLB files gracefully" do
      invalid_cases = [
        {"empty file", <<>>},
        {"too short", <<1, 2, 3, 4>>},
        {"wrong magic", <<"FAKE", 2::little-32, 100::little-32, "JSON", 8::little-32>>},
        {"unsupported version", <<"glTF", 99::little-32, 100::little-32>>}
      ]

      for {desc, binary_data} <- invalid_cases do
        temp_file = "test/fixtures/invalid_#{String.replace(desc, " ", "_")}.glb"
        File.write!(temp_file, binary_data)

        assert {:error, _reason} = GLTF.GLBLoader.load_gltf(temp_file)

        File.rm!(temp_file)
      end
    end

    test "handles missing files gracefully" do
      assert {:error, reason} = GLTF.GLBLoader.load_gltf("nonexistent_file.glb")
      assert is_binary(reason)
    end
  end

  # Helper functions

  defp download_file(url, local_path) do
    try do
      :inets.start()

      case :httpc.request(:get, {String.to_charlist(url), []}, [timeout: 30_000],
             body_format: :binary
           ) do
        {:ok, {{_version, 200, _reason}, _headers, body}} ->
          File.write!(local_path, body)
          :ok

        {:ok, {{_version, status, _reason}, _headers, _body}} ->
          {:error, "HTTP #{status}"}

        {:error, reason} ->
          {:error, inspect(reason)}
      end
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  defp assert_valid_gltf_structure(gltf, name) do
    # Test that GLTF validation passes
    case GLTF.validate(gltf) do
      :ok ->
        IO.puts("✓ #{name}: Structure validation passed")

      {:error, reason} ->
        flunk("#{name}: Structure validation failed: #{inspect(reason)}")
    end

    # Test that all referenced indices are valid
    assert_valid_indices(gltf, name)

    # Test that all buffers are GLB-stored (for GLB files)
    if gltf.buffers do
      for buffer <- gltf.buffers do
        assert GLTF.Buffer.glb_stored?(buffer),
               "#{name}: Expected GLB-stored buffer, got #{inspect(buffer.uri)}"
      end
    end
  end

  defp assert_valid_indices(gltf, name) do
    buffer_count = length(gltf.buffers || [])
    buffer_view_count = length(gltf.buffer_views || [])
    accessor_count = length(gltf.accessors || [])

    # Check buffer views reference valid buffers
    if gltf.buffer_views do
      for {buffer_view, idx} <- Enum.with_index(gltf.buffer_views) do
        assert buffer_view.buffer >= 0 and buffer_view.buffer < buffer_count,
               "#{name}: BufferView[#{idx}] references invalid buffer #{buffer_view.buffer}"
      end
    end

    # Check accessors reference valid buffer views
    if gltf.accessors do
      for {accessor, idx} <- Enum.with_index(gltf.accessors) do
        if accessor.buffer_view do
          assert accessor.buffer_view >= 0 and accessor.buffer_view < buffer_view_count,
                 "#{name}: Accessor[#{idx}] references invalid buffer view #{accessor.buffer_view}"
        end
      end
    end

    # Check mesh primitives reference valid accessors
    if gltf.meshes do
      for {mesh, mesh_idx} <- Enum.with_index(gltf.meshes) do
        for {primitive, prim_idx} <- Enum.with_index(mesh.primitives) do
          # Check indices accessor
          if primitive.indices do
            assert primitive.indices >= 0 and primitive.indices < accessor_count,
                   "#{name}: Mesh[#{mesh_idx}].primitive[#{prim_idx}] has invalid indices accessor"
          end

          # Check attribute accessors
          if primitive.attributes do
            for {_attr_name, accessor_idx} <- primitive.attributes do
              assert accessor_idx >= 0 and accessor_idx < accessor_count,
                     "#{name}: Mesh[#{mesh_idx}].primitive[#{prim_idx}] has invalid attribute accessor"
            end
          end
        end
      end
    end
  end
end
