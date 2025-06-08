defmodule EAGL.Examples.Teapot do
  @moduledoc """
  Use ModelLoader to load a teapot model and draw it.
  """

  use EAGL.Window
  use EAGL.Const
  use EAGL.Math
  import EAGL.Shader
  import EAGL.Model

  @spec run_example() :: :ok | {:error, term()}
  def run_example, do: EAGL.Window.run(__MODULE__, "EAGL Teapot Example")

  @impl true
  def setup do
    with {:ok, vertex_shader} <- create_shader(@gl_vertex_shader, "vertex_shader_3d_red.glsl"),
         {:ok, fragment_shader} <- create_shader(@gl_fragment_shader, "fragment_shader_3d_default.glsl"),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]),
         {:ok, model} <- load_model_to_vao("teapot.obj") do
      {:ok, {program, model}}
    else
      error ->
        IO.inspect(error, label: "Setup error")
        error
    end
  end

  @impl true
  def render(viewport_width, viewport_height, {program, model}) do
    :gl.useProgram(program)
    :gl.enable(@gl_depth_test)

    # Ensure we're rendering filled polygons (not wireframe)
    :gl.polygonMode(@gl_front_and_back, @gl_fill)

        # Set up transformation matrices using EAGL.Math (now in column-major format for OpenGL)
    # Model matrix (identity)
    model_matrix = mat4_identity()

    # Simple orthographic projection matrix with aspect ratio correction
    # Calculate aspect ratio from viewport dimensions
    aspect = viewport_width / viewport_height

    # Adjust width to maintain square proportions
    base_size = 4.0

    # View matrix (translate world to move camera back)
    camera_distance = base_size * 2.0  # Move camera back proportional to viewing volume
    view_matrix = mat4_translate(vec3(0.0, 0.0, -camera_distance))

    left = -base_size * aspect
    right = base_size * aspect
    bottom = -base_size
    top = base_size
    near = -base_size * 3.0  # Extend clipping planes
    far = base_size * 3.0

    # Debug output
    #IO.puts("Viewing volume: width=#{right-left}, height=#{top-bottom}, depth=#{far-near}")
    #IO.puts("Camera at Z=#{camera_distance}, teapot at origin")

    # Orthographic projection matrix using EAGL.Math
    projection_matrix = mat4_ortho(left, right, bottom, top, near, far)

    # Set uniform matrices
    :gl.getUniformLocation(program, ~c"model") |> :gl.uniformMatrix4fv(0, model_matrix)
    :gl.getUniformLocation(program, ~c"view") |> :gl.uniformMatrix4fv(0, view_matrix)
    :gl.getUniformLocation(program, ~c"projection") |> :gl.uniformMatrix4fv(0, projection_matrix)
    :gl.bindVertexArray(model.vao)
    :gl.drawElements(@gl_triangles, model.vertex_count, @gl_unsigned_int, 0)
    :ok
  end

  @impl true
  def cleanup({program, model}) do
    cleanup_program(program)
    EAGL.Model.delete_vao(model.vao)
    :ok
  end

end
