# EAGL Animation System - Quick Reference

> **TL;DR**: Implementing a three-tier animation system with smart glTF routing for EAGL

## Current State
- ✅ **Tier 2 (EAGL.Animator)**: Functional but single-timeline only
- ❌ **Tier 1 (EAGL.Tween)**: Not implemented - simple functional tweening
- ❌ **Tier 3 (EAGL.MultiAnimator)**: Not implemented - professional multi-layer animation
- ❌ **Smart glTF Routing**: Not implemented - automatic complexity detection

## Three-Tier Vision

### 🥉 Tier 1: EAGL.Tween (Simple)
```elixir
# Target: One-liner animations for 80% of use cases
tween = EAGL.Tween.rotation(cube, 2.0, to: {0, 2*pi, 0}, loop: true)
{updated_tween, rotation} = EAGL.Tween.update(tween, delta_time)
```
- **Use Case**: UI animations, simple object movements, property tweening
- **Approach**: Pure functional (no GenServer), math-based
- **glTF**: Extract simple single-property animations

### 🥈 Tier 2: EAGL.Animator (Moderate) 
```elixir
# Target: Single timeline with multiple channels (current system enhanced)
{:ok, animator} = Animator.from_gltf_animation(gltf_anim, data_store)
Animator.play(animator, "walk_cycle")
```
- **Use Case**: Cutscenes, single character animations, object sequences
- **Approach**: Current GenServer system enhanced with better glTF integration
- **glTF**: Full single-animation support

### 🥇 Tier 3: EAGL.MultiAnimator (Complex)
```elixir
# Target: Professional character animation with layering/blending
{:ok, multi} = MultiAnimator.from_gltf_character(gltf, data_store)
MultiAnimator.play_blend(multi, "locomotion", [{"walk", 0.3}, {"run", 0.7}])
MultiAnimator.play(multi, "upper_body", "wave_gesture")
```
- **Use Case**: Game characters, complex rigs, state machines
- **Approach**: Multi-layer system with blending, masking, state machines
- **glTF**: Multiple animations simultaneously with smart organization

## Smart glTF Routing
```elixir
# Automatically chooses appropriate tier based on complexity
case EAGL.Animation.GLTF.smart_load(gltf_animation, data_store) do
  {:tween, tween} -> # Simple case - use functional tweening
  {:animator, pid} -> # Moderate case - use single animator  
  {:multi_animator, pid} -> # Complex case - use multi-layer system
end
```

## Implementation Phases

### 📋 Phase 1: Foundation (START HERE)
**Goal**: Get simple tweening working
- [ ] Implement `EAGL.Tween` core module
- [ ] Add basic easing functions  
- [ ] Create simple glTF extraction
- [ ] Write comprehensive tests
- [ ] Build example application

**Files to Create**:
```
lib/eagl/tween.ex
lib/eagl/tween/easing.ex
lib/eagl/tween/gltf.ex
test/eagl/tween_test.exs
lib/examples/tween_example.exs
```

### 📋 Phase 2: Enhancement
**Goal**: Improve existing Animator
- [ ] Add convenience functions to `EAGL.Animator`
- [ ] Implement animation events system
- [ ] Add timeline scrubbing
- [ ] Enhance glTF integration

### 📋 Phase 3: Advanced System  
**Goal**: Build professional multi-animator
- [ ] Implement `EAGL.MultiAnimator` 
- [ ] Build layer and state machine systems
- [ ] Advanced glTF character support

### 📋 Phase 4: Smart Routing
**Goal**: Unified glTF animation API
- [ ] Build complexity analyzer
- [ ] Implement smart routing
- [ ] Performance optimization

## Key Design Principles

1. **Progressive Disclosure**: Simple things should be simple, complex things should be possible
2. **Backward Compatibility**: Existing `EAGL.Animator` API must remain unchanged
3. **Performance**: Each tier optimized for its complexity level
4. **Industry Standard**: Full glTF specification support

## Integration Points

- **EAGL.Node**: All tiers manipulate node transforms
- **EAGL.Scene**: Scene graph integration required
- **EAGL.Window**: Tick-based updates (not GenServer timers)
- **EAGL.Math**: Vector/quaternion math operations

## Next Action for AI Agent

1. **Read**: `EAGL_ANIMATION_ARCHITECTURE.md` for full context
2. **Reference**: `EAGL_ANIMATION_API_REFERENCE.md` for implementation details  
3. **Start**: Phase 1 - Implement `EAGL.Tween` core module
4. **Test**: Write comprehensive unit tests
5. **Document**: Update this file with progress

## Quick Complexity Examples

### Simple (Tier 1) 
- Door opening/closing
- UI button hover effects
- Loading spinner rotation
- Simple prop animations

### Moderate (Tier 2)
- Character walk cycle
- Cutscene sequences  
- Multi-property object animation
- Scripted sequences

### Complex (Tier 3)
- Player character with locomotion + upper body + facial
- Multiple characters with synchronized animations
- Animation state machines
- Professional game character rigs

---

**Remember**: Always maintain backward compatibility with existing `EAGL.Animator` usage! 