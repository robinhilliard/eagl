defmodule EAGL.Model do
  @moduledoc """
  Helper module for loading 3D model resources and creating OpenGL vertex array objects.
  """

  use EAGL.Const

  @app Mix.Project.config()[:app]

  @doc """
  Loads a model from the priv/models directory.
  Returns the processed model data ready for OpenGL.

  Options:
    - :flip_normal_direction - boolean, set to true to flip generated normal direction (default: false)
  """
  @spec load_model(String.t(), keyword()) :: {:ok, map()} | {:error, String.t()}
  def load_model(filename, opts \\ []) do
    priv_dir = :code.priv_dir(@app)
    model_path = Path.join([priv_dir, "models", filename])

    case File.exists?(model_path) do
      true -> EAGL.ObjLoader.load_obj(model_path, opts)
      false -> {:error, "Model file not found: #{filename}"}
    end
  end

  @doc """
  Lists all available models in the priv/models directory.
  """
  @spec list_models() :: [String.t()]
  def list_models do
    priv_dir = :code.priv_dir(@app)
    model_dir = Path.join(priv_dir, "models")

    case File.ls(model_dir) do
      {:ok, files} -> Enum.filter(files, &String.ends_with?(&1, ".obj"))
      {:error, _} -> []
    end
  end

  @doc """
  Loads a model and creates a VAO with the model data.
  Returns {:ok, %{vao: vao, vertex_count: count}} or {:error, reason}

  The VAO will have the following attributes:
  - Location 0: Vertex positions (vec3)
  - Location 1: Texture coordinates (vec2)
  - Location 2: Normals (vec3)

  Options:
    - :flip_normal_direction - boolean, set to true to flip generated normal direction (default: false)
  """
  @spec load_model_to_vao(String.t(), keyword()) :: {:ok, %{vao: integer(), vertex_count: integer()}} | {:error, String.t()}
  def load_model_to_vao(filename, opts \\ []) do
    case load_model(filename, opts) do
      {:ok, model_data} ->
        # Validate model data before creating VAO
        cond do
          is_nil(model_data.vertices) or length(model_data.vertices) == 0 ->
            {:error, "Invalid model: no vertices found"}
          is_nil(model_data.indices) or length(model_data.indices) == 0 ->
            {:error, "Invalid model: no indices found"}
          true ->
            try do
          # Create and bind VAO
          [vao] = :gl.genVertexArrays(1)
          :gl.bindVertexArray(vao)

          # Create and populate vertex buffer
          [vbo] = :gl.genBuffers(1)
          :gl.bindBuffer(@gl_array_buffer, vbo)
          vertex_data = for x <- model_data.vertices, into: <<>>, do: <<x::float-32-native>>
          :gl.bufferData(@gl_array_buffer, byte_size(vertex_data), vertex_data, @gl_static_draw)

          # Set up vertex position attributes (location 0)
          :gl.vertexAttribPointer(0, 3, @gl_float, @gl_false, 0, 0)
          :gl.enableVertexAttribArray(0)

          # Create and populate texture coordinate buffer
          [tbo] = :gl.genBuffers(1)
          :gl.bindBuffer(@gl_array_buffer, tbo)
          tex_data = for x <- model_data.tex_coords, into: <<>>, do: <<x::float-32-native>>
          :gl.bufferData(@gl_array_buffer, byte_size(tex_data), tex_data, @gl_static_draw)

          # Set up texture coordinate attributes (location 1)
          :gl.vertexAttribPointer(1, 2, @gl_float, @gl_false, 0, 0)
          :gl.enableVertexAttribArray(1)

          # Create and populate normal buffer
          [nbo] = :gl.genBuffers(1)
          :gl.bindBuffer(@gl_array_buffer, nbo)
          normal_data = for x <- model_data.normals, into: <<>>, do: <<x::float-32-native>>
          :gl.bufferData(@gl_array_buffer, byte_size(normal_data), normal_data, @gl_static_draw)

          # Set up normal attributes (location 2)
          :gl.vertexAttribPointer(2, 3, @gl_float, @gl_false, 0, 0)
          :gl.enableVertexAttribArray(2)

          # Create and populate index buffer
          [ebo] = :gl.genBuffers(1)
          :gl.bindBuffer(@gl_element_array_buffer, ebo)
          index_data = for x <- model_data.indices, into: <<>>, do: <<x::unsigned-32-native>>
          :gl.bufferData(@gl_element_array_buffer, byte_size(index_data), index_data, @gl_static_draw)

          # Unbind VAO
          :gl.bindVertexArray(0)

                      {:ok, %{
              vao: vao,
              vertex_count: length(model_data.indices)
            }}
          rescue
            e -> {:error, "Failed to create VAO: #{Exception.message(e)}"}
          end
        end

      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Deletes a VAO and all its associated buffers.
  Note: This function requires an active OpenGL context.
  """
  @spec delete_vao(integer()) :: :ok | {:error, String.t()}
  def delete_vao(vao) do
    try do
      # Check if we have a valid OpenGL context
      case :gl.getError() do
        error when error != 0 ->
          # If there's already an error, the context might be invalid
          # Just try to delete the VAO directly
          :gl.deleteVertexArrays([vao])
        _ ->
          # We have a valid context, do full cleanup
          # Bind VAO to get access to its buffers
          :gl.bindVertexArray(vao)

          # Get buffer names - handle cases where buffers might not exist
          vbo = try do
            {buffer, _, _, _} = :gl.getVertexAttribiv(0, @gl_vertex_attrib_array_buffer_binding)
            buffer
          rescue
            _ -> 0
          end

          tbo = try do
            {buffer, _, _, _} = :gl.getVertexAttribiv(1, @gl_vertex_attrib_array_buffer_binding)
            buffer
          rescue
            _ -> 0
          end

          nbo = try do
            {buffer, _, _, _} = :gl.getVertexAttribiv(2, @gl_vertex_attrib_array_buffer_binding)
            buffer
          rescue
            _ -> 0
          end

          ebo = try do
            [buffer] = :gl.getIntegerv(@gl_element_array_buffer_binding)
            buffer
          rescue
            _ -> 0
          end

          # Delete buffers only if they exist (non-zero)
          if vbo > 0, do: :gl.deleteBuffers([vbo])
          if tbo > 0, do: :gl.deleteBuffers([tbo])
          if nbo > 0, do: :gl.deleteBuffers([nbo])
          if ebo > 0, do: :gl.deleteBuffers([ebo])

          # Unbind and delete VAO
          :gl.bindVertexArray(0)
          :gl.deleteVertexArrays([vao])
      end

            :ok
    rescue
      e ->
        # Check if it's a wx environment error
        if Exception.message(e) =~ "unknown_env" do
          # OpenGL context is not available, skip cleanup
          :ok
        else
          {:error, "Failed to delete VAO: #{Exception.message(e)}"}
        end
    end
  end
end
