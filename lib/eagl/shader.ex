defmodule EAGL.Shader do
  @moduledoc """
  OpenGL shader compilation and program management.

  Handles the complex multi-step process of shader compilation, linking,
  and uniform management with Wings3D-inspired error handling.

  ## Original Source

  Uniform helper functions (`uloc/2`, `set_uloc/3`) are inspired by Wings3D's
  `wings_gl.erl` module:
  <https://github.com/dgud/wings/blob/master/src/wings_gl.erl>

  ## Usage

      import EAGL.Shader
      import EAGL.Math

      # Compile and link shaders with typed parameters
      {:ok, vertex} = create_shader(:vertex, "vertex.glsl")
      {:ok, fragment} = create_shader(:fragment, "fragment.glsl")
      {:ok, program} = create_attach_link([vertex, fragment])

      # Set uniforms with automatic type detection
      set_uniform(program, "model_matrix", model_matrix)
      set_uniform(program, "light_position", vec3(10.0, 10.0, 5.0))

      # Set multiple uniforms efficiently
      set_uniforms(program, [
        model: model_matrix,
        view: view_matrix,
        projection: projection_matrix
      ])

      # Use OpenGL directly for program binding
      :gl.useProgram(program)

      # Clean up when done
      cleanup_program(program)
  """

  use EAGL.Const

  # Import types from EAGL.Math for uniform function specs
  @type vec2 :: EAGL.Math.vec2()
  @type vec3 :: EAGL.Math.vec3()
  @type vec4 :: EAGL.Math.vec4()
  @type mat2 :: EAGL.Math.mat2()
  @type mat3 :: EAGL.Math.mat3()
  @type mat4 :: EAGL.Math.mat4()
  @type quat :: EAGL.Math.quat()

  @type shader_id :: non_neg_integer()
  @type program_id :: non_neg_integer()
  @type shader_type :: non_neg_integer()

  @type uniform_value ::
          vec2()
          | vec3()
          | vec4()
          | mat2()
          | mat3()
          | mat4()
          | quat()
          | float()
          | integer()
          | boolean()

  @app Mix.Project.config()[:app]

  @doc """
  Creates and compiles a shader from a file.

  ## Parameters

  - `shader_type`: OpenGL shader type constant (e.g., @gl_vertex_shader, @gl_fragment_shader)
  - `file_path`: Path to the shader file (relative to priv/shaders/ or absolute)

  ## Examples

      {:ok, vertex_shader} = create_shader(@gl_vertex_shader, "vertex.glsl")
      {:ok, fragment_shader} = create_shader(@gl_fragment_shader, "fragment.glsl")
  """
  @spec create_shader(shader_type(), String.t()) :: {:ok, shader_id()} | {:error, String.t()}
  def create_shader(shader_type, file_path) do
    case read_shader_file(file_path) do
      {:ok, source} ->
        compile_shader_source(shader_type, source, file_path)

      {:error, reason} ->
        {:error, "Failed to read shader file '#{file_path}': #{reason}"}
    end
  end

  @doc """
  Creates and compiles a shader from source code.

  ## Parameters

  - `shader_type`: OpenGL shader type constant (e.g., @gl_vertex_shader, @gl_fragment_shader)
  - `source`: GLSL source code as string or charlist
  - `name`: Optional name for error reporting (defaults to "inline shader")

  ## Examples

      vertex_source = "#version 330 core\nlayout (location = 0) in vec3 aPos;\nvoid main() { gl_Position = vec4(aPos, 1.0); }"
      {:ok, shader_id} = create_shader_from_source(@gl_vertex_shader, vertex_source, "my_vertex")
  """
  @spec create_shader_from_source(shader_type(), String.t() | charlist(), String.t()) ::
          {:ok, shader_id()} | {:error, String.t()}
  def create_shader_from_source(shader_type, source, name \\ "inline shader") do
    compile_shader_source(shader_type, source, name)
  end

  # ============================================================================
  # PRIVATE HELPER FUNCTIONS
  # ============================================================================

  # Read shader file from priv/shaders/ directory or absolute path
  @spec read_shader_file(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp read_shader_file(file_path) do
    # Try absolute path first, then relative to priv/shaders/
    path =
      if Path.absname(file_path) == file_path do
        file_path
      else
        priv_dir = :code.priv_dir(@app)
        Path.join([priv_dir, "shaders", file_path])
      end

    case File.read(path) do
      {:ok, content} -> {:ok, content}
      {:error, reason} -> {:error, "Cannot read file '#{path}': #{:file.format_error(reason)}"}
    end
  end

  # Prepare shader source for OpenGL
  @spec prepare_shader_source(String.t() | charlist()) :: charlist()
  defp prepare_shader_source(source) when is_binary(source) do
    String.to_charlist(source)
  end

  defp prepare_shader_source(source) when is_list(source) do
    source
  end

  # Compile shader source code
  @spec compile_shader_source(shader_type(), String.t() | charlist(), String.t()) ::
          {:ok, shader_id()} | {:error, String.t()}
  defp compile_shader_source(shader_type, source, name) do
    shader_id = :gl.createShader(shader_type)

    try do
      # Convert source to the format expected by gl:shaderSource
      gl_source = prepare_shader_source(source)
      :gl.shaderSource(shader_id, [gl_source])
      :gl.compileShader(shader_id)

      case :gl.getShaderiv(shader_id, @gl_compile_status) do
        @gl_true ->
          {:ok, shader_id}

        @gl_false ->
          log_length = :gl.getShaderiv(shader_id, @gl_info_log_length)
          error_log = :gl.getShaderInfoLog(shader_id, log_length)
          :gl.deleteShader(shader_id)
          {:error, "Shader compilation failed for '#{name}':\n#{error_log}"}
      end
    catch
      error_type, reason ->
        :gl.deleteShader(shader_id)
        {:error, "Shader compilation exception for '#{name}': #{error_type}:#{inspect(reason)}"}
    end
  end

  @doc """
  Checks if a shader compiled successfully.
  """
  def check_compile_status(shader) do
    compile_status = :gl.getShaderiv(shader, @gl_compile_status)

    if compile_status == 0 do
      log_length = :gl.getShaderiv(shader, @gl_info_log_length)
      log = :gl.getShaderInfoLog(shader, log_length)
      {:error, "Shader compilation failed: #{log}"}
    else
      {:ok, shader}
    end
  end

  def check_link_status(program) do
    case :gl.getProgramiv(program, @gl_link_status) do
      status when status != 0 ->
        {:ok, program}

      _ ->
        log_length = :gl.getProgramiv(program, @gl_info_log_length)
        log = :gl.getProgramInfoLog(program, log_length)
        message = "Program linking failed: #{log}"
        {:error, message}
    end
  end

  @doc """
  Cleans up a shader program and all its attached shaders.
  """
  def cleanup_program(program) when is_integer(program) do
    # Check if program exists and is valid
    case :gl.getProgramiv(program, @gl_delete_status) do
      -1 ->
        {:error, "Invalid program"}

      _ ->
        # Get attached shaders
        num_shaders = :gl.getProgramiv(program, @gl_attached_shaders)
        shaders = :gl.getAttachedShaders(program, num_shaders)

        # Unbind program if it's currently bound
        current_program = :gl.getIntegerv(@gl_current_program) |> List.first()

        if current_program == program do
          :gl.useProgram(0)
        end

        # Delete program
        :gl.deleteProgram(program)

        # Delete attached shaders
        Enum.each(shaders, &cleanup_shader/1)

        :ok
    end
  end

  @doc """
  Cleans up a shader.
  """
  def cleanup_shader(shader) when is_integer(shader) do
    # Check if shader exists and is valid
    case :gl.getShaderiv(shader, @gl_delete_status) do
      -1 ->
        {:error, "Invalid shader"}

      _ ->
        :gl.deleteShader(shader)
        :ok
    end
  end

  @doc """
  Creates a program, attaches shaders, links, and returns the link status.
  """
  @spec create_attach_link([shader_id()]) :: {:ok, program_id()} | {:error, String.t()}
  def create_attach_link(shaders) do
    program = :gl.createProgram()
    Enum.each(shaders, &:gl.attachShader(program, &1))
    :gl.linkProgram(program)
    check_link_status(program)
  end

  # ============================================================================
  # UNIFORM HELPER FUNCTIONS
  # ============================================================================

  @doc """
  Get uniform location for a program. Similar to wings_gl:uloc/2.
  Returns the uniform location or -1 if not found.
  """
  @spec get_uniform_location(program_id(), String.t() | charlist()) :: integer()
  def get_uniform_location(program, uniform_name) when is_binary(uniform_name) do
    :gl.getUniformLocation(program, String.to_charlist(uniform_name))
  end

  def get_uniform_location(program, uniform_name) when is_list(uniform_name) do
    :gl.getUniformLocation(program, uniform_name)
  end

  @doc """
  Set uniform value with automatic type detection. Similar to wings_gl:set_uloc/3.
  Supports various EAGL.Math types and basic values.
  """
  @spec set_uniform(program_id(), String.t() | charlist(), uniform_value()) :: :ok
  def set_uniform(program, uniform_name, value) do
    location = get_uniform_location(program, uniform_name)
    set_uniform_at_location(location, value)
  end

  @doc """
  Set uniform value at a specific location with automatic type detection.
  """
  @spec set_uniform_at_location(integer(), uniform_value()) :: :ok | {:error, String.t()}
  def set_uniform_at_location(location, _value) when location < 0 do
    # Invalid location, uniform not found - return error
    {:error, "Invalid uniform location: #{location}"}
  end

  # vec3 uniform
  @spec set_uniform_at_location(integer(), vec3()) :: :ok
  def set_uniform_at_location(location, [{x, y, z}])
      when is_number(x) and is_number(y) and is_number(z) do
    :gl.uniform3f(location, x, y, z)
  end

  # vec2 uniform
  @spec set_uniform_at_location(integer(), vec2()) :: :ok
  def set_uniform_at_location(location, [{x, y}]) when is_number(x) and is_number(y) do
    :gl.uniform2f(location, x, y)
  end

  # vec4 uniform (also handles quaternions which have the same structure)
  @spec set_uniform_at_location(integer(), vec4() | quat()) :: :ok
  def set_uniform_at_location(location, [{x, y, z, w}])
      when is_number(x) and is_number(y) and is_number(z) and is_number(w) do
    :gl.uniform4f(location, x, y, z, w)
  end

  # mat4 uniform (16 element tuple)
  @spec set_uniform_at_location(integer(), mat4()) :: :ok
  def set_uniform_at_location(
        location,
        [{_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _}] = matrix
      ) do
    :gl.uniformMatrix4fv(location, 0, matrix)
  end

  # mat3 uniform (9 element tuple)
  @spec set_uniform_at_location(integer(), mat3()) :: :ok
  def set_uniform_at_location(location, [{_, _, _, _, _, _, _, _, _}] = matrix) do
    :gl.uniformMatrix3fv(location, 0, matrix)
  end

  # mat2 uniform (4 element tuple)
  @spec set_uniform_at_location(integer(), mat2()) :: :ok
  def set_uniform_at_location(location, [{_, _, _, _}] = matrix) do
    :gl.uniformMatrix2fv(location, 0, matrix)
  end

  # Integer uniform (must come before float to avoid pattern matching issues)
  @spec set_uniform_at_location(integer(), integer()) :: :ok
  def set_uniform_at_location(location, value) when is_integer(value) do
    :gl.uniform1i(location, value)
  end

  # Float uniform
  @spec set_uniform_at_location(integer(), float()) :: :ok
  def set_uniform_at_location(location, value) when is_number(value) do
    :gl.uniform1f(location, value)
  end

  # Boolean uniform (as integer)
  @spec set_uniform_at_location(integer(), boolean()) :: :ok
  def set_uniform_at_location(location, value) when is_boolean(value) do
    :gl.uniform1i(location, if(value, do: 1, else: 0))
  end

  @doc """
  Convenience function to set multiple uniforms at once.
  Takes a program and a list of {name, value} tuples where name can be atom or string.
  """
  @spec set_uniforms(program_id(), [{atom() | String.t(), uniform_value()}]) :: :ok
  def set_uniforms(program, uniforms) when is_list(uniforms) do
    Enum.each(uniforms, fn {name, value} ->
      uniform_name = if is_atom(name), do: Atom.to_string(name), else: to_string(name)
      set_uniform(program, uniform_name, value)
    end)
  end

  @doc """
  Convenience function to cache uniform locations for repeated use.
  Returns a map of uniform names to their locations.
  """
  @spec cache_uniform_locations(program_id(), [String.t() | atom()]) :: %{String.t() => integer()}
  def cache_uniform_locations(program, uniform_names) do
    Enum.into(uniform_names, %{}, fn name ->
      uniform_name = if is_atom(name), do: Atom.to_string(name), else: name
      {uniform_name, get_uniform_location(program, uniform_name)}
    end)
  end
end
