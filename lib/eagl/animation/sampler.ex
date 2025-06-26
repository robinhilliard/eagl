defmodule EAGL.Animation.Sampler do
  @moduledoc """
  Defines keyframe data and interpolation method for animation.

  Contains timestamp inputs, value outputs, and interpolation algorithm.
  """

  defstruct [
    :input_times,
    :output_values,
    :interpolation,
    :metadata
  ]

  @type interpolation_mode :: :linear | :step | :cubicspline
  @type keyframe_data :: [float()] | [tuple()] | [any()]
  @type timestamp :: float()

  @type t :: %__MODULE__{
          input_times: [timestamp()],
          output_values: keyframe_data(),
          interpolation: interpolation_mode(),
          metadata: map()
        }

  @doc """
  Create a new animation sampler.
  """
  @spec new([timestamp()], keyframe_data(), interpolation_mode(), keyword()) :: t()
  def new(input_times, output_values, interpolation \\ :linear, opts \\ []) do
    %__MODULE__{
      input_times: input_times,
      output_values: output_values,
      interpolation: interpolation,
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  @doc """
  Get the duration of this sampler.
  """
  @spec duration(t()) :: float()
  def duration(%__MODULE__{input_times: []}), do: 0.0
  def duration(%__MODULE__{input_times: times}), do: List.last(times)

  @doc """
  Sample the animation at a specific time with proper interpolation.
  """
  @spec sample(t(), timestamp()) :: any()
  def sample(%__MODULE__{} = sampler, time) do
    case find_keyframe_indices(sampler.input_times, time) do
      {:exact, index} ->
        # Exact keyframe match
        Enum.at(sampler.output_values, index)

      {:between, index1, index2, factor} ->
        # Interpolate between keyframes
        value1 = Enum.at(sampler.output_values, index1)
        value2 = Enum.at(sampler.output_values, index2)
        EAGL.Animation.interpolate(value1, value2, factor, sampler.interpolation)

      {:before_start} ->
        # Before first keyframe
        List.first(sampler.output_values)

      {:after_end} ->
        # After last keyframe
        List.last(sampler.output_values)
    end
  end

  # Find the appropriate keyframe indices for a given time
  defp find_keyframe_indices([], _time), do: {:before_start}

  defp find_keyframe_indices([single_time], time) do
    if abs(time - single_time) < 0.001 do
      {:exact, 0}
    else
      {:before_start}
    end
  end

  defp find_keyframe_indices(times, time) do
    first_time = List.first(times)
    last_time = List.last(times)

    cond do
      time <= first_time ->
        if abs(time - first_time) < 0.001 do
          {:exact, 0}
        else
          {:before_start}
        end

      time >= last_time ->
        if abs(time - last_time) < 0.001 do
          {:exact, length(times) - 1}
        else
          {:after_end}
        end

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
