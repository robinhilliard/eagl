defmodule EAGL.Examples.GLTF.Box do
  @moduledoc """
  GLTF Example 1: Load and display a Box using the EAGL GLTF bridge.

  The simplest GLTF model test: an indexed cube with positions and normals.
  """

  use EAGL.Window
  use EAGL.Const
  use EAGL.OrbitCamera

  import Bitwise
  import EAGL.Shader
  alias EAGL.Scene

  @glb_path "test/fixtures/samples/Box.glb"

  def run_example(opts \\ []) do
    default_opts = [depth_testing: true, size: {1024, 768}, enter_to_exit: true]
    EAGL.Window.run(__MODULE__, "EAGL GLTF Example 1: Box", Keyword.merge(default_opts, opts))
  end

  @impl true
  def setup do
    with {:ok, program} <- GLTF.EAGL.create_phong_shader(),
         {:ok, scene, gltf, _ds} <- GLTF.EAGL.load_scene(@glb_path, program) do
      orbit = EAGL.OrbitCamera.fit_to_gltf(gltf)
      {:ok, %{program: program, scene: scene, orbit: orbit}}
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
      object_color: EAGL.Math.vec3(0.8, 0.3, 0.2),
      view_pos: EAGL.OrbitCamera.get_position(orbit)
    )

    Scene.render(scene, view, proj)
    {:ok, state}
  end

  @impl true
  def cleanup(%{program: p}) do
    cleanup_program(p)
    :ok
  end
end
