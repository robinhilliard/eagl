defmodule EZGL.Examples.Teapot do
  @moduledoc """
  Use ModelLoader to load a teapot model and draw it.
  """

  use GL.Window
  use GL.Const
  import GL.Shader
  import GL.ModelLoader

  @spec run_example() :: :ok | {:error, term()}
  def run_example, do: GL.Window.run(__MODULE__, "EZGL Teapot Example")

  @impl true
  def setup do
    with {:ok, vertex_shader} <- create_shader(@gl_vertex_shader, vertex_shader_source()),
         {:ok, fragment_shader} <- create_shader(@gl_fragment_shader, fragment_shader_source()),
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

        # Set up transformation matrices as list with tuples (correct for Erlang GL bindings)
    # Model matrix (identity) - OpenGL column-major format
    model_matrix = [{
      1.0, 0.0, 0.0, 0.0,  # Column 1
      0.0, 1.0, 0.0, 0.0,  # Column 2
      0.0, 0.0, 1.0, 0.0,  # Column 3
      0.0, 0.0, 0.0, 1.0   # Column 4
    }]

    # Simple orthographic projection matrix with aspect ratio correction
    # Calculate aspect ratio from viewport dimensions
    aspect = viewport_width / viewport_height

    # Adjust width to maintain square proportions
    base_size = 4.0

    # View matrix (translate world to move camera back) - OpenGL column-major format
    camera_distance = base_size * 2.0  # Move camera back proportional to viewing volume
    view_matrix = [{
      1.0, 0.0, 0.0, 0.0,                # Column 1
      0.0, 1.0, 0.0, 0.0,                # Column 2
      0.0, 0.0, 1.0, 0.0,                # Column 3
      0.0, 0.0, -camera_distance, 1.0    # Column 4 (translation)
    }]
    left = -base_size * aspect
    right = base_size * aspect
    bottom = -base_size
    top = base_size
    near = -base_size * 3.0  # Extend clipping planes
    far = base_size * 3.0

    # Debug output
    #IO.puts("Viewing volume: width=#{right-left}, height=#{top-bottom}, depth=#{far-near}")
    #IO.puts("Camera at Z=#{camera_distance}, teapot at origin")

    # Orthographic projection matrix calculation for clarity
    width = right - left
    height = top - bottom
    depth = far - near

    # Orthographic projection matrix
    projection_matrix = [{
      2.0 / width,  0.0,           0.0,          0.0,
      0.0,          2.0 / height,  0.0,          0.0,
      0.0,          0.0,          -2.0 / depth,  0.0,
      -(right + left) / width, -(top + bottom) / height, -(far + near) / depth, 1.0
    }]

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
    GL.ModelLoader.delete_vao(model.vao)
    :ok
  end

  defp vertex_shader_source do
    """
    #version 150

    in vec3 position;
    in vec3 normal;
    in vec2 tex_coord;

    out vec3 frag_color;
    out vec2 frag_tex_coord;

    uniform mat4 model;
    uniform mat4 view;
    uniform mat4 projection;

    void main() {
      gl_Position = projection * view * model * vec4(position, 1.0);
      frag_color = vec3(1.0, 0.0, 0.0);
      frag_tex_coord = tex_coord;
    }

    """
  end

  defp fragment_shader_source do
    """
    #version 150

    in vec2 frag_tex_coord;
    in vec3 frag_color;

    out vec4 out_color;

    void main() {
      out_color = vec4(frag_color, 1.0);
    }

    """
  end
end
