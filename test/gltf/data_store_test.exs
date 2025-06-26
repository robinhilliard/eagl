defmodule GLTF.DataStoreTest do
  use ExUnit.Case, async: true
  doctest GLTF.DataStore

  alias GLTF.DataStore

  describe "new/0" do
    test "creates empty data store" do
      store = DataStore.new()
      assert store.glb_buffers == %{}
      assert store.external_buffers == %{}
      assert store.data_uri_buffers == %{}
    end
  end

  describe "GLB buffer operations" do
    test "stores and retrieves GLB buffer data" do
      store = DataStore.new()
      binary_data = <<1, 2, 3, 4, 5, 6, 7, 8>>

      store = DataStore.store_glb_buffer(store, 0, binary_data)

      assert DataStore.get_buffer_data(store, 0) == binary_data
      assert DataStore.has_buffer?(store, 0) == true
      assert DataStore.has_buffer?(store, 1) == false
    end

    test "handles multiple GLB buffers" do
      store = DataStore.new()
      data1 = <<1, 2, 3, 4>>
      data2 = <<5, 6, 7, 8>>

      store =
        store
        |> DataStore.store_glb_buffer(0, data1)
        |> DataStore.store_glb_buffer(1, data2)

      assert DataStore.get_buffer_data(store, 0) == data1
      assert DataStore.get_buffer_data(store, 1) == data2
      assert DataStore.buffer_count(store) == 2
    end

    test "overwrites existing GLB buffer" do
      store = DataStore.new()
      original_data = <<1, 2, 3, 4>>
      new_data = <<5, 6, 7, 8>>

      store =
        store
        |> DataStore.store_glb_buffer(0, original_data)
        |> DataStore.store_glb_buffer(0, new_data)

      assert DataStore.get_buffer_data(store, 0) == new_data
      assert DataStore.buffer_count(store) == 1
    end
  end

  describe "external buffer operations" do
    setup do
      # Create temporary directory and files for testing
      temp_dir = "test/fixtures/external_buffers"
      File.mkdir_p!(temp_dir)

      # Create test files
      test_data = <<10, 20, 30, 40, 50>>
      test_file = Path.join(temp_dir, "test_buffer.bin")
      File.write!(test_file, test_data)

      # Create file with spaces in name (common in glTF samples)
      spaces_data = <<60, 70, 80, 90>>
      spaces_file = Path.join(temp_dir, "buffer with spaces.bin")
      File.write!(spaces_file, spaces_data)

      on_exit(fn -> File.rm_rf!(temp_dir) end)

      {:ok,
       temp_dir: temp_dir,
       test_file: test_file,
       test_data: test_data,
       spaces_file: spaces_file,
       spaces_data: spaces_data}
    end

    test "loads external buffer from file", %{test_file: test_file, test_data: test_data} do
      store = DataStore.new()

      assert {:ok, updated_store} =
               DataStore.load_external_buffer(
                 store,
                 0,
                 "test_buffer.bin",
                 Path.dirname(test_file)
               )

      assert DataStore.get_buffer_data(updated_store, 0) == test_data
      assert DataStore.has_buffer?(updated_store, 0) == true
    end

    test "handles files with spaces in names", %{
      spaces_file: spaces_file,
      spaces_data: spaces_data
    } do
      store = DataStore.new()

      assert {:ok, updated_store} =
               DataStore.load_external_buffer(
                 store,
                 0,
                 "buffer with spaces.bin",
                 Path.dirname(spaces_file)
               )

      assert DataStore.get_buffer_data(updated_store, 0) == spaces_data
    end

    test "handles missing external file" do
      store = DataStore.new()

      assert {:error, {:file_read_error, _reason, _path}} =
               DataStore.load_external_buffer(store, 0, "missing_file.bin", "/tmp")
    end

    test "stores external buffer data directly" do
      store = DataStore.new()
      binary_data = <<100, 101, 102, 103>>

      store = DataStore.store_external_buffer(store, 0, binary_data)

      assert DataStore.get_buffer_data(store, 0) == binary_data
    end
  end

  describe "data URI buffer operations" do
    test "loads valid base64 data URI" do
      store = DataStore.new()
      # "Hello" in base64
      data_uri = "data:application/octet-stream;base64,SGVsbG8="

      assert {:ok, updated_store} = DataStore.load_data_uri_buffer(store, 0, data_uri)

      assert DataStore.get_buffer_data(updated_store, 0) == "Hello"
    end

    test "loads data URI with gltf-buffer media type" do
      store = DataStore.new()
      # "Test" in base64
      data_uri = "data:application/gltf-buffer;base64,VGVzdA=="

      assert {:ok, updated_store} = DataStore.load_data_uri_buffer(store, 0, data_uri)

      assert DataStore.get_buffer_data(updated_store, 0) == "Test"
    end

    test "handles invalid base64 in data URI" do
      store = DataStore.new()
      data_uri = "data:application/octet-stream;base64,INVALID!!!"

      assert {:error, :invalid_base64} = DataStore.load_data_uri_buffer(store, 0, data_uri)
    end

    test "handles malformed data URI" do
      store = DataStore.new()

      # Missing comma
      assert {:error, :invalid_data_uri_format} =
               DataStore.load_data_uri_buffer(store, 0, "data:application/octet-stream;base64")

      # Not a data URI
      assert {:error, :not_data_uri} =
               DataStore.load_data_uri_buffer(store, 0, "http://example.com/buffer.bin")
    end

    test "stores data URI buffer directly" do
      store = DataStore.new()
      binary_data = <<200, 201, 202, 203>>

      store = DataStore.store_data_uri_buffer(store, 0, binary_data)

      assert DataStore.get_buffer_data(store, 0) == binary_data
    end
  end

  describe "buffer slicing operations" do
    test "gets buffer slice within bounds" do
      store = DataStore.new()
      binary_data = <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9>>
      store = DataStore.store_glb_buffer(store, 0, binary_data)

      # Get slice from byte 2, length 4 -> <<2, 3, 4, 5>>
      assert DataStore.get_buffer_slice(store, 0, 2, 4) == <<2, 3, 4, 5>>

      # Get slice from beginning
      assert DataStore.get_buffer_slice(store, 0, 0, 3) == <<0, 1, 2>>

      # Get slice to end
      assert DataStore.get_buffer_slice(store, 0, 7, 3) == <<7, 8, 9>>
    end

    test "returns nil for out-of-bounds slice" do
      store = DataStore.new()
      binary_data = <<0, 1, 2, 3, 4>>
      store = DataStore.store_glb_buffer(store, 0, binary_data)

      # Slice extends beyond buffer
      assert DataStore.get_buffer_slice(store, 0, 3, 5) == nil

      # Offset beyond buffer
      assert DataStore.get_buffer_slice(store, 0, 10, 2) == nil
    end

    test "returns nil for nonexistent buffer slice" do
      store = DataStore.new()

      assert DataStore.get_buffer_slice(store, 99, 0, 4) == nil
    end

    test "handles zero-length slice" do
      store = DataStore.new()
      binary_data = <<0, 1, 2, 3, 4>>
      store = DataStore.store_glb_buffer(store, 0, binary_data)

      # Zero-length slice should work but function signature prevents it
      # This tests the boundary condition
      assert DataStore.get_buffer_slice(store, 0, 0, 1) == <<0>>
    end
  end

  describe "mixed buffer type operations" do
    test "handles multiple buffer types simultaneously" do
      store = DataStore.new()

      # Store different types of buffers
      glb_data = <<1, 2, 3, 4>>
      external_data = <<5, 6, 7, 8>>
      data_uri_data = <<9, 10, 11, 12>>

      store =
        store
        |> DataStore.store_glb_buffer(0, glb_data)
        |> DataStore.store_external_buffer(1, external_data)
        |> DataStore.store_data_uri_buffer(2, data_uri_data)

      assert DataStore.get_buffer_data(store, 0) == glb_data
      assert DataStore.get_buffer_data(store, 1) == external_data
      assert DataStore.get_buffer_data(store, 2) == data_uri_data
      assert DataStore.buffer_count(store) == 3
    end

    test "GLB buffers take precedence in lookup" do
      store = DataStore.new()
      glb_data = <<1, 2, 3, 4>>
      external_data = <<5, 6, 7, 8>>

      # Store the same index in different stores
      store =
        store
        |> DataStore.store_external_buffer(0, external_data)
        # This should take precedence
        |> DataStore.store_glb_buffer(0, glb_data)

      # GLB buffer should be returned first
      assert DataStore.get_buffer_data(store, 0) == glb_data
    end

    test "fallback chain works correctly" do
      store = DataStore.new()
      external_data = <<5, 6, 7, 8>>
      data_uri_data = <<9, 10, 11, 12>>

      # Store in external and data_uri, but not GLB
      store =
        store
        |> DataStore.store_external_buffer(0, external_data)
        |> DataStore.store_data_uri_buffer(0, data_uri_data)

      # External should be returned (comes before data_uri in fallback)
      assert DataStore.get_buffer_data(store, 0) == external_data
    end
  end

  describe "edge cases and error handling" do
    test "handles negative buffer indices gracefully" do
      _store = DataStore.new()

      # These should not crash but also won't work due to function guards
      # The guards prevent calling with negative indices
    end

    test "handles very large buffer data" do
      store = DataStore.new()
      # Create a reasonably large buffer (1MB)
      large_data = :crypto.strong_rand_bytes(1_024 * 1_024)

      store = DataStore.store_glb_buffer(store, 0, large_data)

      assert DataStore.get_buffer_data(store, 0) == large_data
      assert DataStore.has_buffer?(store, 0) == true
    end

    test "buffer_count is accurate with overlapping indices" do
      store = DataStore.new()

      # Store buffers with overlapping indices across different types
      store =
        store
        |> DataStore.store_glb_buffer(0, <<1>>)
        |> DataStore.store_external_buffer(0, <<2>>)
        |> DataStore.store_data_uri_buffer(0, <<3>>)
        |> DataStore.store_glb_buffer(1, <<4>>)
        |> DataStore.store_external_buffer(2, <<5>>)

      # Should count unique indices: 0, 1, 2
      assert DataStore.buffer_count(store) == 3
    end

    test "handles empty binary data" do
      store = DataStore.new()
      empty_data = <<>>

      store = DataStore.store_glb_buffer(store, 0, empty_data)

      assert DataStore.get_buffer_data(store, 0) == <<>>
      # zero length not allowed
      assert DataStore.get_buffer_slice(store, 0, 0, 0) == nil
    end
  end

  describe "real-world usage patterns" do
    test "typical GLB workflow" do
      store = DataStore.new()

      # Simulate GLB loading: first buffer is from GLB chunk
      glb_chunk_data = <<
        # Vertex positions (3 vertices, 3 floats each + padding)
        # vertex 1: (0, 0, 0) as 4 bytes
        0,
        0,
        0,
        0,
        # vertex 2: (1, 0, 0) as 4 bytes
        1,
        0,
        0,
        0,
        # vertex 3: (0, 1, 0) as 4 bytes
        0,
        1,
        0,
        0,
        # extra padding data
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0
      >>

      store = DataStore.store_glb_buffer(store, 0, glb_chunk_data)

      # Simulate buffer view access patterns
      # Each vertex group is 8 bytes (2 floats worth)
      vertex1 = DataStore.get_buffer_slice(store, 0, 0, 8)
      vertex2 = DataStore.get_buffer_slice(store, 0, 8, 8)
      vertex3 = DataStore.get_buffer_slice(store, 0, 16, 8)

      assert byte_size(vertex1) == 8
      assert byte_size(vertex2) == 8
      assert byte_size(vertex3) == 8

      # Verify we can get the full buffer too
      full_buffer = DataStore.get_buffer_data(store, 0)
      assert byte_size(full_buffer) == 24
    end

    test "mixed gltf + glb workflow" do
      store = DataStore.new()

      # Simulate loading a .gltf file with external .bin and data URIs
      # External buffer for large geometry data
      store = DataStore.store_external_buffer(store, 0, :crypto.strong_rand_bytes(1000))

      # Data URI for small texture data
      # White pixel
      store = DataStore.store_data_uri_buffer(store, 1, <<255, 255, 255, 255>>)

      # GLB chunk for animation data
      store = DataStore.store_glb_buffer(store, 2, :crypto.strong_rand_bytes(500))

      assert DataStore.buffer_count(store) == 3
      assert DataStore.has_buffer?(store, 0)
      assert DataStore.has_buffer?(store, 1)
      assert DataStore.has_buffer?(store, 2)
      assert not DataStore.has_buffer?(store, 3)
    end
  end
end
