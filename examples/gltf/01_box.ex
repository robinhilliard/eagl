defmodule EAGL.Examples.GLTF.Box do
  @moduledoc """
  GLTF Example 1: Load and display a Box using the EAGL GLTF bridge.

  The simplest GLTF model test: an indexed cube with positions and normals.
  """

  # --- COMMON: Every GLTF example uses these ---
  use EAGL.Window          # Provides setup/render/cleanup callbacks and event loop
  use EAGL.Const           # OpenGL constants (e.g. @gl_color_buffer_bit)
  use EAGL.OrbitCamera     # Orbit/zoom/pan mouse controls; fit_to_scene for initial view

  import Bitwise
  import EAGL.Shader
  alias EAGL.Scene

  # --- EXAMPLE-SPECIFIC: Path to the GLB file for this example ---
  @glb_path "test/fixtures/samples/Box.glb"

  # --- COMMON: Entry point; opts can override window size, depth_testing, etc. ---
  def run_example(opts \\ []) do
    default_opts = [depth_testing: true, size: {1024, 768}, enter_to_exit: true]
    EAGL.Window.run(__MODULE__, "EAGL GLTF Example 1: Box", Keyword.merge(default_opts, opts))
  end

  @impl true
  def setup do
    # --- EXAMPLE-SPECIFIC: Box has no textures, so we use Phong (simple diffuse) ---
    with {:ok, program} <- GLTF.EAGL.create_phong_shader(),
         # --- COMMON: load_scene parses GLB, builds VAOs, attaches shader to all meshes ---
         {:ok, scene, _gltf, _ds} <- GLTF.EAGL.load_scene(@glb_path, program) do
      # --- COMMON: Position camera to frame the model's bounding box ---
      orbit = EAGL.OrbitCamera.fit_to_scene(scene)
      {:ok, %{program: program, scene: scene, orbit: orbit}}
    end
  end

  @impl true
  def render(w, h, %{program: prog, scene: scene, orbit: orbit} = state) do
    # --- COMMON: Standard OpenGL state for 3D rendering ---
    :gl.viewport(0, 0, trunc(w), trunc(h))
    :gl.clearColor(0.15, 0.15, 0.2, 1.0)
    :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)
    :gl.enable(@gl_cull_face)
    :gl.cullFace(@gl_back)

    # --- COMMON: Use shader and get view/projection from orbit camera ---
    :gl.useProgram(prog)
    view = EAGL.OrbitCamera.get_view_matrix(orbit)
    proj = EAGL.OrbitCamera.get_projection_matrix(orbit, w / max(h, 1))

    # --- EXAMPLE-SPECIFIC: Phong uniforms; object_color is a flat colour (no textures) ---
    GLTF.EAGL.set_phong_uniforms(prog,
      object_color: EAGL.Math.vec3(0.8, 0.3, 0.2),
      view_pos: EAGL.OrbitCamera.get_position(orbit)
    )

    # --- COMMON: Recursively render scene graph with model/view/proj matrices ---
    Scene.render(scene, view, proj)
    {:ok, state}
  end

  @impl true
  def cleanup(%{program: p}) do
    # --- COMMON: Release shader program; no textures to delete in this example ---
    cleanup_program(p)
    :ok
  end
end
