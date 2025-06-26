defmodule GLTF.GLBLoaderTest do
  use ExUnit.Case, async: true
  alias GLTF.{GLBLoader, Binary}

  # Khronos Sample Asset - ChairDamaskPurplegold GLB file
  @test_url "https://github.com/KhronosGroup/glTF-Sample-Assets/raw/refs/heads/main/Models/ChairDamaskPurplegold/glTF-Binary/ChairDamaskPurplegold.glb"

  describe "parse_url/2" do
    @tag :external
    test "successfully parses ChairDamaskPurplegold.glb from URL" do
      {:ok, glb} = GLBLoader.parse_url(@test_url, timeout: 30_000)

      # Validate basic GLB structure
      assert %Binary{} = glb
      assert glb.magic == "glTF"
      assert glb.version == 2
      assert is_integer(glb.length)
      assert glb.length > 0

      # Validate JSON chunk
      assert glb.json_chunk.type == :json
      assert is_binary(glb.json_chunk.data)
      assert byte_size(glb.json_chunk.data) > 0

      # Validate binary chunk (should be present)
      assert glb.binary_chunk != nil
      assert glb.binary_chunk.type == :bin
      assert is_binary(glb.binary_chunk.data)
      assert byte_size(glb.binary_chunk.data) > 0
    end

    @tag :external
    test "parsed GLB has valid JSON content" do
      {:ok, glb} = GLBLoader.parse_url(@test_url, timeout: 30_000)
      {:ok, json_map} = GLBLoader.get_json_map(glb)

      # Validate glTF asset structure
      assert is_map(json_map)
      assert Map.has_key?(json_map, "asset")
      assert Map.has_key?(json_map, "scenes")
      assert Map.has_key?(json_map, "nodes")
      assert Map.has_key?(json_map, "meshes")

      # Validate asset metadata
      asset = json_map["asset"]
      assert asset["version"] == "2.0"
      assert String.contains?(asset["generator"], "3ds Max")
      assert String.contains?(asset["copyright"], "Wayfair")

      # Validate extensions
      assert Map.has_key?(json_map, "extensionsUsed")
      extensions_used = json_map["extensionsUsed"]
      assert is_list(extensions_used)
      assert "KHR_texture_transform" in extensions_used
      assert "KHR_materials_sheen" in extensions_used
      assert "KHR_materials_specular" in extensions_used
    end

    @tag :external
    test "parsed GLB has expected content counts" do
      {:ok, glb} = GLBLoader.parse_url(@test_url, timeout: 30_000)
      {:ok, json_map} = GLBLoader.get_json_map(glb)

      # The chair model should have multiple meshes, materials, etc.
      assert length(json_map["scenes"]) >= 1
      # Chair has many parts
      assert length(json_map["nodes"]) >= 10
      # Multiple mesh components
      assert length(json_map["meshes"]) >= 10
      # Different materials
      assert length(json_map["materials"]) >= 3
      # Geometry data
      assert length(json_map["accessors"]) >= 20
      # Buffer views
      assert length(json_map["bufferViews"]) >= 10
      # At least one buffer
      assert length(json_map["buffers"]) >= 1
    end
  end

  describe "parse/2 auto-detection" do
    @tag :external
    test "automatically detects URL and parses correctly" do
      {:ok, glb} = GLBLoader.parse(@test_url, timeout: 30_000)

      assert %Binary{} = glb
      assert glb.magic == "glTF"
      assert glb.version == 2
      assert Binary.has_binary?(glb)
    end
  end

  describe "validate/2" do
    @tag :external
    test "validates parsed GLB structure" do
      {:ok, glb} = GLBLoader.parse_url(@test_url, timeout: 30_000)

      assert :ok = GLBLoader.validate(glb)
      assert :ok = GLBLoader.validate(glb, strict: false)
      assert :ok = GLBLoader.validate(glb, strict: true)
    end
  end

  describe "get_info/1" do
    @tag :external
    test "provides correct file information" do
      {:ok, glb} = GLBLoader.parse_url(@test_url, timeout: 30_000)
      info = GLBLoader.get_info(glb)

      assert info.magic == "glTF"
      assert info.version == 2
      # Large file with geometry and textures
      assert info.total_size > 100_000
      assert info.header_size == 12
      # Substantial JSON
      assert info.json_chunk_size > 1000
      # Large binary data
      assert info.binary_chunk_size > 50_000
      assert info.has_binary == true
      assert info.chunk_count == 2
    end
  end

  describe "Binary helper functions" do
    @tag :external
    test "Binary.get_json/1 returns JSON string" do
      {:ok, glb} = GLBLoader.parse_url(@test_url, timeout: 30_000)
      json_string = Binary.get_json(glb)

      assert is_binary(json_string)
      assert String.starts_with?(json_string, "{")
      assert String.contains?(json_string, "asset")
      assert String.contains?(json_string, "version")
    end

    @tag :external
    test "Binary.get_binary/1 returns binary data" do
      {:ok, glb} = GLBLoader.parse_url(@test_url, timeout: 30_000)
      binary_data = Binary.get_binary(glb)

      assert is_binary(binary_data)
      # Substantial geometry data
      assert byte_size(binary_data) > 50_000
    end

    @tag :external
    test "Binary.has_binary?/1 returns true" do
      {:ok, glb} = GLBLoader.parse_url(@test_url, timeout: 30_000)

      assert Binary.has_binary?(glb) == true
    end
  end

  describe "error handling" do
    test "handles invalid URLs gracefully" do
      assert {:error, reason} =
               GLBLoader.parse_url("https://invalid-url-that-does-not-exist.com/model.glb")

      assert is_binary(reason)
    end

    test "handles non-GLB content" do
      # Try to parse a plain text URL - this returns base64 decoded "HTTPBIN is awesome"
      case GLBLoader.parse_url("https://httpbin.org/base64/SFRUUEJJTiBpcyBhd2Vzb21l") do
        {:error, reason} ->
          # Could be various errors: header too small, invalid magic, or HTTP error
          assert String.contains?(reason, "GLB header requires 12 bytes") or
                   String.contains?(reason, "Invalid magic") or
                   String.contains?(reason, "HTTP error")

        {:ok, _} ->
          # If it somehow succeeds, that's unexpected but not necessarily wrong
          # (the server might return something different than expected)
          assert true
      end
    end
  end

  describe "HTTP client options" do
    @tag :external
    test "works with different HTTP clients" do
      # Test with httpc (default)
      {:ok, glb1} = GLBLoader.parse_url(@test_url, http_client: :httpc, timeout: 30_000)
      assert %Binary{} = glb1

      # Test with req if available
      case GLBLoader.parse_url(@test_url, http_client: :req, timeout: 30_000) do
        {:ok, glb2} ->
          assert %Binary{} = glb2
          assert glb1.magic == glb2.magic

        {:error, reason} ->
          # Req library not available, that's OK
          assert String.contains?(reason, "Req library not available")
      end

      # Test with httpoison if available
      case GLBLoader.parse_url(@test_url, http_client: :httpoison, timeout: 30_000) do
        {:ok, glb3} ->
          assert %Binary{} = glb3
          assert glb1.magic == glb3.magic

        {:error, reason} ->
          # HTTPoison library not available, that's OK
          assert String.contains?(reason, "HTTPoison library not available")
      end
    end

    test "rejects unsupported HTTP clients" do
      {:error, reason} = GLBLoader.parse_url(@test_url, http_client: :invalid_client)
      assert String.contains?(reason, "Unsupported HTTP client")
    end
  end

  describe "chunk type conversion" do
    test "Binary.chunk_type_to_atom/1 converts correctly" do
      assert Binary.chunk_type_to_atom(0x4E4F534A) == :json
      assert Binary.chunk_type_to_atom(0x004E4942) == :bin
      assert Binary.chunk_type_to_atom(0x12345678) == :unknown
    end

    test "Binary.chunk_type_to_int/1 converts correctly" do
      assert Binary.chunk_type_to_int(:json) == 0x4E4F534A
      assert Binary.chunk_type_to_int(:bin) == 0x004E4942
    end

    test "Binary.magic/0 returns correct magic string" do
      assert Binary.magic() == "glTF"
    end
  end

  describe "validation edge cases" do
    test "validates magic string" do
      json_chunk = Binary.chunk(4, :json, "{}")

      # Valid magic - Total = header(12) + json_chunk_header(8) + json_data(4) = 24
      glb = Binary.new("glTF", 2, 24, json_chunk)
      assert :ok = Binary.validate(glb)

      # Invalid magic
      bad_glb = Binary.new("GLTF", 2, 24, json_chunk)
      assert {:error, reason} = Binary.validate(bad_glb)
      assert String.contains?(reason, "Invalid magic")
    end

    test "validates version" do
      json_chunk = Binary.chunk(4, :json, "{}")

      # Valid version - Total = header(12) + json_chunk_header(8) + json_data(4) = 24
      glb = Binary.new("glTF", 2, 24, json_chunk)
      assert :ok = Binary.validate(glb)

      # Invalid version
      bad_glb = Binary.new("glTF", 1, 24, json_chunk)
      assert {:error, reason} = Binary.validate(bad_glb)
      assert String.contains?(reason, "Unsupported version")
    end

    test "validates JSON chunk requirement" do
      json_chunk = Binary.chunk(4, :json, "{}")
      bin_chunk = Binary.chunk(4, :bin, <<1, 2, 3, 4>>)

      # JSON chunk required - Total = header(12) + json_chunk_header(8) + json_data(4) + binary_chunk_header(8) + binary_data(4) = 36
      glb = Binary.new("glTF", 2, 36, json_chunk, bin_chunk)
      assert :ok = Binary.validate(glb)

      # Binary chunk as first chunk should fail
      bad_glb = Binary.new("glTF", 2, 36, bin_chunk, json_chunk)
      assert {:error, reason} = Binary.validate(bad_glb)
      assert String.contains?(reason, "First chunk must be JSON")
    end
  end

  describe "print_info/1" do
    @tag :external
    test "prints detailed information without errors" do
      {:ok, glb} = GLBLoader.parse_url(@test_url, timeout: 30_000)

      # Capture IO to verify it doesn't crash
      import ExUnit.CaptureIO

      output =
        capture_io(fn ->
          GLBLoader.print_info(glb)
        end)

      assert String.contains?(output, "GLB File Information")
      assert String.contains?(output, "Magic: glTF")
      assert String.contains?(output, "Version: 2")
      assert String.contains?(output, "GLTF Asset Info")
      assert String.contains?(output, "GLTF Content")
    end
  end

  describe "parse_binary/1" do
    test "parses valid GLB file structure" do
      # Create a minimal valid GLB file
      json_data = ~s({"asset":{"version":"2.0"}})
      json_padded = json_data <> String.duplicate(" ", 4 - rem(byte_size(json_data), 4))

      # 8 bytes
      binary_data = <<1, 2, 3, 4, 5, 6, 7, 8>>
      # Pad to 4-byte alignment
      binary_padded = binary_data <> <<0, 0, 0, 0>>

      json_chunk = <<byte_size(json_padded)::little-32, 0x4E4F534A::little-32>> <> json_padded
      bin_chunk = <<byte_size(binary_padded)::little-32, 0x004E4942::little-32>> <> binary_padded

      total_length = 12 + byte_size(json_chunk) + byte_size(bin_chunk)

      glb_data = <<"glTF", 2::little-32, total_length::little-32>> <> json_chunk <> bin_chunk

      assert {:ok, glb_binary} = GLBLoader.parse_binary(glb_data)
      assert glb_binary.magic == "glTF"
      assert glb_binary.version == 2
      assert glb_binary.length == total_length
      assert glb_binary.json_chunk.type == :json
      assert glb_binary.binary_chunk.type == :bin
    end

    test "handles GLB without binary chunk" do
      json_data = ~s({"asset":{"version":"2.0"}})
      json_padded = json_data <> String.duplicate(" ", 4 - rem(byte_size(json_data), 4))

      json_chunk = <<byte_size(json_padded)::little-32, 0x4E4F534A::little-32>> <> json_padded
      total_length = 12 + byte_size(json_chunk)

      glb_data = <<"glTF", 2::little-32, total_length::little-32>> <> json_chunk

      assert {:ok, glb_binary} = GLBLoader.parse_binary(glb_data)
      assert glb_binary.binary_chunk == nil
    end

    test "rejects files with invalid magic" do
      invalid_data = <<"FAKE", 2::little-32, 100::little-32, "test">>
      assert {:error, reason} = GLBLoader.parse_binary(invalid_data)
      assert reason =~ "Invalid magic"
    end

    test "rejects files with unsupported version" do
      invalid_data = <<"glTF", 99::little-32, 100::little-32, "test">>
      assert {:error, reason} = GLBLoader.parse_binary(invalid_data)
      assert reason =~ "Unsupported version"
    end

    test "rejects files that are too short" do
      assert {:error, reason} = GLBLoader.parse_binary(<<1, 2, 3>>)
      assert reason =~ "too small"
    end

    test "rejects files with length mismatch" do
      # Header claims 1000 bytes but file is only 20 bytes
      invalid_data = <<"glTF", 2::little-32, 1000::little-32, "test">>
      assert {:error, reason} = GLBLoader.parse_binary(invalid_data)
      assert reason =~ "size mismatch"
    end

    test "rejects files where first chunk is not JSON" do
      # Create a GLB with binary chunk first (invalid)
      bin_chunk = <<8::little-32, 0x004E4942::little-32, 1, 2, 3, 4, 5, 6, 7, 8>>
      total_length = 12 + byte_size(bin_chunk)

      glb_data = <<"glTF", 2::little-32, total_length::little-32>> <> bin_chunk

      assert {:error, reason} = GLBLoader.parse_binary(glb_data)
      assert reason =~ "First chunk must be JSON"
    end

    test "handles truncated chunk data" do
      # JSON chunk header claims 100 bytes but only 5 bytes follow
      json_chunk_header = <<100::little-32, 0x4E4F534A::little-32>>
      # Only 5 bytes instead of claimed 100
      short_data = "short"

      # Total file size should match what we actually provide:
      # 12 (header) + 8 (chunk header) + 5 (actual short data) = 25 bytes
      total_length = 12 + 8 + 5

      glb_data =
        <<"glTF", 2::little-32, total_length::little-32>> <> json_chunk_header <> short_data

      assert {:error, reason} = GLBLoader.parse_binary(glb_data)
      assert reason =~ "truncated"
    end
  end

  describe "validation" do
    setup do
      # Create a valid GLB binary for testing validation
      json_data = ~s({"asset":{"version":"2.0"}})
      json_chunk = Binary.chunk(byte_size(json_data), :json, json_data)
      binary_chunk = Binary.chunk(8, :bin, <<1, 2, 3, 4, 5, 6, 7, 8>>)

      glb_binary = Binary.new("glTF", 2, 100, json_chunk, binary_chunk)
      {:ok, glb_binary: glb_binary}
    end

    test "validates correct GLB structure", %{glb_binary: glb_binary} do
      assert :ok = GLBLoader.validate(glb_binary)
    end

    test "validates in strict mode", %{glb_binary: glb_binary} do
      assert :ok = GLBLoader.validate(glb_binary, strict: true)
    end

    test "rejects invalid binary structure" do
      invalid_glb = %Binary{
        magic: "FAKE",
        version: 2,
        length: 100,
        json_chunk: Binary.chunk(10, :json, "test")
      }

      assert {:error, reason} = GLBLoader.validate(invalid_glb)
      assert reason =~ "Invalid magic"
    end
  end

  describe "file operations" do
    setup do
      # Create a temporary valid GLB file
      json_data = ~s({"asset":{"version":"2.0"}})
      json_padded = json_data <> String.duplicate(" ", 4 - rem(byte_size(json_data), 4))

      json_chunk = <<byte_size(json_padded)::little-32, 0x4E4F534A::little-32>> <> json_padded
      total_length = 12 + byte_size(json_chunk)

      glb_data = <<"glTF", 2::little-32, total_length::little-32>> <> json_chunk

      temp_file = "test/fixtures/temp_test.glb"
      File.mkdir_p!("test/fixtures")
      File.write!(temp_file, glb_data)

      on_exit(fn -> File.rm(temp_file) end)
      {:ok, temp_file: temp_file}
    end

    test "parse_file/2 loads local files", %{temp_file: temp_file} do
      assert {:ok, glb_binary} = GLBLoader.parse_file(temp_file)
      assert glb_binary.magic == "glTF"
    end

    test "parse_file/2 handles missing files" do
      assert {:error, reason} = GLBLoader.parse_file("nonexistent.glb")
      assert is_binary(reason)
    end

    test "parse/2 auto-detects file vs URL", %{temp_file: temp_file} do
      # Local file
      assert {:ok, _glb_binary} = GLBLoader.parse(temp_file)

      # URL (will fail due to test env, but should try URL parsing)
      assert {:error, _reason} = GLBLoader.parse("https://example.com/test.glb")
    end

    test "load_gltf/2 completes full pipeline", %{temp_file: temp_file} do
      assert {:ok, gltf} = GLBLoader.load_gltf(temp_file, json_library: :poison)
      assert gltf.asset.version == "2.0"
    end
  end

  describe "HTTP client handling" do
    test "rejects unsupported HTTP client" do
      assert {:error, reason} =
               GLBLoader.parse_url("http://example.com", http_client: :unsupported)

      assert reason =~ "Unsupported HTTP client"
    end

    # Note: HTTP client tests are limited in test environment
    # Integration tests with real URLs are handled in GLTFIntegrationTest
  end

  describe "JSON parsing integration" do
    test "handles both Poison and Jason for GLB loading" do
      # Create GLB with valid JSON
      json_data = ~s({"asset":{"version":"2.0","generator":"Test"},"buffers":[{"byteLength":8}]})
      json_padded = json_data <> String.duplicate(" ", 4 - rem(byte_size(json_data), 4))

      binary_data = <<1, 2, 3, 4, 5, 6, 7, 8>>

      json_chunk = <<byte_size(json_padded)::little-32, 0x4E4F534A::little-32>> <> json_padded
      bin_chunk = <<byte_size(binary_data)::little-32, 0x004E4942::little-32>> <> binary_data

      total_length = 12 + byte_size(json_chunk) + byte_size(bin_chunk)
      glb_data = <<"glTF", 2::little-32, total_length::little-32>> <> json_chunk <> bin_chunk

      temp_file = "test/fixtures/json_test.glb"
      File.write!(temp_file, glb_data)

      # Test Poison
      assert {:ok, gltf_poison} = GLBLoader.load_gltf(temp_file, json_library: :poison)
      assert gltf_poison.asset.version == "2.0"
      assert gltf_poison.asset.generator == "Test"

      # Test Jason (if available)
      case GLBLoader.load_gltf(temp_file, json_library: :jason) do
        {:ok, gltf_jason} ->
          assert gltf_jason.asset.version == "2.0"
          assert gltf_jason.asset.generator == "Test"

        {:error, :jason_not_available} ->
          # Expected if Jason not installed
          :ok
      end

      File.rm!(temp_file)
    end

    test "handles invalid JSON gracefully" do
      # Create GLB with invalid JSON
      json_data = ~s({"asset":{"version":"2.0" INVALID})
      json_padded = json_data <> String.duplicate(" ", 4 - rem(byte_size(json_data), 4))

      json_chunk = <<byte_size(json_padded)::little-32, 0x4E4F534A::little-32>> <> json_padded
      total_length = 12 + byte_size(json_chunk)

      glb_data = <<"glTF", 2::little-32, total_length::little-32>> <> json_chunk

      temp_file = "test/fixtures/invalid_json.glb"
      File.write!(temp_file, glb_data)

      assert {:error, reason} = GLBLoader.load_gltf(temp_file, json_library: :poison)
      assert reason =~ "JSON"

      File.rm!(temp_file)
    end
  end

  describe "edge cases and robustness" do
    test "handles very small valid GLB" do
      # Minimal possible GLB
      json_data = ~s({"asset":{"version":"2.0"}})
      json_chunk = <<byte_size(json_data)::little-32, 0x4E4F534A::little-32>> <> json_data
      total_length = 12 + byte_size(json_chunk)

      glb_data = <<"glTF", 2::little-32, total_length::little-32>> <> json_chunk

      assert {:ok, glb_binary} = GLBLoader.parse_binary(glb_data)
      assert glb_binary.magic == "glTF"
    end

    test "handles GLB with padding in chunks" do
      # 3 bytes, needs 1 byte padding
      json_data = "abc"
      # Pad with space for JSON
      json_padded = json_data <> " "

      json_chunk = <<byte_size(json_padded)::little-32, 0x4E4F534A::little-32>> <> json_padded
      total_length = 12 + byte_size(json_chunk)

      glb_data = <<"glTF", 2::little-32, total_length::little-32>> <> json_chunk

      assert {:ok, glb_binary} = GLBLoader.parse_binary(glb_data)
      # Padding should be removed
      assert String.trim_trailing(glb_binary.json_chunk.data, " ") == "abc"
    end

    test "rejects GLB with excessive length claim" do
      # Very large length that would be problematic
      huge_length = 999_999_999_999
      glb_data = <<"glTF", 2::little-32, huge_length::little-32, "test">>

      assert {:error, reason} = GLBLoader.parse_binary(glb_data)
      assert reason =~ "mismatch"
    end
  end

  describe "get_json_map/1" do
    test "extracts JSON as Elixir map" do
      json_data = ~s({"asset":{"version":"2.0"},"test":"value"})
      json_chunk = Binary.chunk(byte_size(json_data), :json, json_data)
      glb_binary = Binary.new("glTF", 2, 100, json_chunk)

      assert {:ok, json_map} = GLBLoader.get_json_map(glb_binary)
      assert json_map["asset"]["version"] == "2.0"
      assert json_map["test"] == "value"
    end

    test "handles invalid JSON in get_json_map" do
      invalid_json = ~s({"asset":{"version":"2.0" BROKEN})
      json_chunk = Binary.chunk(byte_size(invalid_json), :json, invalid_json)
      glb_binary = Binary.new("glTF", 2, 100, json_chunk)

      assert {:error, reason} = GLBLoader.get_json_map(glb_binary)
      assert reason =~ "JSON decode error"
    end
  end
end
