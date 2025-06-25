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
