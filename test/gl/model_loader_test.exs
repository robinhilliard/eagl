defmodule GL.ModelLoaderTest do
  use ExUnit.Case, async: false
  doctest GL.ModelLoader

  describe "list_models/0" do
    test "returns list including cube.obj" do
      models = GL.ModelLoader.list_models()
      assert "cube.obj" in models
      assert "teapot.obj" in models
    end
  end

  describe "load_model/1" do
    test "successfully loads cube model" do
      assert {:ok, _model_data} = GL.ModelLoader.load_model("cube.obj")
    end

    test "successfully loads teapot model" do
      assert {:ok, _model_data} = GL.ModelLoader.load_model("teapot.obj")
    end

    test "returns error for non-existent model" do
      assert {:error, _reason} = GL.ModelLoader.load_model("nonexistent.obj")
    end
  end

  describe "load_model_to_vao/1" do
    setup do
      # Skip tests that require OpenGL context if not available
      try do
        :application.start(:wx)
        wx = :wx.new()
        frame = :wxFrame.new(wx, -1, "Test", size: {100, 100})
        gl_canvas = :wxGLCanvas.new(frame, [{:attribList, [16, 5, 0]}])
        :wxFrame.show(frame)
        :timer.sleep(50)
        gl_context = :wxGLContext.new(gl_canvas)
        :wxGLCanvas.setCurrent(gl_canvas, gl_context)

        on_exit(fn ->
          try do
            :wxGLContext.destroy(gl_context)
          rescue
            _ -> :ok
          end
          try do
            :wxFrame.destroy(frame)
          rescue
            _ -> :ok
          end
          try do
            :application.stop(:wx)
          rescue
            _ -> :ok
          end
        end)

        {:ok, %{gl_available: true}}
      rescue
        _ -> {:ok, %{gl_available: false}}
      end
    end

    test "successfully loads cube model to VAO", %{gl_available: gl_available} do
      if gl_available do
        assert {:ok, model} = GL.ModelLoader.load_model_to_vao("cube.obj")
        assert is_map(model)
        assert Map.has_key?(model, :vao)
        assert Map.has_key?(model, :vertex_count)
        assert is_integer(model.vao)
        assert is_integer(model.vertex_count)
        assert model.vertex_count > 0

        # Clean up
        GL.ModelLoader.delete_vao(model.vao)
      else
        # Skip test if OpenGL not available
        assert true
      end
    end

    test "successfully loads teapot model to VAO", %{gl_available: gl_available} do
      if gl_available do
        assert {:ok, model} = GL.ModelLoader.load_model_to_vao("teapot.obj")
        assert is_map(model)
        assert Map.has_key?(model, :vao)
        assert Map.has_key?(model, :vertex_count)
        assert is_integer(model.vao)
        assert is_integer(model.vertex_count)
        assert model.vertex_count > 0

        # Clean up
        GL.ModelLoader.delete_vao(model.vao)
      else
        # Skip test if OpenGL not available
        assert true
      end
    end

    test "returns error for non-existent model", %{gl_available: gl_available} do
      if gl_available do
        assert {:error, reason} = GL.ModelLoader.load_model_to_vao("nonexistent.obj")
        assert is_binary(reason)
        assert String.contains?(reason, "not found")
      else
        # Skip test if OpenGL not available
        assert true
      end
    end

    test "returns error for invalid model file", %{gl_available: gl_available} do
      if gl_available do
        # Create a temporary invalid OBJ file
        invalid_content = "invalid content that is not a valid OBJ file"
        temp_dir = System.tmp_dir!()
        temp_file = Path.join(temp_dir, "invalid.obj")

        try do
          File.write!(temp_file, invalid_content)

          # Copy to priv/models for testing
          priv_dir = :code.priv_dir(:ezgl)
          model_dir = Path.join(priv_dir, "models")
          test_file = Path.join(model_dir, "test_invalid.obj")
          File.cp!(temp_file, test_file)

          assert {:error, _reason} = GL.ModelLoader.load_model_to_vao("test_invalid.obj")
        after
          File.rm(temp_file)
          priv_dir = :code.priv_dir(:ezgl)
          test_file = Path.join([priv_dir, "models", "test_invalid.obj"])
          File.rm(test_file)
        end
      else
        # Skip test if OpenGL not available
        assert true
      end
    end
  end

  describe "delete_vao/1" do
    setup do
      # Skip tests that require OpenGL context if not available
      try do
        :application.start(:wx)
        wx = :wx.new()
        frame = :wxFrame.new(wx, -1, "Test", size: {100, 100})
        gl_canvas = :wxGLCanvas.new(frame, [{:attribList, [16, 5, 0]}])
        :wxFrame.show(frame)
        :timer.sleep(50)
        gl_context = :wxGLContext.new(gl_canvas)
        :wxGLCanvas.setCurrent(gl_canvas, gl_context)

        on_exit(fn ->
          try do
            :wxGLContext.destroy(gl_context)
          rescue
            _ -> :ok
          end
          try do
            :wxFrame.destroy(frame)
          rescue
            _ -> :ok
          end
          try do
            :application.stop(:wx)
          rescue
            _ -> :ok
          end
        end)

        {:ok, %{gl_available: true}}
      rescue
        _ -> {:ok, %{gl_available: false}}
      end
    end

    test "successfully deletes VAO", %{gl_available: gl_available} do
      if gl_available do
        {:ok, model} = GL.ModelLoader.load_model_to_vao("cube.obj")
        assert :ok = GL.ModelLoader.delete_vao(model.vao)
      else
        # Skip test if OpenGL not available
        assert true
      end
    end

    test "handles invalid VAO gracefully", %{gl_available: gl_available} do
      if gl_available do
        # Test with invalid VAO ID
        result = GL.ModelLoader.delete_vao(99999)
        assert result == :ok or match?({:error, _}, result)
      else
        # Skip test if OpenGL not available
        assert true
      end
    end
  end
end
