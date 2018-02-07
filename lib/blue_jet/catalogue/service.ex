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

  def get_product_collection(id, opts) do
    account_id = opts[:account_id] || opts[:account].id
    Repo.get_by(ProductCollection, id: id, account_id: account_id)
  end

  def get_product_collection_by_code(code, opts) do
    account_id = opts[:account_id] || opts[:account].id
    Repo.get_by(ProductCollection, code: code, account_id: account_id)
  end

  def update_product_collection(id, fields, opts) do
    account_id = opts[:account_id] || opts[:account].id

    product_collection =
      ProductCollection.Query.default()
      |> ProductCollection.Query.for_account(account_id)
      |> Repo.get(id)

    if product_collection do
      product_collection
      |> Map.put(:account, opts[:account])
      |> ProductCollection.changeset(fields, opts[:locale])
      |> Repo.update()
    else
      {:error, :not_found}
    end
  end

  def get_price(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    Price.Query.default()
    |> Price.Query.with_order_quantity(fields[:order_quantity])
    |> Repo.get_by(fields)
    |> preload(preloads[:path], preloads[:opts])
  end

  # def get_price(id, opts) do
  #   account_id = opts[:account_id] || opts[:account].id
  #   Repo.get_by(Price, id: id, account_id: account_id)
  # end

  # def get_price_by_code(code, opts) do
  #   account_id = opts[:account_id] || opts[:account].id
  #   Repo.get_by(Price, code: code, account_id: account_id)
  # end

  def create_price(fields, opts) do
    account_id = opts[:account_id] || opts[:account].id

    %Price{ account_id: account_id, account: opts[:account] }
    |> Price.changeset(fields)
    |> Repo.insert()
  end

  def update_price(price = %{}, fields, opts) do
    changeset =
      price
      |> Repo.preload(:parent)
      |> Map.put(:account, opts[:account])
      |> Price.changeset(fields, opts[:locale])

    statements =
      Multi.new()
      |> Multi.update(:price, changeset)
      |> Multi.run(:balanced_price, fn(%{ price: price }) ->
          if price.parent do
            {:ok, Price.balance(price.parent)}
          else
            {:ok, price}
          end
         end)

    case Repo.transaction(statements) do
      {:ok, %{ balanced_price: price }} -> {:ok, price}

      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  def update_price(id, fields, opts) do
    account_id = opts[:account_id] || opts[:account].id

    price =
      Price.Query.default()
      |> Price.Query.for_account(account_id)
      |> Repo.get(id)

    if price do
      update_price(price, fields, opts)
    else
      {:error, :not_found}
    end
  end

  def get_product_collection_membership(%{ collection_id: collection_id, product_id: product_id }, opts) do
    account_id = opts[:account_id] || opts[:account].id

    ProductCollectionMembership
    |> Repo.get_by(collection_id: collection_id, product_id: product_id, account_id: account_id)
  end

  def create_product_collection_membership(fields, opts) do
    account_id = opts[:account_id] || opts[:account].id

    %ProductCollectionMembership{ account_id: account_id, account: opts[:account] }
    |> ProductCollectionMembership.changeset(fields)
    |> Repo.insert()
  end
end