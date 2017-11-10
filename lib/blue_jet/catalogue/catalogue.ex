defmodule BlueJet.Catalogue do
  use BlueJet, :context

  alias Ecto.Changeset
  alias BlueJet.Identity
  alias BlueJet.FileStorage

  alias BlueJet.Catalogue.Product
  alias BlueJet.Catalogue.ProductItem
  alias BlueJet.Catalogue.Price

  ######
  # Product
  ######
  def list_product(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "catalogue.list_product") do
      do_list_product(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_list_product(request = %AccessRequest{ vas: %{ account_id: account_id }, filter: filter, pagination: pagination }) do
    query =
      Product.Query.default()
      |> search([:name], request.search, request.locale)
      |> filter_by(status: filter[:status], item_mode: filter[:item_mode], parent_id: filter[:parent_id])

    query = if filter[:parent_id] do
      query |> Product.Query.for_account(account_id)
    else
      query
      |> Product.Query.root()
      |> Product.Query.for_account(account_id)
    end

    result_count = Repo.aggregate(query, :count, :id)

    total_query = Product |> Product.Query.for_account(account_id)
    total_count = Repo.aggregate(total_query, :count, :id)

    query = paginate(query, size: pagination[:size], number: pagination[:number])

    products =
      Repo.all(query)
      |> Repo.preload(Product.Query.preloads(request.preloads))
      |> Translation.translate(request.locale)

    response = %AccessResponse{
      meta: %{
        total_count: total_count,
        result_count: result_count,
      },
      data: products
    }

    {:ok, response}
  end

  def create_product(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "catalogue.create_product") do
      do_create_product(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_create_product(request = %{ vas: vas }) do
    fields = Map.merge(request.fields, %{ "account_id" => vas[:account_id] })
    changeset = Product.changeset(%Product{}, fields)

    with {:ok, product} <- Repo.insert(changeset) do
      product = Repo.preload(product, Product.Query.preloads(request.preloads))
      {:ok, %AccessResponse{ data: product }}
    else
      {:error, changeset} ->
        errors = Enum.into(changeset.errors, %{})
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  def get_product(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "catalogue.get_product") do
      do_get_product(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_get_product(request = %AccessRequest{ vas: vas, params: %{ product_id: product_id } }) do
    product = Product |> Product.Query.for_account(vas[:account_id]) |> Repo.get(product_id)

    if product do
      product =
        product
        |> Repo.preload(Product.Query.preloads(request.preloads))
        |> Translation.translate(request.locale)

      {:ok, %AccessResponse{ data: product }}
    else
      {:error, :not_found}
    end
  end

  def update_product(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "catalogue.update_product") do
      do_update_product(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_update_product(request = %AccessRequest{ vas: vas, params: %{ product_id: product_id }}) do
    product = Product |> Product.Query.for_account(vas[:account_id]) |> Repo.get(product_id)

    with %Product{} <- product,
         changeset = %Changeset{ valid?: true } <- Product.changeset(product, request.fields, request.locale)
    do
      {:ok, product} = Repo.transaction(fn ->
        if Changeset.get_change(changeset, :primary) do
          parent_id = product.parent_id
          from(pi in Product, where: pi.parent_id == ^parent_id)
          |> Repo.update_all(set: [primary: false])
        end

        Repo.update!(changeset)
      end)

      product =
        product
        |> Repo.preload(Product.Query.preloads(request.preloads))
        |> Translation.translate(request.locale)

      {:ok, %AccessResponse{ data: product }}
    else
      nil -> {:error, :not_found}
      changeset = %Changeset{} ->
        errors = Enum.into(changeset.errors, %{})
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  def delete_product(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "catalogue.delete_product") do
      do_delete_product(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_delete_product(%AccessRequest{ vas: vas, params: %{ product_id: product_id } }) do
    product = Product |> Product.Query.for_account(vas[:account_id]) |> Repo.get(product_id)

    cond do
      product && product.avatar_id ->
        Repo.transaction(fn ->
          FileStorage.do_delete_external_file(%AccessRequest{
            vas: vas,
            params: %{ external_file_id: product.avatar_id }
          })
          Repo.delete!(product)
        end)
      product ->
        Repo.delete!(product)
      !product ->
        {:error, :not_found}
    end
  end

  #####
  # Price
  #####
  def list_price(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "catalogue.list_price") do
      do_list_price(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_list_price(request = %AccessRequest{ vas: %{ account_id: account_id }, filter: filter, pagination: pagination }) do
    query =
      Price.Query.default()
      |> search([:name, :id], request.search, request.locale)
      |> filter_by(product_id: filter[:product_id], label: filter[:label])
      |> Price.Query.for_account(account_id)
    result_count = Repo.aggregate(query, :count, :id)

    total_query = Price |> Price.Query.for_account(account_id)
    total_count = Repo.aggregate(total_query, :count, :id)

    query = paginate(query, size: pagination[:size], number: pagination[:number])

    prices =
      Repo.all(query)
      |> Repo.preload(Price.Query.preloads(request.preloads))
      |> Translation.translate(request.locale)

    response = %AccessResponse{
      meta: %{
        total_count: total_count,
        result_count: result_count,
      },
      data: prices
    }

    {:ok, response}
  end

  def create_price(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "catalogue.create_price") do
      do_create_price(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_create_price(request = %AccessRequest{ vas: vas }) do
    fields = Map.merge(request.fields, %{ "account_id" => vas[:account_id] })
    changeset = Price.changeset(%Price{}, fields)

    with {:ok, price} <- Repo.insert(changeset) do
      price = Repo.preload(price, Price.Query.preloads(request.preloads))
      {:ok, %AccessResponse{ data: price }}
    else
      {:error, changeset} ->
        errors = Enum.into(changeset.errors, %{})
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  def get_price(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "catalogue.get_price") do
      do_get_price(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_get_price(request = %AccessRequest{ vas: vas, params: %{ price_id: price_id } }) do
    price = Price |> Price.Query.for_account(vas[:account_id]) |> Repo.get(price_id)

    if price do
      price =
        price
        |> Repo.preload(Price.Query.preloads(request.preloads))
        |> Translation.translate(request.locale)

      {:ok, %AccessResponse{ data: price }}
    else
      {:error, :not_found}
    end
  end

  def update_price(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "catalogue.update_price") do
      do_update_price(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_update_price(request = %AccessRequest{ vas: vas, params: %{ price_id: price_id }}) do
    price = Price |> Price.Query.for_account(vas[:account_id]) |> Repo.get(price_id) |> Repo.preload(:parent)

    with %Price{} <- price,
         changeset = %{ valid?: true } <- Price.changeset(price, request.fields, request.locale)
    do
      {:ok, price} = Repo.transaction(fn ->
        price = Repo.update!(changeset)
        if price.parent do
          Price.balance!(price.parent)
        end

        price
      end)

      price =
        price
        |> Repo.preload(Price.Query.preloads(request.preloads))
        |> Translation.translate(request.locale)

      {:ok, %AccessResponse{ data: price }}
    else
      nil -> {:error, :not_found}
      changeset = %Changeset{} ->
        errors = Enum.into(changeset.errors, %{})
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  def delete_price(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "catalogue.delete_price") do
      do_delete_price(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_delete_price(%AccessRequest{ vas: vas, params: %{ price_id: price_id } }) do
    price = Price |> Price.Query.for_account(vas[:account_id]) |> Repo.get(price_id)

    case price.status do
      "disabled" ->
        Repo.delete!(price)
        {:ok, %AccessResponse{}}
      _ ->
        errors = %{ id: {"Only Disabled Price can be deleted.", [validation: :only_disabled_can_be_deleted]} }
        {:error, %AccessResponse{ errors: errors }}
    end
  end

end
