defmodule GLTF.Extension do
  @moduledoc """
  glTF extensions mechanism support.

  Extensions allow the base format to be extended with new capabilities.
  Any glTF object can have an optional 'extensions' property.
  """

  @type t :: %{String.t() => any()}

  @doc """
  Validates that all extensions are properly declared in extensionsUsed.
  """
  def validate_extensions(extensions, extensions_used) when is_map(extensions) do
    extension_names = Map.keys(extensions)
    undeclared = extension_names -- extensions_used

    case undeclared do
      [] -> :ok
      _ -> {:error, {:undeclared_extensions, undeclared}}
    end
  end

  def validate_extensions(nil, _), do: :ok

  @doc """
  Check if required extensions are supported.
  """
  def check_required_support(extensions_required, supported_extensions) do
    unsupported = extensions_required -- supported_extensions

    case unsupported do
      [] -> :ok
      _ -> {:error, {:unsupported_required_extensions, unsupported}}
    end
  end

  @doc """
  Get a specific extension from an extensions map.
  """
  def get_extension(extensions, extension_name) when is_map(extensions) do
    Map.get(extensions, extension_name)
  end

  def get_extension(nil, _), do: nil

  @doc """
  Check if an extension is present.
  """
  def has_extension?(extensions, extension_name) when is_map(extensions) do
    Map.has_key?(extensions, extension_name)
  end

  def has_extension?(nil, _), do: false

  @doc """
  Known Khronos extensions (KHR_*).
  """
  def known_khr_extensions do
    [
      "KHR_draco_mesh_compression",
      "KHR_lights_punctual",
      "KHR_materials_clearcoat",
      "KHR_materials_ior",
      "KHR_materials_iridescence",
      "KHR_materials_sheen",
      "KHR_materials_specular",
      "KHR_materials_transmission",
      "KHR_materials_unlit",
      "KHR_materials_variants",
      "KHR_materials_volume",
      "KHR_mesh_quantization",
      "KHR_texture_basisu",
      "KHR_texture_transform",
      "KHR_xmp_json_ld"
    ]
  end

  @doc """
  Check if extension name follows proper naming convention.
  """
  def valid_extension_name?(name) when is_binary(name) do
    # Extension names should follow KHR_, EXT_, or vendor prefix pattern
    String.match?(name, ~r/^[A-Z][A-Z0-9]*_[a-zA-Z0-9_]+$/)
  end

  def valid_extension_name?(_), do: false
end
