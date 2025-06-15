defmodule EAGL.ShaderTest do
  use ExUnit.Case, async: false
  use EAGL.Const

  import EAGL.Shader
  import EAGL.Math

  # Setup OpenGL context similar to buffer_test.exs
  setup do
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

      {:ok, %{gl_available: true, canvas: gl_canvas, context: gl_context}}
    rescue
      _ -> {:ok, %{gl_available: false}}
    end
  end

  describe "shader creation and compilation" do
    test "create_shader with valid vertex shader", %{gl_available: gl_available} do
      if gl_available do
        # Create a simple test shader file
        shader_content = """
        #version 330 core
        layout (location = 0) in vec3 aPos;
        void main() {
            gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
        }
        """

        # Write to a temporary file in priv/shaders
        priv_dir = :code.priv_dir(:eagl)
        shader_dir = Path.join([priv_dir, "shaders"])
        File.mkdir_p!(shader_dir)
        test_shader_path = Path.join(shader_dir, "test_vertex.glsl")
        File.write!(test_shader_path, shader_content)

        try do
          assert {:ok, shader_id} = create_shader(:vertex, "test_vertex.glsl")
          assert is_integer(shader_id)
          assert shader_id > 0

          # Clean up
          cleanup_shader(shader_id)
        after
          File.rm(test_shader_path)
        end
      else
        assert true
      end
    end

    test "create_shader with valid fragment shader", %{gl_available: gl_available} do
      if gl_available do
        # Create a simple test fragment shader
        shader_content = """
        #version 330 core
        out vec4 FragColor;
        void main() {
            FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
        }
        """

        priv_dir = :code.priv_dir(:eagl)
        shader_dir = Path.join([priv_dir, "shaders"])
        File.mkdir_p!(shader_dir)
        test_shader_path = Path.join(shader_dir, "test_fragment.glsl")
        File.write!(test_shader_path, shader_content)

        try do
          assert {:ok, shader_id} = create_shader(:fragment, "test_fragment.glsl")
          assert is_integer(shader_id)
          assert shader_id > 0

          # Clean up
          cleanup_shader(shader_id)
        after
          File.rm(test_shader_path)
        end
      else
        assert true
      end
    end

    test "create_shader with non-existent file", %{gl_available: gl_available} do
      if gl_available do
        assert {:error, message} = create_shader(:vertex, "non_existent.glsl")
        assert String.contains?(message, "Shader file not found")
      else
        assert true
      end
    end

    test "create_shader with invalid shader source", %{gl_available: gl_available} do
      if gl_available do
        # Create an invalid shader
        invalid_shader_content = """
        #version 330 core
        this is not valid GLSL code
        """

        priv_dir = :code.priv_dir(:eagl)
        shader_dir = Path.join([priv_dir, "shaders"])
        File.mkdir_p!(shader_dir)
        test_shader_path = Path.join(shader_dir, "test_invalid.glsl")
        File.write!(test_shader_path, invalid_shader_content)

        try do
          assert {:error, message} = create_shader(:vertex, "test_invalid.glsl")
          assert String.contains?(message, "Shader compilation failed")
        after
          File.rm(test_shader_path)
        end
      else
        assert true
      end
    end
  end

  describe "shader program creation and linking" do
    test "create_attach_link with valid shaders", %{gl_available: gl_available} do
      if gl_available do
        # Create vertex shader
        vertex_content = """
        #version 330 core
        layout (location = 0) in vec3 aPos;
        void main() {
            gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
        }
        """

        # Create fragment shader
        fragment_content = """
        #version 330 core
        out vec4 FragColor;
        void main() {
            FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
        }
        """

        priv_dir = :code.priv_dir(:eagl)
        shader_dir = Path.join([priv_dir, "shaders"])
        File.mkdir_p!(shader_dir)
        vertex_path = Path.join(shader_dir, "test_link_vertex.glsl")
        fragment_path = Path.join(shader_dir, "test_link_fragment.glsl")

        File.write!(vertex_path, vertex_content)
        File.write!(fragment_path, fragment_content)

        try do
          {:ok, vertex_shader} = create_shader(:vertex, "test_link_vertex.glsl")
          {:ok, fragment_shader} = create_shader(:fragment, "test_link_fragment.glsl")

          assert {:ok, program_id} = create_attach_link([vertex_shader, fragment_shader])
          assert is_integer(program_id)
          assert program_id > 0

          # Clean up
          cleanup_program(program_id)
        after
          File.rm(vertex_path)
          File.rm(fragment_path)
        end
      else
        assert true
      end
    end
  end

  describe "uniform handling" do
    test "get_uniform_location with string name", %{gl_available: gl_available} do
      if gl_available do
        # Create a shader program with uniforms for testing
        vertex_content = """
        #version 330 core
        layout (location = 0) in vec3 aPos;
        uniform mat4 model;
        void main() {
            gl_Position = model * vec4(aPos, 1.0);
        }
        """

        fragment_content = """
        #version 330 core
        out vec4 FragColor;
        uniform vec3 color;
        void main() {
            FragColor = vec4(color, 1.0);
        }
        """

        priv_dir = :code.priv_dir(:eagl)
        shader_dir = Path.join([priv_dir, "shaders"])
        File.mkdir_p!(shader_dir)
        vertex_path = Path.join(shader_dir, "test_uniform_vertex.glsl")
        fragment_path = Path.join(shader_dir, "test_uniform_fragment.glsl")

        File.write!(vertex_path, vertex_content)
        File.write!(fragment_path, fragment_content)

        try do
          {:ok, vertex_shader} = create_shader(:vertex, "test_uniform_vertex.glsl")
          {:ok, fragment_shader} = create_shader(:fragment, "test_uniform_fragment.glsl")
          {:ok, program} = create_attach_link([vertex_shader, fragment_shader])

          :gl.useProgram(program)

          location = get_uniform_location(program, "color")
          assert is_integer(location)
          # Location should be >= 0 for existing uniforms, -1 for non-existent
          assert location >= -1

          # Clean up
          cleanup_program(program)
        after
          File.rm(vertex_path)
          File.rm(fragment_path)
        end
      else
        assert true
      end
    end

    test "get_uniform_location with charlist name", %{gl_available: gl_available} do
      if gl_available do
        vertex_content = """
        #version 330 core
        layout (location = 0) in vec3 aPos;
        uniform mat4 model;
        void main() {
            gl_Position = model * vec4(aPos, 1.0);
        }
        """

        fragment_content = """
        #version 330 core
        out vec4 FragColor;
        uniform vec3 color;
        void main() {
            FragColor = vec4(color, 1.0);
        }
        """

        priv_dir = :code.priv_dir(:eagl)
        shader_dir = Path.join([priv_dir, "shaders"])
        File.mkdir_p!(shader_dir)
        vertex_path = Path.join(shader_dir, "test_charlist_vertex.glsl")
        fragment_path = Path.join(shader_dir, "test_charlist_fragment.glsl")

        File.write!(vertex_path, vertex_content)
        File.write!(fragment_path, fragment_content)

        try do
          {:ok, vertex_shader} = create_shader(:vertex, "test_charlist_vertex.glsl")
          {:ok, fragment_shader} = create_shader(:fragment, "test_charlist_fragment.glsl")
          {:ok, program} = create_attach_link([vertex_shader, fragment_shader])

          :gl.useProgram(program)

          location = get_uniform_location(program, ~c"color")  # charlist
          assert is_integer(location)
          assert location >= -1

          # Clean up
          cleanup_program(program)
        after
          File.rm(vertex_path)
          File.rm(fragment_path)
        end
      else
        assert true
      end
    end

    test "set_uniform with vec2", %{gl_available: gl_available} do
      if gl_available do
        vertex_content = """
        #version 330 core
        layout (location = 0) in vec3 aPos;
        void main() {
            gl_Position = vec4(aPos, 1.0);
        }
        """

        fragment_content = """
        #version 330 core
        out vec4 FragColor;
        uniform vec2 resolution;
        void main() {
            FragColor = vec4(resolution.x / 1920.0, resolution.y / 1080.0, 1.0, 1.0);
        }
        """

        priv_dir = :code.priv_dir(:eagl)
        shader_dir = Path.join([priv_dir, "shaders"])
        File.mkdir_p!(shader_dir)
        vertex_path = Path.join(shader_dir, "test_vec2_vertex.glsl")
        fragment_path = Path.join(shader_dir, "test_vec2_fragment.glsl")

        File.write!(vertex_path, vertex_content)
        File.write!(fragment_path, fragment_content)

        try do
          {:ok, vertex_shader} = create_shader(:vertex, "test_vec2_vertex.glsl")
          {:ok, fragment_shader} = create_shader(:fragment, "test_vec2_fragment.glsl")
          {:ok, program} = create_attach_link([vertex_shader, fragment_shader])

          :gl.useProgram(program)

          resolution = vec2(1920.0, 1080.0)
          assert :ok = set_uniform(program, "resolution", resolution)

          # Clean up
          cleanup_program(program)
        after
          File.rm(vertex_path)
          File.rm(fragment_path)
        end
      else
        assert true
      end
    end

    test "set_uniform with vec4", %{gl_available: gl_available} do
      if gl_available do
        vertex_content = """
        #version 330 core
        layout (location = 0) in vec3 aPos;
        void main() {
            gl_Position = vec4(aPos, 1.0);
        }
        """

        fragment_content = """
        #version 330 core
        out vec4 FragColor;
        uniform vec4 color;
        void main() {
            FragColor = color;
        }
        """

        priv_dir = :code.priv_dir(:eagl)
        shader_dir = Path.join([priv_dir, "shaders"])
        File.mkdir_p!(shader_dir)
        vertex_path = Path.join(shader_dir, "test_vec4_vertex.glsl")
        fragment_path = Path.join(shader_dir, "test_vec4_fragment.glsl")

        File.write!(vertex_path, vertex_content)
        File.write!(fragment_path, fragment_content)

        try do
          {:ok, vertex_shader} = create_shader(:vertex, "test_vec4_vertex.glsl")
          {:ok, fragment_shader} = create_shader(:fragment, "test_vec4_fragment.glsl")
          {:ok, program} = create_attach_link([vertex_shader, fragment_shader])

          :gl.useProgram(program)

          color = vec4(1.0, 0.5, 0.2, 0.8)
          assert :ok = set_uniform(program, "color", color)

          # Clean up
          cleanup_program(program)
        after
          File.rm(vertex_path)
          File.rm(fragment_path)
        end
      else
        assert true
      end
    end

    test "set_uniform with integer", %{gl_available: gl_available} do
      if gl_available do
        vertex_content = """
        #version 330 core
        layout (location = 0) in vec3 aPos;
        void main() {
            gl_Position = vec4(aPos, 1.0);
        }
        """

        fragment_content = """
        #version 330 core
        out vec4 FragColor;
        uniform int textureUnit;
        void main() {
            FragColor = vec4(float(textureUnit) / 10.0, 1.0, 1.0, 1.0);
        }
        """

        priv_dir = :code.priv_dir(:eagl)
        shader_dir = Path.join([priv_dir, "shaders"])
        File.mkdir_p!(shader_dir)
        vertex_path = Path.join(shader_dir, "test_int_vertex.glsl")
        fragment_path = Path.join(shader_dir, "test_int_fragment.glsl")

        File.write!(vertex_path, vertex_content)
        File.write!(fragment_path, fragment_content)

        try do
          {:ok, vertex_shader} = create_shader(:vertex, "test_int_vertex.glsl")
          {:ok, fragment_shader} = create_shader(:fragment, "test_int_fragment.glsl")
          {:ok, program} = create_attach_link([vertex_shader, fragment_shader])

          :gl.useProgram(program)

          assert :ok = set_uniform(program, "textureUnit", 2)

          # Clean up
          cleanup_program(program)
        after
          File.rm(vertex_path)
          File.rm(fragment_path)
        end
      else
        assert true
      end
    end

    test "set_uniform with boolean", %{gl_available: gl_available} do
      if gl_available do
        vertex_content = """
        #version 330 core
        layout (location = 0) in vec3 aPos;
        void main() {
            gl_Position = vec4(aPos, 1.0);
        }
        """

        fragment_content = """
        #version 330 core
        out vec4 FragColor;
        uniform bool enableLighting;
        void main() {
            FragColor = enableLighting ? vec4(1.0, 1.0, 1.0, 1.0) : vec4(0.5, 0.5, 0.5, 1.0);
        }
        """

        priv_dir = :code.priv_dir(:eagl)
        shader_dir = Path.join([priv_dir, "shaders"])
        File.mkdir_p!(shader_dir)
        vertex_path = Path.join(shader_dir, "test_bool_vertex.glsl")
        fragment_path = Path.join(shader_dir, "test_bool_fragment.glsl")

        File.write!(vertex_path, vertex_content)
        File.write!(fragment_path, fragment_content)

        try do
          {:ok, vertex_shader} = create_shader(:vertex, "test_bool_vertex.glsl")
          {:ok, fragment_shader} = create_shader(:fragment, "test_bool_fragment.glsl")
          {:ok, program} = create_attach_link([vertex_shader, fragment_shader])

          :gl.useProgram(program)

          assert :ok = set_uniform(program, "enableLighting", true)
          assert :ok = set_uniform(program, "enableLighting", false)

          # Clean up
          cleanup_program(program)
        after
          File.rm(vertex_path)
          File.rm(fragment_path)
        end
      else
        assert true
      end
    end

    test "cache_uniform_locations", %{gl_available: gl_available} do
      if gl_available do
        vertex_content = """
        #version 330 core
        layout (location = 0) in vec3 aPos;
        uniform mat4 model;
        uniform mat4 view;
        uniform mat4 projection;
        void main() {
            gl_Position = projection * view * model * vec4(aPos, 1.0);
        }
        """

        fragment_content = """
        #version 330 core
        out vec4 FragColor;
        uniform vec3 color;
        uniform float alpha;
        uniform bool useTexture;
        void main() {
            FragColor = vec4(color, alpha);
        }
        """

        priv_dir = :code.priv_dir(:eagl)
        shader_dir = Path.join([priv_dir, "shaders"])
        File.mkdir_p!(shader_dir)
        vertex_path = Path.join(shader_dir, "test_cache_vertex.glsl")
        fragment_path = Path.join(shader_dir, "test_cache_fragment.glsl")

        File.write!(vertex_path, vertex_content)
        File.write!(fragment_path, fragment_content)

        try do
          {:ok, vertex_shader} = create_shader(:vertex, "test_cache_vertex.glsl")
          {:ok, fragment_shader} = create_shader(:fragment, "test_cache_fragment.glsl")
          {:ok, program} = create_attach_link([vertex_shader, fragment_shader])

          :gl.useProgram(program)

          uniform_names = ["model", "view", "projection", "color", "alpha", "useTexture"]
          locations = cache_uniform_locations(program, uniform_names)

          assert is_map(locations)
          assert map_size(locations) == 6

          # Check that all locations are integers
          Enum.each(locations, fn {_name, location} ->
            assert is_integer(location)
            assert location >= -1
          end)

          # Test with atom names too
          atom_names = [:model, :view, :projection, :color, :alpha, :useTexture]
          atom_locations = cache_uniform_locations(program, atom_names)

          assert is_map(atom_locations)
          assert map_size(atom_locations) == 6

          # Clean up
          cleanup_program(program)
        after
          File.rm(vertex_path)
          File.rm(fragment_path)
        end
      else
        assert true
      end
    end

    test "set_uniform with vec3", %{gl_available: gl_available} do
      if gl_available do
        # Create a simple shader program
        vertex_content = """
        #version 330 core
        layout (location = 0) in vec3 aPos;
        void main() {
            gl_Position = vec4(aPos, 1.0);
        }
        """

        fragment_content = """
        #version 330 core
        out vec4 FragColor;
        uniform vec3 color;
        void main() {
            FragColor = vec4(color, 1.0);
        }
        """

        priv_dir = :code.priv_dir(:eagl)
        shader_dir = Path.join([priv_dir, "shaders"])
        File.mkdir_p!(shader_dir)
        vertex_path = Path.join(shader_dir, "test_vec3_vertex.glsl")
        fragment_path = Path.join(shader_dir, "test_vec3_fragment.glsl")

        File.write!(vertex_path, vertex_content)
        File.write!(fragment_path, fragment_content)

        try do
          {:ok, vertex_shader} = create_shader(:vertex, "test_vec3_vertex.glsl")
          {:ok, fragment_shader} = create_shader(:fragment, "test_vec3_fragment.glsl")
          {:ok, program} = create_attach_link([vertex_shader, fragment_shader])

          :gl.useProgram(program)

          color = vec3(1.0, 0.5, 0.2)
          assert :ok = set_uniform(program, "color", color)

          # Clean up
          cleanup_program(program)
        after
          File.rm(vertex_path)
          File.rm(fragment_path)
        end
      else
        assert true
      end
    end

    test "set_uniform with float", %{gl_available: gl_available} do
      if gl_available do
        # Create a simple shader program
        vertex_content = """
        #version 330 core
        layout (location = 0) in vec3 aPos;
        void main() {
            gl_Position = vec4(aPos, 1.0);
        }
        """

        fragment_content = """
        #version 330 core
        out vec4 FragColor;
        uniform float alpha;
        void main() {
            FragColor = vec4(1.0, 1.0, 1.0, alpha);
        }
        """

        priv_dir = :code.priv_dir(:eagl)
        shader_dir = Path.join([priv_dir, "shaders"])
        File.mkdir_p!(shader_dir)
        vertex_path = Path.join(shader_dir, "test_float_vertex.glsl")
        fragment_path = Path.join(shader_dir, "test_float_fragment.glsl")

        File.write!(vertex_path, vertex_content)
        File.write!(fragment_path, fragment_content)

        try do
          {:ok, vertex_shader} = create_shader(:vertex, "test_float_vertex.glsl")
          {:ok, fragment_shader} = create_shader(:fragment, "test_float_fragment.glsl")
          {:ok, program} = create_attach_link([vertex_shader, fragment_shader])

          :gl.useProgram(program)

          assert :ok = set_uniform(program, "alpha", 0.8)

          # Clean up
          cleanup_program(program)
        after
          File.rm(vertex_path)
          File.rm(fragment_path)
        end
      else
        assert true
      end
    end

    test "set_uniforms with multiple values", %{gl_available: gl_available} do
      if gl_available do
        # Create a shader program with multiple uniforms
        vertex_content = """
        #version 330 core
        layout (location = 0) in vec3 aPos;
        uniform mat4 model;
        void main() {
            gl_Position = model * vec4(aPos, 1.0);
        }
        """

        fragment_content = """
        #version 330 core
        out vec4 FragColor;
        uniform vec3 color;
        uniform float alpha;
        uniform bool useTexture;
        void main() {
            FragColor = vec4(color, alpha);
        }
        """

        priv_dir = :code.priv_dir(:eagl)
        shader_dir = Path.join([priv_dir, "shaders"])
        File.mkdir_p!(shader_dir)
        vertex_path = Path.join(shader_dir, "test_multi_vertex.glsl")
        fragment_path = Path.join(shader_dir, "test_multi_fragment.glsl")

        File.write!(vertex_path, vertex_content)
        File.write!(fragment_path, fragment_content)

        try do
          {:ok, vertex_shader} = create_shader(:vertex, "test_multi_vertex.glsl")
          {:ok, fragment_shader} = create_shader(:fragment, "test_multi_fragment.glsl")
          {:ok, program} = create_attach_link([vertex_shader, fragment_shader])

          :gl.useProgram(program)

          uniforms = [
            color: vec3(1.0, 0.0, 0.0),
            alpha: 1.0,
            useTexture: true,
            model: mat4_identity()
          ]

          assert :ok = set_uniforms(program, uniforms)

          # Clean up
          cleanup_program(program)
        after
          File.rm(vertex_path)
          File.rm(fragment_path)
        end
      else
        assert true
      end
    end
  end

  describe "cleanup functions" do
    test "cleanup_shader with valid shader", %{gl_available: gl_available} do
      if gl_available do
        vertex_content = """
        #version 330 core
        layout (location = 0) in vec3 aPos;
        void main() {
            gl_Position = vec4(aPos, 1.0);
        }
        """

        priv_dir = :code.priv_dir(:eagl)
        shader_dir = Path.join([priv_dir, "shaders"])
        File.mkdir_p!(shader_dir)
        test_shader_path = Path.join(shader_dir, "test_cleanup_vertex.glsl")
        File.write!(test_shader_path, vertex_content)

        try do
          {:ok, shader_id} = create_shader(:vertex, "test_cleanup_vertex.glsl")
          assert :ok = cleanup_shader(shader_id)
        after
          File.rm(test_shader_path)
        end
      else
        assert true
      end
    end
  end

  describe "error handling" do
    test "set_uniform_at_location with invalid location" do
      # Should not error, just silently ignore
      assert :ok = set_uniform_at_location(-1, vec3(1.0, 2.0, 3.0))
      assert :ok = set_uniform_at_location(-5, 42.0)
    end
  end
end
