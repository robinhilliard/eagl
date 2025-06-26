defmodule GLTF.MeshTest do
  use ExUnit.Case, async: true
  doctest GLTF.Mesh

  alias GLTF.Mesh

  describe "load/1" do
    test "loads valid mesh with basic primitive" do
      json_data = %{
        "primitives" => [
          %{
            "attributes" => %{
              "POSITION" => 0,
              "NORMAL" => 1,
              "TEXCOORD_0" => 2
            },
            "indices" => 3,
            "material" => 0,
            # TRIANGLES
            "mode" => 4
          }
        ],
        "name" => "TestMesh"
      }

      assert {:ok, mesh} = Mesh.load(json_data)
      assert mesh.name == "TestMesh"
      assert length(mesh.primitives) == 1

      primitive = hd(mesh.primitives)
      assert primitive.attributes["POSITION"] == 0
      assert primitive.attributes["NORMAL"] == 1
      assert primitive.attributes["TEXCOORD_0"] == 2
      assert primitive.indices == 3
      assert primitive.material == 0
      assert primitive.mode == :triangles
    end

    test "uses default primitive mode when not specified" do
      json_data = %{
        "primitives" => [
          %{
            "attributes" => %{"POSITION" => 0}
          }
        ]
      }

      assert {:ok, mesh} = Mesh.load(json_data)
      primitive = hd(mesh.primitives)
      # Default mode
      assert primitive.mode == :triangles
    end

    test "rejects mesh without primitives" do
      json_data = %{"name" => "EmptyMesh"}

      assert {:error, :missing_primitives} = Mesh.load(json_data)
    end

    test "rejects mesh with empty primitives array" do
      json_data = %{
        "primitives" => []
      }

      assert {:error, :missing_primitives} = Mesh.load(json_data)
    end

    test "loads mesh with multiple primitives" do
      json_data = %{
        "primitives" => [
          %{
            "attributes" => %{"POSITION" => 0},
            "material" => 0
          },
          %{
            "attributes" => %{"POSITION" => 1},
            "material" => 1
          }
        ]
      }

      assert {:ok, mesh} = Mesh.load(json_data)
      assert length(mesh.primitives) == 2
      assert Enum.at(mesh.primitives, 0).material == 0
      assert Enum.at(mesh.primitives, 1).material == 1
    end
  end

  describe "primitive mode parsing" do
    test "parses all valid primitive modes" do
      mode_mappings = [
        {0, :points},
        {1, :lines},
        {2, :line_loop},
        {3, :line_strip},
        {4, :triangles},
        {5, :triangle_strip},
        {6, :triangle_fan}
      ]

      for {mode_value, expected_mode} <- mode_mappings do
        json_data = %{
          "primitives" => [
            %{
              "attributes" => %{"POSITION" => 0},
              "mode" => mode_value
            }
          ]
        }

        assert {:ok, mesh} = Mesh.load(json_data)
        primitive = hd(mesh.primitives)
        assert primitive.mode == expected_mode
      end
    end

    test "rejects invalid primitive mode" do
      json_data = %{
        "primitives" => [
          %{
            "attributes" => %{"POSITION" => 0},
            # Invalid mode
            "mode" => 99
          }
        ]
      }

      assert {:error, {:invalid_primitive_mode, 99}} = Mesh.load(json_data)
    end
  end

  describe "primitive attribute validation" do
    test "requires POSITION attribute" do
      json_data = %{
        "primitives" => [
          %{
            "attributes" => %{
              "NORMAL" => 1,
              "TEXCOORD_0" => 2
            }
            # Missing POSITION
          }
        ]
      }

      assert {:error, :missing_position_attribute} = Mesh.load(json_data)
    end

    test "accepts various standard attributes" do
      json_data = %{
        "primitives" => [
          %{
            "attributes" => %{
              "POSITION" => 0,
              "NORMAL" => 1,
              "TANGENT" => 2,
              "TEXCOORD_0" => 3,
              "TEXCOORD_1" => 4,
              "COLOR_0" => 5,
              "JOINTS_0" => 6,
              "WEIGHTS_0" => 7
            }
          }
        ]
      }

      assert {:ok, mesh} = Mesh.load(json_data)
      primitive = hd(mesh.primitives)

      assert primitive.attributes["POSITION"] == 0
      assert primitive.attributes["NORMAL"] == 1
      assert primitive.attributes["TANGENT"] == 2
      assert primitive.attributes["TEXCOORD_0"] == 3
      assert primitive.attributes["TEXCOORD_1"] == 4
      assert primitive.attributes["COLOR_0"] == 5
      assert primitive.attributes["JOINTS_0"] == 6
      assert primitive.attributes["WEIGHTS_0"] == 7
    end

    test "accepts custom application-specific attributes" do
      json_data = %{
        "primitives" => [
          %{
            "attributes" => %{
              "POSITION" => 0,
              "_CUSTOM_ATTR" => 1,
              "_VERTEX_ID" => 2
            }
          }
        ]
      }

      assert {:ok, mesh} = Mesh.load(json_data)
      primitive = hd(mesh.primitives)
      assert primitive.attributes["_CUSTOM_ATTR"] == 1
      assert primitive.attributes["_VERTEX_ID"] == 2
    end
  end

  describe "morph targets" do
    test "loads mesh with morph targets" do
      json_data = %{
        "primitives" => [
          %{
            "attributes" => %{"POSITION" => 0},
            "targets" => [
              %{
                "POSITION" => 1,
                "NORMAL" => 2
              },
              %{
                "POSITION" => 3,
                "NORMAL" => 4
              }
            ]
          }
        ],
        "weights" => [0.5, 0.3]
      }

      assert {:ok, mesh} = Mesh.load(json_data)
      assert mesh.weights == [0.5, 0.3]

      primitive = hd(mesh.primitives)
      assert length(primitive.targets) == 2

      target1 = Enum.at(primitive.targets, 0)
      target2 = Enum.at(primitive.targets, 1)
      assert target1["POSITION"] == 1
      assert target1["NORMAL"] == 2
      assert target2["POSITION"] == 3
      assert target2["NORMAL"] == 4
    end

    test "handles mesh without morph targets" do
      json_data = %{
        "primitives" => [
          %{
            "attributes" => %{"POSITION" => 0}
          }
        ]
      }

      assert {:ok, mesh} = Mesh.load(json_data)
      assert mesh.weights == nil

      primitive = hd(mesh.primitives)
      assert primitive.targets == nil
    end
  end

  describe "mesh validation" do
    test "validates primitive with minimal data" do
      json_data = %{
        "primitives" => [
          %{
            "attributes" => %{"POSITION" => 0}
          }
        ]
      }

      assert {:ok, mesh} = Mesh.load(json_data)

      primitive = hd(mesh.primitives)
      assert primitive.attributes != nil
      # No indices specified
      assert primitive.indices == nil
      # No material specified
      assert primitive.material == nil
      # Default mode
      assert primitive.mode == :triangles
    end

    test "handles primitive without material" do
      json_data = %{
        "primitives" => [
          %{
            "attributes" => %{"POSITION" => 0}
            # No material specified
          }
        ]
      }

      assert {:ok, mesh} = Mesh.load(json_data)
      primitive = hd(mesh.primitives)
      assert primitive.material == nil
    end

    test "handles primitive without indices (non-indexed rendering)" do
      json_data = %{
        "primitives" => [
          %{
            "attributes" => %{"POSITION" => 0}
            # No indices - direct vertex rendering
          }
        ]
      }

      assert {:ok, mesh} = Mesh.load(json_data)
      primitive = hd(mesh.primitives)
      assert primitive.indices == nil
    end
  end

  describe "error handling" do
    test "handles malformed primitive data gracefully" do
      json_data = %{
        "primitives" => [
          %{
            # Should be a map
            "attributes" => "invalid"
          }
        ]
      }

      assert {:error, :invalid_primitive_format} = Mesh.load(json_data)
    end

    test "handles invalid attribute accessor indices" do
      json_data = %{
        "primitives" => [
          %{
            "attributes" => %{
              # Should be integer
              "POSITION" => "invalid"
            }
          }
        ]
      }

      assert {:error, :invalid_primitive_format} = Mesh.load(json_data)
    end

    test "handles invalid material index" do
      json_data = %{
        "primitives" => [
          %{
            "attributes" => %{"POSITION" => 0},
            # Should be integer
            "material" => "invalid"
          }
        ]
      }

      assert {:error, :invalid_primitive_format} = Mesh.load(json_data)
    end

    test "handles invalid indices accessor" do
      json_data = %{
        "primitives" => [
          %{
            "attributes" => %{"POSITION" => 0},
            # Should be integer
            "indices" => "invalid"
          }
        ]
      }

      assert {:error, :invalid_primitive_format} = Mesh.load(json_data)
    end
  end

  describe "real-world usage patterns" do
    test "typical textured mesh" do
      # Common pattern: mesh with positions, normals, and texture coordinates
      json_data = %{
        "primitives" => [
          %{
            "attributes" => %{
              "POSITION" => 0,
              "NORMAL" => 1,
              "TEXCOORD_0" => 2
            },
            "indices" => 3,
            "material" => 0,
            # TRIANGLES
            "mode" => 4
          }
        ],
        "name" => "TexturedCube"
      }

      assert {:ok, mesh} = Mesh.load(json_data)
      assert mesh.name == "TexturedCube"

      primitive = hd(mesh.primitives)
      assert Map.has_key?(primitive.attributes, "POSITION")
      assert Map.has_key?(primitive.attributes, "NORMAL")
      assert Map.has_key?(primitive.attributes, "TEXCOORD_0")
      assert primitive.indices != nil
      assert primitive.material != nil
    end

    test "skinned mesh with bones" do
      # Common pattern: mesh with skinning data
      json_data = %{
        "primitives" => [
          %{
            "attributes" => %{
              "POSITION" => 0,
              "NORMAL" => 1,
              "JOINTS_0" => 2,
              "WEIGHTS_0" => 3
            },
            "material" => 0
          }
        ],
        "name" => "SkinnedCharacter"
      }

      assert {:ok, mesh} = Mesh.load(json_data)

      primitive = hd(mesh.primitives)
      assert Map.has_key?(primitive.attributes, "JOINTS_0")
      assert Map.has_key?(primitive.attributes, "WEIGHTS_0")
    end

    test "line mesh (wireframe)" do
      # Line rendering mode
      json_data = %{
        "primitives" => [
          %{
            "attributes" => %{"POSITION" => 0},
            "indices" => 1,
            # LINES
            "mode" => 1
          }
        ],
        "name" => "Wireframe"
      }

      assert {:ok, mesh} = Mesh.load(json_data)

      primitive = hd(mesh.primitives)
      assert primitive.mode == :lines
    end

    test "point cloud mesh" do
      # Point rendering mode
      json_data = %{
        "primitives" => [
          %{
            "attributes" => %{
              "POSITION" => 0,
              "COLOR_0" => 1
            },
            # POINTS
            "mode" => 0
          }
        ],
        "name" => "PointCloud"
      }

      assert {:ok, mesh} = Mesh.load(json_data)

      primitive = hd(mesh.primitives)
      assert primitive.mode == :points
      assert Map.has_key?(primitive.attributes, "COLOR_0")
    end

    test "multi-material mesh" do
      # Mesh with multiple primitives using different materials
      json_data = %{
        "primitives" => [
          %{
            "attributes" => %{"POSITION" => 0},
            "indices" => 1,
            "material" => 0
          },
          %{
            "attributes" => %{"POSITION" => 2},
            "indices" => 3,
            "material" => 1
          }
        ],
        "name" => "MultiMaterial"
      }

      assert {:ok, mesh} = Mesh.load(json_data)
      assert length(mesh.primitives) == 2

      [prim1, prim2] = mesh.primitives
      assert prim1.material == 0
      assert prim2.material == 1
    end
  end
end
