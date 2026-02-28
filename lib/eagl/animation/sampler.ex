defmodule EAGL.Animation.Sampler do
  @moduledoc """
  Defines keyframe data and interpolation method for animation.

  Contains timestamp inputs, value outputs, and interpolation algorithm.
  Internally stores values as tuples for O(1) indexed access during per-frame sampling.
  """

  defstruct [
    :input_times,
    :output_values,
    :interpolation,
    :duration,
    :metadata
  ]

  @type interpolation_mode :: :linear | :step | :cubicspline
  @type keyframe_data :: [float()] | [tuple()] | [any()]
  @type timestamp :: float()

  @type t :: %__MODULE__{
          input_times: [timestamp()],
          output_values: tuple(),
          interpolation: interpolation_mode(),
          duration: float(),
          metadata: map()
        }

  @doc """
  Create a new animation sampler.

  Accepts lists for `input_times` and `output_values`. Values are converted
  to tuples internally for O(1) access during per-frame sampling.
  """
  @spec new([timestamp()], keyframe_data(), interpolation_mode(), keyword()) :: t()
  def new(input_times, output_values, interpolation \\ :linear, opts \\ []) do
    %__MODULE__{
      input_times: input_times,
      output_values: List.to_tuple(output_values),
      interpolation: interpolation,
      duration: List.last(input_times) || 0.0,
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  @doc """
  Get the duration of this sampler.
  """
  @spec duration(t()) :: float()
  def duration(%__MODULE__{duration: d}), do: d

  @doc """
  Sample the animation at a specific time with proper interpolation.
  """
  @spec sample(t(), timestamp()) :: any()
  def sample(%__MODULE__{} = sampler, time) do
    case find_keyframe_indices(sampler.input_times, sampler.duration, time) do
      {:exact, index} ->
        elem(sampler.output_values, index)

      {:between, index1, index2, factor} ->
        value1 = elem(sampler.output_values, index1)
        value2 = elem(sampler.output_values, index2)
        EAGL.Animation.interpolate(value1, value2, factor, sampler.interpolation)

      :before_start ->
        elem(sampler.output_values, 0)

      :after_end ->
        elem(sampler.output_values, tuple_size(sampler.output_values) - 1)
    end
  end

  defp find_keyframe_indices([], _duration, _time), do: :before_start

  defp find_keyframe_indices([single_time], _duration, time) do
    if abs(time - single_time) < 0.001, do: {:exact, 0}, else: :before_start
  end

  defp find_keyframe_indices(times, duration, time) do
    [first_time | _] = times

    cond do
      time <= first_time ->
        if abs(time - first_time) < 0.001, do: {:exact, 0}, else: :before_start

      time >= duration ->
        if abs(time - duration) < 0.001,
          do: {:exact, length(times) - 1},
          else: :after_end

      true ->
        find_surrounding_keyframes(times, time, 0)
    end
  end

  defp find_surrounding_keyframes([t1, t2 | _rest], time, index) when time >= t1 and time <= t2 do
    if abs(time - t1) < 0.001 do
      {:exact, index}
    else
      factor = (time - t1) / (t2 - t1)
      {:between, index, index + 1, factor}
    end
  end

  defp find_surrounding_keyframes([_t1 | rest], time, index) do
    find_surrounding_keyframes(rest, time, index + 1)
  end
end
