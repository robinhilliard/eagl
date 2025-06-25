defmodule GLTF.GLBLoader do
  @moduledoc """
  GLB (Binary glTF) file loader.

  Parses the binary GLB format according to section 4 of the glTF 2.0 specification.
  GLB files contain a 12-byte header followed by one or more chunks containing
  JSON and optional binary data.

  Based on section 4.4 "Binary glTF Layout" of the glTF 2.0 specification.

  ## Loading GLB Files

  The loader supports loading GLB files from multiple sources:

  - **Local files**: `parse_file/2` for files on disk
  - **URLs**: `parse_url/2` for remote files (HTTP/HTTPS)
  - **Auto-detect**: `parse/2` automatically detects URLs vs file paths
  - **Binary data**: `parse_binary/1` for data already in memory

  ## Khronos Reference Files

  The loader is designed to work with the official Khronos glTF sample assets:

      # Simple box model
      url = "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/Box/glTF-Binary/Box.glb"
      {:ok, glb} = GLTF.GLBLoader.parse_url(url)

      # Complex scene
      url = "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/Sponza/glTF-Binary/Sponza.glb"
      {:ok, glb} = GLTF.GLBLoader.parse_url(url)

  ## HTTP Client Support

  The loader supports multiple HTTP clients for URL loading:

  - **:httpc** (default) - Built into Erlang/OTP, no extra dependencies
  - **:req** - Modern HTTP client, add `{:req, "~> 0.4"}` to dependencies
  - **:httpoison** - Popular HTTP client, add `{:httpoison, "~> 2.0"}` to dependencies
  """

  alias GLTF.Binary

  @doc """
  Loads a GLB file from a local file path and returns the parsed binary structure.
  Returns {:ok, glb_binary} where glb_binary is a GLTF.Binary struct containing:
    - magic: GLB magic string
    - version: GLB version number
    - length: Total file length in bytes
    - json_chunk: JSON chunk with parsed metadata
    - binary_chunk: Optional binary chunk with geometry data

  Options:
    - :validate - boolean, set to true to validate the parsed structure (default: true)
    - :strict - boolean, set to true for strict validation that rejects any warnings (default: false)

  ## Examples

      iex> {:ok, glb} = GLTF.GLBLoader.parse_file("model.glb")
      iex> json_string = GLTF.Binary.get_json(glb)
      iex> binary_data = GLTF.Binary.get_binary(glb)

  """
  @spec parse_file(String.t(), keyword()) :: {:ok, Binary.t()} | {:error, String.t()}
  def parse_file(file_path, opts \\ []) do
    validate_option = Keyword.get(opts, :validate, true)
    strict = Keyword.get(opts, :strict, false)

    try do
      with {:ok, binary_data} <- File.read(file_path),
           {:ok, glb_binary} <- parse_binary(binary_data),
           :ok <- maybe_validate(glb_binary, validate_option, strict) do
        {:ok, glb_binary}
      else
        {:error, reason} -> {:error, reason}
        error -> {:error, "Failed to parse GLB file: #{inspect(error)}"}
      end
    rescue
      e -> {:error, "Failed to load GLB file: #{Exception.message(e)}"}
    end
  end

  @doc """
  Loads a GLB file from a URL and returns the parsed binary structure.
  Returns {:ok, glb_binary} where glb_binary is a GLTF.Binary struct containing:
    - magic: GLB magic string
    - version: GLB version number
    - length: Total file length in bytes
    - json_chunk: JSON chunk with parsed metadata
    - binary_chunk: Optional binary chunk with geometry data

  Options:
    - :validate - boolean, set to true to validate the parsed structure (default: true)
    - :strict - boolean, set to true for strict validation that rejects any warnings (default: false)
    - :timeout - integer, timeout in milliseconds for HTTP request (default: 30000)
    - :http_client - atom, HTTP client to use (:httpc, :req, :httpoison) (default: :httpc)

  ## Examples

      # Load Khronos reference GLB files
      iex> url = "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/Box/glTF-Binary/Box.glb"
      iex> {:ok, glb} = GLTF.GLBLoader.parse_url(url)
      iex> json_string = GLTF.Binary.get_json(glb)

  """
  @spec parse_url(String.t(), keyword()) :: {:ok, Binary.t()} | {:error, String.t()}
  def parse_url(url, opts \\ []) do
    validate_option = Keyword.get(opts, :validate, true)
    strict = Keyword.get(opts, :strict, false)
    timeout = Keyword.get(opts, :timeout, 30_000)
    http_client = Keyword.get(opts, :http_client, :httpc)

    try do
      with {:ok, binary_data} <- fetch_url(url, timeout, http_client),
           {:ok, glb_binary} <- parse_binary(binary_data),
           :ok <- maybe_validate(glb_binary, validate_option, strict) do
        {:ok, glb_binary}
      else
        {:error, reason} -> {:error, reason}
        error -> {:error, "Failed to parse GLB from URL: #{inspect(error)}"}
      end
    rescue
      e -> {:error, "Failed to load GLB from URL: #{Exception.message(e)}"}
    end
  end

  @doc """
  Automatically parses a GLB file from either a local file path or URL.

  Determines whether the input is a URL (starts with http:// or https://) or
  a local file path and calls the appropriate parsing function.

  Options are passed through to either parse_file/2 or parse_url/2.

  ## Examples

      # Local file
      iex> {:ok, glb} = GLTF.GLBLoader.parse("model.glb")

      # URL
      iex> {:ok, glb} = GLTF.GLBLoader.parse("https://example.com/model.glb")

  """
  @spec parse(String.t(), keyword()) :: {:ok, Binary.t()} | {:error, String.t()}
  def parse(path_or_url, opts \\ []) do
    if String.starts_with?(path_or_url, ["http://", "https://"]) do
      parse_url(path_or_url, opts)
    else
      parse_file(path_or_url, opts)
    end
  end

  @doc """
  Parses GLB binary data directly.

  Useful when you already have the binary data in memory.

  ## Examples

      iex> binary_data = File.read!("model.glb")
      iex> {:ok, glb} = GLTF.GLBLoader.parse_binary(binary_data)

  """
  @spec parse_binary(binary()) :: {:ok, Binary.t()} | {:error, String.t()}
  def parse_binary(binary_data) when is_binary(binary_data) do
    try do
      with {:ok, header, rest} <- parse_header(binary_data),
           {:ok, glb_binary} <- parse_chunks(header, rest) do
        {:ok, glb_binary}
      else
        {:error, reason} -> {:error, reason}
      end
    rescue
      e -> {:error, "Failed to parse GLB binary: #{Exception.message(e)}"}
    end
  end

  @doc """
  Validates a parsed GLB binary structure.

  Checks that the structure conforms to the GLB specification:
  - Valid magic string
  - Supported version
  - Proper chunk structure
  - Total length consistency

  ## Options

  - :strict - boolean, when true treats warnings as errors (default: false)

  ## Examples

      iex> GLTF.GLBLoader.validate(glb_binary)
      :ok

      iex> GLTF.GLBLoader.validate(invalid_glb)
      {:error, "Invalid magic: expected 'glTF', got 'GLTF'"}

  """
  @spec validate(Binary.t(), keyword()) :: :ok | {:error, String.t()}
  def validate(%Binary{} = glb_binary, opts \\ []) do
    strict = Keyword.get(opts, :strict, false)

    with :ok <- Binary.validate(glb_binary),
         :ok <- validate_chunk_padding(glb_binary, strict),
         :ok <- validate_json_content(glb_binary, strict) do
      :ok
    end
  end

  # Private functions

  # Fetch binary data from URL using different HTTP clients
  defp fetch_url(url, timeout, :httpc) do
    fetch_url_httpc(url, timeout)
  end

  defp fetch_url(url, timeout, :req) do
    fetch_url_req(url, timeout)
  end

  defp fetch_url(url, timeout, :httpoison) do
    fetch_url_httpoison(url, timeout)
  end

  defp fetch_url(_url, _timeout, client) do
    {:error, "Unsupported HTTP client: #{client}. Supported clients: :httpc, :req, :httpoison"}
  end

  # Fetch using built-in :httpc (Erlang)
  defp fetch_url_httpc(url, timeout) do
    url_charlist = String.to_charlist(url)

    # Start inets if not already started
    :inets.start()

    # Set options for binary response and timeout
    http_options = [timeout: timeout, autoredirect: true]
    options = [body_format: :binary]

    case :httpc.request(:get, {url_charlist, []}, http_options, options) do
      {:ok, {{_version, 200, _reason_phrase}, _headers, body}} ->
        {:ok, body}

      {:ok, {{_version, status_code, reason_phrase}, _headers, _body}} ->
        {:error, "HTTP error #{status_code}: #{reason_phrase}"}

      {:error, reason} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  # Fetch using Req library (if available)
  defp fetch_url_req(url, timeout) do
    try do
      case Req.get(url, receive_timeout: timeout) do
        {:ok, %{status: 200, body: body}} ->
          {:ok, body}

        {:ok, %{status: status_code}} ->
          {:error, "HTTP error #{status_code}"}

        {:error, reason} ->
          {:error, "Req request failed: #{inspect(reason)}"}
      end
    rescue
      UndefinedFunctionError ->
        {:error, "Req library not available. Please add {:req, \"~> 0.4\"} to your dependencies or use :httpc"}
    end
  end

  # Fetch using HTTPoison library (if available)
  defp fetch_url_httpoison(url, timeout) do
    try do
      case HTTPoison.get(url, [], recv_timeout: timeout) do
        {:ok, %{status_code: 200, body: body}} ->
          {:ok, body}

        {:ok, %{status_code: status_code}} ->
          {:error, "HTTP error #{status_code}"}

        {:error, %{reason: reason}} ->
          {:error, "HTTPoison request failed: #{inspect(reason)}"}

        {:error, reason} ->
          {:error, "HTTPoison request failed: #{inspect(reason)}"}
      end
    rescue
      UndefinedFunctionError ->
        {:error, "HTTPoison library not available. Please add {:httpoison, \"~> 2.0\"} to your dependencies or use :httpc"}
    end
  end

  # Parse the 12-byte GLB header
  defp parse_header(binary_data) when byte_size(binary_data) < 12 do
    {:error, "File too small: GLB header requires 12 bytes, got #{byte_size(binary_data)}"}
  end

  defp parse_header(binary_data) do
    <<magic::binary-size(4), version::little-unsigned-32, length::little-unsigned-32, rest::binary>> = binary_data

    if byte_size(binary_data) < length do
      {:error, "File size mismatch: header claims #{length} bytes, file has #{byte_size(binary_data)}"}
    else
      header = %{
        magic: magic,
        version: version,
        length: length
      }
      {:ok, header, rest}
    end
  end

  # Parse chunks following the header
  defp parse_chunks(header, chunk_data) do
    case parse_json_chunk(chunk_data) do
      {:ok, json_chunk, remaining} ->
        case parse_binary_chunk(remaining) do
          {:ok, binary_chunk} ->
            glb_binary = Binary.new(
              header.magic,
              header.version,
              header.length,
              json_chunk,
              binary_chunk
            )
            {:ok, glb_binary}

          {:ok, nil} ->
            glb_binary = Binary.new(
              header.magic,
              header.version,
              header.length,
              json_chunk
            )
            {:ok, glb_binary}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Parse the required JSON chunk (always first)
  defp parse_json_chunk(chunk_data) when byte_size(chunk_data) < 8 do
    {:error, "Not enough data for JSON chunk header"}
  end

  defp parse_json_chunk(chunk_data) do
    <<length::little-unsigned-32, chunk_type::little-unsigned-32, rest::binary>> = chunk_data

    if byte_size(rest) < length do
      {:error, "JSON chunk data truncated: expected #{length} bytes, got #{byte_size(rest)}"}
    else
      case Binary.chunk_type_to_atom(chunk_type) do
        :json ->
          <<json_data::binary-size(length), remaining::binary>> = rest

          # Remove null padding if present
          json_string = String.trim_trailing(json_data, <<0>>)

          json_chunk = Binary.chunk(length, :json, json_string)
          {:ok, json_chunk, remaining}

        other ->
          {:error, "First chunk must be JSON, got #{other} (0x#{Integer.to_string(chunk_type, 16)})"}
      end
    end
  end

  # Parse the optional binary chunk (second chunk if present)
  defp parse_binary_chunk(chunk_data) when byte_size(chunk_data) == 0 do
    {:ok, nil}
  end

  defp parse_binary_chunk(chunk_data) when byte_size(chunk_data) < 8 do
    {:error, "Not enough data for binary chunk header"}
  end

  defp parse_binary_chunk(chunk_data) do
    <<length::little-unsigned-32, chunk_type::little-unsigned-32, rest::binary>> = chunk_data

    if byte_size(rest) < length do
      {:error, "Binary chunk data truncated: expected #{length} bytes, got #{byte_size(rest)}"}
    else
      case Binary.chunk_type_to_atom(chunk_type) do
        :bin ->
          <<binary_data::binary-size(length), _remaining::binary>> = rest
          binary_chunk = Binary.chunk(length, :bin, binary_data)
          {:ok, binary_chunk}

        :unknown ->
          # For now, treat unknown chunks as binary data
          <<binary_data::binary-size(length), _remaining::binary>> = rest
          binary_chunk = Binary.chunk(length, :unknown, binary_data)
          {:ok, binary_chunk}

        other ->
          {:error, "Unexpected chunk type: #{other} (0x#{Integer.to_string(chunk_type, 16)})"}
      end
    end
  end

  # Conditional validation helper
  defp maybe_validate(glb_binary, true, strict), do: validate(glb_binary, strict: strict)
  defp maybe_validate(_glb_binary, false, _strict), do: :ok

  # Validate chunk padding according to GLB specification
  defp validate_chunk_padding(%Binary{json_chunk: json_chunk, binary_chunk: binary_chunk}, strict) do
    with :ok <- validate_json_padding(json_chunk, strict),
         :ok <- validate_binary_padding(binary_chunk, strict) do
      :ok
    end
  end

  # JSON chunks should be padded with spaces (0x20) to 4-byte alignment
  defp validate_json_padding(%{length: length, data: data}, strict) do
    actual_length = byte_size(data)

    cond do
      actual_length > length ->
        {:error, "JSON chunk data longer than declared length"}

      actual_length == length ->
        :ok

      # Check if padding is correct (spaces for JSON)
      actual_length < length ->
        if strict do
          {:error, "JSON chunk has padding but strict mode enabled"}
        else
          :ok
        end
    end
  end

  # Binary chunks should be padded with zeros (0x00) to 4-byte alignment
  defp validate_binary_padding(nil, _strict), do: :ok
  defp validate_binary_padding(%{length: length, data: data}, strict) do
    actual_length = byte_size(data)

    cond do
      actual_length > length ->
        {:error, "Binary chunk data longer than declared length"}

      actual_length == length ->
        :ok

      # Allow padding in non-strict mode
      actual_length < length ->
        if strict do
          {:error, "Binary chunk has padding but strict mode enabled"}
        else
          :ok
        end
    end
  end

  # Validate that JSON content is valid JSON
  defp validate_json_content(%Binary{json_chunk: %{data: json_string}}, _strict) do
    case Jason.decode(json_string) do
      {:ok, _json} -> :ok
      {:error, reason} -> {:error, "Invalid JSON content: #{inspect(reason)}"}
    end
  rescue
    UndefinedFunctionError ->
      # Jason not available, skip JSON validation
      :ok
  end

  @doc """
  Extracts the parsed JSON from a GLB binary as an Elixir map.

  Requires the Jason library to be available for JSON parsing.

  ## Examples

      iex> {:ok, json_map} = GLTF.GLBLoader.get_json_map(glb_binary)
      iex> json_map["asset"]["version"]
      "2.0"

  """
  @spec get_json_map(Binary.t()) :: {:ok, map()} | {:error, String.t()}
  def get_json_map(%Binary{} = glb_binary) do
    json_string = Binary.get_json(glb_binary)

    try do
      case Jason.decode(json_string) do
        {:ok, json_map} -> {:ok, json_map}
        {:error, reason} -> {:error, "JSON decode error: #{inspect(reason)}"}
      end
    rescue
      UndefinedFunctionError ->
        {:error, "Jason library not available for JSON parsing"}
    end
  end

  @doc """
  Gets information about the GLB file structure.

  Returns a map with file statistics and structure information.

  ## Examples

      iex> info = GLTF.GLBLoader.get_info(glb_binary)
      iex> info.total_size
      1024
      iex> info.has_binary
      true

  """
  @spec get_info(Binary.t()) :: map()
  def get_info(%Binary{} = glb_binary) do
    json_size = glb_binary.json_chunk.length
    binary_size = case glb_binary.binary_chunk do
      nil -> 0
      chunk -> chunk.length
    end

    %{
      magic: glb_binary.magic,
      version: glb_binary.version,
      total_size: glb_binary.length,
      header_size: 12,
      json_chunk_size: json_size + 8,  # +8 for chunk header
      binary_chunk_size: if(glb_binary.binary_chunk, do: binary_size + 8, else: 0),
      has_binary: Binary.has_binary?(glb_binary),
      chunk_count: if(Binary.has_binary?(glb_binary), do: 2, else: 1)
    }
  end

  @doc """
  Pretty prints information about a GLB file.

  ## Examples

      iex> GLTF.GLBLoader.print_info(glb_binary)
      GLB File Information:
      =====================
      Magic: glTF
      Version: 2
      Total Size: 1024 bytes
      ...

  """
  @spec print_info(Binary.t()) :: :ok
  def print_info(%Binary{} = glb_binary) do
    info = get_info(glb_binary)

    IO.puts("GLB File Information:")
    IO.puts("=====================")
    IO.puts("Magic: #{info.magic}")
    IO.puts("Version: #{info.version}")
    IO.puts("Total Size: #{info.total_size} bytes")
    IO.puts("Header Size: #{info.header_size} bytes")
    IO.puts("JSON Chunk Size: #{info.json_chunk_size} bytes")
    IO.puts("Binary Chunk Size: #{info.binary_chunk_size} bytes")
    IO.puts("Has Binary Data: #{info.has_binary}")
    IO.puts("Chunk Count: #{info.chunk_count}")

    case get_json_map(glb_binary) do
      {:ok, json_map} ->
        IO.puts("\nGLTF Asset Info:")
        IO.puts("================")
        if asset = json_map["asset"] do
          IO.puts("Version: #{asset["version"] || "unknown"}")
          IO.puts("Generator: #{asset["generator"] || "unknown"}")
          IO.puts("Copyright: #{asset["copyright"] || "none"}")
        end

        # Count various glTF elements
        counts = %{
          scenes: length(json_map["scenes"] || []),
          nodes: length(json_map["nodes"] || []),
          meshes: length(json_map["meshes"] || []),
          materials: length(json_map["materials"] || []),
          textures: length(json_map["textures"] || []),
          images: length(json_map["images"] || []),
          accessors: length(json_map["accessors"] || []),
          bufferViews: length(json_map["bufferViews"] || []),
          buffers: length(json_map["buffers"] || []),
          animations: length(json_map["animations"] || []),
          cameras: length(json_map["cameras"] || [])
        }

        IO.puts("\nGLTF Content:")
        IO.puts("=============")
        Enum.each(counts, fn {key, count} ->
          if count > 0 do
            IO.puts("#{String.capitalize(to_string(key))}: #{count}")
          end
        end)

      {:error, _reason} ->
        IO.puts("\nCould not parse JSON content for detailed info")
    end

    :ok
  end
end
