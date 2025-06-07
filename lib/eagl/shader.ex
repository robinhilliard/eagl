defmodule EAGL.Shader do
  @moduledoc """
  Module for OpenGL shader management.
  Handles shader creation, compilation, and program linking.
  """

  use EAGL.Const

  @app Mix.Project.config()[:app]

  # Cache shader type values for pattern matching
  @vertex_shader_type @gl_vertex_shader
  @fragment_shader_type @gl_fragment_shader

  @doc """
  Creates and compiles a shader of the specified type with the given source code.
  Returns the shader ID.
  """
  @spec create_shader(non_neg_integer(), String.t()) :: {:ok, non_neg_integer()} | {:error, String.t()}
  def create_shader(shader_type, filename) do
    try do
      # Create shader
      shader = :gl.createShader(shader_type)

      priv_dir = :code.priv_dir(@app)
      model_path = Path.join([priv_dir, "shaders", filename])

      case File.exists?(model_path) do
        true ->
          :gl.shaderSource(shader, [File.read!(model_path)])
          :gl.compileShader(shader)
          case check_compile_status(shader) do
            {:ok, shader} ->
              shader_type_name = case shader_type do
                @vertex_shader_type -> "Vertex"
                @fragment_shader_type -> "Fragment"
                _ -> "Unknown"
              end
              IO.puts("#{shader_type_name} shader compiled successfully")
              {:ok, shader}

            {:error, message} ->
              case shader_type do
                @vertex_shader_type -> "Vertex"
                @fragment_shader_type -> "Fragment"
                _ -> "Unknown"
              end
              IO.puts(message)
              cleanup_shader(shader)
              {:error, message}
          end
        false ->
          {:error, "Shader file not found: #{filename}"}
      end

    rescue
      e ->
        {:error, "Shader creation failed: #{inspect(e)}"}
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
        IO.puts("Program linked successfully")
        {:ok, program}
      _ ->
        log_length = :gl.getProgramiv(program, @gl_info_log_length)
        log = :gl.getProgramInfoLog(program, log_length)
        message = "Program linking failed: #{log}"
        IO.puts(message)
        {:error, message}
    end
  end

  @doc """
  Cleans up a shader program and all its attached shaders.
  """
  def cleanup_program(program) when is_integer(program) do
    # Check if program exists and is valid
    case :gl.getProgramiv(program, @gl_delete_status) do
      -1 -> {:error, "Invalid program"}
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
      -1 -> {:error, "Invalid shader"}
      _ ->
        :gl.deleteShader(shader)
        :ok
    end
  end

  @doc """
  Creates a program, attaches shaders, links, and returns the link status.
  """
  def create_attach_link(shaders) do
    program = :gl.createProgram()
    Enum.each(shaders, &:gl.attachShader(program, &1))
    :gl.linkProgram(program)
    check_link_status(program)
  end


end
