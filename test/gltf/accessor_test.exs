defmodule GLTF.AccessorTest do
  use ExUnit.Case, async: true
  doctest GLTF.Accessor

  alias GLTF.Accessor

  describe "load/1" do
    test "loads valid accessor data" do
      json_data = %{
        "bufferView" => 0,
        "byteOffset" => 0,
        # FLOAT
        "componentType" => 5126,
        "count" => 12,
        "type" => "VEC3",
        "max" => [1.0, 1.0, 1.0],
        "min" => [-1.0, -1.0, -1.0]
      }

      assert {:ok, accessor} = Accessor.load(json_data)
      assert accessor.buffer_view == 0
      assert accessor.byte_offset == 0
      assert accessor.component_type == 5126
      assert accessor.count == 12
      assert accessor.type == :vec3
      assert accessor.max == [1.0, 1.0, 1.0]
      assert accessor.min == [-1.0, -1.0, -1.0]
    end

    test "uses default values correctly" do
      json_data = %{
        # UNSIGNED_SHORT
        "componentType" => 5123,
        "count" => 6,
        "type" => "SCALAR"
      }

      assert {:ok, accessor} = Accessor.load(json_data)
      # No buffer view (sparse accessor)
      assert accessor.buffer_view == nil
      # Default
      assert accessor.byte_offset == 0
      # Default
      assert accessor.normalized == false
    end

    test "rejects accessor without component type" do
      json_data = %{
        "count" => 12,
        "type" => "VEC3"
      }

      assert {:error, :missing_component_type} = Accessor.load(json_data)
    end

    test "rejects accessor without count" do
      json_data = %{
        "componentType" => 5126,
        "type" => "VEC3"
      }

      assert {:error, :missing_count} = Accessor.load(json_data)
    end

    test "rejects accessor with invalid type" do
      json_data = %{
        "componentType" => 5126,
        "count" => 12,
        "type" => "INVALID_TYPE"
      }

      assert {:error, :invalid_accessor_type} = Accessor.load(json_data)
    end

    test "rejects unsupported component type" do
      json_data = %{
        # Invalid component type
        "componentType" => 9999,
        "count" => 12,
        "type" => "VEC3"
      }

      assert {:error, {:unsupported_component_type, 9999}} = Accessor.load(json_data)
    end
  end

  describe "accessor type parsing" do
    test "parses all valid accessor types" do
      type_mappings = [
        {"SCALAR", :scalar},
        {"VEC2", :vec2},
        {"VEC3", :vec3},
        {"VEC4", :vec4},
        {"MAT2", :mat2},
        {"MAT3", :mat3},
        {"MAT4", :mat4}
      ]

      for {json_type, expected_type} <- type_mappings do
        json_data = %{
          "componentType" => 5126,
          "count" => 1,
          "type" => json_type
        }

        assert {:ok, accessor} = Accessor.load(json_data)
        assert accessor.type == expected_type
      end
    end

    test "handles nil type gracefully" do
      json_data = %{
        "componentType" => 5126,
        "count" => 1
        # No type field
      }

      assert {:error, :invalid_accessor_type} = Accessor.load(json_data)
    end
  end

  describe "component type validation" do
    test "accepts all valid component types" do
      valid_component_types = [
        # BYTE
        5120,
        # UNSIGNED_BYTE
        5121,
        # SHORT
        5122,
        # UNSIGNED_SHORT
        5123,
        # UNSIGNED_INT
        5125,
        # FLOAT
        5126
      ]

      for component_type <- valid_component_types do
        json_data = %{
          "componentType" => component_type,
          "count" => 1,
          "type" => "SCALAR"
        }

        assert {:ok, accessor} = Accessor.load(json_data)
        assert accessor.component_type == component_type
      end
    end
  end

  describe "sparse accessor support" do
    test "loads sparse accessor data" do
      json_data = %{
        "componentType" => 5126,
        "count" => 100,
        "type" => "VEC3",
        "sparse" => %{
          "count" => 5,
          "indices" => %{
            "bufferView" => 1,
            "byteOffset" => 0,
            "componentType" => 5123
          },
          "values" => %{
            "bufferView" => 2,
            "byteOffset" => 0
          }
        }
      }

      assert {:ok, accessor} = Accessor.load(json_data)
      assert accessor.sparse != nil
      assert accessor.sparse.count == 5
      assert accessor.sparse.indices.buffer_view == 1
      assert accessor.sparse.indices.component_type == 5123
      assert accessor.sparse.values.buffer_view == 2
    end

    test "handles accessor without sparse data" do
      json_data = %{
        "bufferView" => 0,
        "componentType" => 5126,
        "count" => 12,
        "type" => "VEC3"
      }

      assert {:ok, accessor} = Accessor.load(json_data)
      assert accessor.sparse == nil
    end

    test "uses default byte offsets in sparse data" do
      json_data = %{
        "componentType" => 5126,
        "count" => 100,
        "type" => "VEC3",
        "sparse" => %{
          "count" => 5,
          "indices" => %{
            "bufferView" => 1,
            "componentType" => 5123
            # No byteOffset
          },
          "values" => %{
            "bufferView" => 2
            # No byteOffset
          }
        }
      }

      assert {:ok, accessor} = Accessor.load(json_data)
      assert accessor.sparse.indices.byte_offset == 0
      assert accessor.sparse.values.byte_offset == 0
    end
  end

  describe "element_size/1" do
    test "calculates correct sizes for different combinations" do
      test_cases = [
        # {component_type, accessor_type, expected_size}
        # BYTE + SCALAR = 1 * 1 = 1
        {5120, :scalar, 1},
        # UNSIGNED_BYTE + VEC2 = 1 * 2 = 2
        {5121, :vec2, 2},
        # SHORT + VEC3 = 2 * 3 = 6
        {5122, :vec3, 6},
        # UNSIGNED_SHORT + VEC4 = 2 * 4 = 8
        {5123, :vec4, 8},
        # UNSIGNED_INT + MAT2 = 4 * 4 = 16
        {5125, :mat2, 16},
        # FLOAT + MAT3 = 4 * 9 = 36
        {5126, :mat3, 36},
        # FLOAT + MAT4 = 4 * 16 = 64
        {5126, :mat4, 64}
      ]

      for {component_type, accessor_type, expected_size} <- test_cases do
        accessor = %Accessor{component_type: component_type, type: accessor_type}
        assert Accessor.element_size(accessor) == expected_size
      end
    end
  end

  describe "component_types/0 and accessor_types/0" do
    test "component_types returns correct mappings" do
      types = Accessor.component_types()

      assert types[5120] == {:signed_byte, 1}
      assert types[5121] == {:unsigned_byte, 1}
      assert types[5122] == {:signed_short, 2}
      assert types[5123] == {:unsigned_short, 2}
      assert types[5125] == {:unsigned_int, 4}
      assert types[5126] == {:float, 4}
    end

    test "accessor_types returns correct component counts" do
      types = Accessor.accessor_types()

      assert types[:scalar] == 1
      assert types[:vec2] == 2
      assert types[:vec3] == 3
      assert types[:vec4] == 4
      assert types[:mat2] == 4
      assert types[:mat3] == 9
      assert types[:mat4] == 16
    end
  end

  describe "validation edge cases" do
    test "handles zero count gracefully" do
      json_data = %{
        "componentType" => 5126,
        # Zero count
        "count" => 0,
        "type" => "VEC3"
      }

      assert {:error, :invalid_fields} = Accessor.load(json_data)
    end

    test "handles negative count gracefully" do
      json_data = %{
        "componentType" => 5126,
        # Negative count
        "count" => -5,
        "type" => "VEC3"
      }

      assert {:error, :invalid_fields} = Accessor.load(json_data)
    end

    test "handles non-integer count" do
      json_data = %{
        "componentType" => 5126,
        # String instead of integer
        "count" => "invalid",
        "type" => "VEC3"
      }

      assert {:error, :invalid_fields} = Accessor.load(json_data)
    end

    test "handles non-integer component type" do
      json_data = %{
        # String instead of integer
        "componentType" => "5126",
        "count" => 12,
        "type" => "VEC3"
      }

      assert {:error, :invalid_fields} = Accessor.load(json_data)
    end
  end

  describe "real-world usage patterns" do
    test "typical vertex position accessor" do
      # Common pattern: VEC3 positions using FLOAT
      json_data = %{
        "bufferView" => 0,
        "byteOffset" => 0,
        # FLOAT
        "componentType" => 5126,
        # 8 vertices for a cube
        "count" => 24,
        "type" => "VEC3",
        "max" => [1.0, 1.0, 1.0],
        "min" => [-1.0, -1.0, -1.0]
      }

      assert {:ok, accessor} = Accessor.load(json_data)
      # 4 bytes * 3 components
      assert Accessor.element_size(accessor) == 12
    end

    test "typical index accessor" do
      # Common pattern: SCALAR indices using UNSIGNED_SHORT
      json_data = %{
        "bufferView" => 1,
        "byteOffset" => 0,
        # UNSIGNED_SHORT
        "componentType" => 5123,
        # 36 indices for a cube
        "count" => 36,
        "type" => "SCALAR"
      }

      assert {:ok, accessor} = Accessor.load(json_data)
      # 2 bytes * 1 component
      assert Accessor.element_size(accessor) == 2
    end

    test "texture coordinate accessor" do
      # Common pattern: VEC2 texture coordinates using FLOAT
      json_data = %{
        "bufferView" => 2,
        # FLOAT
        "componentType" => 5126,
        "count" => 24,
        "type" => "VEC2",
        "max" => [1.0, 1.0],
        "min" => [0.0, 0.0]
      }

      assert {:ok, accessor} = Accessor.load(json_data)
      # 4 bytes * 2 components
      assert Accessor.element_size(accessor) == 8
    end

    test "matrix accessor for skinning" do
      # Common pattern: MAT4 matrices for inverse bind matrices
      json_data = %{
        "bufferView" => 3,
        # FLOAT
        "componentType" => 5126,
        # 4 bones
        "count" => 4,
        "type" => "MAT4"
      }

      assert {:ok, accessor} = Accessor.load(json_data)
      # 4 bytes * 16 components
      assert Accessor.element_size(accessor) == 64
    end
  end
end
