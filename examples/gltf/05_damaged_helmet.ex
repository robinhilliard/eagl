defmodule EAGL.Examples.GLTF.DamagedHelmet do
  @moduledoc """
  GLTF Example 5: Load and display the DamagedHelmet using EAGL GLTF bridge.

  Full PBR pipeline: complex geometry, multiple PBR textures, Cook-Torrance BRDF.
  """

  # --- COMMON: Same as other examples ---
  use EAGL.Window
  use EAGL.Const
  use EAGL.OrbitCamera

  import Bitwise
  import EAGL.Shader
  alias EAGL.Scene

  @glb_path "test/fixtures/samples/DamagedHelmet.glb"

  def run_example(opts \\ []) do
    default_opts = [depth_testing: true, size: {1024, 768}, enter_to_exit: true]
    EAGL.Window.run(__MODULE__, "EAGL GLTF Example 5: Damaged Helmet (PBR)", Keyword.merge(default_opts, opts))
  end

  @impl true
  def setup do
    # --- SAME AS 02/03: PBR + load_scene + load_textures ---
    # PLUS: DamagedHelmet has rich per-material factors (baseColor, metallic, roughness,
    # emissive) that affect the final look. We extract them for set_pbr_uniforms.
    with {:ok, program} <- GLTF.EAGL.create_pbr_shader(),
         {:ok, scene, gltf, ds} <- GLTF.EAGL.load_scene(@glb_path, program),
         {:ok, textures} <- GLTF.EAGL.load_textures(gltf, ds),
         {:ok, material} <- extract_material(gltf) do
      orbit = EAGL.OrbitCamera.fit_to_scene(scene)
      {:ok, %{program: program, scene: scene, orbit: orbit, textures: textures, material: material}}
    end
  end

  @impl true
  def render(w, h, %{program: prog, scene: scene, orbit: orbit, textures: tex, material: mat} = state) do
    # --- COMMON: Same as other examples ---
    :gl.viewport(0, 0, trunc(w), trunc(h))
    :gl.clearColor(0.1, 0.1, 0.15, 1.0)
    :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)
    :gl.enable(@gl_cull_face)
    :gl.cullFace(@gl_back)

    :gl.useProgram(prog)
    view = EAGL.OrbitCamera.get_view_matrix(orbit)
    proj = EAGL.OrbitCamera.get_projection_matrix(orbit, w / max(h, 1))

    # --- EXAMPLE-SPECIFIC: Pass material factors from GLTF to PBR shader ---
    # set_pbr_uniforms can use defaults, but DamagedHelmet looks better with the
    # model's actual baseColor, metallic, roughness, and emissive values.
    [r, g, b, _a] = mat.base_color_factor
    [er, eg, eb | _] = mat.emissive_factor || [0.0, 0.0, 0.0]

    GLTF.EAGL.set_pbr_uniforms(prog,
      base_color: EAGL.Math.vec3(r, g, b),
      metallic: mat.metallic_factor,
      roughness: mat.roughness_factor,
      emissive: EAGL.Math.vec3(er * 1.0, eg * 1.0, eb * 1.0),
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

  # --- EXAMPLE-SPECIFIC: Read PBR material factors from the first GLTF material ---
  # load_textures gives us the texture images; the material JSON holds scalar
  # factors (baseColor tint, metallic/roughness, emissive). For simple models
  # you can skip this and use set_pbr_uniforms defaults.
  defp extract_material(gltf) do
    case Enum.at(gltf.materials || [], 0) do
      nil ->
        {:ok, %{base_color_factor: [1.0, 1.0, 1.0, 1.0], metallic_factor: 1.0, roughness_factor: 1.0, emissive_factor: [0.0, 0.0, 0.0]}}

      mat ->
        pbr = mat.pbr_metallic_roughness || %{}
        {:ok, %{
          base_color_factor: Map.get(pbr, :base_color_factor, [1.0, 1.0, 1.0, 1.0]),
          metallic_factor: Map.get(pbr, :metallic_factor, 1.0),
          roughness_factor: Map.get(pbr, :roughness_factor, 1.0),
          emissive_factor: mat.emissive_factor || [0.0, 0.0, 0.0]
        }}
    end
  end
end
