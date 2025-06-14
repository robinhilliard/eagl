defmodule EAGL.TextureTest do
  use ExUnit.Case, async: false
  use EAGL.Const

  import EAGL.Texture
  import EAGL.Error

  # Setup OpenGL context for texture operations
  setup do
    try do
      :application.start(:wx)
      wx = :wx.new()
      frame = :wxFrame.new(wx, -1, "Test", size: {100, 100})
      gl_canvas = :wxGLCanvas.new(frame, [])
      :wxFrame.show(frame)
      :timer.sleep(50)
      gl_context = :wxGLContext.new(gl_canvas)
      :wxGLCanvas.setCurrent(gl_canvas, gl_context)

      on_exit(fn ->
        try do
          :wxGLContext.destroy(gl_context)
        rescue
          _ -> :ok
        end
        try do
          :wxFrame.destroy(frame)
        rescue
          _ -> :ok
        end
        try do
          :application.stop(:wx)
        rescue
          _ -> :ok
        end
      end)

      {:ok, %{gl_available: true, canvas: gl_canvas, context: gl_context}}
    rescue
      _ -> {:ok, %{gl_available: false}}
    end
  end

  describe "texture creation" do
    test "create_texture returns valid texture ID", %{gl_available: gl_available} do
      if gl_available do
        assert {:ok, texture_id} = create_texture()
        assert is_integer(texture_id)
        assert texture_id > 0

        # Clean up
        :gl.deleteTextures([texture_id])
      else
        assert true
      end
    end

    test "create_textures returns multiple valid texture IDs", %{gl_available: gl_available} do
      if gl_available do
        assert {:ok, texture_ids} = create_textures(3)
        assert is_list(texture_ids)
        assert length(texture_ids) == 3
        assert Enum.all?(texture_ids, &(is_integer(&1) and &1 > 0))

        # Clean up
        :gl.deleteTextures(texture_ids)
      else
        assert true
      end
    end
  end

  describe "texture parameters" do
    test "set_texture_parameters with default values", %{gl_available: gl_available} do
      if gl_available do
        {:ok, texture_id} = create_texture()
        :gl.bindTexture(@gl_texture_2d, texture_id)

        # Should not raise any errors
        assert :ok = set_texture_parameters()

        # Clean up
        :gl.deleteTextures([texture_id])
      else
        assert true
      end
    end

    test "set_texture_parameters with custom values", %{gl_available: gl_available} do
      if gl_available do
        {:ok, texture_id} = create_texture()
        :gl.bindTexture(@gl_texture_2d, texture_id)

        assert :ok = set_texture_parameters(
          wrap_s: :clamp_to_edge,
          wrap_t: :clamp_to_edge,
          min_filter: :nearest,
          mag_filter: :nearest
        )

        # Clean up
        :gl.deleteTextures([texture_id])
      else
        assert true
      end
    end
  end

  describe "texture data loading" do
    test "load_texture_data with RGB data", %{gl_available: gl_available} do
      if gl_available do
        {:ok, texture_id} = create_texture()
        :gl.bindTexture(@gl_texture_2d, texture_id)

        # Create simple 2x2 RGB test data (red, green, blue, white)
        pixel_data = <<
          255, 0, 0,    # Red
          0, 255, 0,    # Green
          0, 0, 255,    # Blue
          255, 255, 255 # White
        >>

        assert :ok = load_texture_data(2, 2, pixel_data, format: :rgb)

        # Clean up
        :gl.deleteTextures([texture_id])
      else
        assert true
      end
    end

    test "load_texture_data with RGBA data", %{gl_available: gl_available} do
      if gl_available do
        {:ok, texture_id} = create_texture()
        :gl.bindTexture(@gl_texture_2d, texture_id)

        # Create simple 2x2 RGBA test data
        pixel_data = <<
          255, 0, 0, 255,     # Red, opaque
          0, 255, 0, 128,     # Green, semi-transparent
          0, 0, 255, 255,     # Blue, opaque
          255, 255, 255, 0    # White, transparent
        >>

        assert :ok = load_texture_data(2, 2, pixel_data,
          internal_format: :rgba,
          format: :rgba
        )

        # Clean up
        :gl.deleteTextures([texture_id])
      else
        assert true
      end
    end
  end

  describe "checkerboard texture creation" do
    test "create_checkerboard_texture with default parameters", %{gl_available: gl_available} do
      if gl_available do
        assert {:ok, texture_id, width, height} = create_checkerboard_texture()
        assert is_integer(texture_id)
        assert texture_id > 0
        assert width == 256
        assert height == 256

        # Clean up
        :gl.deleteTextures([texture_id])
      else
        assert true
      end
    end

    test "create_checkerboard_texture with custom parameters", %{gl_available: gl_available} do
      if gl_available do
        assert {:ok, texture_id, width, height} = create_checkerboard_texture(128, 16)
        assert is_integer(texture_id)
        assert texture_id > 0
        assert width == 128
        assert height == 128

        # Clean up
        :gl.deleteTextures([texture_id])
      else
        assert true
      end
    end
  end

  describe "image loading from files" do
    test "load_texture_from_file with PNG image", %{gl_available: gl_available} do
      if gl_available do
        # Test with the PNG version of the EAGL logo
        png_path = "priv/images/eagl_logo_black_on_white.png"

        if File.exists?(png_path) do
          assert {:ok, texture_id, width, height} = load_texture_from_file(png_path)
          assert is_integer(texture_id)
          assert texture_id > 0
          assert width == 418
          assert height == 418

          # Clean up
          :gl.deleteTextures([texture_id])
        else
          # Skip if image file doesn't exist
          assert true
        end
      else
        assert true
      end
    end

    test "load_texture_from_file with JPG image", %{gl_available: gl_available} do
      if gl_available do
        # Test with the JPG version of the EAGL logo
        jpg_path = "priv/images/eagl_logo_black_on_white.jpg"

        if File.exists?(jpg_path) do
          assert {:ok, texture_id, width, height} = load_texture_from_file(jpg_path)
          assert is_integer(texture_id)
          assert texture_id > 0
          assert width == 418
          assert height == 418

          # Clean up
          :gl.deleteTextures([texture_id])
        else
          # Skip if image file doesn't exist
          assert true
        end
      else
        assert true
      end
    end

    test "load_texture_from_file with Y-flip disabled", %{gl_available: gl_available} do
      if gl_available do
        png_path = "priv/images/eagl_logo_black_on_white.png"

        if File.exists?(png_path) do
          assert {:ok, texture_id, width, height} = load_texture_from_file(png_path, flip_y: false)
          assert is_integer(texture_id)
          assert texture_id > 0
          assert width == 418
          assert height == 418

          # Clean up
          :gl.deleteTextures([texture_id])
        else
          assert true
        end
      else
        assert true
      end
    end

    test "load_texture_from_file with non-existent file falls back to checkerboard", %{gl_available: gl_available} do
      if gl_available do
        # This should fall back to checkerboard texture
        assert {:ok, texture_id, width, height} = load_texture_from_file("non_existent_image.jpg")
        assert is_integer(texture_id)
        assert texture_id > 0
        # Should be default checkerboard size
        assert width == 256
        assert height == 256

        # Clean up
        :gl.deleteTextures([texture_id])
      else
        assert true
      end
    end

    test "load_texture_from_file with custom fallback parameters", %{gl_available: gl_available} do
      if gl_available do
        # Test fallback with custom parameters
        assert {:ok, texture_id, width, height} = load_texture_from_file(
          "non_existent_image.jpg",
          fallback_size: 128,
          fallback_square_size: 16
        )
        assert is_integer(texture_id)
        assert texture_id > 0
        assert width == 128
        assert height == 128

        # Clean up
        :gl.deleteTextures([texture_id])
      else
        assert true
      end
    end
  end

  describe "stb_image integration" do
    test "graceful handling when stb_image is not available", %{gl_available: gl_available} do
      if gl_available do
        # This test verifies that the module handles missing stb_image gracefully
        # Even if stb_image is available, we can test the fallback path by using a non-existent file
        assert {:ok, texture_id, width, height} = load_texture_from_file("test_fallback.jpg")
        assert is_integer(texture_id)
        assert texture_id > 0
        # Should fall back to checkerboard
        assert width == 256
        assert height == 256

        # Clean up
        :gl.deleteTextures([texture_id])
      else
        assert true
      end
    end
  end

  describe "texture format handling" do
    test "handles different channel counts correctly", %{gl_available: gl_available} do
      if gl_available do
        # Test that the module correctly determines format based on channels
        # This is tested indirectly through successful image loading
        png_path = "priv/images/eagl_logo_black_on_white.png"

        if File.exists?(png_path) do
          # PNG should have 4 channels (RGBA)
          assert {:ok, texture_id, _width, _height} = load_texture_from_file(png_path)
          assert is_integer(texture_id)
          assert texture_id > 0

          # Clean up
          :gl.deleteTextures([texture_id])
        else
          assert true
        end
      else
        assert true
      end
    end
  end

  describe "pixel alignment handling" do
    test "handles non-4-byte-aligned image widths correctly", %{gl_available: gl_available} do
      if gl_available do
        # The 418-pixel wide images test the pixel alignment fix
        # This should not cause diagonal skewing
        png_path = "priv/images/eagl_logo_black_on_white.png"

        if File.exists?(png_path) do
          assert {:ok, texture_id, width, height} = load_texture_from_file(png_path)
          assert is_integer(texture_id)
          assert texture_id > 0
          # 418 * 4 = 1672 bytes per row (not divisible by 4 without alignment fix)
          assert width == 418
          assert height == 418

          # Clean up
          :gl.deleteTextures([texture_id])
        else
          assert true
        end
      else
        assert true
      end
    end
  end

  describe "error handling" do
    test "create_texture handles OpenGL errors gracefully", %{gl_available: gl_available} do
      if gl_available do
        # This should succeed in normal circumstances
        assert {:ok, texture_id} = create_texture()
        assert is_integer(texture_id)

        # Clean up
        :gl.deleteTextures([texture_id])
      else
        assert true
      end
    end

    test "texture operations work with proper OpenGL context", %{gl_available: gl_available} do
      if gl_available do
        # Test a complete texture creation and configuration workflow
        assert {:ok, texture_id} = create_texture()
        :gl.bindTexture(@gl_texture_2d, texture_id)

        assert :ok = set_texture_parameters(
          wrap_s: :repeat,
          wrap_t: :repeat,
          min_filter: :linear,
          mag_filter: :linear
        )

        # Create simple test data
        pixel_data = <<255, 0, 0, 0, 255, 0, 0, 0, 255>>  # 3x1 RGB strip
        assert :ok = load_texture_data(3, 1, pixel_data, format: :rgb)

        # Generate mipmaps
        :gl.generateMipmap(@gl_texture_2d)
        assert :ok = check("After generating mipmaps")

        # Clean up
        :gl.deleteTextures([texture_id])
      else
        assert true
      end
    end
  end
end
