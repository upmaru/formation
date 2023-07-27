defmodule Formation.MixProject do
  use Mix.Project

  def project do
    [
      app: :formation,
      version: "0.11.3",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    """
    Abstractions for managing infrastructural components.
    """
  end

  defp package do
    [
      name: "formation",
      files: ~w(
        lib
        .formatter.exs
        mix.exs
        README*
      ),
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/upmaru/formation"
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:grpc, "~> 0.6"},
      {:lexdee, "~> 2.3"},
      {:postgrex, "~> 0.17.1"},
      {:ecto, "~> 3.10"},

      {:gun, "~> 2.0", override: true},
      {:mint, "~> 1.5", override: true},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:mox, "~> 1.0", only: :test}
    ]
  end
end
