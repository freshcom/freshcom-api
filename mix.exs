defmodule BlueJet.Mixfile do
  use Mix.Project

  def project do
    [
      app: :blue_jet,
      version: "0.0.1",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env),
      test_paths: test_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      deps: deps(),
      docs: docs(),
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
  defp elixirc_paths(:test),        do: ["lib", "test/blue_jet/support", "test/support"]
  defp elixirc_paths(:integration), do: ["lib", "test/blue_jet_web/support", "test/support"]
  defp elixirc_paths(_),            do: ["lib"]

  defp test_paths(:integration), do: ["test/blue_jet_web"]
  defp test_paths(_), do: ["test/blue_jet"]

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
      {:timex_ecto, "~> 3.3"},
      {:httpoison, "~> 0.13"},
      {:cmark, "~> 0.7.0", only: :dev},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:uri_query, "~> 0.1.2"},
      {:csv, "~> 2.0.0"},
      {:bbmustache, "~> 1.5.0"},
      {:bamboo, "~> 0.8"},
      {:bamboo_postmark, "~> 0.4"},
      {:bamboo_smtp, "~> 1.4.0"},
      {:sentry, "~> 6.1.0"},
      {:excoveralls, "~> 0.8", only: :test},
      {:mox, "~> 0.3.1", only: [:test, :integration]}
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
      "test": ["ecto.create --quiet", "ecto.migrate", "test"],
      "test.web": ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end

  defp docs do
    [
      source_url: "https://github.com/freshcom/freshcom-api",
      groups_for_modules: groups_for_modules(),
      markdown_processor: ExDoc.Markdown.Cmark
    ]
  end

  defp groups_for_modules do
    [
      "Identity": [
        BlueJet.Identity,
        BlueJet.Identity.Policy,
        BlueJet.Identity.Service,

        BlueJet.Identity.Account,
        BlueJet.Identity.Account.Query,

        BlueJet.Identity.User,
        BlueJet.Identity.User.Query,
        BlueJet.Identity.User.Proxy
      ],
      "Goods": [
        BlueJet.Goods,
        BlueJet.Goods.Policy,
        BlueJet.Goods.Service,

        BlueJet.Goods.Stockable,
        BlueJet.Goods.Stockable.Query,
        BlueJet.Goods.Stockable.Proxy,

        BlueJet.Goods.Unlockable,
        BlueJet.Goods.Unlockable.Query,
        BlueJet.Goods.Unlockable.Proxy,

        BlueJet.Goods.Depositable,
        BlueJet.Goods.Depositable.Query,
        BlueJet.Goods.Depositable.Proxy,
      ],
      "File Storage": [
        BlueJet.FileStorage,
        BlueJet.FileStorage.Policy,
        BlueJet.FileStorage.Service,

        BlueJet.FileStorage.File,
        BlueJet.FileStorage.File.Query,
        BlueJet.FileStorage.File.Proxy,

        BlueJet.FileStorage.FileCollection,
        BlueJet.FileStorage.FileCollection.Query,
        BlueJet.FileStorage.FileCollection.Proxy,

        BlueJet.FileStorage.FileCollectionMembership,
        BlueJet.FileStorage.FileCollectionMembership.Query,
        BlueJet.FileStorage.FileCollectionMembership.Proxy
      ],
      "Notificaton": [
        BlueJet.Notification,
        BlueJet.Notification.Policy,
        BlueJet.Notification.Service,

        BlueJet.Notification.Trigger,
        BlueJet.Notification.Trigger.Query,
        BlueJet.Notification.Trigger.Proxy,
        BlueJet.Notification.Trigger.Factory,

        BlueJet.Notification.EmailTemplate,
        BlueJet.Notification.EmailTemplate.Query,
        BlueJet.Notification.EmailTemplate.Proxy,
        BlueJet.Notification.EmailTemplate.Factory,

        BlueJet.Notification.Email,
        BlueJet.Notification.Email.Query,
        BlueJet.Notification.Email.Proxy,

        BlueJet.Notification.SMSTemplate,
        BlueJet.Notification.SMSTemplate.Query,
        BlueJet.Notification.SMSTemplate.Proxy,
        BlueJet.Notification.SMSTemplate.Factory,

        BlueJet.Notification.SMS,
        BlueJet.Notification.SMS.Query,
        BlueJet.Notification.SMS.Proxy,
      ],
      "CRM": [
        BlueJet.CRM,
        BlueJet.CRM.Policy,
        BlueJet.CRM.Service,

        BlueJet.CRM.Customer,
        BlueJet.CRM.Customer.Query,
        BlueJet.CRM.Customer.Proxy,

        BlueJet.CRM.PointAccount,
        BlueJet.CRM.PointAccount.Query,
        BlueJet.CRM.PointAccount.Proxy,

        BlueJet.CRM.PointTransaction,
        BlueJet.CRM.PointTransaction.Query,
        BlueJet.CRM.PointTransaction.Proxy
      ],
      "Balance": [
        BlueJet.Balance,
        BlueJet.Balance.Policy,
        BlueJet.Balance.Service,

        BlueJet.Balance.Card,
        BlueJet.Balance.Card.Query,
        BlueJet.Balance.Card.Proxy,

        BlueJet.Balance.Payment,
        BlueJet.Balance.Payment.Query,
        BlueJet.Balance.Payment.Proxy,

        BlueJet.Balance.Refund,
        BlueJet.Balance.Refund.Query,
        BlueJet.Balance.Refund.Proxy
      ],
      "Catalogue": [
        BlueJet.Catalogue,
        BlueJet.Catalogue.Policy,
        BlueJet.Catalogue.Service,

        BlueJet.Catalogue.Product,
        BlueJet.Catalogue.Product.Query,
        BlueJet.Catalogue.Product.Proxy,

        BlueJet.Catalogue.Price,
        BlueJet.Catalogue.Price.Query,
        BlueJet.Catalogue.Price.Proxy,

        BlueJet.Catalogue.ProductCollection,
        BlueJet.Catalogue.ProductCollection.Query,
        BlueJet.Catalogue.ProductCollection.Proxy,

        BlueJet.Catalogue.ProductCollectionMembership,
        BlueJet.Catalogue.ProductCollectionMembership.Query,
        BlueJet.Catalogue.ProductCollectionMembership.Proxy
      ]
    ]
  end
end
