defmodule EAGL.Animation.Timeline do
  @moduledoc """
  A complete animation sequence containing multiple channels.

  Represents a self-contained animation action (like "walk", "run", "idle").
  """

  alias EAGL.Animation.{Channel, Sampler}

  defstruct [
    :name,
    :channels,
    :duration,
    :metadata
  ]

  @type node_id :: String.t() | atom()

  @type t :: %__MODULE__{
          name: String.t(),
          channels: [Channel.t()],
          duration: float(),
          metadata: map()
        }

  @doc """
  Create a new animation timeline.
  """
  @spec new(String.t(), keyword()) :: t()
  def new(name, opts \\ []) do
    %__MODULE__{
      name: name,
      channels: [],
      duration: 0.0,
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  @doc """
  Add an animation channel to the timeline.
  """
  @spec add_channel(t(), Channel.t()) :: t()
  def add_channel(%__MODULE__{} = timeline, %Channel{} = channel) do
    new_duration = max(timeline.duration, Sampler.duration(channel.sampler))

    %{
      timeline
      | channels: [channel | timeline.channels],
        duration: new_duration
    }
  end

  @doc """
  Get all channels targeting a specific node.
  """
  @spec channels_for_node(t(), node_id()) :: [Channel.t()]
  def channels_for_node(%__MODULE__{channels: channels}, node_id) do
    Enum.filter(channels, fn channel ->
      channel.target_node_id == node_id
    end)
  end
end
