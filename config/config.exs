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
config :blue_jet, BlueJet.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "wdNdABsV4IpLEClymgU+G6Hb8UXYwFkeDmCnbyC6xunEmhBInx9E0qzEcOrr9mz9",
  render_errors: [view: BlueJet.ErrorView, accepts: ~w(json)],
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

config :blue_jet, :s3, prefix: 'uploads'

config :ex_aws,
  region: [{:system, "AWS_REGION"}, :instance_role]
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"