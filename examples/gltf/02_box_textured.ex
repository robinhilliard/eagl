defmodule EAGL.Examples.GLTF.BoxTextured do
  @moduledoc """
  GLTF Example 2: Load and display a textured Box using EAGL GLTF bridge.

  Adds texture coordinate extraction, embedded texture loading, and
  PBR material properties.
  """

  # --- COMMON: See 01_box.ex for explanation of these ---
  use EAGL.Window
  use EAGL.Const
  use EAGL.OrbitCamera

  import Bitwise
  import EAGL.Shader
  alias EAGL.Scene

  @glb_path "test/fixtures/samples/BoxTextured.glb"

  def run_example(opts \\ []) do
    default_opts = [depth_testing: true, size: {1024, 768}, enter_to_exit: true]
    EAGL.Window.run(__MODULE__, "EAGL GLTF Example 2: Textured Box", Keyword.merge(default_opts, opts))
  end

  @impl true
  def setup do
    # --- EXAMPLE-SPECIFIC: BoxTextured has textures, so we use PBR shader ---
    with {:ok, program} <- GLTF.EAGL.create_pbr_shader(),
         {:ok, scene, gltf, ds} <- GLTF.EAGL.load_scene(@glb_path, program),
         # --- EXAMPLE-SPECIFIC: Extract baseColor, metallicRoughness, etc. from GLTF ---
         {:ok, textures} <- GLTF.EAGL.load_textures(gltf, ds) do
      orbit = EAGL.OrbitCamera.fit_to_gltf(gltf)
      {:ok, %{program: program, scene: scene, orbit: orbit, textures: textures}}
    end
  end

  @impl true
  def render(w, h, %{program: prog, scene: scene, orbit: orbit, textures: tex} = state) do
    # --- COMMON: Same as 01_box ---
    :gl.viewport(0, 0, trunc(w), trunc(h))
    :gl.clearColor(0.15, 0.15, 0.2, 1.0)
    :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)
    :gl.enable(@gl_cull_face)
    :gl.cullFace(@gl_back)

    :gl.useProgram(prog)
    view = EAGL.OrbitCamera.get_view_matrix(orbit)
    proj = EAGL.OrbitCamera.get_projection_matrix(orbit, w / max(h, 1))

    # --- EXAMPLE-SPECIFIC: PBR uniforms with textures; metallic=0 for non-metal look ---
    GLTF.EAGL.set_pbr_uniforms(prog,
      metallic: 0.0,
      textures: tex,
      view_pos: EAGL.OrbitCamera.get_position(orbit)
    )

    Scene.render(scene, view, proj)
    {:ok, state}
  end

  @impl true
  def cleanup(%{program: p, textures: t}) do
    cleanup_program(p)
    # --- EXAMPLE-SPECIFIC: Textured models must delete OpenGL texture IDs ---
    ids = Map.values(t) |> Enum.filter(&is_integer/1)
    if ids != [], do: :gl.deleteTextures(ids)
    :ok
  end
end
