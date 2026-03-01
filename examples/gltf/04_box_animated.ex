defmodule EAGL.Examples.GLTF.BoxAnimated do
  @moduledoc """
  GLTF Example 4: Load and display the BoxAnimated model using EAGL GLTF bridge.

  Tests GLTF animation channel/sampler extraction, EAGL.Animator timeline
  loading and playback, and animated transforms through the scene hierarchy.
  """

  use EAGL.Window
  use EAGL.Const

  import Bitwise
  import EAGL.Shader
  alias EAGL.{Scene, Animator, OrbitCamera}

  @glb_path "test/fixtures/samples/BoxAnimated.glb"

  def run_example(opts \\ []) do
    default_opts = [depth_testing: true, size: {1024, 768}, enter_to_exit: true]
    EAGL.Window.run(__MODULE__, "EAGL GLTF Example 4: Animated Box", Keyword.merge(default_opts, opts))
  end

  @impl true
  def setup do
    with {:ok, program} <- GLTF.EAGL.create_phong_shader(),
         {:ok, gltf, data_store} <- GLTF.EAGL.load_glb(@glb_path),
         {:ok, {scene, _all_nodes}} <- GLTF.EAGL.to_scene(gltf, data_store),
         {:ok, animator} <- setup_animations(gltf, data_store) do
      updated_roots = Enum.map(scene.root_nodes, &attach_program(&1, program))
      scene = %{scene | root_nodes: updated_roots}
      orbit = EAGL.OrbitCamera.fit_to_gltf(gltf)
      {:ok, %{program: program, scene: scene, orbit: orbit, animator: animator}}
    end
  end

  @impl true
  def render(w, h, %{program: prog, scene: scene, orbit: orbit} = state) do
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

  @impl true
  def handle_event({:tick, _dt}, %{scene: scene, animator: animator} = state) do
    :ok = Animator.update(animator, 0.016)
    animated_scene = Animator.apply_to_scene(animator, scene)
    {:ok, %{state | scene: animated_scene}}
  end

  def handle_event({:mouse_motion, x, y}, %{orbit: orbit} = state) do
    {:ok, %{state | orbit: OrbitCamera.handle_mouse_motion(orbit, x, y)}}
  end

  def handle_event({:mouse_down, _, _}, %{orbit: orbit} = state) do
    {:ok, %{state | orbit: OrbitCamera.handle_mouse_down(orbit)}}
  end

  def handle_event({:mouse_up, _, _}, %{orbit: orbit} = state) do
    {:ok, %{state | orbit: OrbitCamera.handle_mouse_up(orbit)}}
  end

  def handle_event({:middle_down, _, _}, %{orbit: orbit} = state) do
    {:ok, %{state | orbit: OrbitCamera.handle_middle_down(orbit)}}
  end

  def handle_event({:middle_up, _, _}, %{orbit: orbit} = state) do
    {:ok, %{state | orbit: OrbitCamera.handle_middle_up(orbit)}}
  end

  def handle_event({:mouse_wheel, _, _, wheel_rotation, _}, %{orbit: orbit} = state) do
    {:ok, %{state | orbit: OrbitCamera.handle_scroll(orbit, wheel_rotation / 120.0)}}
  end

  def handle_event(_event, state), do: {:ok, state}

  @impl true
  def cleanup(%{program: p, animator: animator}) do
    cleanup_program(p)
    Animator.stop(animator)
    :ok
  end

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

  defp attach_program(node, program) do
    updated = case EAGL.Node.get_mesh(node) do
      nil -> node
      mesh -> EAGL.Node.set_mesh(node, Map.put(mesh, :program, program))
    end
    children = Enum.map(EAGL.Node.get_children(updated), &attach_program(&1, program))
    EAGL.Node.set_children(updated, children)
  end
end
