defmodule BlueJet.Catalogue.DefaultService do
  use BlueJet, :service

  alias BlueJet.Catalogue.{Product, ProductCollection, ProductCollectionMembership, Price}

  @behaviour BlueJet.Catalogue.Service

  #
  # MARK: Product
  #
  def list_product(fields \\ %{}, opts) do
    account = extract_account(opts)
    pagination = extract_pagination(opts)
    preload = extract_preload(opts)
    filter = extract_filter(fields)

    Product.Query.default()
    |> Product.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> Product.Query.filter_by(filter)
    |> Product.Query.in_collection(filter[:collection_id])
    |> Product.Query.for_parent(filter[:parent_id])
    |> sort_by(desc: :updated_at)
    |> for_account(account.id)
    |> paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preload[:paths], preload[:opts])
  end

  def count_product(fields \\ %{}, opts) do
    account = extract_account(opts)
    filter = extract_filter(fields)

    Product.Query.default()
    |> Product.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> Product.Query.filter_by(filter)
    |> Product.Query.in_collection(filter[:collection_id])
    |> Product.Query.for_parent(filter[:parent_id])
    |> for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def create_product(fields, opts), do: default(:create, Product, fields, opts)
  def get_product(identifiers, opts), do: default(:get, Product, identifiers, opts)

  def update_product(nil, _, _), do: {:error, :not_found}

  def update_product(product = %Product{}, fields, opts) do
    account = extract_account(opts)
    preload = extract_preload(opts)

    changeset =
      %{product | account: account}
      |> Product.changeset(:update, fields, opts[:locale])

    statements =
      Multi.new()
      |> Multi.update(:product, changeset)
      |> Multi.run(:_, fn(_) -> update_related_products(changeset) end)

    case Repo.transaction(statements) do
      {:ok, %{product: product}} ->
        {:ok, preload(product, preload[:paths], preload[:opts])}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def update_product(identifiers, fields, opts) do
    get_product(identifiers, Map.merge(opts, %{preload: %{}}))
    |> update_product(fields, opts)
  end

  defp update_related_products(%{
    data: %{id: product_id, parent_id: parent_id},
    changes: %{primary: true
  }}) when not is_nil(parent_id) do
    Product.Query.default()
    |> Product.Query.filter_by(%{parent_id: parent_id})
    |> Product.Query.except_id(product_id)
    |> Repo.update_all(set: [primary: false])
  end

  defp update_related_products(changeset), do: {:ok, changeset}

  def delete_product(nil, _), do: {:error, :not_found}

  def delete_product(product = %Product{}, opts) do
    account = extract_account(opts)

    changeset =
      %{product | account: account}
      |> Product.changeset(:delete)

    statements =
      Multi.new()
      |> Multi.delete(:product, changeset)
      |> Multi.run(:avatar, fn %{product: product} ->
        Product.Proxy.delete_avatar(product)
      end)

    case Repo.transaction(statements) do
      {:ok, %{product: product}} ->
        {:ok, product}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def delete_product(identifiers, opts) do
    get_product(identifiers, Map.merge(opts, %{preload: %{}}))
    |> delete_product(opts)
  end

  def delete_all_product(opts) do
    delete_all(Product, opts)
  end

  #
  # MARK: Price
  #
  def list_price(query \\ %{}, opts), do: default(:list, Price, query, opts)
  def count_price(query \\ %{}, opts), do: default(:count, Price, query, opts)
  def create_price(fields, opts), do: default(:create, Price, fields, opts)

  def get_price(identifiers, opts) do
    account = extract_account(opts)
    preload = extract_preload(opts)
    filter = extract_nil_filter(identifiers)
    clauses = extract_clauses(identifiers)

    Price.Query.default()
    |> for_account(account.id)
    |> Price.Query.for_order_quantity(identifiers[:order_quantity])
    |> Price.Query.filter_by(filter)
    |> Repo.get_by(Map.drop(clauses, [:order_quantity]))
    |> preload(preload[:paths], preload[:opts])
  end

  def update_price(nil, _, _), do: {:error, :not_found}

  def update_price(price = %Price{}, fields, opts) do
    account = extract_account(opts)
    preloads = extract_preloads(opts, account)

    changeset =
      %{price | account: account}
      |> Price.changeset(:update, fields, opts[:locale])

    statements =
      Multi.new()
      |> Multi.update(:price, changeset)
      |> Multi.run(:parent, fn %{price: price} ->
        Price.balance_parent(price)
      end)

    case Repo.transaction(statements) do
      {:ok, %{price: price}} ->
        price = preload(price, preloads[:path], preloads[:opts])
        {:ok, price}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def update_price(identifiers, fields, opts) do
    get_price(identifiers, Map.merge(opts, %{preload: %{}}))
    |> update_price(fields, opts)
  end

  def delete_price(identifiers, opts), do: default(:delete, identifiers, opts, &get_price/2)

  #
  # MARK: Product Collection
  #
  def list_product_collection(query \\ %{}, opts) do
    opts = Map.merge(%{sort: [desc: :sort_index]}, opts)
    default(:list, ProductCollection, query, opts)
  end

  def count_product_collection(query \\ %{}, opts), do: default(:count, ProductCollection, query, opts)
  def create_product_collection(fields, opts), do: default(:create, ProductCollection, fields, opts)

  def get_product_collection(identifiers, opts) do
    default(:get, ProductCollection, identifiers, opts)
    |> ProductCollection.put_product_count()
  end

  def update_product_collection(identifiers, fields, opts),
    do: default(:update, identifiers, fields, opts, &get_product_collection/2)

  def delete_product_collection(nil, _), do: {:error, :not_found}

  def delete_product_collection(%ProductCollection{} = collection, opts) do
    account = extract_account(opts)

    changeset =
      %{collection | account: account}
      |> ProductCollection.changeset(:delete)

    statements =
      Multi.new()
      |> Multi.delete(:collection, changeset)
      |> Multi.run(:_, fn %{collection: collection} ->
        ProductCollection.Proxy.delete_avatar(collection)
      end)

    case Repo.transaction(statements) do
      {:ok, %{collection: collection}} ->
        {:ok, collection}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def delete_product_collection(identifiers, opts) do
    get_product_collection(identifiers, opts)
    |> delete_product_collection(opts)
  end

  def delete_all_product_collection(opts), do: default(:delete_all, ProductCollection, opts)

  #
  # MARK: Product Collection Membership
  #
  def list_product_collection_membership(query \\ %{}, opts) do
    account = extract_account(opts)
    pagination = extract_pagination(opts)
    preload = extract_preload(opts)
    filter = extract_filter(query)

    ProductCollectionMembership.Query.default()
    |> ProductCollectionMembership.Query.search(query[:search], opts[:locale], account.default_locale)
    |> ProductCollectionMembership.Query.filter_by(filter)
    |> ProductCollectionMembership.Query.with_product_status(filter[:product_status])
    |> for_account(account.id)
    |> paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preload[:paths], preload[:opts])
  end

  def count_product_collection_membership(query \\ %{}, opts) do
    account = extract_account(opts)
    filter = extract_filter(query)

    ProductCollectionMembership.Query.default()
    |> ProductCollectionMembership.Query.search(query[:search], opts[:locale], account.default_locale)
    |> ProductCollectionMembership.Query.filter_by(filter)
    |> ProductCollectionMembership.Query.with_product_status(filter[:product_status])
    |> for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def create_product_collection_membership(fields, opts),
    do: default(:create, ProductCollectionMembership, fields, opts)

  def get_product_collection_membership(identifiers, opts),
    do: default(:get, ProductCollectionMembership, identifiers, opts)

  def delete_product_collection_membership(identifiers, opts),
    do: default(:delete, identifiers, opts, &get_product_collection_membership/2)
end
