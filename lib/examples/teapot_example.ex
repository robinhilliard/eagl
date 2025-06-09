defmodule EAGL.Examples.Teapot do
  @moduledoc """
  Draw a 3D teapot with switchable shaders.

  Controls:
  - Press '1' for simple red shading
  - Press '2' for glossy Phong porcelain shading
  - Press '3' for normals debugging (shows normals as colors)
  - Press ESC to quit
  """

  use EAGL.Window
  use EAGL.Const
  use EAGL.Math
  import Bitwise

  import EAGL.Shader
  import EAGL.Model

  @spec run_example() :: :ok | {:error, term()}
  def run_example, do: EAGL.Window.run(__MODULE__, "EAGL Utah Teapot Example - Press 1/2/3 to switch shaders")

  @impl true
  def setup do
    # Load all three shader programs
    with {:ok, vertex_simple} <- create_shader(@gl_vertex_shader, "vertex_shader_3d_red.glsl"),
         {:ok, fragment_simple} <- create_shader(@gl_fragment_shader, "fragment_shader_3d_default.glsl"),
         {:ok, program_simple} <- create_attach_link([vertex_simple, fragment_simple]),
         {:ok, vertex_phong} <- create_shader(@gl_vertex_shader, "vertex_shader_phong.glsl"),
         {:ok, fragment_phong} <- create_shader(@gl_fragment_shader, "fragment_shader_phong_porcelain.glsl"),
         {:ok, program_phong} <- create_attach_link([vertex_phong, fragment_phong]),
         {:ok, vertex_normals} <- create_shader(@gl_vertex_shader, "vertex_shader_phong.glsl"),
         {:ok, fragment_normals} <- create_shader(@gl_fragment_shader, "fragment_shader_normals_debug.glsl"),
         {:ok, program_normals} <- create_attach_link([vertex_normals, fragment_normals]),
         {:ok, model} <- load_model_to_vao("teapot.obj", clockwise_winding: false) do

      # Check depth buffer availability
      depth_bits = :gl.getIntegerv(@gl_depth_bits)
      if length(depth_bits) > 0 and hd(depth_bits) > 0 do
        IO.puts("Using default framebuffer with #{hd(depth_bits)}-bit depth buffer")
      else
        IO.puts("Warning: No depth buffer available - depth testing may not work properly")
      end

      # State: {simple_program, phong_program, normals_program, model, current_shader_index}
      # current_shader_index: 0 = simple, 1 = phong, 2 = normals debug
      {:ok, {program_simple, program_phong, program_normals, model, 0}}
    end
  end



  @impl true
  def render(viewport_width, viewport_height, {program_simple, program_phong, program_normals, model, current_shader}) do
    # Select which program to use
    program = case current_shader do
      0 -> program_simple
      1 -> program_phong
      2 -> program_normals
      _ -> program_simple
    end

    :gl.useProgram(program)

    # Set viewport to use the full window
    :gl.viewport(0, 0, trunc(viewport_width), trunc(viewport_height))

    # Enable depth testing and configure it properly
    :gl.enable(@gl_depth_test)
    :gl.depthFunc(@gl_less)
    :gl.clearDepth(1.0)
    :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)

    # Enable face culling to hide back faces
    :gl.enable(@gl_cull_face)
    :gl.cullFace(@gl_back)

    # Set front face winding order to match the model's actual winding
    # The teapot uses clockwise winding, so front faces are clockwise
    :gl.frontFace(@gl_ccw)  # Clockwise winding to match teapot.obj

    # Set polygon mode
    :gl.polygonMode(@gl_front, @gl_fill)

    # Common transformation matrices
    model_matrix = mat4_identity()
    camera_position = vec3(0.0, 4.0, -8.0)
    view_matrix = mat4_look_at(
      camera_position,          # camera position
      vec3(0.0, 1.0, 0.0),     # camera target
      vec3(0.0, 1.0, 0.0)      # camera up vector
    )

    # Guard against division by zero
    aspect_ratio = if viewport_height > 0, do: viewport_width / viewport_height, else: 1.0
    projection_matrix = mat4_perspective(
      radians(45.0), aspect_ratio, 1.0, 20.0)

    # Set common uniforms
    :gl.getUniformLocation(program, ~c"model") |> :gl.uniformMatrix4fv(0, model_matrix)
    :gl.getUniformLocation(program, ~c"view") |> :gl.uniformMatrix4fv(0, view_matrix)
    :gl.getUniformLocation(program, ~c"projection") |> :gl.uniformMatrix4fv(0, projection_matrix)

    # Set lighting uniforms for Phong and debug shaders
    if current_shader == 1 or current_shader == 2 do
      light_position = vec3(0.0, 4.0, -8.0)
      light_color = vec3(1.0, 1.0, 1.0)  # White light

      [{cam_x, cam_y, cam_z}] = camera_position
      [{light_x, light_y, light_z}] = light_position
      [{light_r, light_g, light_b}] = light_color

      :gl.getUniformLocation(program, ~c"light_position") |> :gl.uniform3f(light_x, light_y, light_z)
      :gl.getUniformLocation(program, ~c"light_color") |> :gl.uniform3f(light_r, light_g, light_b)
      :gl.getUniformLocation(program, ~c"camera_position") |> :gl.uniform3f(cam_x, cam_y, cam_z)
    end

    # Render the model
    :gl.bindVertexArray(model.vao)
    :gl.drawElements(@gl_triangles, model.vertex_count, @gl_unsigned_int, 0)

    :ok
  end

  @impl true
  def handle_event({:key, key_code}, {program_simple, program_phong, program_normals, model, current_shader}) do
    new_shader = case key_code do
      49 -> 0                     # Key '1' - simple red shader
      50 -> 1                     # Key '2' - phong porcelain shader
      51 -> 2                     # Key '3' - normals debug shader
      27 -> throw(:close_window)  # ESC key - quit
      _ -> current_shader
    end
    {:ok, {program_simple, program_phong, program_normals, model, new_shader}}
  end

  @impl true
  def cleanup({program_simple, program_phong, program_normals, model, _current_shader}) do
    cleanup_program(program_simple)
    cleanup_program(program_phong)
    cleanup_program(program_normals)
    delete_vao(model.vao)

    :ok
  end
end
