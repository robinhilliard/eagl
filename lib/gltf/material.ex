defmodule GLTF.Material do
  @moduledoc """
  The material appearance of a primitive using Physically Based Rendering (PBR).
  """

  defstruct [
    :name,
    :extensions,
    :extras,
    :pbr_metallic_roughness,
    :normal_texture,
    :occlusion_texture,
    :emissive_texture,
    :emissive_factor,
    :alpha_mode,
    :alpha_cutoff,
    :double_sided
  ]

  @type t :: %__MODULE__{
          name: String.t() | nil,
          extensions: map() | nil,
          extras: any() | nil,
          pbr_metallic_roughness: GLTF.Material.PbrMetallicRoughness.t() | nil,
          normal_texture: GLTF.Material.NormalTextureInfo.t() | nil,
          occlusion_texture: GLTF.Material.OcclusionTextureInfo.t() | nil,
          emissive_texture: GLTF.TextureInfo.t() | nil,
          emissive_factor: [float()] | nil,
          alpha_mode: alpha_mode(),
          alpha_cutoff: float(),
          double_sided: boolean()
        }

  @type alpha_mode :: :opaque | :mask | :blend

  def alpha_modes do
    [:opaque, :mask, :blend]
  end

  @doc """
  Create a new material with default PBR properties.
  """
  def new(opts \\ []) do
    %__MODULE__{
      name: Keyword.get(opts, :name),
      pbr_metallic_roughness: Keyword.get(opts, :pbr_metallic_roughness),
      normal_texture: Keyword.get(opts, :normal_texture),
      occlusion_texture: Keyword.get(opts, :occlusion_texture),
      emissive_texture: Keyword.get(opts, :emissive_texture),
      emissive_factor: Keyword.get(opts, :emissive_factor, [0.0, 0.0, 0.0]),
      alpha_mode: Keyword.get(opts, :alpha_mode, :opaque),
      alpha_cutoff: Keyword.get(opts, :alpha_cutoff, 0.5),
      double_sided: Keyword.get(opts, :double_sided, false),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end

  @doc """
  Create a default material (no properties specified).
  """
  def default do
    %__MODULE__{
      alpha_mode: :opaque,
      alpha_cutoff: 0.5,
      double_sided: false,
      emissive_factor: [0.0, 0.0, 0.0]
    }
  end

  @doc """
  Check if material uses the default metallic-roughness workflow.
  """
  def metallic_roughness?(%__MODULE__{pbr_metallic_roughness: nil}), do: false
  def metallic_roughness?(%__MODULE__{pbr_metallic_roughness: _}), do: true

  @doc """
  Load a Material struct from JSON data.
  """
  def load(json_data) when is_map(json_data) do
    # Load PBR metallic-roughness workflow
    pbr_metallic_roughness =
      case json_data["pbrMetallicRoughness"] do
        nil -> nil
        pbr_data -> load_pbr_metallic_roughness(pbr_data)
      end

    # Load normal texture
    normal_texture =
      case json_data["normalTexture"] do
        nil -> nil
        normal_data -> load_normal_texture(normal_data)
      end

    # Load occlusion texture
    occlusion_texture =
      case json_data["occlusionTexture"] do
        nil -> nil
        occlusion_data -> load_occlusion_texture(occlusion_data)
      end

    # Load emissive texture
    emissive_texture =
      case json_data["emissiveTexture"] do
        nil -> nil
        emissive_data -> load_texture_info(emissive_data)
      end

    # Parse alpha mode
    alpha_mode =
      case json_data["alphaMode"] do
        "OPAQUE" -> :opaque
        "MASK" -> :mask
        "BLEND" -> :blend
        # Default
        _ -> :opaque
      end

    material = %__MODULE__{
      name: json_data["name"],
      pbr_metallic_roughness: pbr_metallic_roughness,
      normal_texture: normal_texture,
      occlusion_texture: occlusion_texture,
      emissive_texture: emissive_texture,
      emissive_factor: json_data["emissiveFactor"] || [0.0, 0.0, 0.0],
      alpha_mode: alpha_mode,
      alpha_cutoff: json_data["alphaCutoff"] || 0.5,
      double_sided: json_data["doubleSided"] || false,
      extensions: json_data["extensions"],
      extras: json_data["extras"]
    }

    {:ok, material}
  end

  defp load_pbr_metallic_roughness(pbr_data) when is_map(pbr_data) do
    # Load base color texture
    base_color_texture =
      case pbr_data["baseColorTexture"] do
        nil -> nil
        texture_data -> load_texture_info(texture_data)
      end

    # Load metallic-roughness texture
    metallic_roughness_texture =
      case pbr_data["metallicRoughnessTexture"] do
        nil -> nil
        texture_data -> load_texture_info(texture_data)
      end

    # Create PBR struct using map syntax to avoid forward reference
    %{
      __struct__: GLTF.Material.PbrMetallicRoughness,
      base_color_factor: pbr_data["baseColorFactor"] || [1.0, 1.0, 1.0, 1.0],
      base_color_texture: base_color_texture,
      metallic_factor: pbr_data["metallicFactor"] || 1.0,
      roughness_factor: pbr_data["roughnessFactor"] || 1.0,
      metallic_roughness_texture: metallic_roughness_texture,
      extensions: pbr_data["extensions"],
      extras: pbr_data["extras"]
    }
  end

  defp load_normal_texture(normal_data) when is_map(normal_data) do
    # Create normal texture struct using map syntax to avoid forward reference
    %{
      __struct__: GLTF.Material.NormalTextureInfo,
      index: normal_data["index"],
      tex_coord: normal_data["texCoord"] || 0,
      scale: normal_data["scale"] || 1.0,
      extensions: normal_data["extensions"],
      extras: normal_data["extras"]
    }
  end

  defp load_occlusion_texture(occlusion_data) when is_map(occlusion_data) do
    # Create occlusion texture struct using map syntax to avoid forward reference
    %{
      __struct__: GLTF.Material.OcclusionTextureInfo,
      index: occlusion_data["index"],
      tex_coord: occlusion_data["texCoord"] || 0,
      strength: occlusion_data["strength"] || 1.0,
      extensions: occlusion_data["extensions"],
      extras: occlusion_data["extras"]
    }
  end

  defp load_texture_info(texture_data) when is_map(texture_data) do
    # Create texture info struct using map syntax to avoid forward reference
    %{
      __struct__: GLTF.TextureInfo,
      index: texture_data["index"],
      tex_coord: texture_data["texCoord"] || 0,
      extensions: texture_data["extensions"],
      extras: texture_data["extras"]
    }
  end
end

defmodule GLTF.Material.PbrMetallicRoughness do
  @moduledoc """
  A set of parameter values that are used to define the metallic-roughness material model.
  """

  defstruct [
    :base_color_factor,
    :base_color_texture,
    :metallic_factor,
    :roughness_factor,
    :metallic_roughness_texture,
    :extensions,
    :extras
  ]

  @type t :: %__MODULE__{
          base_color_factor: [float()] | nil,
          base_color_texture: GLTF.TextureInfo.t() | nil,
          metallic_factor: float(),
          roughness_factor: float(),
          metallic_roughness_texture: GLTF.TextureInfo.t() | nil,
          extensions: map() | nil,
          extras: any() | nil
        }

  @doc """
  Create new PBR metallic-roughness properties with defaults.
  """
  def new(opts \\ []) do
    %__MODULE__{
      base_color_factor: Keyword.get(opts, :base_color_factor, [1.0, 1.0, 1.0, 1.0]),
      base_color_texture: Keyword.get(opts, :base_color_texture),
      metallic_factor: Keyword.get(opts, :metallic_factor, 1.0),
      roughness_factor: Keyword.get(opts, :roughness_factor, 1.0),
      metallic_roughness_texture: Keyword.get(opts, :metallic_roughness_texture),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end
end

defmodule GLTF.Material.NormalTextureInfo do
  @moduledoc """
  Normal texture information with scale parameter.
  """

  defstruct [
    :index,
    :tex_coord,
    :scale,
    :extensions,
    :extras
  ]

  @type t :: %__MODULE__{
          index: non_neg_integer(),
          tex_coord: non_neg_integer(),
          scale: float(),
          extensions: map() | nil,
          extras: any() | nil
        }

  @doc """
  Create new normal texture info.
  """
  def new(index, opts \\ []) when is_integer(index) and index >= 0 do
    %__MODULE__{
      index: index,
      tex_coord: Keyword.get(opts, :tex_coord, 0),
      scale: Keyword.get(opts, :scale, 1.0),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end
end

defmodule GLTF.Material.OcclusionTextureInfo do
  @moduledoc """
  Occlusion texture information with strength parameter.
  """

  defstruct [
    :index,
    :tex_coord,
    :strength,
    :extensions,
    :extras
  ]

  @type t :: %__MODULE__{
          index: non_neg_integer(),
          tex_coord: non_neg_integer(),
          strength: float(),
          extensions: map() | nil,
          extras: any() | nil
        }

  @doc """
  Create new occlusion texture info.
  """
  def new(index, opts \\ []) when is_integer(index) and index >= 0 do
    %__MODULE__{
      index: index,
      tex_coord: Keyword.get(opts, :tex_coord, 0),
      strength: Keyword.get(opts, :strength, 1.0),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end
end
