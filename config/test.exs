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
  hostname: System.get_env("DB_HOSTNAME"),
  username: System.get_env("DB_USERNAME"),
  pool: Ecto.Adapters.SQL.Sandbox

config :comeonin, :bcrypt_log_rounds, 4

config :blue_jet, BlueJet.GlobalMailer,
  adapter: Bamboo.TestAdapter

config :blue_jet, BlueJet.AccountMailer,
  adapter: Bamboo.TestAdapter

config :blue_jet, :authorization, BlueJet.AuthorizationMock

config :blue_jet, :goods, %{
  identity_service: BlueJet.Goods.IdentityServiceMock
}

config :blue_jet, :balance, %{
  stripe_client: BlueJet.Balance.StripeClientMock,
  identity_service: BlueJet.Balance.IdentityServiceMock,
  listeners: [BlueJet.EventHandlerMock]
}

config :blue_jet, :crm, %{
  identity_service: BlueJet.Crm.IdentityServiceMock
}

config :blue_jet, :catalogue, %{
  identity_service: BlueJet.Catalogue.IdentityServiceMock,
  goods_service: BlueJet.Catalogue.GoodsServiceMock,
  file_storage_service: BlueJet.Catalogue.FileStorageServiceMock
}

config :blue_jet, :storefront, %{
  balance_service: BlueJet.Storefront.BalanceServiceMock,
  distribution_service: BlueJet.Storefront.DistributionServiceMock,
  catalogue_service: BlueJet.Storefront.CatalogueServiceMock,
  identity_service: BlueJet.Storefront.IdentityServiceMock,
  goods_service: BlueJet.Storefront.GoodsServiceMock,
  crm_service: BlueJet.Storefront.CrmServiceMock
}
