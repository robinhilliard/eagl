defmodule EAGL.Examples.GLTF.Duck do
  @moduledoc """
  GLTF Example 3: Load and display the Duck model using EAGL GLTF bridge.

  Tests multi-node scene graph with parent-child transforms and larger geometry.
  """

  # --- COMMON: Same as 01_box and 02_box_textured ---
  use EAGL.Window
  use EAGL.Const
  use EAGL.OrbitCamera

  import Bitwise
  import EAGL.Shader
  alias EAGL.Scene

  @glb_path "test/fixtures/samples/Duck.glb"

  def run_example(opts \\ []) do
    default_opts = [depth_testing: true, size: {1024, 768}, enter_to_exit: true]
    EAGL.Window.run(__MODULE__, "EAGL GLTF Example 3: Duck", Keyword.merge(default_opts, opts))
  end

  @impl true
  def setup do
    # --- SAME AS 02_box_textured: PBR + load_textures for textured model ---
    # The only difference from example 2 is the model file: Duck has a multi-node
    # scene graph (parent-child hierarchy) and more geometry. load_scene handles
    # both automatically.
    with {:ok, program} <- GLTF.EAGL.create_pbr_shader(),
         {:ok, scene, gltf, ds} <- GLTF.EAGL.load_scene(@glb_path, program),
         {:ok, textures} <- GLTF.EAGL.load_textures(gltf, ds) do
      orbit = EAGL.OrbitCamera.fit_to_scene(scene)
      {:ok, %{program: program, scene: scene, orbit: orbit, textures: textures}}
    end
  end

  @impl true
  def render(w, h, %{program: prog, scene: scene, orbit: orbit, textures: tex} = state) do
    # --- COMMON: Same as 01_box and 02_box_textured ---
    :gl.viewport(0, 0, trunc(w), trunc(h))
    :gl.clearColor(0.15, 0.15, 0.2, 1.0)
    :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)
    :gl.enable(@gl_cull_face)
    :gl.cullFace(@gl_back)

    :gl.useProgram(prog)
    view = EAGL.OrbitCamera.get_view_matrix(orbit)
    proj = EAGL.OrbitCamera.get_projection_matrix(orbit, w / max(h, 1))

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
    ids = Map.values(t) |> Enum.filter(&is_integer/1)
    if ids != [], do: :gl.deleteTextures(ids)
    :ok
  end
end
