defmodule BlueJet.Catalogue.Service do
  use BlueJet, :service

  alias BlueJet.Repo
  alias Ecto.{Multi, Changeset}
  alias BlueJet.Catalogue.IdentityService
  alias BlueJet.Catalogue.{Product, ProductCollection, ProductCollectionMembership, Price}

  defp get_account(opts) do
    opts[:account] || IdentityService.get_account(opts)
  end

  def get_product(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    Product.Query.default()
    |> Product.Query.for_account(account.id)
    |> Repo.get_by(fields)
    |> preload(preloads[:path], preloads[:opts])
  end

  # def get_product(id, opts) do
  #   account_id = opts[:account_id] || opts[:account].id
  #   Repo.get_by(Product, id: id, account_id: account_id)
  # end

  # def get_product_by_code(code, opts) do
  #   account_id = opts[:account_id] || opts[:account].id
  #   Repo.get_by(Product, code: code, account_id: account_id)
  # end

  def create_product(fields, opts) do
    account_id = opts[:account_id] || opts[:account].id

    %Product{ account_id: account_id, account: opts[:account] }
    |> Product.changeset(fields)
    |> Repo.insert()
  end

  def update_product(id, fields, opts) do
    account_id = opts[:account_id] || opts[:account].id

    product =
      Product.Query.default()
      |> Product.Query.for_account(account_id)
      |> Repo.get(id)
      |> Map.put(:account, opts[:account])

    with %Product{} <- product,
       changeset = %{ valid?: true } <- Product.changeset(product, fields, opts[:locale])
    do
      {:ok, product} = Repo.transaction(fn ->
        if Changeset.get_change(changeset, :primary) do
          Product.Query.default()
          |> Product.Query.with_parent(product.parent_id)
          |> Repo.update_all(set: [primary: false])
        end

        Repo.update!(changeset)
      end)

      {:ok, product}
    else
      nil -> {:error, :not_found}

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

  def create_product_collection(fields, opts) do
    account_id = opts[:account_id] || opts[:account].id

    %ProductCollection{ account_id: account_id, account: opts[:account] }
    |> ProductCollection.changeset(fields)
    |> Repo.insert()
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