defmodule EAGL.ModelTest do
  use ExUnit.Case, async: false
  doctest EAGL.Model

  describe "list_models/0" do
    test "returns list including cube.obj" do
      models = EAGL.Model.list_models()
      assert "cube.obj" in models
      assert "teapot.obj" in models
    end
  end

  describe "load_model/1" do
    test "successfully loads cube model" do
      assert {:ok, model_data} = EAGL.Model.load_model("cube.obj")
      assert is_list(model_data.vertices)
      assert is_list(model_data.normals)
      assert is_list(model_data.indices)
      assert length(model_data.vertices) > 0
      assert length(model_data.normals) > 0
    end

    test "successfully loads teapot model" do
      assert {:ok, model_data} = EAGL.Model.load_model("teapot.obj")
      assert is_list(model_data.vertices)
      assert is_list(model_data.normals)
      assert is_list(model_data.indices)
      assert length(model_data.vertices) > 0
      assert length(model_data.normals) > 0
    end

    test "generates face normals for models without normals (teapot)" do
      assert {:ok, model_data} = EAGL.Model.load_model("teapot.obj")

      # Teapot should have generated normals
      assert length(model_data.normals) > 0

      # Normals should be in groups of 3 (x, y, z)
      assert rem(length(model_data.normals), 3) == 0

      # Check that normals are normalized (should be close to length 1)
      normal_count = div(length(model_data.normals), 3)
      normals_list = Enum.chunk_every(model_data.normals, 3)

      # Test a few normals to ensure they're normalized
      sample_normals = Enum.take(normals_list, 5)
      for [x, y, z] <- sample_normals do
        length = :math.sqrt(x * x + y * y + z * z)
        assert_in_delta(length, 1.0, 0.01, "Normal should be normalized")
      end
    end

    test "preserves existing normals for models that have them (cube)" do
      assert {:ok, model_data} = EAGL.Model.load_model("cube.obj")

      # Cube should have its original normals preserved
      assert length(model_data.normals) > 0

      # Should have proper cube normals (6 faces, each with their own normal)
      normals_list = Enum.chunk_every(model_data.normals, 3)

      # Test that we have expected cube normals
      unique_normals = Enum.uniq(normals_list)
      assert length(unique_normals) >= 6, "Cube should have at least 6 unique normals"
    end

    test "returns error for non-existent model" do
      assert {:error, _reason} = EAGL.Model.load_model("nonexistent.obj")
    end
  end

  describe "load_model_to_vao/1" do
    setup do
      # Skip tests that require OpenGL context if not available
      try do
        :application.start(:wx)
        wx = :wx.new()
        frame = :wxFrame.new(wx, -1, "Test", size: {100, 100})
        gl_canvas = :wxGLCanvas.new(frame, [])
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
        assert {:ok, model} = EAGL.Model.load_model_to_vao("cube.obj")
        assert is_map(model)
        assert Map.has_key?(model, :vao)
        assert Map.has_key?(model, :vertex_count)
        assert is_integer(model.vao)
        assert is_integer(model.vertex_count)
        assert model.vertex_count > 0

        # Clean up
        EAGL.Model.delete_vao(model.vao)
      else
        # Skip test if OpenGL not available
        assert true
      end
    end

    test "successfully loads teapot model to VAO", %{gl_available: gl_available} do
      if gl_available do
        assert {:ok, model} = EAGL.Model.load_model_to_vao("teapot.obj")
        assert is_map(model)
        assert Map.has_key?(model, :vao)
        assert Map.has_key?(model, :vertex_count)
        assert is_integer(model.vao)
        assert is_integer(model.vertex_count)
        assert model.vertex_count > 0

        # Clean up
        EAGL.Model.delete_vao(model.vao)
      else
        # Skip test if OpenGL not available
        assert true
      end
    end

    test "returns error for non-existent model", %{gl_available: gl_available} do
      if gl_available do
        assert {:error, reason} = EAGL.Model.load_model_to_vao("nonexistent.obj")
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
          priv_dir = :code.priv_dir(:eagl)
          model_dir = Path.join(priv_dir, "models")
          test_file = Path.join(model_dir, "test_invalid.obj")
          File.cp!(temp_file, test_file)

          assert {:error, _reason} = EAGL.Model.load_model_to_vao("test_invalid.obj")
        after
          File.rm(temp_file)
          priv_dir = :code.priv_dir(:eagl)
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
        gl_canvas = :wxGLCanvas.new(frame, [])
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
        {:ok, model} = EAGL.Model.load_model_to_vao("cube.obj")
        assert :ok = EAGL.Model.delete_vao(model.vao)
      else
        # Skip test if OpenGL not available
        assert true
      end
    end

    test "handles invalid VAO gracefully", %{gl_available: gl_available} do
      if gl_available do
        # Test with invalid VAO ID
        result = EAGL.Model.delete_vao(99999)
        assert result == :ok or match?({:error, _}, result)
      else
        # Skip test if OpenGL not available
        assert true
      end
    end
  end
end
