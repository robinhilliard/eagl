# EAGL Animation Architecture: Three-Tier System

## Overview

This document defines the architecture for EAGL's three-tier animation system, designed to provide progressive complexity from simple tweening to professional character animation with smart glTF integration.

## Architecture Philosophy

### Design Principles
1. **Progressive Disclosure**: Simple cases should be simple, complex cases should be powerful
2. **Industry Compatibility**: Full glTF specification support across all tiers
3. **Performance Optimization**: Each tier optimized for its use cases
4. **Backward Compatibility**: Existing EAGL.Animator remains functional
5. **Smart Routing**: Automatic complexity detection and appropriate tier selection

### Complexity Spectrum
```
Simple           Moderate              Complex
|                |                     |
Tier 1           Tier 2               Tier 3
EAGL.Tween   →   EAGL.Animator   →   EAGL.MultiAnimator
```

## Tier Specifications

### Tier 1: EAGL.Tween (Simple Animations)
**Target:** 80% of animation needs - simple property animations

#### Characteristics
- Pure functional approach (no GenServer overhead)
- Single property animations (position, rotation, scale, color, etc.)
- Mathematical easing functions
- Minimal ceremony - one line to create, one line to update
- No scene graph management - just math

#### Core API
```elixir
# Module: EAGL.Tween
defmodule EAGL.Tween do
  @moduledoc """
  Simple functional animation system for common property tweening.
  
  Designed for 80% of animation use cases where you just need to animate
  a single property over time with easing functions.
  """
  
  # Core tween creation
  def new(from, to, duration, opts \\ [])
  def rotation(node, duration, opts \\ [])
  def position(node, duration, opts \\ [])
  def scale(node, duration, opts \\ [])
  def color(from_color, to_color, duration, opts \\ [])
  
  # Update and query
  def update(tween, delta_time)
  def current_value(tween)
  def progress(tween)
  def completed?(tween)
  
  # Easing functions
  def with_easing(tween, easing_func)
  def linear(progress)
  def ease_in_out(progress)
  def bounce(progress)
  def elastic(progress)
end
```

#### Usage Examples
```elixir
# Dead simple rotation
tween = EAGL.Tween.rotation(cube, 2.0, to: {0, 2*pi, 0}, loop: true)
{updated_tween, rotation} = EAGL.Tween.update(tween, delta_time)
cube = Node.set_rotation(cube, rotation)

# UI element fade
fade_tween = EAGL.Tween.new(1.0, 0.0, 1.5, easing: :ease_out)
{updated_tween, alpha} = EAGL.Tween.update(fade_tween, delta_time)
```

#### glTF Integration
```elixir
# Module: EAGL.Tween.GLTF
def from_simple_animation(gltf_animation, node_name, property)
def extract_simple_rotation(gltf_animation, node_name)
def extract_simple_translation(gltf_animation, node_name)
```

### Tier 2: EAGL.Animator (Timeline Animations)
**Target:** Single timeline with multiple channels - current system refined

#### Characteristics
- GenServer-based for state management
- Multiple properties per timeline (rotation + translation + scale)
- Keyframe-based with interpolation
- Scene graph integration
- Professional timeline features (loop, speed, events)

#### Core API (Existing - Refined)
```elixir
# Module: EAGL.Animator (enhanced existing)
defmodule EAGL.Animator do
  # Existing API remains unchanged for backward compatibility
  def new(opts \\ [])
  def load_timeline(animator, timeline)
  def play(animator, timeline_name)
  def update(animator, delta_time)
  def apply_to_scene(animator, scene)
  
  # New convenience functions
  def from_gltf_animation(gltf_animation, data_store, opts \\ [])
  def with_events(animator, event_callbacks)
  def set_time(animator, time)  # For scrubbing
end
```

#### Enhanced Features
- Animation events/callbacks
- Timeline scrubbing
- Better glTF integration
- Performance optimizations

### Tier 3: EAGL.MultiAnimator (Layered Animation)
**Target:** Complex character animation with blending and state machines

#### Characteristics
- Multiple animation layers with masks
- Animation blending and crossfading
- State machine integration
- Professional character animation features
- Advanced glTF support (multiple animations simultaneously)

