#!/usr/bin/env elixir

# GLB Loader Example
# ==================
#
# This example demonstrates how to use the EAGL GLB loader to parse
# a real GLB file from the Khronos test file
#
# Run with: elixir examples/glb_loader_example.exs

# Add the current project to the code path
Code.append_path("_build/dev/lib/eagl/ebin")

defmodule GLBLoaderExample do
  @moduledoc """
  Example usage of the EAGL GLB loader with real Khronos Sample Assets.
  """

  alias GLTF.{GLBLoader, Binary}

  # Khronos Sample Asset - ChairDamaskPurplegold
  @chair_url "https://github.com/KhronosGroup/glTF-Sample-Assets/raw/refs/heads/main/Models/ChairDamaskPurplegold/glTF-Binary/ChairDamaskPurplegold.glb"

  def run do
    IO.puts("GLB Loader Example")
    IO.puts("==================")
    IO.puts("")

    IO.puts("Loading ChairDamaskPurplegold.glb from Khronos Sample Assets...")
    IO.puts("URL: #{@chair_url}")
    IO.puts("")

    case GLBLoader.parse_url(@chair_url, timeout: 30_000) do
      {:ok, glb} ->
        demo_basic_info(glb)
        demo_json_content(glb)
        demo_binary_data(glb)
        demo_validation(glb)

        IO.puts("\n🎉 GLB file loaded and parsed successfully!")

      {:error, reason} ->
        IO.puts("❌ Failed to load GLB file: #{reason}")
        IO.puts("\nThis example requires internet connectivity to download the GLB file.")
    end
  end

  defp demo_basic_info(glb) do
    IO.puts("📊 Basic GLB Information:")
    IO.puts("   Magic: #{glb.magic}")
    IO.puts("   Version: #{glb.version}")
    IO.puts("   Total Size: #{glb.length} bytes")
    IO.puts("   Has Binary Data: #{Binary.has_binary?(glb)}")
    IO.puts("")
  end

  defp demo_json_content(glb) do
    IO.puts("📋 JSON Content Analysis:")

    case GLBLoader.get_json_map(glb) do
      {:ok, json_map} ->
        asset = json_map["asset"]
        IO.puts("   glTF Version: #{asset["version"]}")
        IO.puts("   Generator: #{asset["generator"]}")
        IO.puts("   Copyright: #{asset["copyright"]}")

        # Count various elements
        IO.puts("   Scenes: #{length(json_map["scenes"] || [])}")
        IO.puts("   Nodes: #{length(json_map["nodes"] || [])}")
        IO.puts("   Meshes: #{length(json_map["meshes"] || [])}")
        IO.puts("   Materials: #{length(json_map["materials"] || [])}")
        IO.puts("   Textures: #{length(json_map["textures"] || [])}")
        IO.puts("   Images: #{length(json_map["images"] || [])}")
        IO.puts("   Buffers: #{length(json_map["buffers"] || [])}")

        # Extensions
        if extensions = json_map["extensionsUsed"] do
          IO.puts("   Extensions Used: #{Enum.join(extensions, ", ")}")
        end

      {:error, reason} ->
        IO.puts("   ❌ Failed to parse JSON: #{reason}")
    end

    IO.puts("")
  end

  defp demo_binary_data(glb) do
    binary_data = Binary.get_binary(glb)

    IO.puts("💾 Binary Data:")
    if binary_data do
      IO.puts("   Size: #{byte_size(binary_data)} bytes")
      IO.puts("   Contains: Vertex data, indices, textures, etc.")

      # Show first few bytes (hex)
      first_bytes = binary_data |> :binary.part(0, min(16, byte_size(binary_data)))
      hex_string = first_bytes |> :binary.bin_to_list() |> Enum.map(&Integer.to_string(&1, 16)) |> Enum.join(" ")
      IO.puts("   First 16 bytes (hex): #{hex_string}")
    else
      IO.puts("   No binary data present")
    end

    IO.puts("")
  end

  defp demo_validation(glb) do
    IO.puts("✅ Validation:")

    case GLBLoader.validate(glb) do
      :ok ->
        IO.puts("   GLB structure is valid according to specification")

        case GLBLoader.validate(glb, strict: true) do
          :ok ->
            IO.puts("   Passes strict validation (no warnings)")
          {:error, reason} ->
            IO.puts("   Strict validation warning: #{reason}")
        end

      {:error, reason} ->
        IO.puts("   ❌ Validation failed: #{reason}")
    end

    IO.puts("")
  end

  def demo_file_info(glb) do
    IO.puts("📈 Detailed File Information:")
    GLBLoader.print_info(glb)
    IO.puts("")
  end

  def demo_auto_detection do
    IO.puts("🔍 Auto-detection Demo:")
    IO.puts("The parse/2 function can automatically detect URLs vs file paths:")
    IO.puts("")

    # URL detection
    case GLBLoader.parse(@chair_url, timeout: 30_000) do
      {:ok, _glb} ->
        IO.puts("   ✅ URL detected and parsed successfully")
      {:error, reason} ->
        IO.puts("   ❌ URL parsing failed: #{reason}")
    end

    # File path would be detected differently
    IO.puts("   📁 Local file paths are handled by parse_file/2")
    IO.puts("   🌐 URLs (http/https) are handled by parse_url/2")
    IO.puts("")
  end
end

# Run the example
GLBLoaderExample.run()
GLBLoaderExample.demo_auto_detection()
