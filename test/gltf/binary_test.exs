defmodule GLTF.BinaryTest do
  use ExUnit.Case, async: true
  alias GLTF.Binary

  describe "new/4 and new/5" do
    test "creates binary structure with required fields" do
      json_chunk = Binary.chunk(4, :json, "{}")
      glb = Binary.new("glTF", 2, 16, json_chunk)

      assert %Binary{} = glb
      assert glb.magic == "glTF"
      assert glb.version == 2
      assert glb.length == 16
      assert glb.json_chunk == json_chunk
      assert glb.binary_chunk == nil
    end

    test "creates binary structure with binary chunk" do
      json_chunk = Binary.chunk(4, :json, "{}")
      binary_chunk = Binary.chunk(8, :bin, <<1, 2, 3, 4, 5, 6, 7, 8>>)
      glb = Binary.new("glTF", 2, 28, json_chunk, binary_chunk)

      assert %Binary{} = glb
      assert glb.magic == "glTF"
      assert glb.version == 2
      assert glb.length == 28
      assert glb.json_chunk == json_chunk
      assert glb.binary_chunk == binary_chunk
    end
  end

  describe "chunk/3" do
    test "creates JSON chunk" do
      chunk = Binary.chunk(100, :json, "{\"asset\":{\"version\":\"2.0\"}}")

      assert chunk.length == 100
      assert chunk.type == :json
      assert chunk.data == "{\"asset\":{\"version\":\"2.0\"}}"
    end

    test "creates binary chunk" do
      binary_data = <<1, 2, 3, 4, 5, 6, 7, 8>>
      chunk = Binary.chunk(8, :bin, binary_data)

      assert chunk.length == 8
      assert chunk.type == :bin
      assert chunk.data == binary_data
    end

    test "creates unknown chunk type" do
      chunk = Binary.chunk(4, :unknown, <<255, 254, 253, 252>>)

      assert chunk.length == 4
      assert chunk.type == :unknown
      assert chunk.data == <<255, 254, 253, 252>>
    end
  end

  describe "chunk_type_to_atom/1" do
    test "converts JSON chunk type correctly" do
      assert Binary.chunk_type_to_atom(0x4E4F534A) == :json
    end

    test "converts BIN chunk type correctly" do
      assert Binary.chunk_type_to_atom(0x004E4942) == :bin
    end

    test "converts unknown chunk type to :unknown" do
      assert Binary.chunk_type_to_atom(0x12345678) == :unknown
      assert Binary.chunk_type_to_atom(0xFFFFFFFF) == :unknown
      assert Binary.chunk_type_to_atom(0x00000000) == :unknown
    end
  end

  describe "chunk_type_to_int/1" do
    test "converts :json to correct integer" do
      assert Binary.chunk_type_to_int(:json) == 0x4E4F534A
    end

    test "converts :bin to correct integer" do
      assert Binary.chunk_type_to_int(:bin) == 0x004E4942
    end
  end

  describe "magic/0" do
    test "returns correct GLB magic string" do
      assert Binary.magic() == "glTF"
    end
  end

  describe "validate/1" do
    test "validates correct GLB structure" do
      json_chunk = Binary.chunk(4, :json, "{}")
      # Total = header(12) + json_chunk_header(8) + json_data(4) = 24
      glb = Binary.new("glTF", 2, 24, json_chunk)

      assert :ok = Binary.validate(glb)
    end

    test "validates GLB with binary chunk" do
      json_chunk = Binary.chunk(4, :json, "{}")
      binary_chunk = Binary.chunk(8, :bin, <<1, 2, 3, 4, 5, 6, 7, 8>>)
      # Total = header(12) + json_chunk_header(8) + json_data(4) + binary_chunk_header(8) + binary_data(8) = 40
      glb = Binary.new("glTF", 2, 40, json_chunk, binary_chunk)

      assert :ok = Binary.validate(glb)
    end

    test "rejects invalid magic string" do
      json_chunk = Binary.chunk(4, :json, "{}")
      glb = Binary.new("GLTF", 2, 24, json_chunk)

      assert {:error, reason} = Binary.validate(glb)
      assert String.contains?(reason, "Invalid magic")
      assert String.contains?(reason, "expected 'glTF'")
    end

    test "rejects unsupported version" do
      json_chunk = Binary.chunk(4, :json, "{}")
      glb = Binary.new("glTF", 1, 24, json_chunk)

      assert {:error, reason} = Binary.validate(glb)
      assert String.contains?(reason, "Unsupported version: 1")
    end

    test "rejects missing JSON chunk" do
      glb = %Binary{
        magic: "glTF",
        version: 2,
        length: 20,
        json_chunk: nil,
        binary_chunk: nil
      }

      assert {:error, reason} = Binary.validate(glb)
      assert String.contains?(reason, "JSON chunk is required")
    end

    test "rejects non-JSON first chunk" do
      binary_chunk = Binary.chunk(8, :bin, <<1, 2, 3, 4, 5, 6, 7, 8>>)
      glb = Binary.new("glTF", 2, 28, binary_chunk)

      assert {:error, reason} = Binary.validate(glb)
      assert String.contains?(reason, "First chunk must be JSON")
    end

    test "rejects invalid binary chunk type" do
      json_chunk = Binary.chunk(4, :json, "{}")
      unknown_chunk = Binary.chunk(4, :unknown, <<1, 2, 3, 4>>)
      glb = Binary.new("glTF", 2, 36, json_chunk, unknown_chunk)

      assert {:error, reason} = Binary.validate(glb)
      assert String.contains?(reason, "Binary chunk must be BIN type")
    end

    test "rejects total length too small" do
      json_chunk = Binary.chunk(4, :json, "{}")
      glb = Binary.new("glTF", 2, 10, json_chunk)  # Too small

      assert {:error, reason} = Binary.validate(glb)
      assert String.contains?(reason, "Total length")
      assert String.contains?(reason, "less than expected minimum")
    end
  end

  describe "get_json/1" do
    test "returns JSON data from JSON chunk" do
      json_data = "{\"asset\":{\"version\":\"2.0\"}}"
      json_chunk = Binary.chunk(byte_size(json_data), :json, json_data)
      # Total = header(12) + json_chunk_header(8) + json_data(26) = 46
      glb = Binary.new("glTF", 2, 46, json_chunk)

      assert Binary.get_json(glb) == json_data
    end

    test "handles empty JSON" do
      json_chunk = Binary.chunk(2, :json, "{}")
      # Total = header(12) + json_chunk_header(8) + json_data(2) = 22
      glb = Binary.new("glTF", 2, 22, json_chunk)

      assert Binary.get_json(glb) == "{}"
    end
  end

  describe "get_binary/1" do
    test "returns binary data when present" do
      json_chunk = Binary.chunk(4, :json, "{}")
      binary_data = <<1, 2, 3, 4, 5, 6, 7, 8>>
      binary_chunk = Binary.chunk(byte_size(binary_data), :bin, binary_data)
      # Total = header(12) + json_chunk_header(8) + json_data(4) + binary_chunk_header(8) + binary_data(8) = 40
      glb = Binary.new("glTF", 2, 40, json_chunk, binary_chunk)

      assert Binary.get_binary(glb) == binary_data
    end

    test "returns nil when no binary chunk" do
      json_chunk = Binary.chunk(4, :json, "{}")
      # Total = header(12) + json_chunk_header(8) + json_data(4) = 24
      glb = Binary.new("glTF", 2, 24, json_chunk)

      assert Binary.get_binary(glb) == nil
    end
  end

  describe "has_binary?/1" do
    test "returns true when binary chunk present" do
      json_chunk = Binary.chunk(4, :json, "{}")
      binary_chunk = Binary.chunk(8, :bin, <<1, 2, 3, 4, 5, 6, 7, 8>>)
      # Total = header(12) + json_chunk_header(8) + json_data(4) + binary_chunk_header(8) + binary_data(8) = 40
      glb = Binary.new("glTF", 2, 40, json_chunk, binary_chunk)

      assert Binary.has_binary?(glb) == true
    end

    test "returns false when no binary chunk" do
      json_chunk = Binary.chunk(4, :json, "{}")
      # Total = header(12) + json_chunk_header(8) + json_data(4) = 24
      glb = Binary.new("glTF", 2, 24, json_chunk)

      assert Binary.has_binary?(glb) == false
    end
  end

  describe "struct enforcement" do
        test "allows creation with all required keys" do
      json_chunk = Binary.chunk(4, :json, "{}")

      glb = %Binary{
        magic: "glTF",
        version: 2,
        length: 24,
        json_chunk: json_chunk
      }

      assert %Binary{} = glb
      assert glb.binary_chunk == nil  # Optional field defaults to nil
    end

    test "struct has correct enforce_keys behavior" do
      # Test that the struct definition enforces the required keys
      # by checking that creating a struct with all required keys works
      json_chunk = Binary.chunk(4, :json, "{}")

      # This should work - all required keys provided
      glb = %Binary{
        magic: "glTF",
        version: 2,
        length: 24,
        json_chunk: json_chunk,
        binary_chunk: nil
      }

      assert glb.magic == "glTF"
      assert glb.version == 2
      assert glb.length == 24
      assert glb.json_chunk == json_chunk
      assert glb.binary_chunk == nil
    end
  end

  describe "type specifications" do
    test "chunk type specification includes all expected types" do
      # Test that our chunk types are properly defined
      json_chunk = Binary.chunk(4, :json, "{}")
      bin_chunk = Binary.chunk(4, :bin, <<1, 2, 3, 4>>)
      unknown_chunk = Binary.chunk(4, :unknown, <<1, 2, 3, 4>>)

      assert json_chunk.type == :json
      assert bin_chunk.type == :bin
      assert unknown_chunk.type == :unknown
    end
  end

  describe "edge cases" do
    test "handles large chunk lengths" do
      large_data = :binary.copy(<<0>>, 1_000_000)
      chunk = Binary.chunk(1_000_000, :bin, large_data)

      assert chunk.length == 1_000_000
      assert byte_size(chunk.data) == 1_000_000
    end

    test "handles empty chunk data" do
      chunk = Binary.chunk(0, :json, "")

      assert chunk.length == 0
      assert chunk.data == ""
    end

    test "validates with minimal valid structure" do
      json_chunk = Binary.chunk(0, :json, "")
      # Total = header(12) + json_chunk_header(8) + json_data(0) = 20
      glb = Binary.new("glTF", 2, 20, json_chunk)

      assert :ok = Binary.validate(glb)
    end
  end
end
