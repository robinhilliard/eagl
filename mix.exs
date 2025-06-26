defmodule EAGL.MixProject do
  use Mix.Project

  @version "0.9.0"
  @source_url "https://github.com/robinhilliard/eagl"

  def project do
    [
      app: :eagl,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      included_files: ["priv/**/*"],

      # Hex.pm metadata
      description: description(),
      package: package(),

      # Documentation
      docs: docs(),

      # Testing
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "eagl.test": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :wx, :observer]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Optional dependencies for enhanced functionality
      {:stb_image, "~> 0.6", optional: true},

      # Optional JSON libraries for glTF loading (choose one)
      {:poison, "~> 5.0", optional: true},
      {:jason, "~> 1.4", optional: true},

      # Development and documentation
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end

  defp description do
    """
    EAGL (Easier OpenGL) - A clean, idiomatic Elixir interface for OpenGL programming.
    Features GLM-inspired 3D math, Wings3D-inspired helpers, direct ports of
    LearnOpenGL.com tutorials, and comprehensive glTF/GLB model loading.
    Intended for 3D graphics and game development.

    Optional dependencies: stb_image (texture loading), poison or jason (glTF JSON parsing).
    """
  end

  defp package do
    [
      name: "eagl",
      files: [
        "lib",
        "priv/models",
        "priv/shaders",
        "priv/scripts",
        "mix.exs",
        "README.md",
        "LICENSE"
      ],
      maintainers: ["Robin Hilliard"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Documentation" => "https://hexdocs.pm/eagl",
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
      },
      exclude_patterns: [
        "priv/scripts/debug_*",
        "test/",
        "_build/",
        ".git/",
        ".elixir_ls/",
        "erl_crash.dump"
      ]
    ]
  end

  defp docs do
    [
      name: "EAGL",
      source_ref: "v#{@version}",
      source_url: @source_url,
      homepage_url: @source_url,
      main: "readme",
      logo: "priv/images/eagl_logo.png",
      assets: %{"priv/images" => "assets"},
      extras: [
        "README.md",
        "LICENSE"
      ],
      groups_for_modules: [
        Core: [
          EAGL.Math,
          EAGL.Shader,
          EAGL.Buffer,
          EAGL.Texture,
          EAGL.Error,
          EAGL.Window
        ],
        "Model Loading": [
          EAGL.Model,
          EAGL.ObjLoader
        ],
        Constants: [
          EAGL.Const
        ],
        Examples: [
          EAGL.Examples.Math,
          EAGL.Examples.Teapot
        ],
        "LearnOpenGL Examples": [
          EAGL.Examples.LearnOpenGL.GettingStarted.HelloWindow,
          EAGL.Examples.LearnOpenGL.GettingStarted.HelloWindowClear,
          EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangle,
          EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleIndexed,
          EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise1,
          EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise2,
          EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise3,
          EAGL.Examples.LearnOpenGL.GettingStarted.ShadersUniform,
          EAGL.Examples.LearnOpenGL.GettingStarted.ShadersInterpolation,
          EAGL.Examples.LearnOpenGL.GettingStarted.ShadersClass,
          EAGL.Examples.LearnOpenGL.GettingStarted.ShadersExercise1,
          EAGL.Examples.LearnOpenGL.GettingStarted.ShadersExercise2,
          EAGL.Examples.LearnOpenGL.GettingStarted.ShadersExercise3,
          EAGL.Examples.LearnOpenGL.GettingStarted.Textures
        ]
      ],
      groups_for_docs: [
        "Vector Operations": &(&1[:group] == :vector),
        "Matrix Operations": &(&1[:group] == :matrix),
        "Quaternion Operations": &(&1[:group] == :quaternion),
        "Utility Functions": &(&1[:group] == :utility)
      ]
    ]
  end
end
