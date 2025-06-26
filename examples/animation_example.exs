#!/usr/bin/env elixir

# EAGL Animation System Example
# ============================
#
# This example demonstrates EAGL's new animation system with:
# - Keyframe-based animations
# - Multiple interpolation modes
# - Scene graph integration
# - Animation playback control
#
# Run with: elixir examples/animation_example.exs

# Add the current project to the code path
Code.append_path("_build/dev/lib/eagl/ebin")

defmodule AnimationExample do
  @moduledoc """
  Demonstrates EAGL's animation system with rotating and translating cubes.

  Features shown:
  - Multiple animation timelines
  - Rotation and translation animations
  - Looping animations
  - Scene graph hierarchy
  - Real-time animation playback
  """

  use EAGL.Window
  use EAGL.Const
  import EAGL.{Math, Shader, Buffer, Error}
  alias EAGL.{Scene, Node, Animation, Animator}

  @cube_vertices ~v'''
  # Front face
  -1.0 -1.0  1.0
   1.0 -1.0  1.0
   1.0  1.0  1.0
  -1.0  1.0  1.0
  # Back face
  -1.0 -1.0 -1.0
  -1.0  1.0 -1.0
   1.0  1.0 -1.0
   1.0 -1.0 -1.0
  '''

  @cube_indices ~i'''
  # Front face
  0 1 2  2 3 0
  # Back face
  4 5 6  6 7 4
  # Left face
  0 3 5  5 4 0
  # Right face
  1 7 6  6 2 1
  # Top face
  3 2 6  6 5 3
  # Bottom face
  0 4 7  7 1 0
  '''

  @spec run_example(keyword()) :: :ok | {:error, term()}
  def run_example(opts \\ []) do
    default_opts = [enter_to_exit: true]
    merged_opts = Keyword.merge(default_opts, opts)

    EAGL.Window.run(
      __MODULE__,
      "EAGL Animation System Demo",
      merged_opts
    )
  end

  @impl true
  def setup do
    IO.puts("""

    === EAGL Animation System Demo ===
    This example demonstrates EAGL's new animation system:

    Animation Features:
    - Keyframe-based animations with multiple interpolation modes
    - Animation timelines and channels
    - Scene graph integration
    - Real-time playback control

    Scene Setup:
    - Rotating red cube (3-second loop)
    - Oscillating blue cube (2-second back-and-forth)
    - Static green cube (no animation)
    - All cubes in a hierarchical scene graph

    Animation System Components:
    - EAGL.Animation: Core animation data structures
    - EAGL.Animator: Runtime animation controller
    - Scene integration: Animations applied to scene nodes

    Controls:
    - Press ENTER to exit
    - Watch the animations loop automatically

    Educational Value:
    - Industry-standard animation concepts
    - Keyframe interpolation (linear, step, cubic spline)
    - Transform hierarchies
    - Delta-time based updates
    ===============================
    """)

    # Set up OpenGL state
    :gl.enable(@gl_depth_test)
    :gl.depthFunc(@gl_less)

    # Create shader program
    {:ok, vertex_shader} = create_shader(@gl_vertex_shader, "vertex_shader_3d_red.glsl")
    {:ok, fragment_shader} = create_shader(@gl_fragment_shader, "fragment_shader_3d_default.glsl")
    {:ok, program} = create_attach_link([vertex_shader, fragment_shader])

    # Create cube mesh data
    {vao, vbo, ebo} = create_indexed_array(@cube_vertices, @cube_indices, [
      position_attribute(),
      color_attribute()
    ])

    cube_mesh = %{
      vao: vao,
      vbo: vbo,
      ebo: ebo,
      index_count: length(@cube_indices),
      program: program
    }

    # Create scene with animated nodes
    scene = Scene.new(name: "Animation Demo Scene")

    # Create nodes with unique IDs for animation targeting
    red_cube = Node.new(
      name: "rotating_cube",
      position: vec3(-3.0, 0.0, 0.0),
      mesh: cube_mesh
    )

    blue_cube = Node.new(
      name: "translating_cube",
      position: vec3(0.0, 0.0, 0.0),
      mesh: cube_mesh
    )

    green_cube = Node.new(
      name: "static_cube",
      position: vec3(3.0, 0.0, 0.0),
      mesh: cube_mesh
    )

    scene = scene
    |> Scene.add_root_node(red_cube)
    |> Scene.add_root_node(blue_cube)
    |> Scene.add_root_node(green_cube)

    # Create animations
    rotation_animation = Animation.create_rotation_animation(3.0,
      node_id: "rotating_cube",
      name: "rotate_red_cube"
    )

    translation_animation = Animation.create_translation_animation(
      vec3(0.0, 0.0, 0.0),  # start position
      vec3(0.0, 2.0, 0.0),  # end position
      2.0,  # duration
      node_id: "translating_cube",
      name: "oscillate_blue_cube"
    )

    # Create animator and load animations
    {:ok, animator} = Animator.new(loop: true)
    :ok = Animator.load_timeline(animator, rotation_animation)
    :ok = Animator.load_timeline(animator, translation_animation)

    # Start both animations
    :ok = Animator.play(animator, "rotate_red_cube")

    # Create a separate animator for the translating cube
    {:ok, translator} = Animator.new(loop: true)
    :ok = Animator.load_timeline(translator, translation_animation)
    :ok = Animator.play(translator, "oscillate_blue_cube")

    current_time = :erlang.system_time(:millisecond) / 1000.0

    {:ok,
     %{
       scene: scene,
       animator: animator,
       translator: translator,
       program: program,
       cube_mesh: cube_mesh,
       current_time: current_time,
       last_frame_time: current_time
     }}
  end

  @impl true
  def render(viewport_width, viewport_height, state) do
    # Update timing
    current_time = :erlang.system_time(:millisecond) / 1000.0
    delta_time = current_time - state.last_frame_time

    # Update animations
    :ok = Animator.update(state.animator, delta_time)
    :ok = Animator.update(state.translator, delta_time)

    # Apply animations to scene
    animated_scene = Animator.apply_to_scene(state.animator, state.scene)
    animated_scene = Animator.apply_to_scene(state.translator, animated_scene)

    # Set up rendering
    :gl.viewport(0, 0, trunc(viewport_width), trunc(viewport_height))
    :gl.clearColor(0.1, 0.1, 0.2, 1.0)
    :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)

    # Set up camera
    aspect_ratio = viewport_width / viewport_height
    projection = mat4_perspective(radians(45.0), aspect_ratio, 0.1, 100.0)

    # Camera positioned to view all cubes
    view = mat4_look_at(
      vec3(0.0, 3.0, 8.0),   # camera position
      vec3(0.0, 0.0, 0.0),   # look at center
      vec3(0.0, 1.0, 0.0)    # up vector
    )

    # Use shader program
    :gl.useProgram(state.program)

    # Set view and projection matrices
    set_uniforms(state.program, [
      view: view,
      projection: projection
    ])

    # Render the animated scene
    Scene.render(animated_scene, view, projection)

    check("After animation render")

    new_state = %{state |
      current_time: current_time,
      last_frame_time: current_time,
      scene: animated_scene
    }

    {new_state, :ok}
  end

  @impl true
  def cleanup(state) do
    # Clean up mesh
    :gl.deleteVertexArrays([state.cube_mesh.vao])
    :gl.deleteBuffers([state.cube_mesh.vbo, state.cube_mesh.ebo])
    :gl.deleteProgram(state.program)

    # Clean up animators (GenServers will be terminated automatically)
    :ok
  end

  @impl true
  def handle_key(_key, _action, _mods, state) do
    # For now, just pass through
    state
  end
end

# Run the example if called directly
case System.argv() do
  ["--test"] ->
    AnimationExample.run_example(timeout: 500)
  _ ->
    AnimationExample.run_example()
end
