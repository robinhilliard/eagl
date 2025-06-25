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
