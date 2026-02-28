defmodule EAGL.Examples.GLTF.Box do
  @moduledoc """
  GLTF Example 1: Load and display a Box using the EAGL GLTF bridge.

  The simplest GLTF model test: an indexed cube with positions and normals.
  Validates GLB loading, accessor data extraction, VAO/VBO creation via
  EAGL.Buffer, and scene graph rendering via EAGL.Scene.
  """

  use EAGL.Window
  use EAGL.Const

  import Bitwise
  import EAGL.{Shader, Math}
  alias EAGL.{Camera, Scene}

  @glb_path "test/fixtures/samples/Box.glb"

  def run_example(opts \\ []) do
    default_opts = [depth_testing: true, size: {1024, 768}, enter_to_exit: true]
    EAGL.Window.run(__MODULE__, "EAGL GLTF Example 1: Box", Keyword.merge(default_opts, opts))
  end

  @impl true
  def setup do
    with {:ok, program} <- create_shader_program(),
         {:ok, scene, _gltf, _ds} <- GLTF.EAGL.load_scene(@glb_path, program) do
      camera = Camera.new(position: vec3(2.0, 2.0, 5.0), yaw: -110.0, pitch: -20.0)
      {:ok, %{program: program, scene: scene, camera: camera, time: 0.0, last_mouse: nil, mouse_down: false}}
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

    set_uniforms(program,
      objectColor: vec3(0.8, 0.3, 0.2),
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
  def cleanup(%{program: program}) do
    cleanup_program(program)
    :ok
  end

  defp create_shader_program do
    vs_source = """
    #version 330 core
    layout (location = 0) in vec3 aPos;
    layout (location = 1) in vec3 aNormal;

    uniform mat4 model;
    uniform mat4 view;
    uniform mat4 projection;

    out vec3 FragPos;
    out vec3 Normal;

    void main() {
        FragPos = vec3(model * vec4(aPos, 1.0));
        Normal = mat3(transpose(inverse(model))) * aNormal;
        gl_Position = projection * view * vec4(FragPos, 1.0);
    }
    """

    fs_source = """
    #version 330 core
    out vec4 FragColor;
    in vec3 FragPos;
    in vec3 Normal;

    uniform vec3 objectColor;
    uniform vec3 lightPos;
    uniform vec3 lightColor;
    uniform vec3 viewPos;

    void main() {
        vec3 norm = normalize(Normal);
        vec3 lightDir = normalize(lightPos - FragPos);
        float diff = max(dot(norm, lightDir), 0.0);
        vec3 viewDir = normalize(viewPos - FragPos);
        vec3 reflectDir = reflect(-lightDir, norm);
        float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32.0);

        vec3 ambient = 0.15 * lightColor;
        vec3 diffuse = diff * lightColor;
        vec3 specular = 0.5 * spec * lightColor;

        vec3 result = (ambient + diffuse + specular) * objectColor;
        FragColor = vec4(result, 1.0);
    }
    """

    with {:ok, vs} <- create_shader_from_source(@gl_vertex_shader, vs_source, "box_vs"),
         {:ok, fs} <- create_shader_from_source(@gl_fragment_shader, fs_source, "box_fs"),
         {:ok, prog} <- create_attach_link([vs, fs]) do
      {:ok, prog}
    end
  end
end
