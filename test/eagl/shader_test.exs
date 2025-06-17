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
          assert {:ok, shader_id} = create_shader(@gl_vertex_shader, "test_vertex.glsl")
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
          assert {:ok, shader_id} = create_shader(@gl_fragment_shader, "test_fragment.glsl")
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
        assert {:error, message} = create_shader(@gl_vertex_shader, "non_existent.glsl")
        assert String.contains?(message, "Failed to read shader file")
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
          assert {:error, message} = create_shader(@gl_vertex_shader, "test_invalid.glsl")
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
          {:ok, vertex_shader} = create_shader(@gl_vertex_shader, "test_link_vertex.glsl")
          {:ok, fragment_shader} = create_shader(@gl_fragment_shader, "test_link_fragment.glsl")

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
          {:ok, vertex_shader} = create_shader(@gl_vertex_shader, "test_uniform_vertex.glsl")

          {:ok, fragment_shader} =
            create_shader(@gl_fragment_shader, "test_uniform_fragment.glsl")

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
          {:ok, vertex_shader} = create_shader(@gl_vertex_shader, "test_charlist_vertex.glsl")

          {:ok, fragment_shader} =
            create_shader(@gl_fragment_shader, "test_charlist_fragment.glsl")

          {:ok, program} = create_attach_link([vertex_shader, fragment_shader])

          :gl.useProgram(program)

          # charlist
          location = get_uniform_location(program, ~c"color")
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
          {:ok, vertex_shader} = create_shader(@gl_vertex_shader, "test_vec2_vertex.glsl")
          {:ok, fragment_shader} = create_shader(@gl_fragment_shader, "test_vec2_fragment.glsl")
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
          {:ok, vertex_shader} = create_shader(@gl_vertex_shader, "test_vec4_vertex.glsl")
          {:ok, fragment_shader} = create_shader(@gl_fragment_shader, "test_vec4_fragment.glsl")
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
          {:ok, vertex_shader} = create_shader(@gl_vertex_shader, "test_int_vertex.glsl")
          {:ok, fragment_shader} = create_shader(@gl_fragment_shader, "test_int_fragment.glsl")
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
          {:ok, vertex_shader} = create_shader(@gl_vertex_shader, "test_bool_vertex.glsl")
          {:ok, fragment_shader} = create_shader(@gl_fragment_shader, "test_bool_fragment.glsl")
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
          {:ok, vertex_shader} = create_shader(@gl_vertex_shader, "test_cache_vertex.glsl")
          {:ok, fragment_shader} = create_shader(@gl_fragment_shader, "test_cache_fragment.glsl")
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
          {:ok, vertex_shader} = create_shader(@gl_vertex_shader, "test_vec3_vertex.glsl")
          {:ok, fragment_shader} = create_shader(@gl_fragment_shader, "test_vec3_fragment.glsl")
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
          {:ok, vertex_shader} = create_shader(@gl_vertex_shader, "test_float_vertex.glsl")
          {:ok, fragment_shader} = create_shader(@gl_fragment_shader, "test_float_fragment.glsl")
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
          {:ok, vertex_shader} = create_shader(@gl_vertex_shader, "test_multi_vertex.glsl")
          {:ok, fragment_shader} = create_shader(@gl_fragment_shader, "test_multi_fragment.glsl")
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
          {:ok, shader_id} = create_shader(@gl_vertex_shader, "test_cleanup_vertex.glsl")
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
      # Should return error for invalid locations
      assert {:error, _} = set_uniform_at_location(-1, vec3(1.0, 2.0, 3.0))
      assert {:error, _} = set_uniform_at_location(-5, 42.0)
    end
  end

  describe "comprehensive uniform testing" do
    test "set_uniform with EAGL.Math vectors", %{gl_available: gl_available} do
      if gl_available do
        # Create a test program with various uniform types
        vertex_content = """
        #version 330 core
        layout (location = 0) in vec3 aPos;
        uniform vec2 test_vec2;
        uniform vec3 test_vec3;
        uniform vec4 test_vec4;
        uniform mat3 test_mat3;
        uniform mat4 test_mat4;
        uniform float test_float;
        uniform int test_int;
        uniform bool test_bool;
        void main() {
            vec4 pos = vec4(aPos, 1.0);
            pos.xy += test_vec2 * 0.001;
            pos.xyz += test_vec3 * 0.001;
            pos += test_vec4 * 0.001;
            pos = test_mat4 * pos;
            pos.xyz = test_mat3 * pos.xyz;
            pos.x += test_float * 0.001;
            pos.y += float(test_int) * 0.001;
            pos.z += float(test_bool) * 0.001;
            gl_Position = pos;
        }
        """

        fragment_content = """
        #version 330 core
        out vec4 FragColor;
        void main() {
            FragColor = vec4(1.0, 0.5, 0.2, 1.0);
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
          {:ok, vertex_shader} = create_shader(@gl_vertex_shader, "test_uniform_vertex.glsl")

          {:ok, fragment_shader} =
            create_shader(@gl_fragment_shader, "test_uniform_fragment.glsl")

          {:ok, program} = create_attach_link([vertex_shader, fragment_shader])

          :gl.useProgram(program)

          # Test vec2
          assert :ok = set_uniform(program, "test_vec2", vec2(1.0, 2.0))

          # Test vec3
          assert :ok = set_uniform(program, "test_vec3", vec3(1.0, 2.0, 3.0))

          # Test vec4
          assert :ok = set_uniform(program, "test_vec4", vec4(1.0, 2.0, 3.0, 4.0))

          # Test float
          assert :ok = set_uniform(program, "test_float", 42.0)

          # Test int
          assert :ok = set_uniform(program, "test_int", 42)

          # Test bool
          assert :ok = set_uniform(program, "test_bool", true)
          assert :ok = set_uniform(program, "test_bool", false)

          # Test matrix types
          identity_mat3 = mat3_identity()
          assert :ok = set_uniform(program, "test_mat3", identity_mat3)

          identity_mat4 = mat4_identity()
          assert :ok = set_uniform(program, "test_mat4", identity_mat4)

          cleanup_program(program)
        after
          File.rm(vertex_path)
          File.rm(fragment_path)
        end
      else
        assert true
      end
    end

    test "set_uniforms batch setting", %{gl_available: gl_available} do
      if gl_available do
        vertex_content = """
        #version 330 core
        layout (location = 0) in vec3 aPos;
        uniform vec3 position;
        uniform vec3 color;
        uniform float scale;
        void main() {
            gl_Position = vec4(aPos * scale + position, 1.0);
        }
        """

        fragment_content = """
        #version 330 core
        uniform vec3 color;
        out vec4 FragColor;
        void main() {
            FragColor = vec4(color, 1.0);
        }
        """

        priv_dir = :code.priv_dir(:eagl)
        shader_dir = Path.join([priv_dir, "shaders"])
        File.mkdir_p!(shader_dir)
        vertex_path = Path.join(shader_dir, "test_batch_vertex.glsl")
        fragment_path = Path.join(shader_dir, "test_batch_fragment.glsl")

        File.write!(vertex_path, vertex_content)
        File.write!(fragment_path, fragment_content)

        try do
          {:ok, vs} = create_shader(@gl_vertex_shader, "test_batch_vertex.glsl")
          {:ok, fs} = create_shader(@gl_fragment_shader, "test_batch_fragment.glsl")
          {:ok, program} = create_attach_link([vs, fs])

          :gl.useProgram(program)

          # Test batch uniform setting
          uniforms = [
            {"position", vec3(1.0, 2.0, 3.0)},
            {"color", vec3(1.0, 0.5, 0.2)},
            {"scale", 2.0}
          ]

          assert :ok = set_uniforms(program, uniforms)

          cleanup_program(program)
        after
          File.rm(vertex_path)
          File.rm(fragment_path)
        end
      else
        assert true
      end
    end

    test "get_uniform_location and error handling", %{gl_available: gl_available} do
      if gl_available do
        vertex_content = """
        #version 330 core
        layout (location = 0) in vec3 aPos;
        uniform vec3 valid_uniform;
        void main() {
            gl_Position = vec4(aPos + valid_uniform, 1.0);
        }
        """

        fragment_content = """
        #version 330 core
        out vec4 FragColor;
        void main() {
            FragColor = vec4(1.0, 0.5, 0.2, 1.0);
        }
        """

        priv_dir = :code.priv_dir(:eagl)
        shader_dir = Path.join([priv_dir, "shaders"])
        File.mkdir_p!(shader_dir)
        vertex_path = Path.join(shader_dir, "test_location_vertex.glsl")
        fragment_path = Path.join(shader_dir, "test_location_fragment.glsl")

        File.write!(vertex_path, vertex_content)
        File.write!(fragment_path, fragment_content)

        try do
          {:ok, vs} = create_shader(@gl_vertex_shader, "test_location_vertex.glsl")
          {:ok, fs} = create_shader(@gl_fragment_shader, "test_location_fragment.glsl")
          {:ok, program} = create_attach_link([vs, fs])

          # Test valid uniform location
          location = get_uniform_location(program, "valid_uniform")
          assert is_integer(location)
          assert location >= 0

          # Test invalid uniform location
          invalid_location = get_uniform_location(program, "invalid_uniform")
          assert invalid_location == -1

          # Test setting uniform at valid location
          assert :ok = set_uniform_at_location(location, vec3(1.0, 2.0, 3.0))

          # Test setting uniform at invalid location (should return error)
          assert {:error, _} = set_uniform_at_location(-1, vec3(1.0, 2.0, 3.0))

          cleanup_program(program)
        after
          File.rm(vertex_path)
          File.rm(fragment_path)
        end
      else
        assert true
      end
    end

    test "cache_uniform_locations helper", %{gl_available: gl_available} do
      if gl_available do
        vertex_content = """
        #version 330 core
        layout (location = 0) in vec3 aPos;
        uniform vec3 position;
        uniform vec3 color;
        uniform float scale;
        void main() {
            gl_Position = vec4(aPos * scale + position, 1.0);
        }
        """

        fragment_content = """
        #version 330 core
        uniform vec3 color;
        out vec4 FragColor;
        void main() {
            FragColor = vec4(color, 1.0);
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
          {:ok, vs} = create_shader(@gl_vertex_shader, "test_cache_vertex.glsl")
          {:ok, fs} = create_shader(@gl_fragment_shader, "test_cache_fragment.glsl")
          {:ok, program} = create_attach_link([vs, fs])

          # Test caching uniform locations
          uniform_names = ["position", "color", "scale", "invalid_uniform"]
          locations = cache_uniform_locations(program, uniform_names)

          assert is_map(locations)
          assert Map.has_key?(locations, "position")
          assert Map.has_key?(locations, "color")
          assert Map.has_key?(locations, "scale")
          assert Map.has_key?(locations, "invalid_uniform")

          # Valid uniforms should have non-negative locations
          assert locations["position"] >= 0
          assert locations["color"] >= 0
          assert locations["scale"] >= 0

          # Invalid uniform should have -1
          assert locations["invalid_uniform"] == -1

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
end
