defmodule EAGL.BufferTest do
  use ExUnit.Case
  doctest EAGL.Buffer

  describe "create_position_array/1" do
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

    test "creates VAO and VBO for triangle vertices", %{gl_available: gl_available} do
      if gl_available do
        vertices = [-0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0]
        {vao, vbo} = EAGL.Buffer.create_position_array(vertices)

        assert is_integer(vao)
        assert is_integer(vbo)
        assert vao > 0
        assert vbo > 0

        # Clean up
        EAGL.Buffer.delete_vertex_array(vao, vbo)
      else
        # Skip test if OpenGL not available
        assert true
      end
    end
  end


end
