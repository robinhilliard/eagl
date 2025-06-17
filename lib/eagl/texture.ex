defmodule EAGL.Texture do
  @moduledoc """
  OpenGL texture management utilities.

  Handles texture creation, loading, and parameter configuration with
  Wings3D-inspired helper functions, focusing on meaningful abstractions
  rather than thin wrappers around OpenGL calls.

  ## Original Source

  Texture management patterns and helper functions are inspired by Wings3D's
  `wings_gl.erl` module:
  <https://github.com/dgud/wings/blob/master/src/wings_gl.erl>

  ## Basic Usage

      import EAGL.Texture
      import EAGL.Error

      # Load texture from image file (requires optional stb_image dependency)
      {:ok, texture_id, width, height} = load_texture_from_file("priv/images/eagl_logo_black_on_white.jpg")

      # Or create procedural textures
      {:ok, texture_id, width, height} = create_checkerboard_texture(256, 32)

      # Manual texture creation and configuration
      {:ok, texture_id} = create_texture()
      :gl.bindTexture(@gl_texture_2d, texture_id)
      set_texture_parameters(wrap_s: @gl_clamp_to_edge, min_filter: @gl_linear)
      load_texture_data(width, height, pixel_data, format: @gl_rgb)
      :gl.generateMipmap(@gl_texture_2d)
      check("After generating mipmaps")

      # Clean up
      :gl.deleteTextures([texture_id])

  ## Texture Parameters

  Use OpenGL constants for texture parameters:
  - **Wrapping**: `@gl_repeat`, `@gl_mirrored_repeat`, `@gl_clamp_to_edge`, `@gl_clamp_to_border`
  - **Filtering**: `@gl_nearest`, `@gl_linear`, `@gl_nearest_mipmap_nearest`, `@gl_linear_mipmap_linear`, etc.
  - **Format**: `@gl_rgb`, `@gl_rgba`, `@gl_red`, `@gl_rg`

  ## Philosophy

  This module provides substantial helper functions rather than thin wrappers:
  - `create_texture()` - Returns `{:ok, id}` tuples for error handling
  - `set_texture_parameters()` - Type-safe parameter configuration
  - `load_texture_data()` - Handles format/type conversion with defaults
  - `create_checkerboard_texture()` - Generates procedural textures

  For simple operations like binding, unbinding, or generating mipmaps,
  call the OpenGL functions directly and use `EAGL.Error.check()` as needed.
  """

  use EAGL.Const
  import EAGL.Error

  @type texture_id :: non_neg_integer()
  # GL constants like @gl_repeat, @gl_clamp_to_edge
  @type wrap_mode :: non_neg_integer()
  # GL constants like @gl_linear, @gl_nearest
  @type filter_mode :: non_neg_integer()
  # GL constants like @gl_rgb, @gl_rgba
  @type texture_format :: non_neg_integer()
  # GL constants like @gl_unsigned_byte, @gl_float
  @type pixel_type :: non_neg_integer()

  @doc """
  Creates a new texture object and returns its ID.
  """
  @spec create_texture() :: {:ok, texture_id()} | {:error, String.t()}
  def create_texture do
    try do
      [texture_id] = :gl.genTextures(1)
      check("After texture creation")
      {:ok, texture_id}
    rescue
      e -> {:error, "Failed to create texture: #{inspect(e)}"}
    end
  end

  @doc """
  Creates multiple texture objects and returns their IDs.
  """
  @spec create_textures(pos_integer()) :: {:ok, [texture_id()]} | {:error, String.t()}
  def create_textures(count) when count > 0 do
    try do
      texture_ids = :gl.genTextures(count)
      check("After texture creation")
      {:ok, texture_ids}
    rescue
      e -> {:error, "Failed to create textures: #{inspect(e)}"}
    end
  end

  @doc """
  Sets texture parameters for wrapping and filtering with type-safe options.

  ## Options

  - `wrap_s`: Wrapping mode for S coordinate (default: @gl_repeat)
  - `wrap_t`: Wrapping mode for T coordinate (default: @gl_repeat)
  - `min_filter`: Minification filter (default: @gl_linear)
  - `mag_filter`: Magnification filter (default: @gl_linear)

  ## Examples

      # Use default parameters (repeat wrapping, linear filtering)
      set_texture_parameters()

      # Custom parameters with type-safe options
      set_texture_parameters(
        wrap_s: @gl_clamp_to_edge,
        wrap_t: @gl_clamp_to_edge,
        min_filter: @gl_nearest,
        mag_filter: @gl_nearest
      )
  """
  @spec set_texture_parameters(keyword()) :: :ok
  def set_texture_parameters(opts \\ []) do
    wrap_s = Keyword.get(opts, :wrap_s, @gl_repeat)
    wrap_t = Keyword.get(opts, :wrap_t, @gl_repeat)
    min_filter = Keyword.get(opts, :min_filter, @gl_linear)
    mag_filter = Keyword.get(opts, :mag_filter, @gl_linear)

    # Set wrapping parameters
    :gl.texParameteri(@gl_texture_2d, @gl_texture_wrap_s, wrap_s)
    :gl.texParameteri(@gl_texture_2d, @gl_texture_wrap_t, wrap_t)

    # Set filtering parameters
    :gl.texParameteri(@gl_texture_2d, @gl_texture_min_filter, min_filter)
    :gl.texParameteri(@gl_texture_2d, @gl_texture_mag_filter, mag_filter)

    check("After setting texture parameters")
  end

  @doc """
  Loads pixel data into the currently bound texture.

  ## Parameters

  - `width`: Texture width in pixels
  - `height`: Texture height in pixels
  - `pixel_data`: Binary containing pixel data
  - `opts`: Options for format and type

  ## Options

  - `internal_format`: Internal storage format (default: @gl_rgb)
  - `format`: Pixel data format (default: @gl_rgb)
  - `type`: Pixel data type (default: @gl_unsigned_byte)
  - `level`: Mipmap level (default: 0)

  ## Examples

      # RGB data
      load_texture_data(256, 256, pixel_data, format: @gl_rgb)

      # RGBA data with alpha channel
      load_texture_data(256, 256, pixel_data,
        internal_format: @gl_rgba,
        format: @gl_rgba
      )
  """
  @spec load_texture_data(pos_integer(), pos_integer(), binary(), keyword()) :: :ok
  def load_texture_data(width, height, pixel_data, opts \\ []) do
    level = Keyword.get(opts, :level, 0)
    internal_format = Keyword.get(opts, :internal_format, @gl_rgb)
    format = Keyword.get(opts, :format, @gl_rgb)
    type = Keyword.get(opts, :type, @gl_unsigned_byte)

    :gl.texImage2D(
      @gl_texture_2d,
      level,
      internal_format,
      width,
      height,
      # border (must be 0)
      0,
      format,
      type,
      pixel_data
    )

    check("After loading texture data")
  end

  @doc """
  Loads a texture from an image file.

  Requires the optional `stb_image` dependency. If not available, falls back to
  checkerboard texture with a helpful warning message.

  ## Parameters

  - `file_path`: Path to the image file (relative to project root or absolute)
  - `opts`: Options for texture loading

  ## Options

  - `flip_y`: Flip image vertically (default: true, matches OpenGL convention)
  - `fallback_size`: Size of fallback checkerboard if image loading fails (default: 256)
  - `fallback_square_size`: Square size for fallback checkerboard (default: 32)

  ## Examples

      # Load EAGL logo
      {:ok, texture_id, width, height} = load_texture_from_file("priv/images/eagl_logo_black_on_white.jpg")

      # Load with custom options
      {:ok, texture_id, width, height} = load_texture_from_file("container.jpg", flip_y: false)
  """
  @spec load_texture_from_file(String.t(), keyword()) ::
          {:ok, texture_id(), pos_integer(), pos_integer()} | {:error, String.t()}
  def load_texture_from_file(file_path, opts \\ []) do
    flip_y = Keyword.get(opts, :flip_y, true)
    fallback_size = Keyword.get(opts, :fallback_size, 256)
    fallback_square_size = Keyword.get(opts, :fallback_square_size, 32)

    case load_image_with_stb(file_path, flip_y) do
      {:ok, width, height, pixel_data, channels} ->
        try do
          # Create and configure texture
          {:ok, texture_id} = create_texture()
          :gl.bindTexture(@gl_texture_2d, texture_id)

          # Determine format based on channels
          format =
            case channels do
              1 -> @gl_red
              2 -> @gl_rg
              3 -> @gl_rgb
              4 -> @gl_rgba
              _ -> @gl_rgb
            end

          set_texture_parameters(
            wrap_s: @gl_repeat,
            wrap_t: @gl_repeat,
            min_filter: @gl_linear_mipmap_linear,
            mag_filter: @gl_linear
          )

          # Set pixel store parameters for proper alignment
          :gl.pixelStorei(@gl_unpack_alignment, 1)

          load_texture_data(width, height, pixel_data,
            internal_format: format,
            format: format
          )

          :gl.generateMipmap(@gl_texture_2d)

          {:ok, texture_id, width, height}
        rescue
          e -> {:error, "Failed to create texture from image: #{inspect(e)}"}
        end

      {:error, :stb_image_not_available} ->
        print_stb_image_warning(file_path)
        create_checkerboard_texture(fallback_size, fallback_square_size)

      {:error, reason} ->
        IO.puts("""
        ⚠️  Failed to load image: #{file_path}
        Error: #{reason}
        Falling back to checkerboard texture...
        """)

        create_checkerboard_texture(fallback_size, fallback_square_size)
    end
  end

  @doc """
  Creates a simple checkerboard texture for testing purposes.
  Returns a tuple of {texture_id, width, height}.

  ## Parameters

  - `size`: Size of the checkerboard (default: 256)
  - `square_size`: Size of each square (default: 32)

  ## Examples

      {:ok, texture_id, width, height} = create_checkerboard_texture()
      {:ok, texture_id, width, height} = create_checkerboard_texture(128, 16)
  """
  @spec create_checkerboard_texture(pos_integer(), pos_integer()) ::
          {:ok, texture_id(), pos_integer(), pos_integer()} | {:error, String.t()}
  def create_checkerboard_texture(size \\ 256, square_size \\ 32) do
    try do
      # Generate checkerboard pattern
      pixel_data = generate_checkerboard_data(size, size, square_size)

      # Create and configure texture
      {:ok, texture_id} = create_texture()
      :gl.bindTexture(@gl_texture_2d, texture_id)

      set_texture_parameters(
        wrap_s: @gl_repeat,
        wrap_t: @gl_repeat,
        min_filter: @gl_linear,
        mag_filter: @gl_linear
      )

      load_texture_data(size, size, pixel_data, format: @gl_rgb)
      :gl.generateMipmap(@gl_texture_2d)

      {:ok, texture_id, size, size}
    rescue
      e -> {:error, "Failed to create checkerboard texture: #{inspect(e)}"}
    end
  end

  # ============================================================================
  # PRIVATE HELPER FUNCTIONS
  # ============================================================================

  # Generate checkerboard pattern data
  @spec generate_checkerboard_data(pos_integer(), pos_integer(), pos_integer()) :: binary()
  defp generate_checkerboard_data(width, height, square_size) do
    for y <- 0..(height - 1), x <- 0..(width - 1), into: <<>> do
      # Determine if we're in a "white" or "black" square
      square_x = div(x, square_size)
      square_y = div(y, square_size)

      if rem(square_x + square_y, 2) == 0 do
        # White square
        <<255, 255, 255>>
      else
        # Black square
        <<0, 0, 0>>
      end
    end
  end

  # Load image using stb_image if available
  @spec load_image_with_stb(String.t(), boolean()) ::
          {:ok, pos_integer(), pos_integer(), binary(), pos_integer()}
          | {:error, atom() | String.t()}
  defp load_image_with_stb(file_path, flip_y) do
    if Code.ensure_loaded?(StbImage) do
      try do
        case StbImage.read_file(file_path, desired_channels: 0) do
          {:ok, %StbImage{data: pixel_data, shape: {width, height, channels}}} ->
            # Flip Y if requested (OpenGL convention)
            final_data =
              if flip_y do
                flip_image_vertically(pixel_data, width, height, channels)
              else
                pixel_data
              end

            {:ok, width, height, final_data, channels}

          {:error, reason} ->
            {:error, "StbImage error: #{reason}"}
        end
      rescue
        e -> {:error, "StbImage exception: #{inspect(e)}"}
      end
    else
      {:error, :stb_image_not_available}
    end
  end

  # Flip image data vertically (Y-axis)
  @spec flip_image_vertically(binary(), pos_integer(), pos_integer(), pos_integer()) :: binary()
  defp flip_image_vertically(pixel_data, width, height, channels) do
    bytes_per_row = width * channels

    # Convert binary to list of rows, reverse, then back to binary
    rows =
      for row <- 0..(height - 1) do
        start_byte = row * bytes_per_row
        :binary.part(pixel_data, start_byte, bytes_per_row)
      end

    rows
    |> Enum.reverse()
    |> IO.iodata_to_binary()
  end

  # Print helpful warning when stb_image is not available
  @spec print_stb_image_warning(String.t()) :: :ok
  defp print_stb_image_warning(file_path) do
    IO.puts("""

    ⚠️  Image Loading Not Available
    ═══════════════════════════════════════════════════════════════

    Attempted to load: #{file_path}

    The optional 'stb_image' dependency is not available.

    To enable real image loading, add to your mix.exs:

        def deps do
          [
            {:stb_image, "~> 0.6"}
          ]
        end

    Then run:
        mix deps.get
        mix compile

    For now, falling back to checkerboard texture...
    ═══════════════════════════════════════════════════════════════
    """)
  end
end
