# EAGL Animation API Reference

This document provides detailed API specifications for all modules in the three-tier animation system. Use this as a reference when implementing each module.

## Tier 1: EAGL.Tween

### Core Module: `lib/eagl/tween.ex`

```elixir
defmodule EAGL.Tween do
  @moduledoc """
  Simple functional animation system for common property tweening.
  
  Designed for 80% of animation use cases where you just need to animate
  a single property over time with easing functions.
  
  ## Examples
  
      # Simple rotation
      tween = EAGL.Tween.rotation(cube, 2.0, to: {0, 2*pi, 0}, loop: true)
      {updated_tween, rotation} = EAGL.Tween.update(tween, delta_time)
      cube = Node.set_rotation(cube, rotation)
      
      # Position animation with easing
      tween = EAGL.Tween.position(player, 3.0, to: vec3(10, 0, 0), easing: :ease_in_out)
      
      # Color fade
      fade = EAGL.Tween.color({1.0, 1.0, 1.0, 1.0}, {1.0, 1.0, 1.0, 0.0}, 1.5)
  """
  
  alias EAGL.{Node, Math}
  import EAGL.Math
  
  defstruct [
    :from_value,
    :to_value,
    :duration,
    :current_time,
    :easing_func,
    :loop,
    :ping_pong,
    :completed,
    :metadata
  ]
  
  @type t :: %__MODULE__{
    from_value: any(),
    to_value: any(),
    duration: float(),
    current_time: float(),
    easing_func: atom() | function(),
    loop: boolean(),
    ping_pong: boolean(),
    completed: boolean(),
    metadata: map()
  }
  
  @type easing_function :: :linear | :ease_in | :ease_out | :ease_in_out | 
                          :bounce | :elastic | :back | function()
  
  # Core creation functions
  @spec new(any(), any(), float(), keyword()) :: t()
  def new(from, to, duration, opts \\ [])
  
  @spec rotation(Node.t(), float(), keyword()) :: t()
  def rotation(node, duration, opts \\ [])
  
  @spec position(Node.t(), float(), keyword()) :: t()
  def position(node, duration, opts \\ [])
  
  @spec scale(Node.t(), float(), keyword()) :: t()
  def scale(node, duration, opts \\ [])
  
  @spec color(tuple(), tuple(), float(), keyword()) :: t()
  def color(from_color, to_color, duration, opts \\ [])
  
  # Update and query functions
  @spec update(t(), float()) :: {t(), any()}
  def update(tween, delta_time)
  
  @spec current_value(t()) :: any()
  def current_value(tween)
  
  @spec progress(t()) :: float()
  def progress(tween)
  
  @spec completed?(t()) :: boolean()
  def completed?(tween)
  
  @spec reset(t()) :: t()
  def reset(tween)
  
  # Easing configuration
  @spec with_easing(t(), easing_function()) :: t()
  def with_easing(tween, easing_func)
  
  # Utility functions
  @spec reverse(t()) :: t()
  def reverse(tween)
  
  @spec set_loop(t(), boolean()) :: t()
  def set_loop(tween, loop)
  
  @spec set_ping_pong(t(), boolean()) :: t()
  def set_ping_pong(tween, ping_pong)
end
```

### Easing Module: `lib/eagl/tween/easing.ex`

```elixir
defmodule EAGL.Tween.Easing do
  @moduledoc """
  Easing functions for smooth animation transitions.
  
  All functions take a progress value (0.0 to 1.0) and return
  an eased progress value.
  """
  
  @spec linear(float()) :: float()
  def linear(t)
  
  @spec ease_in(float()) :: float()
  def ease_in(t)
  
  @spec ease_out(float()) :: float()
  def ease_out(t)
  
  @spec ease_in_out(float()) :: float()
  def ease_in_out(t)
  
  @spec bounce(float()) :: float()
  def bounce(t)
  
  @spec elastic(float()) :: float()
  def elastic(t)
  
  @spec back(float()) :: float()
  def back(t)
  
  @spec apply_easing(atom() | function(), float()) :: float()
  def apply_easing(easing_func, progress)
end
```

