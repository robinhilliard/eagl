defmodule GLTF.Animation do
  @moduledoc """
  A keyframe animation.
  """

  defstruct [
    :channels,
    :samplers,
    :name,
    :extensions,
    :extras
  ]

  @type t :: %__MODULE__{
          channels: [GLTF.Animation.Channel.t()],
          samplers: [GLTF.Animation.Sampler.t()],
          name: String.t() | nil,
          extensions: map() | nil,
          extras: any() | nil
        }

  @doc """
  Get the number of animation channels.
  """
  def channel_count(%__MODULE__{channels: channels}) when is_list(channels), do: length(channels)
  def channel_count(%__MODULE__{}), do: 0

  @doc """
  Load an Animation struct from JSON data.
  """
  def load(json_data) when is_map(json_data) do
    # Load channels
    channels =
      case json_data["channels"] do
        nil ->
          []

        channels_data when is_list(channels_data) ->
          Enum.map(channels_data, &load_channel/1)

        _ ->
          []
      end

    # Load samplers
    samplers =
      case json_data["samplers"] do
        nil ->
          []

        samplers_data when is_list(samplers_data) ->
          Enum.map(samplers_data, &load_sampler/1)

        _ ->
          []
      end

    animation = %__MODULE__{
      channels: channels,
      samplers: samplers,
      name: json_data["name"],
      extensions: json_data["extensions"],
      extras: json_data["extras"]
    }

    {:ok, animation}
  end

  defp load_channel(channel_data) when is_map(channel_data) do
    target =
      case channel_data["target"] do
        nil -> nil
        target_data -> load_channel_target(target_data)
      end

    # Create channel struct using map syntax to avoid forward reference
    %{
      __struct__: GLTF.Animation.Channel,
      sampler: channel_data["sampler"],
      target: target,
      extensions: channel_data["extensions"],
      extras: channel_data["extras"]
    }
  end

  defp load_channel_target(target_data) when is_map(target_data) do
    # Create target struct using map syntax to avoid forward reference
    %{
      __struct__: GLTF.Animation.Channel.Target,
      node: target_data["node"],
      path: target_data["path"],
      extensions: target_data["extensions"],
      extras: target_data["extras"]
    }
  end

  defp load_sampler(sampler_data) when is_map(sampler_data) do
    # Create sampler struct using map syntax to avoid forward reference
    %{
      __struct__: GLTF.Animation.Sampler,
      input: sampler_data["input"],
      interpolation: parse_interpolation(sampler_data["interpolation"]),
      output: sampler_data["output"],
      extensions: sampler_data["extensions"],
      extras: sampler_data["extras"]
    }
  end

  defp parse_interpolation("LINEAR"), do: :linear
  defp parse_interpolation("STEP"), do: :step
  defp parse_interpolation("CUBICSPLINE"), do: :cubicspline
  # Default
  defp parse_interpolation(_), do: :linear
end

defmodule GLTF.Animation.Sampler do
  @moduledoc """
  Combines input and output accessors with an interpolation algorithm to define a keyframe graph.
  """

  defstruct [
    :input,
    :interpolation,
    :output,
    :extensions,
    :extras
  ]

  @type t :: %__MODULE__{
          input: non_neg_integer(),
          interpolation: interpolation_type(),
          output: non_neg_integer(),
          extensions: map() | nil,
          extras: any() | nil
        }

  @type interpolation_type :: :linear | :step | :cubicspline

  def interpolation_types do
    [:linear, :step, :cubicspline]
  end
end

defmodule GLTF.Animation.Channel do
  @moduledoc """
  Targets an animation's sampler at a node's property.
  """

  defstruct [
    :sampler,
    :target,
    :extensions,
    :extras
  ]

  @type t :: %__MODULE__{
          sampler: non_neg_integer(),
          target: GLTF.Animation.Channel.Target.t(),
          extensions: map() | nil,
          extras: any() | nil
        }
end

defmodule GLTF.Animation.Channel.Target do
  @moduledoc """
  The index of the node and TRS property to target.
  """

  defstruct [
    :node,
    :path,
    :extensions,
    :extras
  ]

  @type t :: %__MODULE__{
          node: non_neg_integer() | nil,
          path: target_path(),
          extensions: map() | nil,
          extras: any() | nil
        }

  @type target_path :: :translation | :rotation | :scale | :weights

  def target_paths do
    [:translation, :rotation, :scale, :weights]
  end
end
