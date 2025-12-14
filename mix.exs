defmodule GS1Barcode.MixProject do
  use Mix.Project

  @source_url "https://github.com/AlexGx/gs1_barcode"
  @version "0.0.1"

  def project do
    [
      app: :gs1_barcode,
      version: "0.0.1",
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      docs: docs(),
      package: package(),
      description: description(),
      source_url: @source_url,
      homepage_url: @source_url,
      dialyzer: dialyzer(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def cli do
    [preferred_envs: ["test.setup": :test, test: :test]]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:nimble_parsec, "~> 1.4"},

      # dev and test deps
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.38", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end

  defp aliases do
    [
      lint: ["format", "dialyzer"],
      "cover.html": ["cmd MIX_ENV=test mix coveralls", "cmd open cover/excoveralls.html"]
    ]
  end

  defp package do
    [
      name: "gs1_barcode",
      maintainers: ["Alexander Gubarev"],
      licenses: ["MIT"],
      links: %{GitHub: @source_url},
      files: ~w[lib .formatter.exs mix.exs README* LICENSE*]
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:mix, :ex_unit],
      plt_core_path: "_build/#{Mix.env()}",
      flags: [:error_handling, :missing_return, :underspecs],
      ignore_warnings: ".dialyzer_ignore.exs"
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      extras: docs_guides(),
      groups_for_modules: []
    ]
  end

  defp docs_guides do
    [
      "README.md",
      "guides/installation.md"
    ]
  end

  defp description do
    """
    GS1 lib for parsing, validation and formatting.
    """
  end
end
