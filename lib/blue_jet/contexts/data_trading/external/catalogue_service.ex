defmodule BlueJet.DataTrading.CatalogueService do
  alias BlueJet.Catalogue.{Product, ProductCollection, ProductCollectionMembership, Price}

  @catalogue_service Application.get_env(:blue_jet, :data_trading)[:catalogue_service]

  @callback get_product(String.t, map) :: Product.t | nil
  @callback create_product(map, map) :: {:ok, Product.t} | {:error, any}
  @callback update_product(String.t, map, map) :: {:ok, Product.t} | {:error, any}

  @callback get_product_collection(map, map) :: ProductCollection.t | nil

  @callback get_price(map, map) :: Price.t | nil
  @callback create_price(map, map) :: {:ok, Price.t} | {:error, any}
  @callback update_price(String.t, map, map) :: {:ok, Price.t} | {:error, any}

  @callback get_product_collection_membership(map, map) :: ProductCollectionMembership.t | nil
  @callback create_product_collection_membership(map, map) :: {:ok, ProductCollectionMembership.t} | {:error, any}

  defdelegate get_product(identifiers, opts), to: @catalogue_service
  defdelegate create_product(fields, opts), to: @catalogue_service
  defdelegate update_product(id, fields, opts), to: @catalogue_service

  defdelegate get_product_collection(identifiers, opts), to: @catalogue_service

  defdelegate get_price(identifiers, opts), to: @catalogue_service
  defdelegate create_price(fields, opts), to: @catalogue_service
  defdelegate update_price(id, fields, opts), to: @catalogue_service

  defdelegate get_product_collection_membership(identifiers, opts), to: @catalogue_service
  defdelegate create_product_collection_membership(fields, opts), to: @catalogue_service
end