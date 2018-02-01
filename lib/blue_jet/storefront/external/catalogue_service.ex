defmodule BlueJet.Storefront.CatalogueService do
  alias BlueJet.Catalogue.{Product, Price}

  @catalogue_service Application.get_env(:blue_jet, :storefront)[:catalogue_service]

  @callback get_product(String.t, map) :: Product.t
  @callback get_price(String.t | map, map) :: Price.t

  defdelegate get_product(id, opts), to: @catalogue_service
  defdelegate get_price(id_or_filter, opts), to: @catalogue_service
end