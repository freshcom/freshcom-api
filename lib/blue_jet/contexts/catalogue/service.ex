defmodule BlueJet.Catalogue.Service do
  @service Application.get_env(:blue_jet, :catalogue)[:service]

  @callback list_product(map, map) :: [Product.t()]
  @callback count_product(map, map) :: integer
  @callback create_product(map, map) :: {:ok, Product.t()} | {:error, any}
  @callback get_product(map, map) :: Product.t() | nil
  @callback update_product(String.t() | Product.t(), map, map) ::
              {:ok, Product.t()} | {:error, any}
  @callback delete_product(Strint.t() | Product.t(), map) :: {:ok, Product.t()} | {:error, any}
  @callback delete_all_product(map) :: :ok

  @callback list_product_collection(map, map) :: [ProductCollection.t()]
  @callback count_product_collection(map, map) :: integer
  @callback create_product_collection(map, map) :: {:ok, ProductCollection.t()} | {:error, any}
  @callback get_product_collection(map, map) :: ProductCollection.t() | nil
  @callback update_product_collection(String.t() | ProductCollection.t(), map, map) ::
              {:ok, ProductCollection.t()} | {:error, any}
  @callback delete_product_collection(String.t() | ProductCollection.t(), map) ::
              {:ok, ProductCollection.t()} | {:error, any}
  @callback delete_all_product_collection(map) :: :ok

  @callback list_product_collection_membership(map, map) :: [ProductCollectionMembership.t()]
  @callback count_product_collection_membership(map, map) :: integer
  @callback create_product_collection_membership(map, map) ::
              {:ok, ProductCollectionMembership} | {:error, any}
  @callback get_product_collection_membership(map, map) :: ProductCollectionMembership.t() | nil
  @callback delete_product_collection_membership(
              String.t() | ProductCollectionMembership.t(),
              map
            ) :: {:ok, ProductCollectionMembership.t()} | {:error, any}

  @callback list_price(map, map) :: [Price.t()]
  @callback count_price(map, map) :: integer
  @callback create_price(map, map) :: {:ok, Price.t()} | {:error, any}
  @callback get_price(map, map) :: Price.t() | nil
  @callback update_price(String.t() | Price.t(), map, map) :: {:ok, Price.t()} | {:error, any}
  @callback delete_price(map, map) :: {:ok, Price.t()} | {:error, any}

  defdelegate list_product(params \\ %{}, opts), to: @service
  defdelegate count_product(params \\ %{}, opts), to: @service
  defdelegate create_product(fields, opts), to: @service
  defdelegate get_product(identifiers, opts), to: @service
  defdelegate update_product(id_or_product, fields, opts), to: @service
  defdelegate delete_product(id_or_product, opts), to: @service
  defdelegate delete_all_product(opts), to: @service

  defdelegate list_product_collection(params \\ %{}, opts), to: @service
  defdelegate count_product_collection(params \\ %{}, opts), to: @service
  defdelegate create_product_collection(fields, opts), to: @service
  defdelegate get_product_collection(identifiers, opts), to: @service
  defdelegate update_product_collection(id_or_product_collection, fields, opts), to: @service
  defdelegate delete_product_collection(id_or_product_collection, opts), to: @service
  defdelegate delete_all_product_collection(opts), to: @service

  defdelegate list_product_collection_membership(params \\ %{}, opts), to: @service
  defdelegate count_product_collection_membership(params \\ %{}, opts), to: @service
  defdelegate create_product_collection_membership(fields, opts), to: @service
  defdelegate get_product_collection_membership(identifiers, opts), to: @service
  defdelegate delete_product_collection_membership(id_or_pcm, opts), to: @service

  defdelegate list_price(params \\ %{}, opts), to: @service
  defdelegate count_price(params \\ %{}, opts), to: @service
  defdelegate create_price(fields, opts), to: @service
  defdelegate get_price(identifiers, opts), to: @service
  defdelegate update_price(id_or_price, fields, opts), to: @service
  defdelegate delete_price(id_or_price, opts), to: @service
end
