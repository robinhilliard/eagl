defmodule EAGL.Examples.GLTF.BoxTextured do
  @moduledoc """
  GLTF Example 2: Load and display a textured Box using EAGL GLTF bridge.

  Builds on Example 1 by adding texture coordinate extraction, embedded
  texture loading from GLB binary data, and material property extraction.
  """

  use EAGL.Window
  use EAGL.Const

  import Bitwise
  import EAGL.{Shader, Math}
  alias EAGL.{Camera, Scene}

  @glb_path "test/fixtures/samples/BoxTextured.glb"

  def run_example(opts \\ []) do
    default_opts = [depth_testing: true, size: {1024, 768}, enter_to_exit: true]
    EAGL.Window.run(__MODULE__, "EAGL GLTF Example 2: Textured Box", Keyword.merge(default_opts, opts))
  end

  @impl true
  def setup do
    with {:ok, program} <- GLTF.EAGL.create_pbr_shader(),
         {:ok, scene, gltf, data_store} <- GLTF.EAGL.load_scene(@glb_path, program),
         {:ok, textures} <- GLTF.EAGL.load_textures(gltf, data_store) do
      camera = Camera.new(position: vec3(2.0, 2.0, 5.0), yaw: -110.0, pitch: -20.0)
      {:ok, %{program: program, scene: scene, camera: camera, textures: textures, time: 0.0, last_mouse: nil, mouse_down: false}}
    end
  end

  @impl true
  def render(width, height, %{program: program, scene: scene, camera: camera, textures: textures} = state) do
    :gl.viewport(0, 0, trunc(width), trunc(height))
    :gl.clearColor(0.15, 0.15, 0.2, 1.0)
    :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)
    :gl.enable(@gl_cull_face)
    :gl.cullFace(@gl_back)

    :gl.useProgram(program)
    view = Camera.get_view_matrix(camera)
    aspect = if height > 0, do: width / height, else: 1.0
    projection = mat4_perspective(radians(camera.zoom), aspect, 0.1, 100.0)

    set_uniforms(program,
      "material.baseColor": vec3(1.0, 1.0, 1.0),
      "material.metallic": 0.0,
      "material.roughness": 1.0,
      "material.emissive": vec3(0.0, 0.0, 0.0)
    )

    bind_texture(textures, :base_color, program, "baseColorTexture", "hasBaseColorTexture", @gl_texture0, 0)
    bind_texture(textures, :metallic_roughness, program, "metallicRoughnessTexture", "hasMetallicRoughnessTexture", @gl_texture1, 1)
    bind_texture(textures, :normal, program, "normalTexture", "hasNormalTexture", @gl_texture2, 2)
    bind_texture(textures, :emissive, program, "emissiveTexture", "hasEmissiveTexture", @gl_texture3, 3)
    :gl.activeTexture(@gl_texture0)

    set_uniforms(program,
      lightPos: vec3(3.0, 5.0, 4.0),
      lightColor: vec3(1.0, 1.0, 1.0),
      viewPos: camera.position
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

  defp bind_texture(textures, key, program, sampler_name, has_name, tex_unit, unit_idx) do
    case Map.get(textures, key) do
      nil -> set_uniform(program, has_name, false)
      tex_id ->
        :gl.activeTexture(tex_unit)
        :gl.bindTexture(@gl_texture_2d, tex_id)
        set_uniform(program, sampler_name, unit_idx)
        set_uniform(program, has_name, true)
    end
  end
end