#### Core API
```elixir
# Module: EAGL.MultiAnimator
defmodule EAGL.MultiAnimator do
  @moduledoc """
  Professional multi-timeline animation system with layering and blending.
  
  Designed for complex character animation where multiple animations
  need to run simultaneously with blending, masking, and state management.
  """
  
  # Core management
  def new(opts \\ [])
  def add_layer(multi_animator, layer_name, opts \\ [])
  def remove_layer(multi_animator, layer_name)
  
  # Layer configuration
  def set_layer_weight(multi_animator, layer_name, weight)
  def set_layer_mask(multi_animator, layer_name, node_mask)
  def set_layer_blend_mode(multi_animator, layer_name, blend_mode)
  
  # Animation loading
  def load_animation(multi_animator, layer_name, timeline)
  def load_animation_set(multi_animator, layer_name, timelines)
  def from_gltf_character(multi_animator, gltf, data_store, opts \\ [])
  
  # Playback control
  def play(multi_animator, layer_name, animation_name)
  def play_blend(multi_animator, layer_name, animation_blends)
  def crossfade(multi_animator, layer_name, from_anim, to_anim, duration)
  
  # State machine
  def add_state(multi_animator, layer_name, state_name, animation)
  def transition_to_state(multi_animator, layer_name, state_name, transition_time)
  def set_state_condition(multi_animator, layer_name, condition_func)
  
  # Update and application
  def update(multi_animator, delta_time)
  def apply_to_scene(multi_animator, scene)
end
```

#### Advanced Features
- Bone masking (upper body vs lower body)
- Additive animation layers
- IK target integration
- Animation state machines
- Complex blending modes

## Smart glTF Routing

### Module: EAGL.Animation.GLTF
```elixir
defmodule EAGL.Animation.GLTF do
  @moduledoc """
  Smart routing system for glTF animations.
  
  Automatically analyzes glTF animations and routes them to the
  appropriate tier based on complexity and use case.
  """
  
  # Main entry point
  def smart_load(gltf_animation, opts \\ [])
  def smart_load_all(gltf, data_store, opts \\ [])
  
  # Complexity analysis
  def analyze_complexity(gltf_animation)
  def suggest_tier(gltf_animation)
  
  # Direct tier routing
  def to_tween(gltf_animation, node_name, property)
  def to_animator(gltf_animation, data_store, opts \\ [])
  def to_multi_animator(gltf_animations, data_store, opts \\ [])
  
  # Utility functions
  def extract_simple_properties(gltf_animation)
  def find_animation_by_name(gltf, animation_name)
  def group_animations_by_type(gltf_animations)
end
```

### Complexity Detection Rules
```elixir
defp analyze_complexity(animation) do
  cond do
    single_node_single_property?(animation) -> :simple
    single_node_multiple_properties?(animation) -> :simple_to_moderate
    multiple_nodes_simple_timeline?(animation) -> :moderate
    requires_blending_or_layering?(animation) -> :complex
    has_state_machine_requirements?(animation) -> :complex
  end
end
```

## Implementation Phases

### Phase 1: Foundation (Tier 1 - EAGL.Tween)
**Goal:** Implement simple tweening system with basic glTF support

#### Deliverables
- [ ] `EAGL.Tween` module with core API
- [ ] Basic easing functions
- [ ] Simple glTF integration (`EAGL.Tween.GLTF`)
- [ ] Unit tests and examples
- [ ] Documentation

#### Files to Create/Modify
```
lib/eagl/tween.ex (NEW)
lib/eagl/tween/easing.ex (NEW)
lib/eagl/tween/gltf.ex (NEW)
test/eagl/tween_test.exs (NEW)
lib/examples/tween_example.exs (NEW)
```

### Phase 2: Enhancement (Tier 2 - Refined EAGL.Animator)
**Goal:** Enhance existing animator with better glTF integration

#### Deliverables
- [ ] Enhanced `EAGL.Animator` with new convenience functions
- [ ] Improved glTF integration
- [ ] Animation events system
- [ ] Timeline scrubbing
- [ ] Backward compatibility maintenance

