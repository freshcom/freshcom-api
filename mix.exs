defmodule BlueJet.Mixfile do
  use Mix.Project

  def project do
    [
      app: :blue_jet,
      version: "0.0.1",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {BlueJet.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.3.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:postgrex, ">= 0.0.0"},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      {:ja_serializer, github: "rbao/ja_serializer", branch: "master"},
      {:inflex, "~> 1.7.0"},
      {:faker, "~> 0.7"},
      {:trans, "~> 2.0"},
      {:ex_aws, "~> 1.0"},
      {:hackney, "~> 1.6"},
      {:sweet_xml, "~> 0.6"},
      {:comeonin, "~> 3.0"},
      {:jose, "~> 1.8.3"},
      {:stripity_stripe, "~> 1.6.0"},
      {:timex_ecto, "~> 3.0"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:uri_query, "~> 0.1.2"},
      {:csv, "~> 2.0.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "test": ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
