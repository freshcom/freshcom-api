defmodule BlueJet.Catalogue.Service do
  use BlueJet, :service

  alias Ecto.Multi
  alias BlueJet.Repo
  alias BlueJet.Catalogue.IdentityService
  alias BlueJet.Catalogue.{Product, ProductCollection, ProductCollectionMembership, Price}

  defp get_account(opts) do
    opts[:account] || IdentityService.get_account(opts)
  end

  defp put_account(opts) do
    %{ opts | account: get_account(opts) }
  end

  defp root_only_if_no_parent_id(query, nil), do: Product.Query.root(query)
  defp root_only_if_no_parent_id(query, _), do: query

  defp default_order_if_no_collection_id(query, nil), do: Product.Query.default_order(query)
  defp default_order_if_no_collection_id(query, _), do: query

  def list_product(fields \\ %{}, opts) do
    account = get_account(opts)
    pagination = get_pagination(opts)
    preloads = get_preloads(opts, account)
    filter = get_filter(fields)

    Product.Query.default()
    |> Product.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> Product.Query.filter_by(filter)
    |> Product.Query.in_collection(filter[:collection_id])
    |> root_only_if_no_parent_id(filter[:parent_id])
    |> default_order_if_no_collection_id(filter[:collection_id])
    |> Product.Query.for_account(account.id)
    |> Product.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_product(fields \\ %{}, opts) do
    account = get_account(opts)
    filter = get_filter(fields)

    Product.Query.default()
    |> Product.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> Product.Query.filter_by(filter)
    |> Product.Query.in_collection(filter[:collection_id])
    |> root_only_if_no_parent_id(filter[:parent_id])
    |> Product.Query.for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def create_product(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %Product{ account_id: account.id, account: account }
      |> Product.changeset(:insert, fields)

    with {:ok, product} <- Repo.insert(changeset) do
      product = preload(product, preloads[:path], preloads[:opts])
      {:ok, product}
    else
      other -> other
    end
  end

  def get_product(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    Product.Query.default()
    |> Product.Query.for_account(account.id)
    |> Repo.get_by(fields)
    |> preload(preloads[:path], preloads[:opts])
  end

  def update_product(nil, _, _), do: {:error, :not_found}

  def update_product(product = %Product{}, fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %{ product | account: account }
      |> Product.changeset(:update, fields, opts[:locale])

    statements =
      Multi.new()
      |> Multi.update(:product, changeset)
      |> Multi.run(:processed_product, fn(%{ product: product }) ->
          Product.process(product, changeset)
         end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_product: product }} ->
        product = preload(product, preloads[:path], preloads[:opts])
        {:ok, product}

      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  def update_product(id, fields, opts) do
    opts = put_account(opts)
    account = opts[:account]

    Product
    |> Repo.get_by(id: id, account_id: account.id)
    |> update_product(fields, opts)
  end

  def delete_product(nil, _), do: {:error, :not_found}

  def delete_product(product = %Product{}, opts) do
    account = get_account(opts)

    changeset =
      %{ product | account: account }
      |> Product.changeset(:delete)

    statements =
      Multi.new()
      |> Multi.delete(:product, changeset)
      |> Multi.run(:processed_product, fn(%{ product: product }) ->
          Product.process(product, changeset)
         end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_product: product }} ->
        {:ok, product}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def delete_product(id, opts) do
    opts = put_account(opts)
    account = opts[:account]

    Product
    |> Repo.get_by(id: id, account_id: account.id)
    |> delete_product(opts)
  end

  #
  # MARK: Product Collection
  #
  def list_product_collection(fields \\ %{}, opts) do
    account = get_account(opts)
    pagination = get_pagination(opts)
    preloads = get_preloads(opts, account)
    filter = get_filter(fields)

    ProductCollection.Query.default()
    |> ProductCollection.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> ProductCollection.Query.filter_by(filter)
    |> ProductCollection.Query.for_account(account.id)
    |> ProductCollection.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_product_collection(fields \\ %{}, opts) do
    account = get_account(opts)
    filter = get_filter(fields)

    ProductCollection.Query.default()
    |> ProductCollection.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> ProductCollection.Query.filter_by(filter)
    |> ProductCollection.Query.for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def create_product_collection(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %ProductCollection{ account_id: account.id, account: account }
      |> ProductCollection.changeset(:insert, fields)

    with {:ok, product_collection} <- Repo.insert(changeset) do
      product_collection = preload(product_collection, preloads[:path], preloads[:opts])
      {:ok, product_collection}
    else
      other -> other
    end
  end

  def get_product_collection(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)
    filter = Map.take(fields, [:id, :code])

    ProductCollection.Query.default()
    |> ProductCollection.Query.for_account(account.id)
    |> Repo.get_by(filter)
    |> preload(preloads[:path], preloads[:opts])
  end


  def update_product_collection(nil, _, _), do: {:error, :not_found}

  def update_product_collection(product_collection = %ProductCollection{}, fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %{ product_collection | account: account }
      |> ProductCollection.changeset(:update, fields, opts[:locale])

    with {:ok, product_collection} <- Repo.update(changeset) do
      product_collection = preload(product_collection, preloads[:path], preloads[:opts])
      {:ok, product_collection}
    else
      other -> other
    end
  end

  def update_product_collection(id, fields, opts) do
    opts = put_account(opts)
    account = opts[:account]

    ProductCollection
    |> Repo.get_by(id: id, account_id: account.id)
    |> update_product_collection(fields, opts)
  end

  def delete_product_collection(nil, _), do: {:error, :not_found}

  def delete_product_collection(product_collection = %ProductCollection{}, opts) do
    account = get_account(opts)

    changeset =
      %{ product_collection | account: account }
      |> ProductCollection.changeset(:delete)

    statements =
      Multi.new()
      |> Multi.delete(:product_collection, changeset)
      |> Multi.run(:processed_product_collection, fn(%{ product_collection: product_collection }) ->
          ProductCollection.process(product_collection, changeset)
         end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_product_collection: product_collection }} ->
        {:ok, product_collection}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def delete_product_collection(id, opts) do
    opts = put_account(opts)
    account = opts[:account]

    ProductCollection
    |> Repo.get_by(id: id, account_id: account.id)
    |> delete_product_collection(opts)
  end

  #
  # MARK: Product Collection Membership
  #
  def with_product_status(query, nil), do: query

  def with_product_status(query, product_status) do
    ProductCollectionMembership.Query.with_product_status(query, product_status)
  end

  def list_product_collection_membership(fields \\ %{}, opts) do
    account = get_account(opts)
    pagination = get_pagination(opts)
    preloads = get_preloads(opts, account)
    filter = get_filter(fields)

    ProductCollectionMembership.Query.default()
    |> ProductCollectionMembership.Query.filter_by(filter)
    |> with_product_status(filter[:product_status])
    |> ProductCollectionMembership.Query.for_account(account.id)
    |> ProductCollectionMembership.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_product_collection_membership(fields \\ %{}, opts) do
    account = get_account(opts)
    filter = get_filter(fields)

    ProductCollectionMembership.Query.default()
    |> ProductCollectionMembership.Query.filter_by(filter)
    |> with_product_status(filter[:product_status])
    |> ProductCollectionMembership.Query.for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def create_product_collection_membership(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %ProductCollectionMembership{ account_id: account.id, account: account }
      |> ProductCollectionMembership.changeset(:insert, fields)

    with {:ok, product_collection_membership} <- Repo.insert(changeset) do
      product_collection_membership = preload(product_collection_membership, preloads[:path], preloads[:opts])
      {:ok, product_collection_membership}
    else
      other -> other
    end
  end

  def get_product_collection_membership(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    ProductCollectionMembership.Query.default()
    |> ProductCollectionMembership.Query.for_account(account.id)
    |> Repo.get_by(fields)
    |> preload(preloads[:path], preloads[:opts])
  end

  def delete_product_collection_membership(nil, _), do: {:error, :not_found}

  def delete_product_collection_membership(product_collection_membership = %ProductCollectionMembership{}, opts) do
    account = get_account(opts)

    changeset =
      %{ product_collection_membership | account: account }
      |> ProductCollectionMembership.changeset(:delete)

    with {:ok, product_collection_membership} <- Repo.delete(changeset) do
      {:ok, product_collection_membership}
    else
      other -> other
    end
  end

  def delete_product_collection_membership(id, opts) do
    opts = put_account(opts)
    account = opts[:account]

    ProductCollectionMembership
    |> Repo.get_by(id: id, account_id: account.id)
    |> delete_product_collection_membership(opts)
  end

  #
  # MARK: Price
  #
  def list_price(fields \\ %{}, opts) do
    account = get_account(opts)
    pagination = get_pagination(opts)
    preloads = get_preloads(opts, account)
    filter = get_filter(fields)

    Price.Query.default()
    |> Price.Query.filter_by(filter)
    |> Price.Query.for_account(account.id)
    |> Price.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_price(fields \\ %{}, opts) do
    account = get_account(opts)
    filter = get_filter(fields)

    Price.Query.default()
    |> Price.Query.filter_by(filter)
    |> Price.Query.for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def create_price(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %Price{ account_id: account.id, account: account }
      |> Price.changeset(:insert, fields)

    with {:ok, price} <- Repo.insert(changeset) do
      price = preload(price, preloads[:path], preloads[:opts])
      {:ok, price}
    else
      other -> other
    end
  end

  def get_price(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)
    filter = Map.take(fields, [:id, :code, :status, :product_id, :parent_id])

    Price.Query.default()
    |> Price.Query.with_order_quantity(fields[:order_quantity])
    |> Repo.get_by(filter)
    |> preload(preloads[:path], preloads[:opts])
  end

  def update_price(nil, _, _), do: {:error, :not_found}

  def update_price(price = %Price{}, fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %{ price | account: account }
      |> Price.changeset(:update, fields, opts[:locale])

    statements =
      Multi.new()
      |> Multi.update(:price, changeset)
      |> Multi.run(:processed_price, fn(%{ price: price }) ->
          Price.process(price, changeset)
         end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_price: price }} ->
        price = preload(price, preloads[:path], preloads[:opts])
        {:ok, price}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def update_price(id, fields, opts) do
    opts = put_account(opts)
    account = opts[:account]

    Price
    |> Repo.get_by(id: id, account_id: account.id)
    |> update_price(fields, opts)
  end

  def delete_price(nil, _), do: {:error, :not_found}

  def delete_price(price = %Price{}, opts) do
    account = get_account(opts)

    changeset =
      %{ price | account: account }
      |> Price.changeset(:delete)

    with {:ok, price} <- Repo.delete(changeset) do
      {:ok, price}
    else
      other -> other
    end
  end

  def delete_price(id, opts) do
    opts = put_account(opts)
    account = opts[:account]

    Price
    |> Repo.get_by(id: id, account_id: account.id)
    |> delete_price(opts)
  end
end