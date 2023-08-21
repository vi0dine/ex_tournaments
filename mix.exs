defmodule ExTournaments.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_tournaments,
      version: "0.2.7",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "ExTournaments",
      source_url: "https://github.com/vi0dine/ex_tournaments",
      test_coverage: [
        summary: [threshold: 90]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ExTournaments.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.4"},
      {:typed_struct, "~> 0.3.0"},
      {:rustler, "~> 0.29.1"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev], runtime: false},
      {:doctor, "~> 0.21.0", only: :dev},
      {:versioce, "~> 2.0.0", only: :dev},
      {:git_cli, "~> 0.3.0", only: :dev},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "Library to assist tournaments organizers in creating and managing participants pairing."
  end

  defp package() do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/vi0dine/ex_tournaments"},
      files: ~w(lib priv native mix.exs README.md CHANGELOG.md)
    ]
  end
end
