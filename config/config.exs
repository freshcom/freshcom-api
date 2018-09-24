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

config :ex_aws, :retries,
  max_attempts: 3,
  base_backoff_in_ms: 10,
  max_backoff_in_ms: 10_000

config :sentry,
  dsn: System.get_env("SENTRY_DSN"),
  environment_name: System.get_env("RELEASE_LEVEL") || "development",
  enable_source_code_context: true,
  root_source_code_path: File.cwd!,
  tags: %{
    mix_env: Mix.env
  },
  included_environments: ["staging", "production"]

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

config :blue_jet, :phone_regex, ~r/\+(9[976]\d|8[987530]\d|6[987]\d|5[90]\d|42\d|3[875]\d| 2[98654321]\d|9[8543210]|8[6421]|6[6543210]|5[87654321]| 4[987654310]|3[9643210]|2[70]|7|1)\d{1,14}$/

config :blue_jet, :s3, prefix: "uploads"

alias BlueJet.{Balance, Notification, CRM}

config :blue_jet, :event_bus, %{
  "*" => [Notification.EventHandler],
  "identity:account.create.success" => [
    Balance.EventHandler
  ],
  "identity:account.reset.success" => [
    Goods.EventHandler,
    Catalogue.EventHandler,
    FileStorage.EventHandler,
    CRM.EventHandler
  ],
  "identity:user.update.success" => [
    CRM.EventHandler
  ]
}

config :blue_jet, :identity, %{
  listeners: [
    BlueJet.Balance.EventHandler,
    BlueJet.CRM.EventHandler,
    BlueJet.Goods.EventHandler,
    BlueJet.Catalogue.EventHandler,
    BlueJet.DataTrading.EventHandler,
    BlueJet.FileStorage.EventHandler,
    BlueJet.Fulfillment.EventHandler,
    BlueJet.Notification.EventHandler,
    BlueJet.Storefront.EventHandler
  ]
}

config :blue_jet, :file_storage, %{
  identity_service: BlueJet.Identity.Service,
  s3_client: BlueJet.S3.Client,
  cloudfront_client: BlueJet.Cloudfront.Client
}

config :blue_jet, :goods, %{
  identity_service: BlueJet.Identity.Service,
  file_storage_service: BlueJet.FileStorage.Service
}

config :blue_jet, :crm, %{
  identity_service: BlueJet.Identity.Service,
  file_storage_service: BlueJet.FileStorage.Service
}

config :blue_jet, :notification, %{
  identity_service: BlueJet.Identity.Service
}

config :blue_jet, :balance, %{
  service: BlueJet.Balance.DefaultService,
  stripe_client: BlueJet.Stripe.Client,
  oauth_client: BlueJet.OauthClient,
  identity_service: BlueJet.Identity.Service,
  crm_service: BlueJet.CRM.Service,
  listeners: [BlueJet.Storefront.EventHandler]
}

config :blue_jet, :catalogue, %{
  identity_service: BlueJet.Identity.Service,
  goods_service: BlueJet.Goods.Service,
  file_storage_service: BlueJet.FileStorage.Service
}

config :blue_jet, :data_trading, %{
  service: BlueJet.DataTrading.DefaultService,
  identity_service: BlueJet.Identity.Service,
  goods_service: BlueJet.Goods.Service,
  crm_service: BlueJet.CRM.Service,
  catalogue_service: BlueJet.Catalogue.Service
}

config :blue_jet, :fulfillment, %{
  service: BlueJet.Fulfillment.DefaultService,
  identity_service: BlueJet.Identity.Service,
  crm_service: BlueJet.CRM.Service,
  goods_service: BlueJet.Goods.Service,
  listeners: [BlueJet.Storefront.EventHandler]
}

config :blue_jet, :storefront, %{
  service: BlueJet.Storefront.DefaultService,
  balance_service: BlueJet.Balance.Service,
  fulfillment_service: BlueJet.Fulfillment.Service,
  catalogue_service: BlueJet.Catalogue.Service,
  identity_service: BlueJet.Identity.Service,
  goods_service: BlueJet.Goods.Service,
  crm_service: BlueJet.CRM.Service,
  listeners: [BlueJet.Notification.EventHandler]
}

# config :stripe, secret_key: System.get_env("STRIPE_SECRET_KEY")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
