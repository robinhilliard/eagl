defmodule GLTF.Image do
  @moduledoc """
  Image data used to create a texture. Can reference external files or embed data.
  """

  defstruct [
    :uri,
    :mime_type,
    :buffer_view,
    :name,
    :extensions,
    :extras
  ]

  @type t :: %__MODULE__{
          uri: String.t() | nil,
          mime_type: String.t() | nil,
          buffer_view: non_neg_integer() | nil,
          name: String.t() | nil,
          extensions: map() | nil,
          extras: any() | nil
        }

  @doc """
  Create a new image from URI.
  """
  def from_uri(uri, opts \\ []) when is_binary(uri) do
    %__MODULE__{
      uri: uri,
      name: Keyword.get(opts, :name),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end

  @doc """
  Create a new image from buffer view.
  """
  def from_buffer_view(buffer_view, mime_type, opts \\ [])
      when is_integer(buffer_view) and buffer_view >= 0 and is_binary(mime_type) do
    %__MODULE__{
      buffer_view: buffer_view,
      mime_type: mime_type,
      name: Keyword.get(opts, :name),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end

  @doc """
  Supported MIME types for images.
  """
  def supported_mime_types do
    [
      "image/jpeg",
      "image/png"
    ]
  end

  @doc """
  Check if MIME type is supported.
  """
  def supported_mime_type?(mime_type) do
    mime_type in supported_mime_types()
  end

  @doc """
  Detect MIME type from binary data magic bytes.
  """
  def detect_mime_type(<<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, _::binary>>),
    do: "image/png"

  def detect_mime_type(<<0xFF, 0xD8, 0xFF, _::binary>>), do: "image/jpeg"
  def detect_mime_type(_), do: nil

  @doc """
  Check if image uses embedded data (data URI).
  """
  def embedded?(%__MODULE__{uri: "data:" <> _}), do: true
  def embedded?(%__MODULE__{}), do: false

  @doc """
  Check if image is stored in buffer view.
  """
  def buffer_stored?(%__MODULE__{buffer_view: buffer_view}) when is_integer(buffer_view), do: true
  def buffer_stored?(%__MODULE__{}), do: false

  @doc """
  Check if image references external file.
  """
  def external?(%__MODULE__{uri: uri, buffer_view: nil}) when is_binary(uri) do
    not embedded?(%__MODULE__{uri: uri})
  end

  def external?(%__MODULE__{}), do: false

  @doc """
  Get file extension from URI.
  """
  def file_extension(%__MODULE__{uri: uri}) when is_binary(uri) do
    case Path.extname(uri) do
      "." <> ext -> String.downcase(ext)
      _ -> nil
    end
  end

  def file_extension(%__MODULE__{}), do: nil

  @doc """
  Guess MIME type from file extension.
  """
  def mime_type_from_extension("jpg"), do: "image/jpeg"
  def mime_type_from_extension("jpeg"), do: "image/jpeg"
  def mime_type_from_extension("png"), do: "image/png"
  def mime_type_from_extension(_), do: nil

  @doc """
  Load an Image struct from JSON data.
  """
  def load(json_data) when is_map(json_data) do
    image = %__MODULE__{
      uri: json_data["uri"],
      mime_type: json_data["mimeType"],
      buffer_view: json_data["bufferView"],
      name: json_data["name"],
      extensions: json_data["extensions"],
      extras: json_data["extras"]
    }

    # Validate that either URI or buffer_view is specified, but not both
    case {image.uri, image.buffer_view} do
      {nil, nil} ->
        {:error, :missing_image_source}

      {_, _} when image.uri != nil and image.buffer_view != nil ->
        {:error, :both_uri_and_buffer_view_specified}

      {uri, nil} when is_binary(uri) ->
        {:ok, image}

      {nil, buffer_view} when is_integer(buffer_view) ->
        # When using buffer_view, mime_type is required
        case image.mime_type do
          nil -> {:error, :missing_mime_type_for_buffer_view}
          mime when is_binary(mime) -> {:ok, image}
          _ -> {:error, :invalid_mime_type}
        end

      _ ->
        {:error, :invalid_image_configuration}
    end
  end
end
