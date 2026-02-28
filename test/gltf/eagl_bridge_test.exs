defmodule GLTF.EAGLBridgeTest do
  @moduledoc """
  Tests for the GLTF.EAGL bridge module's data extraction pipeline.

  These tests verify that binary data from GLTF accessors is correctly parsed
  and prepared for EAGL's Buffer functions, without requiring an OpenGL context.
  """
  use ExUnit.Case, async: true
  use EAGL.Const

  alias GLTF.{Accessor, BufferView, Buffer, DataStore, Mesh}

  # ============================================================================
  # Binary Parsing Tests
  # ============================================================================

  describe "binary_to_float_list/1" do
    test "parses little-endian float32 binary correctly" do
      # 1.0 as little-endian float32 = <<0, 0, 128, 63>>
      binary = <<1.0::little-float-32, 2.0::little-float-32, 3.0::little-float-32>>
      assert {:ok, [1.0, 2.0, 3.0]} = GLTF.EAGL.binary_to_float_list(binary)
    end

    test "parses negative floats" do
      binary = <<-1.0::little-float-32, -0.5::little-float-32>>
      assert {:ok, [val1, val2]} = GLTF.EAGL.binary_to_float_list(binary)
      assert_in_delta val1, -1.0, 0.0001
      assert_in_delta val2, -0.5, 0.0001
    end

    test "parses zero correctly" do
      binary = <<0.0::little-float-32>>
      assert {:ok, [0.0]} = GLTF.EAGL.binary_to_float_list(binary)
    end

    test "handles empty binary" do
      assert {:ok, []} = GLTF.EAGL.binary_to_float_list(<<>>)
    end

    test "returns error for non-binary input" do
      assert {:error, _} = GLTF.EAGL.binary_to_float_list([1.0, 2.0])
    end
  end

  describe "binary_to_index_list/2" do
    test "parses UNSIGNED_SHORT (16-bit) indices" do
      binary = <<0::little-unsigned-16, 1::little-unsigned-16, 2::little-unsigned-16>>

      assert {:ok, [0, 1, 2]} =
               GLTF.EAGL.binary_to_index_list(binary, @gl_unsigned_short)
    end

    test "parses UNSIGNED_INT (32-bit) indices" do
      binary = <<0::little-unsigned-32, 1::little-unsigned-32, 2::little-unsigned-32>>

      assert {:ok, [0, 1, 2]} =
               GLTF.EAGL.binary_to_index_list(binary, @gl_unsigned_int)
    end

    test "parses UNSIGNED_BYTE (8-bit) indices" do
      binary = <<0, 1, 2, 255>>

      assert {:ok, [0, 1, 2, 255]} =
               GLTF.EAGL.binary_to_index_list(binary, @gl_unsigned_byte)
    end

    test "handles large UNSIGNED_SHORT values" do
      binary = <<65535::little-unsigned-16>>

      assert {:ok, [65535]} =
               GLTF.EAGL.binary_to_index_list(binary, @gl_unsigned_short)
    end

    test "handles large UNSIGNED_INT values" do
      binary = <<100_000::little-unsigned-32>>

      assert {:ok, [100_000]} =
               GLTF.EAGL.binary_to_index_list(binary, @gl_unsigned_int)
    end

    test "returns error for unsupported component type" do
      assert {:error, _} = GLTF.EAGL.binary_to_index_list(<<0, 1>>, @gl_float)
    end
  end

  # ============================================================================
  # Accessor Data Extraction Tests
  # ============================================================================

  describe "accessor data extraction through GLTF.get_accessor_data/3" do
    setup do
      # Create a simple GLTF document with position data for a triangle:
      # 3 vertices, each with 3 float32 components = 36 bytes
      position_data =
        <<0.0::little-float-32, 0.0::little-float-32, 0.0::little-float-32, 1.0::little-float-32,
          0.0::little-float-32, 0.0::little-float-32, 0.5::little-float-32, 1.0::little-float-32,
          0.0::little-float-32>>

      # Index data: 3 unsigned short indices
      index_data = <<0::little-unsigned-16, 1::little-unsigned-16, 2::little-unsigned-16>>

      # Combined buffer: positions then indices
      combined_buffer = position_data <> index_data

      data_store =
        DataStore.new()
        |> DataStore.store_glb_buffer(0, combined_buffer)

      gltf = %GLTF{
        asset: %GLTF.Asset{version: "2.0"},
        buffers: [%Buffer{byte_length: byte_size(combined_buffer)}],
        buffer_views: [
          # Buffer view 0: positions (36 bytes at offset 0)
          %BufferView{buffer: 0, byte_offset: 0, byte_length: 36},
          # Buffer view 1: indices (6 bytes at offset 36)
          %BufferView{buffer: 0, byte_offset: 36, byte_length: 6}
        ],
        accessors: [
          # Accessor 0: positions (VEC3, FLOAT, 3 elements)
          %Accessor{
            buffer_view: 0,
            byte_offset: 0,
            component_type: @gl_float,
            count: 3,
            type: :vec3
          },
          # Accessor 1: indices (SCALAR, UNSIGNED_SHORT, 3 elements)
          %Accessor{
            buffer_view: 1,
            byte_offset: 0,
            component_type: @gl_unsigned_short,
            count: 3,
            type: :scalar
          }
        ],
        meshes: [
          %Mesh{
            primitives: [
              %Mesh.Primitive{
                attributes: %{"POSITION" => 0},
                indices: 1,
                mode: :triangles
              }
            ]
          }
        ]
      }

      {:ok, gltf: gltf, data_store: data_store}
    end

    test "extracts position data correctly", %{gltf: gltf, data_store: data_store} do
      assert {:ok, binary_data} = GLTF.get_accessor_data(gltf, data_store, 0)
      assert {:ok, floats} = GLTF.EAGL.binary_to_float_list(binary_data)
      assert length(floats) == 9
      assert Enum.at(floats, 0) == 0.0
      assert Enum.at(floats, 3) == 1.0
      assert Enum.at(floats, 7) == 1.0
    end

    test "extracts index data correctly", %{gltf: gltf, data_store: data_store} do
      assert {:ok, binary_data} = GLTF.get_accessor_data(gltf, data_store, 1)

      assert {:ok, indices} =
               GLTF.EAGL.binary_to_index_list(binary_data, @gl_unsigned_short)

      assert indices == [0, 1, 2]
    end

    test "handles accessor byte offset within buffer view", %{data_store: _data_store} do
      # Create a buffer with 4 bytes of padding then 3 floats
      padded_buffer = <<0::32, 1.0::little-float-32, 2.0::little-float-32, 3.0::little-float-32>>

      padded_store =
        DataStore.new()
        |> DataStore.store_glb_buffer(0, padded_buffer)

      gltf = %GLTF{
        asset: %GLTF.Asset{version: "2.0"},
        buffers: [%Buffer{byte_length: byte_size(padded_buffer)}],
        buffer_views: [
          %BufferView{buffer: 0, byte_offset: 0, byte_length: byte_size(padded_buffer)}
        ],
        accessors: [
          %Accessor{
            buffer_view: 0,
            byte_offset: 4,
            component_type: @gl_float,
            count: 3,
            type: :scalar
          }
        ]
      }

      assert {:ok, binary_data} = GLTF.get_accessor_data(gltf, padded_store, 0)
      assert {:ok, [1.0, 2.0, 3.0]} = GLTF.EAGL.binary_to_float_list(binary_data)
    end
  end

  # ============================================================================
  # Vertex Data Interleaving Tests
  # ============================================================================

  describe "interleave_vertex_data/1" do
    test "interleaves position-only data" do
      pos_binary =
        <<0.0::little-float-32, 1.0::little-float-32, 2.0::little-float-32, 3.0::little-float-32,
          4.0::little-float-32, 5.0::little-float-32>>

      vertex_data = %{
        position: pos_binary,
        attributes: [],
        indices: nil
      }

      assert {:ok, vertices} = GLTF.EAGL.interleave_vertex_data(vertex_data)
      assert vertices == [0.0, 1.0, 2.0, 3.0, 4.0, 5.0]
    end

    test "interleaves position + normal data" do
      pos_binary = <<0.0::little-float-32, 0.0::little-float-32, 0.0::little-float-32>>
      norm_binary = <<0.0::little-float-32, 1.0::little-float-32, 0.0::little-float-32>>

      vertex_data =
        %{"NORMAL" => norm_binary}
        |> Map.put(:position, pos_binary)
        |> Map.put(:attributes, [])
        |> Map.put(:indices, nil)

      assert {:ok, vertices} = GLTF.EAGL.interleave_vertex_data(vertex_data)
      # position(3) + normal(3) = 6 floats per vertex
      assert vertices == [0.0, 0.0, 0.0, 0.0, 1.0, 0.0]
    end

    test "interleaves position + normal + texcoord data" do
      pos_binary = <<1.0::little-float-32, 2.0::little-float-32, 3.0::little-float-32>>
      norm_binary = <<0.0::little-float-32, 1.0::little-float-32, 0.0::little-float-32>>
      tex_binary = <<0.5::little-float-32, 0.5::little-float-32>>

      vertex_data =
        %{"NORMAL" => norm_binary, "TEXCOORD_0" => tex_binary}
        |> Map.put(:position, pos_binary)
        |> Map.put(:attributes, [])
        |> Map.put(:indices, nil)

      assert {:ok, vertices} = GLTF.EAGL.interleave_vertex_data(vertex_data)
      # position(3) + normal(3) + texcoord(2) = 8 floats per vertex
      assert length(vertices) == 8
      # Position
      assert Enum.slice(vertices, 0, 3) == [1.0, 2.0, 3.0]
      # Normal
      assert Enum.slice(vertices, 3, 3) == [0.0, 1.0, 0.0]
      # Texcoord (V should be flipped: 1.0 - 0.5 = 0.5)
      assert Enum.at(vertices, 6) == 0.5
      assert_in_delta Enum.at(vertices, 7), 0.5, 0.0001
    end

    test "flips V texture coordinate for OpenGL convention" do
      pos_binary = <<0.0::little-float-32, 0.0::little-float-32, 0.0::little-float-32>>
      # V = 0.0 in GLTF should become 1.0 in OpenGL
      tex_binary = <<0.0::little-float-32, 0.0::little-float-32>>

      vertex_data =
        %{"TEXCOORD_0" => tex_binary}
        |> Map.put(:position, pos_binary)
        |> Map.put(:attributes, [])
        |> Map.put(:indices, nil)

      assert {:ok, vertices} = GLTF.EAGL.interleave_vertex_data(vertex_data)
      # V coordinate should be flipped: 1.0 - 0.0 = 1.0
      assert_in_delta Enum.at(vertices, 4), 1.0, 0.0001
    end
  end

  # ============================================================================
  # Vertex Attribute Layout Tests
  # ============================================================================

  describe "get_vertex_attributes/1" do
    test "position-only produces correct attribute" do
      vertex_data = %{position: <<>>, attributes: [], indices: nil}
      assert {:ok, attrs} = GLTF.EAGL.get_vertex_attributes(vertex_data)
      assert length(attrs) == 1
      assert Enum.at(attrs, 0).location == 0
      assert Enum.at(attrs, 0).size == 3
    end

    test "position + normal produces correct attributes" do
      vertex_data =
        %{"NORMAL" => <<>>}
        |> Map.put(:position, <<>>)
        |> Map.put(:attributes, [])
        |> Map.put(:indices, nil)

      assert {:ok, attrs} = GLTF.EAGL.get_vertex_attributes(vertex_data)
      assert length(attrs) == 2
      # Position at location 0
      assert Enum.at(attrs, 0).location == 0
      assert Enum.at(attrs, 0).size == 3
      # Normal at location 1
      assert Enum.at(attrs, 1).location == 1
      assert Enum.at(attrs, 1).size == 3
    end

    test "position + normal + texcoord produces correct attributes" do
      vertex_data =
        %{"NORMAL" => <<>>, "TEXCOORD_0" => <<>>}
        |> Map.put(:position, <<>>)
        |> Map.put(:attributes, [])
        |> Map.put(:indices, nil)

      assert {:ok, attrs} = GLTF.EAGL.get_vertex_attributes(vertex_data)
      assert length(attrs) == 3
      # Sequential locations 0, 1, 2
      assert Enum.at(attrs, 0).location == 0
      assert Enum.at(attrs, 1).location == 1
      assert Enum.at(attrs, 2).location == 2
      # Sizes: 3, 3, 2
      assert Enum.at(attrs, 0).size == 3
      assert Enum.at(attrs, 1).size == 3
      assert Enum.at(attrs, 2).size == 2
      # Total stride: (3 + 3 + 2) * 4 = 32 bytes
      assert Enum.at(attrs, 0).stride == 32
    end
  end

  # ============================================================================
  # Material Conversion Tests
  # ============================================================================

  describe "material_to_uniforms/1" do
    test "converts default PBR material" do
      pbr = %GLTF.Material.PbrMetallicRoughness{
        base_color_factor: [1.0, 0.0, 0.0, 1.0],
        metallic_factor: 0.5,
        roughness_factor: 0.8
      }

      material = %GLTF.Material{pbr_metallic_roughness: pbr}
      uniforms = GLTF.EAGL.material_to_uniforms(material)

      assert Keyword.has_key?(uniforms, :baseColorFactor)
      assert Keyword.get(uniforms, :metallicFactor) == 0.5
      assert Keyword.get(uniforms, :roughnessFactor) == 0.8
    end

    test "handles material with no PBR properties" do
      material = %GLTF.Material{}
      uniforms = GLTF.EAGL.material_to_uniforms(material)
      assert uniforms == []
    end

    test "includes emissive factor when present" do
      material = %GLTF.Material{emissive_factor: [1.0, 0.5, 0.0]}
      uniforms = GLTF.EAGL.material_to_uniforms(material)
      assert Keyword.has_key?(uniforms, :emissiveFactor)
    end

    test "includes alpha properties when present" do
      material = %GLTF.Material{alpha_mode: :mask, alpha_cutoff: 0.5}
      uniforms = GLTF.EAGL.material_to_uniforms(material)
      assert Keyword.has_key?(uniforms, :alphaMode)
      assert Keyword.get(uniforms, :alphaCutoff) == 0.5
    end
  end

  # ============================================================================
  # End-to-End Data Pipeline Tests (no GL context needed)
  # ============================================================================

  describe "extract_vertex_data (end-to-end without GL)" do
    test "extracts complete vertex data from a simple indexed mesh" do
      # Build a minimal GLTF triangle with positions and indices
      pos_data =
        <<0.0::little-float-32, 0.0::little-float-32, 0.0::little-float-32, 1.0::little-float-32,
          0.0::little-float-32, 0.0::little-float-32, 0.5::little-float-32, 1.0::little-float-32,
          0.0::little-float-32>>

      idx_data = <<0::little-unsigned-16, 1::little-unsigned-16, 2::little-unsigned-16>>

      buffer = pos_data <> idx_data
      data_store = DataStore.new() |> DataStore.store_glb_buffer(0, buffer)

      gltf = %GLTF{
        asset: %GLTF.Asset{version: "2.0"},
        buffers: [%Buffer{byte_length: byte_size(buffer)}],
        buffer_views: [
          %BufferView{buffer: 0, byte_offset: 0, byte_length: 36},
          %BufferView{buffer: 0, byte_offset: 36, byte_length: 6}
        ],
        accessors: [
          %Accessor{
            buffer_view: 0,
            byte_offset: 0,
            component_type: @gl_float,
            count: 3,
            type: :vec3
          },
          %Accessor{
            buffer_view: 1,
            byte_offset: 0,
            component_type: @gl_unsigned_short,
            count: 3,
            type: :scalar
          }
        ],
        meshes: [
          %Mesh{
            primitives: [
              %Mesh.Primitive{
                attributes: %{"POSITION" => 0},
                indices: 1,
                mode: :triangles
              }
            ]
          }
        ]
      }

      # Test the full extraction pipeline (without VAO creation)
      assert {:ok, vertex_data} =
               GLTF.EAGL.extract_vertex_data(
                 gltf,
                 data_store,
                 List.first(gltf.meshes).primitives |> List.first()
               )

      # Verify position data is present
      assert is_binary(vertex_data.position)
      assert {:ok, positions} = GLTF.EAGL.binary_to_float_list(vertex_data.position)
      assert length(positions) == 9

      # Verify index data is present and uses UNSIGNED_SHORT
      assert is_binary(vertex_data.indices)
      assert vertex_data.index_component_type == @gl_unsigned_short
    end

    test "extracts mesh with positions, normals, and texcoords" do
      pos_data = <<
        0.0::little-float-32,
        0.0::little-float-32,
        0.0::little-float-32,
        1.0::little-float-32,
        0.0::little-float-32,
        0.0::little-float-32,
        0.5::little-float-32,
        1.0::little-float-32,
        0.0::little-float-32
      >>

      norm_data = <<
        0.0::little-float-32,
        0.0::little-float-32,
        1.0::little-float-32,
        0.0::little-float-32,
        0.0::little-float-32,
        1.0::little-float-32,
        0.0::little-float-32,
        0.0::little-float-32,
        1.0::little-float-32
      >>

      tex_data = <<
        0.0::little-float-32,
        0.0::little-float-32,
        1.0::little-float-32,
        0.0::little-float-32,
        0.5::little-float-32,
        1.0::little-float-32
      >>

      buffer = pos_data <> norm_data <> tex_data
      data_store = DataStore.new() |> DataStore.store_glb_buffer(0, buffer)

      gltf = %GLTF{
        asset: %GLTF.Asset{version: "2.0"},
        buffers: [%Buffer{byte_length: byte_size(buffer)}],
        buffer_views: [
          %BufferView{buffer: 0, byte_offset: 0, byte_length: 36},
          %BufferView{buffer: 0, byte_offset: 36, byte_length: 36},
          %BufferView{buffer: 0, byte_offset: 72, byte_length: 24}
        ],
        accessors: [
          %Accessor{
            buffer_view: 0,
            byte_offset: 0,
            component_type: @gl_float,
            count: 3,
            type: :vec3
          },
          %Accessor{
            buffer_view: 1,
            byte_offset: 0,
            component_type: @gl_float,
            count: 3,
            type: :vec3
          },
          %Accessor{
            buffer_view: 2,
            byte_offset: 0,
            component_type: @gl_float,
            count: 3,
            type: :vec2
          }
        ],
        meshes: [
          %Mesh{
            primitives: [
              %Mesh.Primitive{
                attributes: %{"POSITION" => 0, "NORMAL" => 1, "TEXCOORD_0" => 2},
                mode: :triangles
              }
            ]
          }
        ]
      }

      primitive = gltf.meshes |> List.first() |> Map.get(:primitives) |> List.first()
      assert {:ok, vertex_data} = GLTF.EAGL.extract_vertex_data(gltf, data_store, primitive)

      assert Map.has_key?(vertex_data, "NORMAL")
      assert Map.has_key?(vertex_data, "TEXCOORD_0")

      # Interleave and verify layout
      assert {:ok, interleaved} = GLTF.EAGL.interleave_vertex_data(vertex_data)
      # 3 vertices * 8 floats each (pos3 + norm3 + tex2) = 24
      assert length(interleaved) == 24
    end
  end

  # ============================================================================
  # Integration test with real GLB file (Box.glb)
  # ============================================================================

  describe "integration with Box.glb sample" do
    setup do
      box_path = "test/fixtures/samples/Box.glb"

      if File.exists?(box_path) do
        {:ok, glb} = GLTF.GLBLoader.parse_file(box_path)
        {:ok, gltf} = GLTF.GLBLoader.load_gltf(box_path, json_library: :poison)

        data_store = DataStore.new()
        binary_data = GLTF.Binary.get_binary(glb)

        data_store =
          if binary_data do
            DataStore.store_glb_buffer(data_store, 0, binary_data)
          else
            data_store
          end

        {:ok, gltf: gltf, data_store: data_store}
      else
        {:ok, skip: true}
      end
    end

    test "extracts vertex data from Box mesh", context do
      if context[:skip] do
        IO.puts("Skipping Box.glb test - file not downloaded")
      else
        %{gltf: gltf, data_store: data_store} = context

        # Box has 1 mesh with 1 primitive
        assert length(gltf.meshes) == 1
        mesh = List.first(gltf.meshes)
        assert length(mesh.primitives) == 1

        primitive = List.first(mesh.primitives)
        assert Map.has_key?(primitive.attributes, "POSITION")

        # Extract and verify position data
        pos_accessor_idx = primitive.attributes["POSITION"]
        assert {:ok, pos_data} = GLTF.get_accessor_data(gltf, data_store, pos_accessor_idx)
        assert {:ok, positions} = GLTF.EAGL.binary_to_float_list(pos_data)
        # Box has 24 vertices * 3 components = 72 floats
        assert length(positions) == 72

        # Extract indices and verify we handle the correct component type
        if primitive.indices do
          idx_accessor = Enum.at(gltf.accessors, primitive.indices)
          assert {:ok, idx_data} = GLTF.get_accessor_data(gltf, data_store, primitive.indices)

          assert {:ok, indices} =
                   GLTF.EAGL.binary_to_index_list(idx_data, idx_accessor.component_type)

          assert length(indices) == idx_accessor.count
          assert Enum.all?(indices, &(&1 >= 0))
        end
      end
    end

    test "interleaves vertex data correctly for Box", context do
      if context[:skip] do
        IO.puts("Skipping Box.glb interleave test - file not downloaded")
      else
        %{gltf: gltf, data_store: data_store} = context

        primitive = gltf.meshes |> List.first() |> Map.get(:primitives) |> List.first()
        assert {:ok, vertex_data} = GLTF.EAGL.extract_vertex_data(gltf, data_store, primitive)
        assert {:ok, interleaved} = GLTF.EAGL.interleave_vertex_data(vertex_data)

        # All values should be finite numbers
        assert Enum.all?(interleaved, &is_float/1)
        assert Enum.all?(interleaved, fn v -> not (v != v) end)
      end
    end
  end
end
