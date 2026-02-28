defmodule EAGL.Examples.GLTF.DamagedHelmet do
  @moduledoc """
  GLTF Example 5: Load and display the DamagedHelmet using EAGL GLTF bridge.

  Full PBR pipeline test: complex mesh geometry, multiple PBR textures
  (base colour, metallic-roughness, normal, emissive), and full
  Cook-Torrance BRDF rendering.
  """

  use EAGL.Window
  use EAGL.Const

  import Bitwise
  import EAGL.{Shader, Math}
  alias EAGL.{Camera, Scene}

  @glb_path "test/fixtures/samples/DamagedHelmet.glb"

  def run_example(opts \\ []) do
    default_opts = [depth_testing: true, size: {1024, 768}, enter_to_exit: true]
    EAGL.Window.run(__MODULE__, "EAGL GLTF Example 5: Damaged Helmet (PBR)", Keyword.merge(default_opts, opts))
  end

  @impl true
  def setup do
    with {:ok, program} <- GLTF.EAGL.create_pbr_shader(),
         {:ok, scene, gltf, data_store} <- GLTF.EAGL.load_scene(@glb_path, program),
         {:ok, textures} <- GLTF.EAGL.load_textures(gltf, data_store),
         {:ok, material} <- extract_material(gltf) do
      camera = Camera.new(position: vec3(0.0, 0.0, 4.0), yaw: -90.0, pitch: 0.0)
      {:ok, %{program: program, scene: scene, camera: camera, textures: textures, material: material, time: 0.0, last_mouse: nil, mouse_down: false}}
    end
  end

  @impl true
  def render(width, height, state) do
    %{program: program, scene: scene, camera: camera, textures: textures, material: material} = state

    :gl.viewport(0, 0, trunc(width), trunc(height))
    :gl.clearColor(0.1, 0.1, 0.15, 1.0)
    :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)
    :gl.enable(@gl_cull_face)
    :gl.cullFace(@gl_back)

    :gl.useProgram(program)
    view = Camera.get_view_matrix(camera)
    aspect = if height > 0, do: width / height, else: 1.0
    projection = mat4_perspective(radians(camera.zoom), aspect, 0.1, 100.0)

    [r, g, b, _a] = material.base_color_factor
    [er, eg, eb | _] = material.emissive_factor || [0.0, 0.0, 0.0]

    GLTF.EAGL.set_pbr_uniforms(program,
      base_color: vec3(r, g, b),
      metallic: material.metallic_factor,
      roughness: material.roughness_factor,
      emissive: vec3(er * 1.0, eg * 1.0, eb * 1.0),
      textures: textures,
      view_pos: camera.position
    )

    Scene.render(scene, view, projection)
    {:ok, state}
  end

  @impl true
  def handle_event({:tick, _dt}, %{camera: camera, time: time} = state) do
    {:ok, %{state | camera: Camera.process_keyboard_input(camera, 0.016), time: time + 0.016}}
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
  def cleanup(%{program: program, textures: textures}) do
    cleanup_program(program)
    tex_ids = Map.values(textures) |> Enum.filter(&is_integer/1)
    if tex_ids != [], do: :gl.deleteTextures(tex_ids)
    :ok
  end

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
