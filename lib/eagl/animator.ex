defmodule EAGL.Animator do
  @moduledoc """
  Runtime animation controller for EAGL.

  Manages animation playback, timeline progression, and application of animated
  values to scene nodes. Supports multiple animations, looping, and basic blending.

  ## Design Philosophy

  The Animator acts as a runtime engine that bridges EAGL's animation data structures
  with the scene graph system. It provides:

  - **Timeline Management**: Load and organize multiple animation timelines
  - **Playback Control**: Play, pause, stop, loop animations
  - **Time Progression**: Delta-time based animation updates
  - **Scene Integration**: Apply animated transforms to EAGL.Scene nodes
  - **Performance**: Efficient updates with minimal allocations

  ## Usage

      # Create an animator
      {:ok, animator} = EAGL.Animator.new()

      # Load animation timelines
      EAGL.Animator.load_timeline(animator, walk_animation)
      EAGL.Animator.load_timeline(animator, run_animation)

      # Control playback
      EAGL.Animator.play(animator, "walk_cycle")
      EAGL.Animator.set_loop(animator, true)

      # In your render loop
      EAGL.Animator.update(animator, delta_time)
      EAGL.Animator.apply_to_scene(animator, scene)

  ## Integration with glTF

  Works seamlessly with glTF animations:

      {:ok, gltf} = GLTF.GLBLoader.parse("character.glb")
      timelines = GLTF.EAGL.convert_animations(gltf, data_store)

      Enum.each(timelines, fn timeline ->
        EAGL.Animator.load_timeline(animator, timeline)
      end)
  """

  use GenServer
  alias EAGL.{Scene, Node}
  alias EAGL.Animation.{Timeline, Channel}

  @type animation_state :: :stopped | :playing | :paused
  @type timeline_name :: String.t()

  defstruct [
    :timelines,
    :current_animation,
    :current_time,
    :playback_state,
    :loop_enabled,
    :playback_speed,
    :metadata
  ]

  @type t :: %__MODULE__{
          timelines: %{timeline_name() => Timeline.t()},
          current_animation: timeline_name() | nil,
          current_time: float(),
          playback_state: animation_state(),
          loop_enabled: boolean(),
          playback_speed: float(),
          metadata: map()
        }

  ## Public API

  @doc """
  Create a new animator.
  """
  @spec new(keyword()) :: {:ok, pid()} | {:error, term()}
  def new(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Load an animation timeline into the animator.
  """
  @spec load_timeline(pid(), Timeline.t()) :: :ok | {:error, term()}
  def load_timeline(animator, %Timeline{} = timeline) do
    GenServer.call(animator, {:load_timeline, timeline})
  end

  @doc """
  Start playing a specific animation timeline.
  """
  @spec play(pid(), timeline_name()) :: :ok | {:error, term()}
  def play(animator, timeline_name) do
    GenServer.call(animator, {:play, timeline_name})
  end

  @doc """
  Pause the current animation.
  """
  @spec pause(pid()) :: :ok
  def pause(animator) do
    GenServer.call(animator, :pause)
  end

  @doc """
  Stop the current animation and reset to beginning.
  """
  @spec stop(pid()) :: :ok
  def stop(animator) do
    GenServer.call(animator, :stop)
  end

  @doc """
  Update the animator with delta time.
  """
  @spec update(pid(), float()) :: :ok
  def update(animator, delta_time) do
    GenServer.call(animator, {:update, delta_time})
  end

  @doc """
  Apply current animation state to a scene.
  """
  @spec apply_to_scene(pid(), Scene.t()) :: Scene.t()
  def apply_to_scene(animator, %Scene{} = scene) do
    GenServer.call(animator, {:apply_to_scene, scene})
  end

  @doc """
  Set whether the current animation should loop.
  """
  @spec set_loop(pid(), boolean()) :: :ok
  def set_loop(animator, loop_enabled) do
    GenServer.call(animator, {:set_loop, loop_enabled})
  end

  @doc """
  Set the playback speed multiplier.
  """
  @spec set_speed(pid(), float()) :: :ok
  def set_speed(animator, speed) do
    GenServer.call(animator, {:set_speed, speed})
  end

  @doc """
  Get the current animation state.
  """
  @spec get_state(pid()) :: t()
  def get_state(animator) do
    GenServer.call(animator, :get_state)
  end

  @doc """
  Get the list of available animation timeline names.
  """
  @spec list_timelines(pid()) :: [timeline_name()]
  def list_timelines(animator) do
    GenServer.call(animator, :list_timelines)
  end

  ## GenServer Implementation

  @impl GenServer
  def init(opts) do
    state = %__MODULE__{
      timelines: %{},
      current_animation: nil,
      current_time: 0.0,
      playback_state: :stopped,
      loop_enabled: Keyword.get(opts, :loop, false),
      playback_speed: Keyword.get(opts, :speed, 1.0),
      metadata: Keyword.get(opts, :metadata, %{})
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_call({:load_timeline, timeline}, _from, state) do
    new_timelines = Map.put(state.timelines, timeline.name, timeline)
    new_state = %{state | timelines: new_timelines}
    {:reply, :ok, new_state}
  end

  @impl GenServer
  def handle_call({:play, timeline_name}, _from, state) do
    case Map.get(state.timelines, timeline_name) do
      nil ->
        {:reply, {:error, "Timeline '#{timeline_name}' not found"}, state}

      _timeline ->
        new_state = %{
          state
          | current_animation: timeline_name,
            current_time: 0.0,
            playback_state: :playing
        }

        {:reply, :ok, new_state}
    end
  end

  @impl GenServer
  def handle_call(:pause, _from, state) do
    new_state = %{state | playback_state: :paused}
    {:reply, :ok, new_state}
  end

  @impl GenServer
  def handle_call(:stop, _from, state) do
    new_state = %{
      state
      | playback_state: :stopped,
        current_time: 0.0
    }

    {:reply, :ok, new_state}
  end

  @impl GenServer
  def handle_call({:update, delta_time}, _from, state) do
    new_state = update_animation_time(state, delta_time)
    {:reply, :ok, new_state}
  end

  @impl GenServer
  def handle_call({:apply_to_scene, scene}, _from, state) do
    updated_scene = apply_current_animation(state, scene)
    {:reply, updated_scene, state}
  end

  @impl GenServer
  def handle_call({:set_loop, loop_enabled}, _from, state) do
    new_state = %{state | loop_enabled: loop_enabled}
    {:reply, :ok, new_state}
  end

  @impl GenServer
  def handle_call({:set_speed, speed}, _from, state) do
    new_state = %{state | playback_speed: speed}
    {:reply, :ok, new_state}
  end

  @impl GenServer
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl GenServer
  def handle_call(:list_timelines, _from, state) do
    timeline_names = Map.keys(state.timelines)
    {:reply, timeline_names, state}
  end

  ## Private Implementation

  defp update_animation_time(%{playback_state: :playing} = state, delta_time) do
    case get_current_timeline(state) do
      nil ->
        state

      timeline ->
        scaled_delta = delta_time * state.playback_speed
        new_time = state.current_time + scaled_delta

        handle_timeline_progression(state, timeline, new_time)
    end
  end

  defp update_animation_time(state, _delta_time) do
    # Not playing, don't update time
    state
  end

  defp handle_timeline_progression(state, timeline, new_time) do
    cond do
      new_time >= timeline.duration and state.loop_enabled ->
        # Loop back to beginning
        looped_time = :math.fmod(new_time, timeline.duration)

        %{state | current_time: looped_time}

      new_time >= timeline.duration ->
        # Stop at end
        %{
          state
          | current_time: timeline.duration,
            playback_state: :stopped
        }

      true ->
        # Normal progression
        %{state | current_time: new_time}
    end
  end

  defp apply_current_animation(state, scene) do
    case get_current_timeline(state) do
      nil ->
        scene

      timeline ->
        apply_timeline_to_scene(timeline, state.current_time, scene)
    end
  end

  defp get_current_timeline(%{current_animation: nil}), do: nil

  defp get_current_timeline(%{current_animation: name, timelines: timelines}) do
    Map.get(timelines, name)
  end

  defp apply_timeline_to_scene(timeline, current_time, scene) do
    # Group channels by target node for efficiency
    channels_by_node = Enum.group_by(timeline.channels, & &1.target_node_id)

    # Apply animations to each affected node
    Enum.reduce(channels_by_node, scene, fn {node_id, channels}, acc_scene ->
      apply_channels_to_node(acc_scene, node_id, channels, current_time)
    end)
  end

  defp apply_channels_to_node(scene, node_id, channels, current_time) do
    case Scene.find_node(scene, node_id) do
      nil ->
        # Node not found, skip
        scene

      node ->
        # Sample all channels and build transform updates
        transform_updates =
          Enum.reduce(channels, %{}, fn channel, acc ->
            value = Channel.sample(channel, current_time)
            Map.put(acc, channel.target_property, value)
          end)

        # Apply transform updates to the node
        updated_node = apply_transform_updates(node, transform_updates)

        # Update the scene with the modified node
        Scene.update_node(scene, node_id, updated_node)
    end
  end

  defp apply_transform_updates(node, updates) do
    node
    |> maybe_update_translation(Map.get(updates, :translation))
    |> maybe_update_rotation(Map.get(updates, :rotation))
    |> maybe_update_scale(Map.get(updates, :scale))
  end

  defp maybe_update_translation(node, nil), do: node

  defp maybe_update_translation(node, translation) do
    Node.set_position(node, translation)
  end

  defp maybe_update_rotation(node, nil), do: node

  defp maybe_update_rotation(node, rotation) do
    Node.set_rotation(node, rotation)
  end

  defp maybe_update_scale(node, nil), do: node

  defp maybe_update_scale(node, scale) do
    Node.set_scale(node, scale)
  end

  ## Convenience Functions

  @doc """
  Create a simple rotating cube animation for testing.
  """
  @spec create_test_animation(float()) :: Timeline.t()
  def create_test_animation(duration \\ 3.0) do
    EAGL.Animation.create_rotation_animation(duration,
      node_id: "test_cube",
      name: "test_rotation"
    )
  end

  @doc """
  Create an animator with a pre-loaded test animation.
  """
  @spec new_with_test_animation(keyword()) :: {:ok, pid()}
  def new_with_test_animation(opts \\ []) do
    duration = Keyword.get(opts, :duration, 3.0)

    with {:ok, animator} <- new(opts) do
      test_animation = create_test_animation(duration)
      :ok = load_timeline(animator, test_animation)
      {:ok, animator}
    end
  end
end
