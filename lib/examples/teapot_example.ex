defmodule EZGL.Examples.Teapot do
  @moduledoc """
  Use ModelLoader to load a teapot model and draw it.
  """

  use GL.Window
  import GL.Shader

  @spec run() :: :ok | {:error, term()}
  def run, do: GL.Window.run(__MODULE__, "EZGL Teapot Example", {800, 600})

  @impl true
  def setup do
    with {:ok, vertex_shader} <- create_shader(gl_vertex_shader(), vertex_shader_source()),
         {:ok, fragment_shader} <- create_shader(gl_fragment_shader(), fragment_shader_source()),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]),
         {:ok, model} <- GL.ModelLoader.load_model_to_vao("teapot.obj") do
      {:ok, {program, model}}
    else
      error ->
        IO.inspect(error, label: "Setup error")
        error
    end
  end

  @impl true
  def render({program, model}) do
    :gl.useProgram(program)

    # Define viewport dimensions (used for both viewport and projection)
    viewport_width = 800.0
    viewport_height = 600.0

    # Set viewport to match window size
    :gl.viewport(0, 0, trunc(viewport_width), trunc(viewport_height))

    # Enable depth testing
    :gl.enable(gl_depth_test())
    :gl.clear(gl_color_buffer_bit() ||| gl_depth_buffer_bit())

    # Ensure we're rendering filled polygons (not wireframe)
    :gl.polygonMode(gl_front_and_back(), gl_fill())

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

    # Orthographic projection matrix - OpenGL column-major format
    projection_matrix = [{
      2.0 / width,  0.0,           0.0,          0.0,                    # Column 1
      0.0,          2.0 / height,  0.0,          0.0,                    # Column 2
      0.0,          0.0,          -2.0 / depth,  0.0,                    # Column 3
      -(right + left) / width, -(top + bottom) / height, -(far + near) / depth, 1.0  # Column 4
    }]

        # Set uniform matrices
    model_location = :gl.getUniformLocation(program, ~c"model")
    view_location = :gl.getUniformLocation(program, ~c"view")
    projection_location = :gl.getUniformLocation(program, ~c"projection")

    :gl.uniformMatrix4fv(model_location, 0, model_matrix)
    :gl.uniformMatrix4fv(view_location, 0, view_matrix)
    :gl.uniformMatrix4fv(projection_location, 0, projection_matrix)

    # === DEBUG DUMP ===
    #IO.puts("\n=== RENDER DEBUG ===")

    # Model info
    #IO.inspect(model, label: "Model")

    # Uniform locations
    #IO.inspect({model_location, view_location, projection_location}, label: "Uniform locations")

    # Matrix values
    #IO.inspect(model_matrix, label: "Model matrix")
    #IO.inspect(view_matrix, label: "View matrix")
    #IO.inspect(projection_matrix, label: "Projection matrix")

    # OpenGL state
    #IO.inspect(:gl.getIntegerv(gl_current_program()), label: "Current program")
    #IO.inspect(:gl.getIntegerv(gl_viewport()), label: "Viewport")
    #IO.inspect(:gl.isEnabled(gl_depth_test()), label: "Depth test enabled")

    :gl.bindVertexArray(model.vao)

    # VAO state after binding
    #IO.inspect(:gl.getIntegerv(gl_vertex_array_binding()), label: "Bound VAO")

    # Check vertex attributes
    #for i <- 0..2 do
      #enabled = :gl.getVertexAttribiv(i, gl_vertex_attrib_array_enabled())
      #size = :gl.getVertexAttribiv(i, gl_vertex_attrib_array_size())
      #stride = :gl.getVertexAttribiv(i, gl_vertex_attrib_array_stride())
      #buffer = :gl.getVertexAttribiv(i, gl_vertex_attrib_array_buffer_binding())
      #IO.inspect({enabled, size, stride, buffer}, label: "Vertex attrib #{i} (enabled, size, stride, buffer)")
    #end

    # Check for OpenGL errors
    error = :gl.getError()
    if error != 0 do
      IO.inspect(error, label: "OpenGL error before draw")
    end

    #IO.puts("Drawing #{model.vertex_count} vertices...")
    :gl.drawElements(gl_triangles(), model.vertex_count, gl_unsigned_int(), 0)

    # Check for errors after draw
    error_after = :gl.getError()
    if error_after != 0 do
      IO.inspect(error_after, label: "OpenGL error after draw")
    end

    #IO.puts("=== END DEBUG ===\n")
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
