defmodule BlueJet.Catalogue.Service do
  use BlueJet, :service

  import BlueJet.Utils, only: [atomize_keys: 2]

  alias BlueJet.Catalogue.{Product, ProductCollection, ProductCollectionMembership, Price}

  #
  # MARK: Product
  #
  def list_product(query \\ %{}, opts) do
    account = extract_account(opts)
    pagination = extract_pagination(opts)
    preload = extract_preload(opts)
    filter = atomize_keys(query[:filter], Product.Query.filterable_fields() ++ [:collection_id])
    filter = Map.put(filter, :parent_id, filter[:parent_id])

    Product.Query.default()
    |> Product.Query.search(query[:search], opts[:locale], account.default_locale)
    |> Product.Query.filter_by(filter)
    |> Product.Query.in_collection(filter[:collection_id])
    |> sort_by(desc: :updated_at)
    |> for_account(account.id)
    |> paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preload[:paths], preload[:opts])
  end

  def count_product(query \\ %{}, opts) do
    account = extract_account(opts)
    filter = atomize_keys(query[:filter], Product.Query.filterable_fields() ++ [:collection_id])

    Product.Query.default()
    |> Product.Query.search(query[:search], opts[:locale], account.default_locale)
    |> Product.Query.filter_by(filter)
    |> Product.Query.in_collection(filter[:collection_id])
    |> for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def create_product(fields, opts), do: default_create(Product, fields, opts)
  def get_product(identifiers, opts), do: default_get(Product.Query, identifiers, opts)

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
    |> except(id: product_id)
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

  def delete_all_product(opts), do: default_delete_all(Product.Query, opts)


  #
  # MARK: Price
  #
  def list_price(query \\ %{}, opts), do: default_list(Price.Query, query, opts)
  def count_price(query \\ %{}, opts), do: default_count(Price.Query, query, opts)
  def create_price(fields, opts), do: default_create(Price, fields, opts)

  def get_price(identifiers, opts) do
    account = extract_account(opts)
    preload = extract_preload(opts)
    identifiers = atomize_keys(identifiers, Price.Query.identifiable_fields() ++ [:order_quantity])

    Price.Query.default()
    |> for_account(account.id)
    |> Price.Query.for_order_quantity(identifiers[:order_quantity])
    |> Price.Query.get_by(identifiers)
    |> Repo.one()
    |> preload(preload[:paths], preload[:opts])
  end

  def update_price(nil, _, _), do: {:error, :not_found}

  def update_price(%Price{} = price, fields, opts) do
    account = extract_account(opts)
    preloads = extract_preloads(opts, account)

    changeset =
      %{price | account: account}
      |> Price.changeset(:update, fields, opts[:locale])

    statements =
      Multi.new()
      |> Multi.update(:price, changeset)

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

  @doc """
  Balance the the given price base on its children. After balancing the
  `charge_amount_cents` of the given price will be the sum of all its children's
  `charge_amount_cents`.

  If the given price has no child then this function updates its `charge_amount_cents`
  to `0`.

  Returns the updated price.
  """
  @spec balance_price(Price.t()) :: Price.t()
  def balance_price(%Price{} = price) do
    children = Ecto.assoc(price, :children) |> Repo.all()

    charge_amount_cents =
      Enum.reduce(children, 0, fn child, acc ->
        acc + child.charge_amount_cents
      end)

    price
    |> change(charge_amount_cents: charge_amount_cents)
    |> Repo.update!()
  end

  def delete_price(identifiers, opts), do: default_delete(identifiers, opts, &get_price/2)

  #
  # MARK: Product Collection
  #
  def list_product_collection(query \\ %{}, opts) do
    opts = Map.merge(%{sort: [desc: :sort_index]}, opts)
    default_list(ProductCollection.Query, query, opts)
  end

  def count_product_collection(query \\ %{}, opts), do: default_count(ProductCollection.Query, query, opts)
  def create_product_collection(fields, opts), do: default_create(ProductCollection, fields, opts)

  def get_product_collection(identifiers, opts) do
    default_get(ProductCollection.Query, identifiers, opts)
    |> ProductCollection.put_product_count()
  end

  def update_product_collection(identifiers, fields, opts),
    do: default_update(identifiers, fields, opts, &get_product_collection/2)

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

  def delete_all_product_collection(opts), do: default_delete_all(ProductCollection.Query, opts)

  #
  # MARK: Product Collection Membership
  #
  def list_product_collection_membership(query \\ %{}, opts) do
    account = extract_account(opts)
    pagination = extract_pagination(opts)
    preload = extract_preload(opts)
    filter = atomize_keys(query[:filter], ProductCollectionMembership.Query.filterable_fields() ++ [:product_status])

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
    filter = atomize_keys(query[:filter], ProductCollectionMembership.Query.filterable_fields() ++ [:product_status])

    ProductCollectionMembership.Query.default()
    |> ProductCollectionMembership.Query.search(query[:search], opts[:locale], account.default_locale)
    |> ProductCollectionMembership.Query.filter_by(filter)
    |> ProductCollectionMembership.Query.with_product_status(filter[:product_status])
    |> for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def create_product_collection_membership(fields, opts),
    do: default_create(ProductCollectionMembership, fields, opts)

  def get_product_collection_membership(identifiers, opts),
    do: default_get(ProductCollectionMembership.Query, identifiers, opts)

  def update_product_collection_membership(identifiers, fields, opts),
    do: default_update(identifiers, fields, opts, &get_product_collection_membership/2)

  def delete_product_collection_membership(identifiers, opts),
    do: default_delete(identifiers, opts, &get_product_collection_membership/2)
end
