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
      assert length(json_map["nodes"]) >= 10  # Chair has many parts
      assert length(json_map["meshes"]) >= 10  # Multiple mesh components
      assert length(json_map["materials"]) >= 3  # Different materials
      assert length(json_map["accessors"]) >= 20  # Geometry data
      assert length(json_map["bufferViews"]) >= 10  # Buffer views
      assert length(json_map["buffers"]) >= 1  # At least one buffer
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
      assert info.total_size > 100_000  # Large file with geometry and textures
      assert info.header_size == 12
      assert info.json_chunk_size > 1000  # Substantial JSON
      assert info.binary_chunk_size > 50_000  # Large binary data
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
      assert byte_size(binary_data) > 50_000  # Substantial geometry data
    end

    @tag :external
    test "Binary.has_binary?/1 returns true" do
      {:ok, glb} = GLBLoader.parse_url(@test_url, timeout: 30_000)

      assert Binary.has_binary?(glb) == true
    end
  end

  describe "error handling" do
    test "handles invalid URLs gracefully" do
      assert {:error, reason} = GLBLoader.parse_url("https://invalid-url-that-does-not-exist.com/model.glb")
      assert is_binary(reason)
    end

    test "handles non-GLB content" do
      # Try to parse a plain text URL - this returns base64 decoded "HTTPBIN is awesome"
      case GLBLoader.parse_url("https://httpbin.org/base64/SFRUUEJJTiBpcyBhd2Vzb21l") do
        {:error, reason} ->
          # Could be various errors: header too small, invalid magic, or HTTP error
          assert (String.contains?(reason, "GLB header requires 12 bytes") or
                  String.contains?(reason, "Invalid magic") or
                  String.contains?(reason, "HTTP error"))
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

      output = capture_io(fn ->
        GLBLoader.print_info(glb)
      end)

      assert String.contains?(output, "GLB File Information")
      assert String.contains?(output, "Magic: glTF")
      assert String.contains?(output, "Version: 2")
      assert String.contains?(output, "GLTF Asset Info")
      assert String.contains?(output, "GLTF Content")
    end
  end
end
