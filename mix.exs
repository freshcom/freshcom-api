defmodule BlueJet.Mixfile do
  use Mix.Project

  def project do
    [
      app: :blue_jet,
      version: "0.0.1",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
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
      {:phoenix, "~> 1.3.2"},
      {:phoenix_pubsub, "~> 1.0.2"},
      {:phoenix_ecto, "~> 3.3"},
      {:ecto, "~> 2.2"},
      {:postgrex, "~> 0.13.5"},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      {:ja_serializer, github: "rbao/ja_serializer", branch: "master"},
      {:inflex, github: "rbao/inflex", branch: "master", override: true},
      {:faker, "~> 0.9"},
      {:trans, "~> 2.0.2"},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:ex_aws_sns, "~> 2.0"},
      {:hackney, "~> 1.8"},
      {:sweet_xml, "~> 0.6"},
      {:comeonin, "~> 3.0"},
      {:jose, "~> 1.8.3"},
      {:timex_ecto, "~> 3.2"},
      {:httpoison, "~> 0.13"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:uri_query, "~> 0.1.2"},
      {:csv, "~> 2.0.0"},
      {:bbmustache, "~> 1.5.0"},
      {:bamboo, "~> 0.8"},
      {:bamboo_postmark, "~> 0.4"},
      {:bamboo_smtp, "~> 1.4.0"},
      {:sentry, "~> 6.1.0"},
      {:excoveralls, "~> 0.8", only: :test},
      {:mox, "~> 0.3.1", only: :test}
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
