defmodule Formation.MixProject do
  use Mix.Project

  def project do
    [
      app: :formation,
      version: "0.14.3",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      preferred_cli_env: [
        vcr: :test,
        "vcr.delete": :test,
        "vcr.check": :test,
        "vcr.show": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Formation.Application, []}
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
      {:lexdee, "~> 2.3"},
      {:aws, "~> 0.13.0"},
      {:finch, "~> 0.16.0"},
      {:tesla, "~> 1.7.0"},
      {:postgrex, "~> 0.17.1"},
      {:ecto, "~> 3.10"},
      {:mustache, "~> 0.5.0"},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:exvcr, "~> 0.11", only: :test},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:mox, "~> 1.0", only: :test}
    ]
  end
end
