defmodule EAGL.Examples.GLTF.BoxAnimated do
  @moduledoc """
  GLTF Example 4: Load and display the BoxAnimated model using EAGL GLTF bridge.

  Builds on Example 3 by testing GLTF animation channel/sampler extraction,
  EAGL.Animator timeline loading and playback, and animated transforms
  applied through the scene hierarchy.
  """

  use EAGL.Window
  use EAGL.Const

  import Bitwise
  import EAGL.{Shader, Math}
  alias EAGL.{Camera, Scene, Animator}

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
      camera = Camera.new(position: vec3(3.0, 3.0, 6.0), yaw: -110.0, pitch: -20.0)
      {:ok, %{program: program, scene: scene, camera: camera, animator: animator, time: 0.0, last_mouse: nil, mouse_down: false}}
    end
  end

  @impl true
  def render(width, height, %{program: program, scene: scene, camera: camera} = state) do
    :gl.viewport(0, 0, trunc(width), trunc(height))
    :gl.clearColor(0.15, 0.15, 0.2, 1.0)
    :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)
    :gl.enable(@gl_cull_face)
    :gl.cullFace(@gl_back)

    :gl.useProgram(program)
    view = Camera.get_view_matrix(camera)
    aspect = if height > 0, do: width / height, else: 1.0
    projection = mat4_perspective(radians(camera.zoom), aspect, 0.1, 100.0)

    GLTF.EAGL.set_phong_uniforms(program,
      object_color: vec3(0.6, 0.8, 0.3),
      light_pos: vec3(3.0, 5.0, 4.0),
      view_pos: camera.position
    )

    Scene.render(scene, view, projection)
    {:ok, state}
  end

  @impl true
  def handle_event({:tick, _dt}, %{camera: camera, scene: scene, animator: animator, time: time} = state) do
    dt = 0.016
    :ok = Animator.update(animator, dt)
    animated_scene = Animator.apply_to_scene(animator, scene)
    {:ok, %{state | camera: Camera.process_keyboard_input(camera, dt), scene: animated_scene, time: time + dt}}
  end

  def handle_event({:mouse_motion, x, y}, %{camera: camera, last_mouse: last_mouse, mouse_down: true} = state) do
    {lx, ly} = last_mouse || {x, y}
    {:ok, %{state | camera: Camera.process_mouse_movement(camera, x - lx, ly - y, true), last_mouse: {x, y}}}
  end

  def handle_event({:mouse_motion, x, y}, state), do: {:ok, %{state | last_mouse: {x, y}}}
  def handle_event({:mouse_down, _, _}, state), do: {:ok, %{state | mouse_down: true}}
  def handle_event({:mouse_up, _, _}, state), do: {:ok, %{state | mouse_down: false, last_mouse: nil}}

  def handle_event({:mouse_wheel, _, _, _, wd}, %{camera: camera} = state) do
    {:ok, %{state | camera: Camera.process_mouse_scroll(camera, wd)}}
  end

  def handle_event(_event, state), do: {:ok, state}

  @impl true
  def cleanup(%{program: program, animator: animator}) do
    cleanup_program(program)
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
