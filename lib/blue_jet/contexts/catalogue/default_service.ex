defmodule BlueJet.Catalogue.DefaultService do
  use BlueJet, :service

  alias Ecto.Multi
  alias BlueJet.Catalogue.{Product, ProductCollection, ProductCollectionMembership, Price}

  @behaviour BlueJet.Catalogue.Service

  def list_product(fields \\ %{}, opts) do
    account = extract_account(opts)
    pagination = extract_pagination(opts)
    preloads = extract_preloads(opts, account)
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
    |> preload(preloads[:path], preloads[:opts])
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

  def create_product(fields, opts) do
    create(Product, fields, opts)
  end

  def get_product(identifiers, opts) do
    get(Product, identifiers, opts)
  end

  def update_product(nil, _, _), do: {:error, :not_found}

  def update_product(product = %Product{}, fields, opts) do
    account = extract_account(opts)
    preloads = extract_preloads(opts, account)

    changeset =
      %{product | account: account}
      |> Product.changeset(:update, fields, opts[:locale])

    statements =
      Multi.new()
      |> Multi.update(:product, changeset)
      |> Multi.run(:_, fn %{product: product} ->
        Product.reset_primary(product)
      end)

    case Repo.transaction(statements) do
      {:ok, %{product: product}} ->
        product = preload(product, preloads[:path], preloads[:opts])
        {:ok, product}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def update_product(identifiers, fields, opts) do
    get_product(identifiers, Map.merge(opts, %{preloads: %{}}))
    |> update_product(fields, opts)
  end

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
    get_product(identifiers, Map.merge(opts, %{preloads: %{}}))
    |> delete_product(opts)
  end

  def delete_all_product(opts) do
    delete_all(Product, opts)
  end

  #
  # MARK: Product Collection
  #
  def list_product_collection(fields \\ %{}, opts) do
    fields =
      %{sort: [desc: :sort_index]}
      |> Map.merge(fields)

    list(ProductCollection, fields, opts)
  end

  def count_product_collection(fields \\ %{}, opts) do
    count(ProductCollection, fields, opts)
  end

  def create_product_collection(fields, opts) do
    create(ProductCollection, fields, opts)
  end

  def get_product_collection(identifiers, opts) do
    get(ProductCollection, identifiers, opts)
    |> ProductCollection.put_product_count()
  end

  def update_product_collection(nil, _, _), do: {:error, :not_found}

  def update_product_collection(product_collection = %ProductCollection{}, fields, opts) do
    update(product_collection, fields, opts)
  end

  def update_product_collection(identifiers, fields, opts) do
    get_product_collection(identifiers, Map.merge(opts, %{preloads: %{}}))
    |> update_product_collection(fields, opts)
  end

  def delete_product_collection(nil, _), do: {:error, :not_found}

  def delete_product_collection(product_collection = %ProductCollection{}, opts) do
    account = extract_account(opts)

    changeset =
      %{product_collection | account: account}
      |> ProductCollection.changeset(:delete)

    statements =
      Multi.new()
      |> Multi.delete(:product_collection, changeset)
      |> Multi.run(:_, fn %{product_collection: product_collection} ->
        ProductCollection.delete_avatar(product_collection)
      end)

    case Repo.transaction(statements) do
      {:ok, %{product_collection: product_collection}} ->
        {:ok, product_collection}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def delete_product_collection(identifiers, opts) do
    get_product_collection(identifiers, Map.merge(opts, %{preloads: %{}}))
    |> delete_product_collection(opts)
  end

  def delete_all_product_collection(opts = %{account: account = %{mode: "test"}}) do
    batch_size = opts[:batch_size] || 1000

    product_ids =
      ProductCollection.Query.default()
      |> for_account(account.id)
      |> paginate(size: batch_size, number: 1)
      |> id_only()
      |> Repo.all()

    ProductCollection.Query.default()
    |> ProductCollection.Query.filter_by(%{id: product_ids})
    |> Repo.delete_all()

    if length(product_ids) === batch_size do
      delete_all_product_collection(opts)
    else
      :ok
    end
  end

  #
  # MARK: Product Collection Membership
  #
  def list_product_collection_membership(fields \\ %{}, opts) do
    account = extract_account(opts)
    pagination = extract_pagination(opts)
    preloads = extract_preloads(opts, account)
    filter = extract_filter(fields)

    ProductCollectionMembership.Query.default()
    |> ProductCollectionMembership.Query.filter_by(filter)
    |> ProductCollectionMembership.Query.with_product_status(filter[:product_status])
    |> for_account(account.id)
    |> paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_product_collection_membership(fields \\ %{}, opts) do
    account = extract_account(opts)
    filter = extract_filter(fields)

    ProductCollectionMembership.Query.default()
    |> ProductCollectionMembership.Query.filter_by(filter)
    |> ProductCollectionMembership.Query.with_product_status(filter[:product_status])
    |> for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def create_product_collection_membership(fields, opts) do
    create(ProductCollectionMembership, fields, opts)
  end

  def get_product_collection_membership(identifiers, opts) do
    get(ProductCollectionMembership, identifiers, opts)
  end

  def delete_product_collection_membership(nil, _), do: {:error, :not_found}

  def delete_product_collection_membership(
        product_collection_membership = %ProductCollectionMembership{},
        opts
      ) do
    delete(product_collection_membership, opts)
  end

  def delete_product_collection_membership(identifiers, opts) do
    get_product_collection_membership(identifiers, Map.merge(opts, %{preloads: %{}}))
    |> delete_product_collection_membership(opts)
  end

  #
  # MARK: Price
  #
  def list_price(fields \\ %{}, opts) do
    list(Price, fields, opts)
  end

  def count_price(fields \\ %{}, opts) do
    count(Price, fields, opts)
  end

  def create_price(fields, opts) do
    create(Price, fields, opts)
  end

  def get_price(identifiers, opts) do
    account = extract_account(opts)
    preloads = extract_preloads(opts, account)
    filter = extract_nil_filter(identifiers)
    clauses = extract_clauses(identifiers)

    Price.Query.default()
    |> for_account(account.id)
    |> Price.Query.for_order_quantity(identifiers[:order_quantity])
    |> Price.Query.filter_by(filter)
    |> Repo.get_by(clauses)
    |> preload(preloads[:path], preloads[:opts])
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
      {:ok, %{processed_price: price}} ->
        price = preload(price, preloads[:path], preloads[:opts])
        {:ok, price}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def update_price(identifiers, fields, opts) do
    get_price(identifiers, Map.merge(opts, %{preloads: %{}}))
    |> update_price(fields, opts)
  end

  def delete_price(nil, _), do: {:error, :not_found}

  def delete_price(price = %Price{}, opts) do
    delete(price, opts)
  end

  def delete_price(identifiers, opts) do
    get_price(identifiers, Map.merge(opts, %{preloads: %{}}))
    |> delete_price(opts)
  end
end