### glTF Integration: `lib/eagl/tween/gltf.ex`

```elixir
defmodule EAGL.Tween.GLTF do
  @moduledoc """
  glTF integration for simple tweening animations.
  
  Extracts simple animations from glTF files and converts them
  to EAGL.Tween structs.
  """
  
  alias EAGL.Tween
  
  @spec from_simple_animation(GLTF.Animation.t(), String.t(), atom()) :: 
    {:ok, Tween.t()} | {:error, String.t()}
  def from_simple_animation(gltf_animation, node_name, property)
  
  @spec extract_simple_rotation(GLTF.Animation.t(), String.t()) :: 
    {:ok, Tween.t()} | {:error, String.t()}
  def extract_simple_rotation(gltf_animation, node_name)
  
  @spec extract_simple_translation(GLTF.Animation.t(), String.t()) :: 
    {:ok, Tween.t()} | {:error, String.t()}
  def extract_simple_translation(gltf_animation, node_name)
  
  @spec extract_simple_scale(GLTF.Animation.t(), String.t()) :: 
    {:ok, Tween.t()} | {:error, String.t()}
  def extract_simple_scale(gltf_animation, node_name)
  
  @spec is_simple_animation?(GLTF.Animation.t()) :: boolean()
  def is_simple_animation?(gltf_animation)
end
```

## Tier 2: Enhanced EAGL.Animator

### Enhanced Animator: `lib/eagl/animator.ex` (additions)

```elixir
defmodule EAGL.Animator do
  # ... existing code remains unchanged ...
  
  # New convenience functions to add:
  
  @spec from_gltf_animation(GLTF.Animation.t(), GLTF.DataStore.t(), keyword()) :: 
    {:ok, pid()} | {:error, term()}
  def from_gltf_animation(gltf_animation, data_store, opts \\ [])
  
  @spec with_events(pid(), map()) :: :ok
  def with_events(animator, event_callbacks)
  
  @spec set_time(pid(), float()) :: :ok
  def set_time(animator, time)
  
  @spec get_current_time(pid()) :: float()
  def get_current_time(animator)
  
  @spec get_duration(pid()) :: float()
  def get_duration(animator)
  
  @spec register_event_callback(pid(), String.t(), function()) :: :ok
  def register_event_callback(animator, event_name, callback)
  
  @spec trigger_event(pid(), String.t(), any()) :: :ok
  def trigger_event(animator, event_name, event_data)
end
```

## Tier 3: EAGL.MultiAnimator

### Core Multi-Animator: `lib/eagl/multi_animator.ex`

