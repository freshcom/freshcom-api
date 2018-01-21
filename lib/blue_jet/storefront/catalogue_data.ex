defmodule BlueJet.Storefront.CatalogueData do
  alias BlueJet.Catalogue.{Product, Price}

  @catalogue_data Application.get_env(:blue_jet, :storefront)[:catalogue_data]

  @callback get_product(String.t) :: Product.t
  @callback get_price(String.t) :: Price.t

  defdelegate get_product(id), to: @catalogue_data
  defdelegate get_price(id), to: @catalogue_data
end