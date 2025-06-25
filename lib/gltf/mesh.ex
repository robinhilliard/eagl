defmodule GLTF.Mesh do
  @moduledoc """
  A set of primitives to be rendered. A client implementation must render all primitives in the same mode.
  """

  defstruct [
    :primitives,
    :weights,
    :name,
    :extensions,
    :extras
  ]

  @type t :: %__MODULE__{
    primitives: [GLTF.Mesh.Primitive.t()],
    weights: [float()] | nil,
    name: String.t() | nil,
    extensions: map() | nil,
    extras: any() | nil
  }

  @doc """
  Create a new mesh with primitives.
  """
  def new(primitives, opts \\ []) when is_list(primitives) do
    %__MODULE__{
      primitives: primitives,
      weights: Keyword.get(opts, :weights),
      name: Keyword.get(opts, :name),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end
end

defmodule GLTF.Mesh.Primitive do
  @moduledoc """
  Geometry to be rendered with the given material.
  """

  defstruct [
    :attributes,
    :indices,
    :material,
    :mode,
    :targets,
    :extensions,
    :extras
  ]

  @type t :: %__MODULE__{
    attributes: %{String.t() => non_neg_integer()},
    indices: non_neg_integer() | nil,
    material: non_neg_integer() | nil,
    mode: primitive_mode(),
    targets: [%{String.t() => non_neg_integer()}] | nil,
    extensions: map() | nil,
    extras: any() | nil
  }

  @type primitive_mode :: :points | :lines | :line_loop | :line_strip | :triangles | :triangle_strip | :triangle_fan

  # WebGL primitive modes
  @points 0
  @lines 1
  @line_loop 2
  @line_strip 3
  @triangles 4
  @triangle_strip 5
  @triangle_fan 6

  def primitive_modes do
    %{
      @points => :points,
      @lines => :lines,
      @line_loop => :line_loop,
      @line_strip => :line_strip,
      @triangles => :triangles,
      @triangle_strip => :triangle_strip,
      @triangle_fan => :triangle_fan
    }
  end

  @doc """
  Create a new primitive.
  """
  def new(attributes, opts \\ []) when is_map(attributes) do
    %__MODULE__{
      attributes: attributes,
      indices: Keyword.get(opts, :indices),
      material: Keyword.get(opts, :material),
      mode: Keyword.get(opts, :mode, :triangles),
      targets: Keyword.get(opts, :targets),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end

  @doc """
  Standard vertex attribute names.
  """
  def standard_attributes do
    [
      "POSITION",
      "NORMAL",
      "TANGENT",
      "TEXCOORD_0",
      "TEXCOORD_1",
      "COLOR_0",
      "JOINTS_0",
      "WEIGHTS_0"
    ]
  end

  @doc """
  Check if attribute name is application-specific (starts with underscore).
  """
  def application_specific?("_" <> _), do: true
  def application_specific?(_), do: false
end