```elixir
defmodule EAGL.MultiAnimator do
  @moduledoc """
  Professional multi-timeline animation system with layering and blending.
  
  Designed for complex character animation where multiple animations
  need to run simultaneously with blending, masking, and state management.
  """
  
  use GenServer
  alias EAGL.{Scene, Node}
  alias EAGL.Animation.Timeline
  alias EAGL.MultiAnimator.{Layer, StateMachine}
  
  defstruct [
    :layers,
    :state_machines,
    :global_speed,
    :metadata
  ]
  
  @type t :: %__MODULE__{
    layers: %{String.t() => Layer.t()},
    state_machines: %{String.t() => StateMachine.t()},
    global_speed: float(),
    metadata: map()
  }
  
  # Core management
  @spec new(keyword()) :: {:ok, pid()} | {:error, term()}
  def new(opts \\ [])
  
  @spec add_layer(pid(), String.t(), keyword()) :: :ok | {:error, term()}
  def add_layer(multi_animator, layer_name, opts \\ [])
  
  @spec remove_layer(pid(), String.t()) :: :ok
  def remove_layer(multi_animator, layer_name)
  
  @spec list_layers(pid()) :: [String.t()]
  def list_layers(multi_animator)
  
  # Layer configuration
  @spec set_layer_weight(pid(), String.t(), float()) :: :ok
  def set_layer_weight(multi_animator, layer_name, weight)
  
  @spec set_layer_mask(pid(), String.t(), [String.t()]) :: :ok
  def set_layer_mask(multi_animator, layer_name, node_mask)
  
  @spec set_layer_blend_mode(pid(), String.t(), atom()) :: :ok
  def set_layer_blend_mode(multi_animator, layer_name, blend_mode)
  
  # Animation loading
  @spec load_animation(pid(), String.t(), Timeline.t()) :: :ok | {:error, term()}
  def load_animation(multi_animator, layer_name, timeline)
  
  @spec load_animation_set(pid(), String.t(), [Timeline.t()]) :: :ok | {:error, term()}
  def load_animation_set(multi_animator, layer_name, timelines)
  
  @spec from_gltf_character(pid(), GLTF.t(), GLTF.DataStore.t(), keyword()) :: 
    :ok | {:error, term()}
  def from_gltf_character(multi_animator, gltf, data_store, opts \\ [])
  
  # Playback control
  @spec play(pid(), String.t(), String.t()) :: :ok | {:error, term()}
  def play(multi_animator, layer_name, animation_name)
  
  @spec play_blend(pid(), String.t(), [{String.t(), float()}]) :: :ok | {:error, term()}
  def play_blend(multi_animator, layer_name, animation_blends)
  
  @spec crossfade(pid(), String.t(), String.t(), String.t(), float()) :: :ok
  def crossfade(multi_animator, layer_name, from_anim, to_anim, duration)
  
  @spec stop(pid(), String.t()) :: :ok
  def stop(multi_animator, layer_name)
  
  @spec pause(pid(), String.t()) :: :ok
  def pause(multi_animator, layer_name)
  
  # State machine
  @spec add_state(pid(), String.t(), String.t(), String.t()) :: :ok
  def add_state(multi_animator, layer_name, state_name, animation_name)
  
  @spec transition_to_state(pid(), String.t(), String.t(), float()) :: :ok
  def transition_to_state(multi_animator, layer_name, state_name, transition_time)
  
  @spec set_state_condition(pid(), String.t(), String.t(), function()) :: :ok
  def set_state_condition(multi_animator, layer_name, state_name, condition_func)
  
  # Update and application
  @spec update(pid(), float()) :: :ok
  def update(multi_animator, delta_time)
  
  @spec apply_to_scene(pid(), Scene.t()) :: Scene.t()
  def apply_to_scene(multi_animator, scene)
  
  # Global controls
  @spec set_global_speed(pid(), float()) :: :ok
  def set_global_speed(multi_animator, speed)
  
  @spec get_state(pid()) :: t()
  def get_state(multi_animator)
end
```

### Animation Layer: `lib/eagl/multi_animator/layer.ex`

```elixir
defmodule EAGL.MultiAnimator.Layer do
  @moduledoc """
  Represents a single animation layer in a multi-animator system.
  
  Each layer can contain multiple animations that can be blended together,
  and has properties like weight, masking, and blend mode.
  """
  
  defstruct [
    :name,
    :weight,
    :mask,
    :blend_mode,
    :timelines,
    :current_blend,
    :crossfade_state,
    :metadata
  ]
  
  @type blend_mode :: :override | :additive | :multiply
  @type crossfade_state :: nil | %{
    from: String.t(),
    to: String.t(),
    duration: float(),
    current_time: float()
  }
  
  @type t :: %__MODULE__{
    name: String.t(),
    weight: float(),
    mask: [String.t()] | nil,
    blend_mode: blend_mode(),
    timelines: %{String.t() => EAGL.Animation.Timeline.t()},
    current_blend: [{String.t(), float()}],
    crossfade_state: crossfade_state(),
    metadata: map()
  }
  
  @spec new(String.t(), keyword()) :: t()
  def new(name, opts \\ [])
  
  @spec add_timeline(t(), EAGL.Animation.Timeline.t()) :: t()
  def add_timeline(layer, timeline)
  
  @spec set_blend(t(), [{String.t(), float()}]) :: t()
  def set_blend(layer, animation_weights)
  
  @spec start_crossfade(t(), String.t(), String.t(), float()) :: t()
  def start_crossfade(layer, from_animation, to_animation, duration)
  
  @spec update(t(), float()) :: t()
  def update(layer, delta_time)
  
  @spec apply_to_scene(t(), Scene.t()) :: Scene.t()
  def apply_to_scene(layer, scene)
  
  @spec node_masked?(t(), String.t()) :: boolean()
  def node_masked?(layer, node_id)
end
```

