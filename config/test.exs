use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :blue_jet, BlueJetWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :blue_jet, BlueJet.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "blue_jet_test",
  hostname: if(System.get_env("CI"), do: "postgres", else: "localhost"),
  username: "postgres",
  pool: Ecto.Adapters.SQL.Sandbox

config :comeonin, :bcrypt_log_rounds, 4