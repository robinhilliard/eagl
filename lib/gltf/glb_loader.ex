defmodule GLTF.GLBLoader do
  @moduledoc """
  GLB (Binary glTF) file loader with HTTP response caching.

  This module provides functionality to load and parse GLB files from local filesystem
  or remote URLs. It supports multiple HTTP clients and implements response caching
  with HTTP conditional requests for efficient remote file handling.

  ## Caching

  When loading GLB files from URLs, this module automatically implements HTTP response
  caching with the following features:

  - **Local cache**: Files are cached in `#{System.tmp_dir!()}/eagl_gltf_cache/`
  - **Conditional requests**: Uses ETags and Last-Modified headers for efficient updates
  - **Automatic expiry**: Cached files are considered fresh for 1 hour by default
  - **Graceful fallback**: Falls back to cached content if network requests fail

  Cache files are stored with SHA256 hashes of the URL to ensure uniqueness and security.

  ## Examples

      # Load from local file
      {:ok, glb_binary} = GLTF.GLBLoader.parse("model.glb")

      # Load from URL with automatic caching
      {:ok, glb_binary} = GLTF.GLBLoader.parse("https://example.com/model.glb")

      # Clear cache if needed
      GLTF.GLBLoader.clear_cache()

  ## HTTP Clients

  Supports multiple HTTP clients for flexibility:

  - **:req** (default) - Modern HTTP client with excellent performance and HTTP/2 support
  - **:httpc** - Built into Erlang/OTP, but may have compatibility issues with newer versions
  - **:httpoison** - Popular HTTP client (requires `{:httpoison, "~> 2.0"}` dependency)

  ## Error Handling

  The module provides comprehensive error handling for various failure scenarios:
  - Network connectivity issues
  - Invalid GLB file format
  - File system errors
  - HTTP errors (4xx, 5xx)

  When network requests fail but cached content is available, the module will
  automatically fall back to the cached version.
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
        {:error, reason} -> {:error, format_error(reason)}
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
    - :http_client - atom, HTTP client to use (:httpc, :req, :httpoison) (default: :req)

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
    http_client = Keyword.get(opts, :http_client, :req)

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

  # Format error atoms/tuples to strings for consistent error handling
  defp format_error(:enoent), do: "File not found"
  defp format_error(:eacces), do: "Permission denied"
  defp format_error(:eisdir), do: "Is a directory"
  defp format_error(reason) when is_atom(reason), do: "File error: #{reason}"
  defp format_error(reason) when is_binary(reason), do: reason
  defp format_error(reason), do: "Error: #{inspect(reason)}"

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
    fetch_url_httpc_cached(url, timeout)
  end

  # Fetch using built-in :httpc with response caching
  defp fetch_url_httpc_cached(url, timeout) do
    cache_info = get_cache_info(url)

    case check_cache(cache_info) do
      {:hit, body} ->
        # Cache hit - return cached content
        {:ok, body}

      {:miss, _reason} ->
        # Cache miss - fetch fresh content
        fetch_and_cache_httpc(url, timeout, cache_info, [])

      {:stale, cached_metadata} ->
        # Cache exists but may be stale - use conditional request
        conditional_headers = build_conditional_headers(cached_metadata)
        fetch_and_cache_httpc(url, timeout, cache_info, conditional_headers)
    end
  end

  # Get cache information for a URL
  defp get_cache_info(url) do
    cache_dir = get_cache_directory()
    url_hash = :crypto.hash(:sha256, url) |> Base.encode16(case: :lower)
    cache_file = Path.join(cache_dir, "#{url_hash}.glb")
    metadata_file = Path.join(cache_dir, "#{url_hash}.meta")

    %{
      url: url,
      cache_file: cache_file,
      metadata_file: metadata_file,
      cache_dir: cache_dir
    }
  end

  # Get or create cache directory
  defp get_cache_directory() do
    cache_dir = Path.join(System.tmp_dir!(), "eagl_gltf_cache")
    File.mkdir_p!(cache_dir)
    cache_dir
  end

  # Check cache status
  defp check_cache(%{cache_file: cache_file, metadata_file: metadata_file}) do
    case {File.exists?(cache_file), File.exists?(metadata_file)} do
      {true, true} ->
        case read_cache_metadata(metadata_file) do
          {:ok, metadata} ->
            if cache_fresh?(metadata) do
              case File.read(cache_file) do
                {:ok, body} -> {:hit, body}
                {:error, _} -> {:miss, :cache_read_error}
              end
            else
              {:stale, metadata}
            end

          {:error, _} ->
            {:miss, :metadata_read_error}
        end

      {true, false} ->
        {:miss, :missing_metadata}

      {false, _} ->
        {:miss, :missing_cache_file}
    end
  end

  # Read cache metadata
  defp read_cache_metadata(metadata_file) do
    case File.read(metadata_file) do
      {:ok, content} ->
        if Code.ensure_loaded?(Jason) do
          try do
            case apply(Jason, :decode, [content]) do
              {:ok, metadata} -> {:ok, metadata}
              {:error, _} -> {:error, :invalid_json}
            end
          rescue
            UndefinedFunctionError ->
              {:error, :invalid_json}
          end
        else
          # Fallback to :erlang.term_to_binary format if Jason not available
          try do
            {:ok, :erlang.binary_to_term(content)}
          rescue
            _ -> {:error, :invalid_term}
          end
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Check if cache is fresh (within 1 hour by default)
  defp cache_fresh?(metadata, max_age_seconds \\ 3600) do
    cached_at = Map.get(metadata, "cached_at", 0)
    current_time = System.system_time(:second)
    current_time - cached_at < max_age_seconds
  end

  # Build conditional request headers
  defp build_conditional_headers(metadata) do
    headers = []

    headers =
      case Map.get(metadata, "etag") do
        nil -> headers
        etag -> [{~c"if-none-match", String.to_charlist(etag)} | headers]
      end

    headers =
      case Map.get(metadata, "last_modified") do
        nil -> headers
        last_modified -> [{~c"if-modified-since", String.to_charlist(last_modified)} | headers]
      end

    headers
  end

  # Fetch and cache using httpc
  defp fetch_and_cache_httpc(url, timeout, cache_info, conditional_headers) do
    url_charlist = String.to_charlist(url)

    # Start inets if not already started
    :inets.start()

    # Set options for binary response and timeout
    http_options = [timeout: timeout, autoredirect: true]
    options = [body_format: :binary]

    case :httpc.request(:get, {url_charlist, conditional_headers}, http_options, options) do
      {:ok, {{_version, 200, _reason_phrase}, headers, body}} ->
        # Fresh content received - cache it
        metadata = extract_cache_metadata(headers)
        store_in_cache(cache_info, body, metadata)
        {:ok, body}

      {:ok, {{_version, 304, _reason_phrase}, _headers, _body}} ->
        # Not modified - use cached content
        case File.read(cache_info.cache_file) do
          {:ok, cached_body} ->
            # Update cache timestamp to extend freshness
            update_cache_timestamp(cache_info.metadata_file)
            {:ok, cached_body}

          {:error, reason} ->
            {:error, "Cache file missing after 304 response: #{reason}"}
        end

      {:ok, {{_version, status_code, reason_phrase}, _headers, _body}} ->
        {:error, "HTTP error #{status_code}: #{reason_phrase}"}

      {:error, reason} ->
        # If request fails but we have cached content, use it as fallback
        case File.read(cache_info.cache_file) do
          {:ok, cached_body} ->
            {:ok, cached_body}

          {:error, _} ->
            {:error, "HTTP request failed: #{inspect(reason)}"}
        end
    end
  end

  # Extract cache metadata from response headers
  defp extract_cache_metadata(headers) do
    etag =
      case :proplists.get_value(~c"etag", headers) do
        :undefined -> nil
        value -> List.to_string(value)
      end

    last_modified =
      case :proplists.get_value(~c"last-modified", headers) do
        :undefined -> nil
        value -> List.to_string(value)
      end

    cache_control =
      case :proplists.get_value(~c"cache-control", headers) do
        :undefined -> nil
        value -> List.to_string(value)
      end

    %{
      "etag" => etag,
      "last_modified" => last_modified,
      "cache_control" => cache_control,
      "cached_at" => System.system_time(:second)
    }
  end

  # Store content and metadata in cache
  defp store_in_cache(%{cache_file: cache_file, metadata_file: metadata_file}, body, metadata) do
    # Ensure cache directory exists
    File.mkdir_p!(Path.dirname(cache_file))

    # Write the binary content
    case File.write(cache_file, body) do
      :ok ->
        # Write metadata
        metadata_content =
          if Code.ensure_loaded?(Jason) do
            try do
              apply(Jason, :encode!, [metadata])
            rescue
              UndefinedFunctionError ->
                # Fallback to Erlang term format if Jason not available
                :erlang.term_to_binary(metadata)
            end
          else
            # Fallback to Erlang term format if Jason not available
            :erlang.term_to_binary(metadata)
          end

        File.write(metadata_file, metadata_content)

      {:error, reason} ->
        {:error, "Failed to write cache file: #{reason}"}
    end
  end

  # Update cache timestamp to extend freshness period
  defp update_cache_timestamp(metadata_file) do
    case read_cache_metadata(metadata_file) do
      {:ok, metadata} ->
        updated_metadata = Map.put(metadata, "cached_at", System.system_time(:second))

        metadata_content =
          if Code.ensure_loaded?(Jason) do
            try do
              apply(Jason, :encode!, [updated_metadata])
            rescue
              UndefinedFunctionError ->
                :erlang.term_to_binary(updated_metadata)
            end
          else
            :erlang.term_to_binary(updated_metadata)
          end

        File.write(metadata_file, metadata_content)

      {:error, _} ->
        # Ignore errors when updating timestamp
        :ok
    end
  end

  # Fetch using Req library (if available)
  defp fetch_url_req(url, timeout) do
    if Code.ensure_loaded?(Req) do
      try do
        case apply(Req, :get, [url, [receive_timeout: timeout]]) do
          {:ok, %{status: 200, body: body}} ->
            {:ok, body}

          {:ok, %{status: status_code}} ->
            {:error, "HTTP error #{status_code}"}

          {:error, reason} ->
            {:error, "Req request failed: #{inspect(reason)}"}
        end
      rescue
        UndefinedFunctionError ->
          {:error,
           "Req library not available. Please add {:req, \"~> 0.4\"} to your dependencies or use :httpc"}
      end
    else
      {:error,
       "Req library not available. Please add {:req, \"~> 0.4\"} to your dependencies or use :httpc"}
    end
  end

  # Fetch using HTTPoison library (if available)
  defp fetch_url_httpoison(url, timeout) do
    if Code.ensure_loaded?(HTTPoison) do
      try do
        case apply(HTTPoison, :get, [url, [], [recv_timeout: timeout]]) do
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
          {:error,
           "HTTPoison library not available. Please add {:httpoison, \"~> 2.0\"} to your dependencies or use :httpc"}
      end
    else
      {:error,
       "HTTPoison library not available. Please add {:httpoison, \"~> 2.0\"} to your dependencies or use :httpc"}
    end
  end

  # Parse the 12-byte GLB header
  defp parse_header(binary_data) when byte_size(binary_data) < 12 do
    {:error, "File too small: GLB header requires 12 bytes, got #{byte_size(binary_data)}"}
  end

  defp parse_header(binary_data) do
    <<magic::binary-size(4), version::little-unsigned-32, length::little-unsigned-32,
      rest::binary>> = binary_data

    # Validate magic first
    cond do
      magic != "glTF" ->
        {:error, "Invalid magic: expected 'glTF', got '#{magic}'"}

      # Then validate version
      version != 2 ->
        {:error, "Unsupported version: expected 2, got #{version}"}

      # Finally validate file size
      byte_size(binary_data) < length ->
        {:error,
         "File size mismatch: header claims #{length} bytes, file has #{byte_size(binary_data)}"}

      # All validations passed
      true ->
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
          {:ok, nil} ->
            glb_binary =
              Binary.new(
                header.magic,
                header.version,
                header.length,
                json_chunk
              )

            {:ok, glb_binary}

          {:ok, binary_chunk} ->
            glb_binary =
              Binary.new(
                header.magic,
                header.version,
                header.length,
                json_chunk,
                binary_chunk
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
          {:error,
           "First chunk must be JSON, got #{other} (0x#{Integer.to_string(chunk_type, 16)})"}
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
    if Code.ensure_loaded?(Jason) do
      try do
        case apply(Jason, :decode, [json_string]) do
          {:ok, _json} -> :ok
          {:error, reason} -> {:error, "Invalid JSON content: #{inspect(reason)}"}
        end
      rescue
        UndefinedFunctionError ->
          # Jason not available, skip JSON validation
          :ok
      end
    else
      # Jason not available, skip JSON validation
      :ok
    end
  end

  @doc """
  Loads a complete GLTF document from a GLB file.

  This function combines GLB parsing with full GLTF struct loading,
  creating a complete tree of module structs with proper data management.

  Options:
    - :validate - boolean, set to true to validate the parsed GLB structure (default: true)
    - :strict - boolean, set to true for strict validation that rejects any warnings (default: false)
    - :json_library - atom, JSON library to use (:poison, :jason) (default: :poison)

  ## Examples

      iex> {:ok, gltf} = GLTF.GLBLoader.load_gltf("model.glb")
      iex> gltf.asset.version
      "2.0"

  """
  @spec load_gltf(String.t(), keyword()) :: {:ok, GLTF.t()} | {:error, String.t()}
  def load_gltf(path_or_url, opts \\ []) do
    json_library = Keyword.get(opts, :json_library, :poison)

    with {:ok, glb_binary} <- parse(path_or_url, opts),
         {:ok, gltf} <- load_gltf_from_glb(glb_binary, json_library) do
      {:ok, gltf}
    end
  end

  @doc """
  Loads a complete GLTF document from a GLB binary structure.

  ## Examples

      iex> {:ok, glb_binary} = GLTF.GLBLoader.parse_binary(binary_data)
      iex> {:ok, gltf} = GLTF.GLBLoader.load_gltf_from_glb(glb_binary)

  """
  @spec load_gltf_from_glb(Binary.t(), atom()) :: {:ok, GLTF.t()} | {:error, String.t()}
  def load_gltf_from_glb(%Binary{} = glb_binary, json_library \\ :poison) do
    case json_library do
      :poison -> GLTF.load_from_glb(glb_binary)
      :jason -> load_gltf_from_glb_jason(glb_binary)
      _ -> {:error, "Unsupported JSON library: #{json_library}. Use :poison or :jason"}
    end
  end

  # Load GLTF using Jason library instead of Poison
  defp load_gltf_from_glb_jason(%Binary{} = glb_binary) do
    json_string = Binary.get_json(glb_binary)

    if Code.ensure_loaded?(Jason) do
      try do
        case apply(Jason, :decode, [json_string]) do
          {:ok, json_data} ->
            binary_data = Binary.get_binary(glb_binary)
            data_store = GLTF.DataStore.new()

            # GLB buffer (index 0) points to the binary chunk
            data_store =
              case binary_data do
                nil -> data_store
                data -> GLTF.DataStore.store_glb_buffer(data_store, 0, data)
              end

            GLTF.load(json_data, data_store)

          {:error, reason} ->
            {:error, "JSON decode error: #{inspect(reason)}"}
        end
      rescue
        UndefinedFunctionError ->
          {:error, "Jason library not available for JSON parsing"}
      end
    else
      {:error, "Jason library not available for JSON parsing"}
    end
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

    if Code.ensure_loaded?(Jason) do
      try do
        case apply(Jason, :decode, [json_string]) do
          {:ok, json_map} -> {:ok, json_map}
          {:error, reason} -> {:error, "JSON decode error: #{inspect(reason)}"}
        end
      rescue
        UndefinedFunctionError ->
          {:error, "Jason library not available for JSON parsing"}
      end
    else
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

    binary_size =
      case glb_binary.binary_chunk do
        nil -> 0
        chunk -> chunk.length
      end

    %{
      magic: glb_binary.magic,
      version: glb_binary.version,
      total_size: glb_binary.length,
      header_size: 12,
      # +8 for chunk header
      json_chunk_size: json_size + 8,
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

  @doc """
  Clears the GLB response cache.

  Removes all cached GLB files and their metadata from the temporary cache directory.
  This is useful for debugging, testing, or when you want to force fresh downloads.

  ## Examples

      iex> GLTF.GLBLoader.clear_cache()
      :ok

  """
  @spec clear_cache() :: :ok | {:error, String.t()}
  def clear_cache() do
    cache_dir = get_cache_directory()

    case File.rm_rf(cache_dir) do
      {:ok, _} ->
        # Recreate the empty cache directory
        File.mkdir_p!(cache_dir)
        :ok

      {:error, reason, _} ->
        {:error, "Failed to clear cache: #{inspect(reason)}"}
    end
  end

  @doc """
  Gets statistics about the GLB response cache.

  Returns information about cache size, number of files, and oldest/newest entries.

  ## Examples

      iex> GLTF.GLBLoader.cache_stats()
      %{
        cache_dir: "/tmp/eagl_gltf_cache",
        file_count: 5,
        total_size_bytes: 2048576,
        oldest_file: ~U[2024-01-15 10:30:00Z],
        newest_file: ~U[2024-01-15 14:45:00Z]
      }

  """
  @spec cache_stats() :: map()
  def cache_stats() do
    cache_dir = get_cache_directory()

    case File.ls(cache_dir) do
      {:ok, files} ->
        glb_files = Enum.filter(files, &String.ends_with?(&1, ".glb"))

        file_stats =
          Enum.map(glb_files, fn file ->
            file_path = Path.join(cache_dir, file)

            case File.stat(file_path) do
              {:ok, %File.Stat{size: size, mtime: mtime}} ->
                %{file: file, size: size, mtime: mtime}

              {:error, _} ->
                nil
            end
          end)
          |> Enum.reject(&is_nil/1)

        total_size = Enum.sum(Enum.map(file_stats, & &1.size))

        %{
          cache_dir: cache_dir,
          file_count: length(glb_files),
          total_size_bytes: total_size,
          oldest_file: file_stats |> Enum.map(& &1.mtime) |> Enum.min(fn -> nil end),
          newest_file: file_stats |> Enum.map(& &1.mtime) |> Enum.max(fn -> nil end)
        }

      {:error, :enoent} ->
        %{
          cache_dir: cache_dir,
          file_count: 0,
          total_size_bytes: 0,
          oldest_file: nil,
          newest_file: nil
        }

      {:error, reason} ->
        %{
          cache_dir: cache_dir,
          error: "Failed to read cache directory: #{inspect(reason)}"
        }
    end
  end
end