### State Machine: `lib/eagl/multi_animator/state_machine.ex`

```elixir
defmodule EAGL.MultiAnimator.StateMachine do
  @moduledoc """
  Animation state machine for managing complex animation transitions.
  """
  
  defstruct [
    :states,
    :transitions,
    :current_state,
    :conditions,
    :metadata
  ]
  
  @type state :: %{
    name: String.t(),
    animation: String.t(),
    loop: boolean(),
    metadata: map()
  }
  
  @type transition :: %{
    from: String.t(),
    to: String.t(),
    duration: float(),
    condition: function() | nil
  }
  
  @type t :: %__MODULE__{
    states: %{String.t() => state()},
    transitions: [transition()],
    current_state: String.t() | nil,
    conditions: %{String.t() => function()},
    metadata: map()
  }
  
  @spec new() :: t()
  def new()
  
  @spec add_state(t(), String.t(), String.t(), keyword()) :: t()
  def add_state(state_machine, state_name, animation_name, opts \\ [])
  
  @spec add_transition(t(), String.t(), String.t(), float(), function() | nil) :: t()
  def add_transition(state_machine, from_state, to_state, duration, condition \\ nil)
  
  @spec set_condition(t(), String.t(), function()) :: t()
  def set_condition(state_machine, condition_name, condition_func)
  
  @spec transition_to(t(), String.t()) :: t()
  def transition_to(state_machine, target_state)
  
  @spec update(t(), any()) :: t()
  def update(state_machine, context)
  
  @spec current_animation(t()) :: String.t() | nil
  def current_animation(state_machine)
end
```

## Smart glTF Routing

### Main Router: `lib/eagl/animation/gltf.ex`

```elixir
defmodule EAGL.Animation.GLTF do
  @moduledoc """
  Smart routing system for glTF animations.
  
  Automatically analyzes glTF animations and routes them to the
  appropriate tier based on complexity and use case.
  """
  
  alias EAGL.{Tween, Animator, MultiAnimator}
  
  @type complexity_level :: :simple | :moderate | :complex
  @type routing_result :: 
    {:tween, Tween.t()} |
    {:animator, pid()} |
    {:multi_animator, pid()} |
    {:error, String.t()}
  
  # Main entry points
  @spec smart_load(GLTF.Animation.t(), GLTF.DataStore.t(), keyword()) :: 
    routing_result()
  def smart_load(gltf_animation, data_store, opts \\ [])
  
  @spec smart_load_all(GLTF.t(), GLTF.DataStore.t(), keyword()) :: 
    [routing_result()]
  def smart_load_all(gltf, data_store, opts \\ [])
  
  # Complexity analysis
  @spec analyze_complexity(GLTF.Animation.t()) :: complexity_level()
  def analyze_complexity(gltf_animation)
  
  @spec suggest_tier(GLTF.Animation.t()) :: 
    {:tier_1, :tween} | {:tier_2, :animator} | {:tier_3, :multi_animator}
  def suggest_tier(gltf_animation)
  
  # Direct tier routing
  @spec to_tween(GLTF.Animation.t(), String.t(), atom()) :: 
    {:ok, Tween.t()} | {:error, String.t()}
  def to_tween(gltf_animation, node_name, property)
  
  @spec to_animator(GLTF.Animation.t(), GLTF.DataStore.t(), keyword()) :: 
    {:ok, pid()} | {:error, String.t()}
  def to_animator(gltf_animation, data_store, opts \\ [])
  
  @spec to_multi_animator([GLTF.Animation.t()], GLTF.DataStore.t(), keyword()) :: 
    {:ok, pid()} | {:error, String.t()}
  def to_multi_animator(gltf_animations, data_store, opts \\ [])
  
  # Utility functions
  @spec extract_simple_properties(GLTF.Animation.t()) :: 
    [{String.t(), atom(), any(), any()}]
  def extract_simple_properties(gltf_animation)
  
  @spec find_animation_by_name(GLTF.t(), String.t()) :: 
    {:ok, GLTF.Animation.t()} | {:error, String.t()}
  def find_animation_by_name(gltf, animation_name)
  
  @spec group_animations_by_type([GLTF.Animation.t()]) :: 
    %{atom() => [GLTF.Animation.t()]}
  def group_animations_by_type(gltf_animations)
end
```

