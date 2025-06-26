defmodule GLTF.AssetTest do
  use ExUnit.Case, async: true
  doctest GLTF.Asset

  alias GLTF.Asset

  describe "load/1" do
    test "loads valid asset data" do
      json_data = %{
        "version" => "2.0",
        "generator" => "Test Generator",
        "copyright" => "Test Copyright",
        "minVersion" => "2.0"
      }

      assert {:ok, asset} = Asset.load(json_data)
      assert asset.version == "2.0"
      assert asset.generator == "Test Generator"
      assert asset.copyright == "Test Copyright"
      assert asset.min_version == "2.0"
    end

    test "loads minimal valid asset" do
      json_data = %{"version" => "2.0"}

      assert {:ok, asset} = Asset.load(json_data)
      assert asset.version == "2.0"
      assert asset.generator == nil
      assert asset.copyright == nil
      assert asset.min_version == nil
    end

    test "rejects asset without version" do
      json_data = %{"generator" => "Test"}

      assert {:error, :missing_version} = Asset.load(json_data)
    end

    test "preserves extensions and extras" do
      json_data = %{
        "version" => "2.0",
        "extensions" => %{"EXT_test" => %{}},
        "extras" => %{"custom" => "data"}
      }

      assert {:ok, asset} = Asset.load(json_data)
      assert asset.extensions["EXT_test"] == %{}
      assert asset.extras["custom"] == "data"
    end
  end

  describe "new/2" do
    test "creates asset with version only" do
      asset = Asset.new("2.0")
      assert asset.version == "2.0"
      assert asset.generator == nil
    end

    test "creates asset with options" do
      opts = [generator: "Test Gen", copyright: "Test Copy"]
      asset = Asset.new("2.0", opts)

      assert asset.version == "2.0"
      assert asset.generator == "Test Gen"
      assert asset.copyright == "Test Copy"
    end
  end

  describe "edge cases" do
    test "handles nil version gracefully" do
      json_data = %{"version" => nil}

      assert {:error, :missing_version} = Asset.load(json_data)
    end

    test "handles empty string version" do
      json_data = %{"version" => ""}

      # Empty version is technically valid JSON, but logically invalid
      assert {:ok, asset} = Asset.load(json_data)
      assert asset.version == ""
    end

    test "handles non-string version" do
      json_data = %{"version" => 2.0}

      # Asset validates version type
      assert {:error, :invalid_version} = Asset.load(json_data)
    end
  end

  describe "real-world patterns" do
    test "typical Blender export" do
      json_data = %{
        "version" => "2.0",
        "generator" => "Khronos glTF Blender I/O v1.6.16"
      }

      assert {:ok, asset} = Asset.load(json_data)
      assert asset.generator =~ "Blender"
    end

    test "typical COLLADA2GLTF export" do
      json_data = %{
        "version" => "2.0",
        "generator" => "COLLADA2GLTF",
        "copyright" => "Sample Model"
      }

      assert {:ok, asset} = Asset.load(json_data)
      assert asset.generator == "COLLADA2GLTF"
      assert asset.copyright == "Sample Model"
    end

    test "asset with minimum version requirement" do
      json_data = %{
        "version" => "2.0",
        "minVersion" => "2.0"
      }

      assert {:ok, asset} = Asset.load(json_data)
      assert asset.min_version == "2.0"
    end
  end
end
