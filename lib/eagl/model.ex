defmodule EAGL.Model do
  @moduledoc """
  3D model loading and OpenGL integration.

  Handles model loading with automatic VAO creation. Currently only supports OBJ files
  but can be extended to support other file formats.

  ## Usage

      import EAGL.Model

      # Load model directly to VAO (most common)
      {:ok, model} = load_model_to_vao("teapot.obj")

      # Render the model
      :gl.bindVertexArray(model.vao)
      :gl.drawElements(@gl_triangles, model.vertex_count, @gl_unsigned_int, 0)

      # Load model data for custom processing
      {:ok, model_data} = load_model("teapot.obj")

      # Options for normal generation
      {:ok, model} = load_model_to_vao("teapot.obj",
        smooth_normals: true,
        flip_normal_direction: false
      )

      # List available models
      models = list_models()

      # Clean up
      delete_vao(model.vao)
  """

  use EAGL.Const

  @app Mix.Project.config()[:app]

  @doc """
  Loads a model from the priv/models directory.
  Returns the processed model data ready for OpenGL.

  Options:
    - :flip_normal_direction - boolean, set to true to flip normal direction for all models (default: false)
                               This works for both models with existing normals and models that need generated normals.
    - :smooth_normals - boolean, set to true to generate smooth normals by averaging across adjacent faces (default: false)
                        This gives a smoother appearance by eliminating the faceted look.
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
    - :flip_normal_direction - boolean, set to true to flip normal direction for all models (default: false)
                               This works for both models with existing normals and models that need generated normals.
                               Useful when model normals are pointing in the wrong direction for your lighting setup.
    - :smooth_normals - boolean, set to true to generate smooth normals by averaging across adjacent faces (default: false)
                        This gives a smoother appearance by eliminating the faceted look.
                        When true, existing normals are ignored and smooth normals are generated.
  """
  @spec load_model_to_vao(String.t(), keyword()) ::
          {:ok, %{vao: integer(), vertex_count: integer()}} | {:error, String.t()}
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

              :gl.bufferData(
                @gl_array_buffer,
                byte_size(vertex_data),
                vertex_data,
                @gl_static_draw
              )

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

              :gl.bufferData(
                @gl_array_buffer,
                byte_size(normal_data),
                normal_data,
                @gl_static_draw
              )

              # Set up normal attributes (location 2)
              :gl.vertexAttribPointer(2, 3, @gl_float, @gl_false, 0, 0)
              :gl.enableVertexAttribArray(2)

              # Create and populate index buffer
              [ebo] = :gl.genBuffers(1)
              :gl.bindBuffer(@gl_element_array_buffer, ebo)
              index_data = for x <- model_data.indices, into: <<>>, do: <<x::unsigned-32-native>>

              :gl.bufferData(
                @gl_element_array_buffer,
                byte_size(index_data),
                index_data,
                @gl_static_draw
              )

              # Store vertex count
              vertex_count = length(model_data.indices)

              # Unbind VAO
              :gl.bindVertexArray(0)

              {:ok, %{vao: vao, vertex_count: vertex_count}}
            rescue
              e ->
                {:error, "Failed to create VAO: #{Exception.message(e)}"}
            end
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Deletes a vertex array object and its associated buffers.
  """
  @spec delete_vao(integer()) :: :ok
  def delete_vao(vao) do
    :gl.deleteVertexArrays([vao])
    :ok
  end
end