### Complexity Analyzer: `lib/eagl/animation/complexity_analyzer.ex`

```elixir
defmodule EAGL.Animation.ComplexityAnalyzer do
  @moduledoc """
  Analyzes glTF animations to determine appropriate routing tier.
  """
  
  @type analysis_result :: %{
    complexity: :simple | :moderate | :complex,
    reasons: [String.t()],
    recommendations: [String.t()],
    node_count: integer(),
    channel_count: integer(),
    property_types: [atom()],
    has_complex_interpolation: boolean()
  }
  
  @spec analyze(GLTF.Animation.t()) :: analysis_result()
  def analyze(gltf_animation)
  
  @spec single_node_single_property?(GLTF.Animation.t()) :: boolean()
  def single_node_single_property?(gltf_animation)
  
  @spec single_node_multiple_properties?(GLTF.Animation.t()) :: boolean()
  def single_node_multiple_properties?(gltf_animation)
  
  @spec multiple_nodes_simple_timeline?(GLTF.Animation.t()) :: boolean()
  def multiple_nodes_simple_timeline?(gltf_animation)
  
  @spec requires_blending_or_layering?(GLTF.Animation.t()) :: boolean()
  def requires_blending_or_layering?(gltf_animation)
  
  @spec has_state_machine_requirements?(GLTF.Animation.t()) :: boolean()
  def has_state_machine_requirements?(gltf_animation)
  
  @spec complexity_score(GLTF.Animation.t()) :: float()
  def complexity_score(gltf_animation)
end
```

## Test Module Templates

### Tween Tests: `test/eagl/tween_test.exs`

```elixir
defmodule EAGL.TweenTest do
  use ExUnit.Case, async: true
  
  alias EAGL.{Tween, Node}
  import EAGL.Math
  
  describe "basic tweening" do
    test "creates simple numeric tween"
    test "updates tween with delta time"
    test "completes at duration"
    test "handles loop mode"
    test "handles ping-pong mode"
  end
  
  describe "node property tweening" do
    test "animates node rotation"
    test "animates node position" 
    test "animates node scale"
  end
  
  describe "easing functions" do
    test "applies linear easing"
    test "applies ease-in-out easing"
    test "applies bounce easing"
    test "applies custom easing function"
  end
  
  describe "glTF integration" do
    test "extracts simple rotation from glTF"
    test "extracts simple translation from glTF"
    test "rejects complex animations"
  end
end
```

## Implementation Checklist

### Phase 1 - Tier 1 Implementation
- [ ] `EAGL.Tween` core module
- [ ] `EAGL.Tween.Easing` functions
- [ ] `EAGL.Tween.GLTF` basic integration
- [ ] Comprehensive tests
- [ ] Example application
- [ ] Documentation

### Phase 2 - Tier 2 Enhancement  
- [ ] Enhanced `EAGL.Animator` functions
- [ ] Animation events system
- [ ] Timeline scrubbing
- [ ] Improved glTF integration
- [ ] Backward compatibility tests

### Phase 3 - Tier 3 Implementation
- [ ] `EAGL.MultiAnimator` core
- [ ] `EAGL.MultiAnimator.Layer` system
- [ ] `EAGL.MultiAnimator.StateMachine`
- [ ] Advanced glTF integration
- [ ] Complex character examples

### Phase 4 - Smart Routing
- [ ] `EAGL.Animation.GLTF` router
- [ ] `EAGL.Animation.ComplexityAnalyzer`
- [ ] Integration tests
- [ ] Performance benchmarks
- [ ] Migration documentation

---

*Use this API reference alongside EAGL_ANIMATION_ARCHITECTURE.md for complete implementation guidance.* 