#### Files to Modify
```
lib/eagl/animator.ex (ENHANCE)
lib/gltf/eagl.ex (ENHANCE)
test/eagl/animator_test.exs (ENHANCE)
lib/examples/gltf/animation_example.exs (ENHANCE)
```

### Phase 3: Advanced System (Tier 3 - EAGL.MultiAnimator)
**Goal:** Implement professional multi-timeline animation system

#### Deliverables
- [ ] `EAGL.MultiAnimator` module with full API
- [ ] Animation layer system
- [ ] Blending and state machines
- [ ] Advanced glTF character support
- [ ] Professional examples

#### Files to Create
```
lib/eagl/multi_animator.ex (NEW)
lib/eagl/multi_animator/layer.ex (NEW)
lib/eagl/multi_animator/state_machine.ex (NEW)
lib/eagl/multi_animator/gltf.ex (NEW)
test/eagl/multi_animator_test.exs (NEW)
lib/examples/character_animation_example.exs (NEW)
```

### Phase 4: Smart Routing (Integration)
**Goal:** Implement smart glTF routing system

#### Deliverables
- [ ] `EAGL.Animation.GLTF` smart routing module
- [ ] Complexity analysis system
- [ ] Unified glTF animation API
- [ ] Migration guides
- [ ] Performance benchmarks

#### Files to Create/Modify
```
lib/eagl/animation/gltf.ex (NEW)
lib/eagl/animation/complexity_analyzer.ex (NEW)
lib/examples/smart_routing_example.exs (NEW)
```

## Integration Points

### Existing EAGL Systems
- **EAGL.Node**: All tiers must work with node transforms
- **EAGL.Scene**: Scene graph integration for all tiers
- **EAGL.Window**: Tick-based updates for all tiers
- **EAGL.Math**: Vector/quaternion operations for all tiers

### Backward Compatibility
- Existing `EAGL.Animator` API remains unchanged
- Current examples continue to work
- Migration path provided for enhanced features

## Testing Strategy

### Unit Tests
- Each tier has comprehensive unit tests
- glTF integration tests with sample files
- Performance benchmarks for each tier
- Complexity analysis tests

### Integration Tests
- Full pipeline tests (glTF → smart routing → animation)
- Cross-tier compatibility tests
- Scene graph integration tests

### Example Applications
- Simple tweening demo
- Character animation demo
- Mixed-complexity animation demo
- Performance comparison demo

## Performance Considerations

### Tier 1 (EAGL.Tween)
- Pure functional, no GenServer overhead
- Single property updates only
- Memory efficient for simple cases

### Tier 2 (EAGL.Animator)
- Current GenServer performance
- Optimized for single timeline
- Minimal memory overhead

### Tier 3 (EAGL.MultiAnimator)
- More complex but optimized for multiple timelines
- Layer-based processing
- Memory pooling for large character rigs

## Future Extensions

### Potential Phase 5+ Features
- **Physics Integration**: Animation-driven physics
- **Procedural Animation**: Noise-based animation
- **Motion Capture**: BVH file support
- **Timeline Editor**: Visual animation editing
- **Animation Compression**: Keyframe optimization

## AI Agent Instructions

### Working on This Project
1. **Always reference this document first** - Check current phase and deliverables
2. **Maintain API consistency** - Follow the specified module structures
3. **Test thoroughly** - Each tier must have comprehensive tests
4. **Document changes** - Update this document when making architectural changes
5. **Preserve backward compatibility** - Existing EAGL.Animator API must remain unchanged

### Phase-Specific Guidelines
- **Phase 1**: Focus on simplicity and ease of use
- **Phase 2**: Enhance without breaking existing functionality
- **Phase 3**: Design for professional use cases
- **Phase 4**: Optimize for automatic complexity detection

### Code Style
- Follow existing EAGL patterns and conventions
- Use comprehensive docstrings with examples
- Include @spec for all public functions
- Maintain consistency with EAGL.Math vector operations

---

*This document serves as the definitive guide for EAGL's animation system development. Update it as the project evolves.* 