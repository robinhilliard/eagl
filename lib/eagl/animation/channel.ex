defmodule EAGL.Animation.Channel do
  @moduledoc """
  Links an animation sampler to a specific node property.

  Each channel animates one property (translation, rotation, scale, or morph weights)
  of one node over time.
  """

  alias EAGL.Animation.Sampler

  defstruct [
    :target_node_id,
    :target_property,
    :sampler,
    :metadata
  ]

  @type node_id :: String.t() | atom()
  @type property_path :: :translation | :rotation | :scale | :weights
  @type timestamp :: float()

  @type t :: %__MODULE__{
          target_node_id: node_id(),
          target_property: property_path(),
          sampler: Sampler.t(),
          metadata: map()
        }

  @doc """
  Create a new animation channel.
  """
  @spec new(node_id(), property_path(), Sampler.t(), keyword()) :: t()
  def new(target_node_id, target_property, sampler, opts \\ []) do
    %__MODULE__{
      target_node_id: target_node_id,
      target_property: target_property,
      sampler: sampler,
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  @doc """
  Sample the channel at a specific time.
  """
  @spec sample(t(), timestamp()) :: any()
  def sample(%__MODULE__{sampler: sampler}, time) do
    Sampler.sample(sampler, time)
  end
end
