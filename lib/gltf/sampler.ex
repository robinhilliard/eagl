defmodule GLTF.Sampler do
  @moduledoc """
  Texture sampler properties for filtering and wrapping modes.
  """

  defstruct [
    :mag_filter,
    :min_filter,
    :wrap_s,
    :wrap_t,
    :name,
    :extensions,
    :extras
  ]

  @type t :: %__MODULE__{
          mag_filter: mag_filter() | nil,
          min_filter: min_filter() | nil,
          wrap_s: wrap_mode(),
          wrap_t: wrap_mode(),
          name: String.t() | nil,
          extensions: map() | nil,
          extras: any() | nil
        }

  @type mag_filter :: :nearest | :linear
  @type min_filter ::
          :nearest
          | :linear
          | :nearest_mipmap_nearest
          | :linear_mipmap_nearest
          | :nearest_mipmap_linear
          | :linear_mipmap_linear
  @type wrap_mode :: :clamp_to_edge | :mirrored_repeat | :repeat

  # WebGL filter constants
  @nearest 9728
  @linear 9729
  @nearest_mipmap_nearest 9984
  @linear_mipmap_nearest 9985
  @nearest_mipmap_linear 9986
  @linear_mipmap_linear 9987

  # WebGL wrap constants
  @clamp_to_edge 33071
  @mirrored_repeat 33648
  @repeat 10497

  def mag_filter_constants do
    %{
      @nearest => :nearest,
      @linear => :linear
    }
  end

  def min_filter_constants do
    %{
      @nearest => :nearest,
      @linear => :linear,
      @nearest_mipmap_nearest => :nearest_mipmap_nearest,
      @linear_mipmap_nearest => :linear_mipmap_nearest,
      @nearest_mipmap_linear => :nearest_mipmap_linear,
      @linear_mipmap_linear => :linear_mipmap_linear
    }
  end

  def wrap_constants do
    %{
      @clamp_to_edge => :clamp_to_edge,
      @mirrored_repeat => :mirrored_repeat,
      @repeat => :repeat
    }
  end

  @doc """
  Create a new sampler with default repeat wrapping.
  """
  def new(opts \\ []) do
    %__MODULE__{
      mag_filter: Keyword.get(opts, :mag_filter),
      min_filter: Keyword.get(opts, :min_filter),
      wrap_s: Keyword.get(opts, :wrap_s, :repeat),
      wrap_t: Keyword.get(opts, :wrap_t, :repeat),
      name: Keyword.get(opts, :name),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end

  @doc """
  Get WebGL constant for mag filter.
  """
  def mag_filter_constant(:nearest), do: @nearest
  def mag_filter_constant(:linear), do: @linear
  def mag_filter_constant(nil), do: nil

  @doc """
  Get WebGL constant for min filter.
  """
  def min_filter_constant(:nearest), do: @nearest
  def min_filter_constant(:linear), do: @linear
  def min_filter_constant(:nearest_mipmap_nearest), do: @nearest_mipmap_nearest
  def min_filter_constant(:linear_mipmap_nearest), do: @linear_mipmap_nearest
  def min_filter_constant(:nearest_mipmap_linear), do: @nearest_mipmap_linear
  def min_filter_constant(:linear_mipmap_linear), do: @linear_mipmap_linear
  def min_filter_constant(nil), do: nil

  @doc """
  Get WebGL constant for wrap mode.
  """
  def wrap_constant(:clamp_to_edge), do: @clamp_to_edge
  def wrap_constant(:mirrored_repeat), do: @mirrored_repeat
  def wrap_constant(:repeat), do: @repeat

  @doc """
  Check if min filter uses mipmapping.
  """
  def uses_mipmaps?(filter)
      when filter in [
             :nearest_mipmap_nearest,
             :linear_mipmap_nearest,
             :nearest_mipmap_linear,
             :linear_mipmap_linear
           ],
      do: true

  def uses_mipmaps?(_), do: false

  @doc """
  Check if this sampler uses linear filtering for magnification.
  """
  def linear_mag?(%__MODULE__{mag_filter: @linear}), do: true
  def linear_mag?(%__MODULE__{}), do: false

  @doc """
  Load a Sampler struct from JSON data.
  """
  def load(json_data) when is_map(json_data) do
    # Parse filter values
    mag_filter = parse_filter(json_data["magFilter"])
    min_filter = parse_filter(json_data["minFilter"])

    # Parse wrap values
    wrap_s = parse_wrap(json_data["wrapS"], @repeat)
    wrap_t = parse_wrap(json_data["wrapT"], @repeat)

    sampler = %__MODULE__{
      mag_filter: mag_filter,
      min_filter: min_filter,
      wrap_s: wrap_s,
      wrap_t: wrap_t,
      name: json_data["name"],
      extensions: json_data["extensions"],
      extras: json_data["extras"]
    }

    {:ok, sampler}
  end

  # Parse filter constants
  defp parse_filter(nil), do: nil
  defp parse_filter(@nearest), do: @nearest
  defp parse_filter(@linear), do: @linear
  defp parse_filter(@nearest_mipmap_nearest), do: @nearest_mipmap_nearest
  defp parse_filter(@linear_mipmap_nearest), do: @linear_mipmap_nearest
  defp parse_filter(@nearest_mipmap_linear), do: @nearest_mipmap_linear
  defp parse_filter(@linear_mipmap_linear), do: @linear_mipmap_linear
  defp parse_filter(_), do: nil

  # Parse wrap constants
  defp parse_wrap(nil, default), do: default
  defp parse_wrap(@clamp_to_edge, _), do: @clamp_to_edge
  defp parse_wrap(@mirrored_repeat, _), do: @mirrored_repeat
  defp parse_wrap(@repeat, _), do: @repeat
  defp parse_wrap(_, default), do: default
end
