defmodule EAGL.Animation do
  @moduledoc """
  Core animation system for EAGL.

  Provides keyframe-based animation support with multiple interpolation modes,
  designed to work seamlessly with EAGL's scene graph system while supporting
  industry-standard formats like glTF.

  ## Animation Concepts

  - **Timeline**: A collection of channels that animate different properties over time
  - **Channel**: Connects a sampler to a specific node property (translation, rotation, scale)
  - **Sampler**: Defines keyframe data with timestamps and interpolation method
  - **Interpolation**: How values are calculated between keyframes (linear, step, cubic spline)

  ## Usage

      # Create an animation timeline
      timeline = EAGL.Animation.Timeline.new("walk_cycle")

      # Add animation channels
      sampler = EAGL.Animation.Sampler.new([0.0, 1.0], [vec3(0,0,0), vec3(1,0,0)])
      channel = EAGL.Animation.Channel.new("leg_bone", :translation, sampler)
      timeline = EAGL.Animation.Timeline.add_channel(timeline, channel)

      # Create and use an animator
      {:ok, animator} = EAGL.Animator.new()
      EAGL.Animator.load_timeline(animator, timeline)
      EAGL.Animator.play(animator, "walk_cycle")

      # In your render loop
      EAGL.Animator.update(animator, delta_time)
      EAGL.Animator.apply_to_scene(animator, scene)

  ## Integration with glTF

  This module works seamlessly with glTF animations via the bridge module:

      gltf_timeline = GLTF.EAGL.animation_to_timeline(gltf_animation, gltf_data)
      EAGL.Animator.load_timeline(animator, gltf_timeline)
  """

  import EAGL.Math
  use EAGL.Const

  alias EAGL.Animation.{Timeline, Channel, Sampler}

  @type timestamp :: float()
  @type node_id :: String.t() | atom()
  @type property_path :: :translation | :rotation | :scale | :weights

  @doc """
  Interpolate between two values based on interpolation mode.
  """
  @spec interpolate(any(), any(), float(), Sampler.interpolation_mode()) :: any()
  def interpolate(value1, value2, factor, interpolation_mode)

  # Linear interpolation for vectors (when wrapped in lists)
  def interpolate([vec1], [vec2], factor, :linear) when is_tuple(vec1) and is_tuple(vec2) do
    vec_lerp([vec1], [vec2], factor)
  end

  # Linear interpolation for vectors
  def interpolate(vec1, vec2, factor, :linear) when is_tuple(vec1) and is_tuple(vec2) do
    vec_lerp([vec1], [vec2], factor)
  end

  # Linear interpolation for quaternions (when wrapped in lists)
  def interpolate([quat1], [quat2], factor, :linear)
      when is_tuple(quat1) and tuple_size(quat1) == 4 do
    quat_slerp([quat1], [quat2], factor)
  end

  # Linear interpolation for quaternions (slerp)
  def interpolate(quat1, quat2, factor, :linear)
      when is_tuple(quat1) and tuple_size(quat1) == 4 do
    quat_slerp([quat1], [quat2], factor)
  end

  # Linear interpolation for scalars
  def interpolate(scalar1, scalar2, factor, :linear)
      when is_number(scalar1) and is_number(scalar2) do
    scalar1 + (scalar2 - scalar1) * factor
  end

  # Step interpolation for single-wrapped values
  def interpolate([value1], [_value2], _factor, :step) do
    value1
  end

  # Step interpolation (no blending)
  def interpolate(value1, _value2, factor, :step) do
    if factor < 1.0, do: value1, else: value1
  end

  # Cubic spline interpolation (simplified - real implementation would use control points)
  def interpolate(value1, value2, factor, :cubicspline) do
    # For now, fall back to linear interpolation
    # A full implementation would use the additional control points from glTF
    interpolate(value1, value2, factor, :linear)
  end

  @doc """
  Create a simple animation sampler for common use cases.
  """
  @spec create_simple_sampler(keyword()) :: Sampler.t()
  def create_simple_sampler(opts) do
    keyframes = Keyword.fetch!(opts, :keyframes)
    duration = Keyword.get(opts, :duration, 1.0)
    interpolation = Keyword.get(opts, :interpolation, :linear)

    # Generate evenly spaced timestamps
    frame_count = length(keyframes)
    time_step = duration / max(frame_count - 1, 1)

    input_times =
      0..(frame_count - 1)
      |> Enum.map(fn i -> i * time_step end)

    Sampler.new(input_times, keyframes, interpolation)
  end

  @doc """
  Create a rotation animation that spins around the Y axis.
  """
  @spec create_rotation_animation(float(), keyword()) :: Timeline.t()
  def create_rotation_animation(duration, opts \\ []) do
    node_id = Keyword.get(opts, :node_id, "animated_node")
    name = Keyword.get(opts, :name, "rotate_y")

    # Create keyframes for full rotation
    keyframes = [
      quat_from_euler(0.0, 0.0, 0.0),
      quat_from_euler(0.0, :math.pi() / 2.0, 0.0),
      quat_from_euler(0.0, :math.pi(), 0.0),
      quat_from_euler(0.0, 3.0 * :math.pi() / 2.0, 0.0),
      quat_from_euler(0.0, 2.0 * :math.pi(), 0.0)
    ]

    sampler =
      create_simple_sampler(
        keyframes: keyframes,
        duration: duration,
        interpolation: :linear
      )

    channel = Channel.new(node_id, :rotation, sampler)

    Timeline.new(name)
    |> Timeline.add_channel(channel)
  end

  @doc """
  Create a translation animation that moves back and forth.
  """
  @spec create_translation_animation(tuple(), tuple(), float(), keyword()) :: Timeline.t()
  def create_translation_animation(start_pos, end_pos, duration, opts \\ []) do
    node_id = Keyword.get(opts, :node_id, "animated_node")
    name = Keyword.get(opts, :name, "translate")

    keyframes = [start_pos, end_pos, start_pos]

    sampler =
      create_simple_sampler(
        keyframes: keyframes,
        duration: duration,
        interpolation: :linear
      )

    channel = Channel.new(node_id, :translation, sampler)

    Timeline.new(name)
    |> Timeline.add_channel(channel)
  end
end
