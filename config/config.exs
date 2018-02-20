# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :blue_jet,
  ecto_repos: [BlueJet.Repo]

# Configures the endpoint
config :blue_jet, BlueJetWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "wdNdABsV4IpLEClymgU+G6Hb8UXYwFkeDmCnbyC6xunEmhBInx9E0qzEcOrr9mz9",
  render_errors: [view: BlueJetWeb.ErrorView, accepts: ~w(json-api json)],
  pubsub: [name: BlueJet.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure phoenix generators
config :phoenix, :generators,
  binary_id: true

config :phoenix, :format_encoders,
  "json-api": Poison

config :mime, :types, %{
  "application/vnd.api+json" => ["json-api"]
}

defmodule JaKeyFormatter do
  def camelize(key) do
    Inflex.camelize(key, :lower)
  end

  def underscore(key) do
    Inflex.underscore(key)
  end
end

config :ja_serializer,
  key_format: {:custom, JaKeyFormatter, :camelize, :underscore}

config :ex_aws, region: System.get_env("AWS_REGION")

config :sentry,
  dsn: "https://4409d5822eb148cd8b2d7883c4e14a59:f8772da31a684c3684e573e2f6644049@sentry.io/286411",
  environment_name: Mix.env,
  enable_source_code_context: true,
  root_source_code_path: File.cwd!,
  tags: %{
    env: Mix.env
  },
  included_environments: [:prod]

config :blue_jet, BlueJet.Gettext,
  default_locale: "en"

config :blue_jet, BlueJet.GlobalMailer,
  adapter: Bamboo.PostmarkAdapter,
  api_key: System.get_env("POSTMARK_API_KEY")

config :blue_jet, BlueJet.AccountMailer,
  adapter: Bamboo.SMTPAdapter,
  server: System.get_env("SMTP_SERVER"),
  port: System.get_env("SMTP_PORT"),
  username: System.get_env("SMTP_USERNAME"), # or {:system, "SMTP_USERNAME"}
  password: System.get_env("SMTP_PASSWORD"), # or {:system, "SMTP_PASSWORD"}
  tls: :always, # can be `:always` or `:never`
  # allowed_tls_versions: [:"tlsv1", :"tlsv1.1", :"tlsv1.2"], # or {":system", ALLOWED_TLS_VERSIONS"} w/ comma seprated values (e.g. "tlsv1.1,tlsv1.2")
  ssl: false, # can be `true`
  retries: 0

config :blue_jet, :email_regex, ~r/^[A-Za-z0-9._%+-+']+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/

config :blue_jet, :s3, prefix: "uploads"


config :blue_jet, :authorization, BlueJet.Identity.Authorization

config :blue_jet, :identity, %{
  listeners: [BlueJet.Balance.EventHandler, BlueJet.Notification.EventHandler]
}

config :blue_jet, :file_storage, %{
  identity_service: BlueJet.Identity.Service,
}

config :blue_jet, :goods, %{
  identity_service: BlueJet.Identity.Service,
  file_storage_service: BlueJet.FileStorage.Service
}

config :blue_jet, :balance, %{
  stripe_client: BlueJet.Stripe.Client,
  oauth_client: BlueJet.OauthClient,
  identity_service: BlueJet.Identity.Service,
  listeners: [BlueJet.Storefront.EventHandler, BlueJet.Crm.EventHandler]
}

config :blue_jet, :crm, %{
  stripe_client: BlueJet.Stripe.Client,
  identity_service: BlueJet.Identity.Service
}

config :blue_jet, :notification, %{
  identity_service: BlueJet.Identity.Service
}

config :blue_jet, :catalogue, %{
  identity_service: BlueJet.Identity.Service,
  goods_service: BlueJet.Goods.Service,
  file_storage_service: BlueJet.FileStorage.Service
}

config :blue_jet, :data_trading, %{
  goods_service: BlueJet.Goods.Service,
  crm_service: BlueJet.Crm.Service,
  catalogue_service: BlueJet.Catalogue.Service
}

config :blue_jet, :fulfillment, %{
  identity_service: BlueJet.Identity.Service,
  crm_service: BlueJet.Crm.Service,
  goods_service: BlueJet.Goods.Service,
  listeners: [BlueJet.Storefront.EventHandler]
}

config :blue_jet, :storefront, %{
  balance_service: BlueJet.Balance.Service,
  fulfillment_service: BlueJet.Fulfillment.Service,
  catalogue_service: BlueJet.Catalogue.Service,
  identity_service: BlueJet.Identity.Service,
  goods_service: BlueJet.Goods.Service,
  crm_service: BlueJet.Crm.Service,
  listeners: [BlueJet.Notification.EventHandler]
}

# config :stripe, secret_key: System.get_env("STRIPE_SECRET_KEY")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
