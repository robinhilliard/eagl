defmodule EAGL.Examples.GLTF.BoxAnimated do
  @moduledoc """
  GLTF Example 4: Load and display the BoxAnimated model using EAGL GLTF bridge.

  Tests GLTF animation channel/sampler extraction, EAGL.Animator timeline
  loading and playback, and animated transforms through the scene hierarchy.
  Uses the on_tick/2 callback from OrbitCamera to update animations.
  """

  # --- COMMON: Same as other examples ---
  use EAGL.Window
  use EAGL.Const
  use EAGL.OrbitCamera

  import Bitwise
  import EAGL.Shader
  alias EAGL.{Scene, Animator}

  @glb_path "test/fixtures/samples/BoxAnimated.glb"

  def run_example(opts \\ []) do
    default_opts = [depth_testing: true, size: {1024, 768}, enter_to_exit: true]
    EAGL.Window.run(__MODULE__, "EAGL GLTF Example 4: Animated Box", Keyword.merge(default_opts, opts))
  end

  @impl true
  def setup do
    # --- EXAMPLE-SPECIFIC: Animated models cannot use load_scene ---
    # load_scene combines load_glb + to_scene + shader attachment. For animations,
    # we need the raw gltf and data_store to build Animator timelines, so we load
    # separately and attach the shader ourselves.
    with {:ok, program} <- GLTF.EAGL.create_phong_shader(),
         {:ok, gltf, data_store} <- GLTF.EAGL.load_glb(@glb_path),
         {:ok, {scene, _all_nodes}} <- GLTF.EAGL.to_scene(gltf, data_store),
         {:ok, animator} <- setup_animations(gltf, data_store) do
      # --- EXAMPLE-SPECIFIC: Manually attach shader to all nodes (since we didn't use load_scene) ---
      updated_roots = Enum.map(scene.root_nodes, &attach_program(&1, program))
      scene = %{scene | root_nodes: updated_roots}
      orbit = EAGL.OrbitCamera.fit_to_scene(scene)
      {:ok, %{program: program, scene: scene, orbit: orbit, animator: animator}}
    end
  end

  @impl true
  def render(w, h, %{program: prog, scene: scene, orbit: orbit} = state) do
    # --- COMMON: Same as 01_box ---
    :gl.viewport(0, 0, trunc(w), trunc(h))
    :gl.clearColor(0.15, 0.15, 0.2, 1.0)
    :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)
    :gl.enable(@gl_cull_face)
    :gl.cullFace(@gl_back)

    :gl.useProgram(prog)
    view = EAGL.OrbitCamera.get_view_matrix(orbit)
    proj = EAGL.OrbitCamera.get_projection_matrix(orbit, w / max(h, 1))

    GLTF.EAGL.set_phong_uniforms(prog,
      object_color: EAGL.Math.vec3(0.6, 0.8, 0.3),
      view_pos: EAGL.OrbitCamera.get_position(orbit)
    )

    Scene.render(scene, view, proj)
    {:ok, state}
  end

  # --- EXAMPLE-SPECIFIC: on_tick is called every frame by OrbitCamera ---
  # Override this to advance animations. Animator.update advances the timeline;
  # Animator.apply_to_scene writes keyframe transforms back into the scene graph.
  # The updated scene must be stored in state so the next render uses it.
  def on_tick(_dt, %{scene: scene, animator: animator} = state) do
    :ok = Animator.update(animator, 0.016)
    {:ok, %{state | scene: Animator.apply_to_scene(animator, scene)}}
  end

  @impl true
  def cleanup(%{program: p, animator: animator}) do
    cleanup_program(p)
    # --- EXAMPLE-SPECIFIC: Stop the Animator process ---
    Animator.stop(animator)
    :ok
  end

  # --- EXAMPLE-SPECIFIC: Build EAGL.Animator from GLTF animation data ---
  # convert_animations turns GLTF channels/samplers into EAGL timelines.
  # We load all timelines, start the first one, and loop it.
  defp setup_animations(gltf, data_store) do
    timelines = GLTF.EAGL.convert_animations(gltf, data_store)
    {:ok, animator} = Animator.new(loop: true)
    Enum.each(timelines, fn t -> :ok = Animator.load_timeline(animator, t) end)
    case timelines do
      [first | _] -> :ok = Animator.play(animator, first.name)
      [] -> :ok
    end
    {:ok, animator}
  end

  # --- EXAMPLE-SPECIFIC: Recursively attach shader program to every mesh in the scene ---
  # load_scene does this internally; we need it here because we used to_scene directly.
  defp attach_program(node, program) do
    updated = case EAGL.Node.get_mesh(node) do
      nil -> node
      mesh -> EAGL.Node.set_mesh(node, Map.put(mesh, :program, program))
    end
    children = Enum.map(EAGL.Node.get_children(updated), &attach_program(&1, program))
    EAGL.Node.set_children(updated, children)
  end
end
