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

config :blue_jet, :identity, %{
  service: BlueJet.Identity.ServiceMock,
  listeners: [BlueJet.EventHandlerMock]
}

config :blue_jet, :file_storage, %{
  service: BlueJet.FileStorage.ServiceMock,
  identity_service: BlueJet.FileStorage.IdentityServiceMock,
  s3_client: BlueJet.FileStorage.S3ClientMock
}

config :blue_jet, :goods, %{
  identity_service: BlueJet.Goods.IdentityServiceMock,
  file_storage_service: BlueJet.Goods.FileStorageServiceMock
}

config :blue_jet, :balance, %{
  service: BlueJet.Balance.ServiceMock,
  stripe_client: BlueJet.Balance.StripeClientMock,
  oauth_client: BlueJet.Balance.OauthClientMock,
  identity_service: BlueJet.Balance.IdentityServiceMock,
  listeners: [BlueJet.EventHandlerMock]
}

config :blue_jet, :crm, %{
  service: BlueJet.Crm.ServiceMock,
  stripe_client: BlueJet.Crm.StripeClientMock,
  identity_service: BlueJet.Crm.IdentityServiceMock
}

config :blue_jet, :notification, %{
  identity_service: BlueJet.Notification.IdentityServiceMock
}

config :blue_jet, :catalogue, %{
  service: BlueJet.Catalogue.ServiceMock,
  identity_service: BlueJet.Catalogue.IdentityServiceMock,
  goods_service: BlueJet.Catalogue.GoodsServiceMock,
  file_storage_service: BlueJet.Catalogue.FileStorageServiceMock
}

config :blue_jet, :data_trading, %{
  service: BlueJet.DataTrading.ServiceMock,
  goods_service: BlueJet.DataTrading.GoodsServiceMock,
  crm_service: BlueJet.DataTrading.CrmServiceMock,
  catalogue_service: BlueJet.DataTrading.CatalogueServiceMock,
}

config :blue_jet, :fulfillment, %{
  identity_service: BlueJet.Fulfillment.IdentityServiceMock,
  crm_service: BlueJet.Fulfillment.CrmServiceMock,
  goods_service: BlueJet.Fulfillment.GoodsServiceMock,
  listeners: [BlueJet.EventHandlerMock]
}

config :blue_jet, :storefront, %{
  balance_service: BlueJet.Storefront.BalanceServiceMock,
  fulfillment_service: BlueJet.Storefront.FulfillmentServiceMock,
  catalogue_service: BlueJet.Storefront.CatalogueServiceMock,
  identity_service: BlueJet.Storefront.IdentityServiceMock,
  goods_service: BlueJet.Storefront.GoodsServiceMock,
  crm_service: BlueJet.Storefront.CrmServiceMock
}