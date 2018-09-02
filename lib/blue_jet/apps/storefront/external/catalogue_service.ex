defmodule BlueJet.Storefront.CatalogueService do
  alias BlueJet.Catalogue.{Product, Price}

  @catalogue_service Application.get_env(:blue_jet, :storefront)[:catalogue_service]

  @callback list_product(map, map) :: list
  @callback get_product(map, map) :: Product.t | nil
  @callback get_price(map, map) :: Price.t | nil

  defdelegate list_product(fields, opts), to: @catalogue_service
  defdelegate get_product(fields, opts), to: @catalogue_service
  defdelegate get_price(fields, opts), to: @catalogue_service
end