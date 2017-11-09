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
      |> filter_by(status: filter[:status], item_mode: filter[:item_mode])
      |> Product.Query.root()
      |> Product.Query.for_account(account_id)
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
  # ProductItem
  #####
  # def list_product_item(request = %AccessRequest{ vas: vas }) do
  #   with {:ok, role} <- Identity.authorize(vas, "catalogue.list_product_item") do
  #     do_list_product_item(request)
  #   else
  #     {:error, reason} -> {:error, :access_denied}
  #   end
  # end
  # def do_list_product_item(request = %AccessRequest{ vas: %{ account_id: account_id }, filter: filter, pagination: pagination }) do
  #   query =
  #     ProductItem
  #     |> search([:short_name, :code, :id], request.search, request.locale)
  #     |> filter_by(sku_id: filter[:sku_id], unlockable_id: filter[:unlockable_id], product_id: filter[:product_id], status: filter[:status])
  #     |> ProductItem.Query.for_account(account_id)
  #   result_count = Repo.aggregate(query, :count, :id)

  #   total_query = ProductItem |> where([s], s.account_id == ^account_id)
  #   total_count = Repo.aggregate(total_query, :count, :id)

  #   query = paginate(query, size: pagination[:size], number: pagination[:number])

  #   product_items =
  #     Repo.all(query)
  #     |> ProductItem.preload(ProductItem.Query.preloads(request.preloads))
  #     |> Translation.translate(request.locale)

  #   response = %AccessResponse{
  #     meta: %{
  #       total_count: total_count,
  #       result_count: result_count,
  #     },
  #     data: product_items
  #   }

  #   {:ok, response}
  # end

  # def create_product_item(request = %AccessRequest{ vas: vas }) do
  #   with {:ok, role} <- Identity.authorize(vas, "catalogue.create_product_item") do
  #     do_create_product_item(request)
  #   else
  #     {:error, reason} -> {:error, :access_denied}
  #   end
  # end
  # def do_create_product_item(request = %{ vas: vas }) do
  #   fields = Map.merge(request.fields, %{ "account_id" => vas[:account_id] })
  #   changeset = ProductItem.changeset(%ProductItem{}, fields)

  #   with {:ok, product_item} <- Repo.insert(changeset) do
  #     product_item = ProductItem.preload(product_item, ProductItem.Query.preloads(request.preloads))
  #     {:ok, %AccessResponse{ data: product_item }}
  #   else
  #     {:error, changeset} ->
  #       errors = Enum.into(changeset.errors, %{})
  #       {:error, %AccessResponse{ errors: errors }}
  #   end
  # end

  # def get_product_item(request = %AccessRequest{ vas: vas }) do
  #   with {:ok, role} <- Identity.authorize(vas, "catalogue.get_product_item") do
  #     do_get_product_item(request)
  #   else
  #     {:error, reason} -> {:error, :access_denied}
  #   end
  # end
  # def do_get_product_item(request = %AccessRequest{ vas: vas, params: %{ product_item_id: product_item_id } }) do
  #   product_item = ProductItem |> ProductItem.Query.for_account(vas[:account_id]) |> Repo.get(product_item_id)

  #   if product_item do
  #     product_item =
  #       product_item
  #       |> Repo.preload(ProductItem.Query.preloads(request.preloads))
  #       |> Translation.translate(request.locale)
  #     {:ok, %AccessResponse{ data: product_item }}
  #   else
  #     {:error, :not_found}
  #   end
  # end

  # def update_product_item(request = %AccessRequest{ vas: vas }) do
  #   with {:ok, role} <- Identity.authorize(vas, "catalogue.update_product_item") do
  #     do_update_product_item(request)
  #   else
  #     {:error, reason} -> {:error, :access_denied}
  #   end
  # end
  # def do_update_product_item(request = %AccessRequest{ vas: vas, params: %{ product_item_id: product_item_id }}) do
  #   product_item = ProductItem |> ProductItem.Query.for_account(vas[:account_id]) |> Repo.get(product_item_id)

  #   with %ProductItem{} <- product_item,
  #        changeset = %Changeset{ valid?: true } <- ProductItem.changeset(product_item, request.fields, request.locale) do
  #     {:ok, product_item} = Repo.transaction(fn ->
  #       if Changeset.get_change(changeset, :primary) do
  #         product_id = product_item.product_id
  #         from(pi in ProductItem, where: pi.product_id == ^product_id)
  #         |> Repo.update_all(set: [primary: false])
  #       end

  #       Repo.update!(changeset)
  #     end)

  #     product_item =
  #       product_item
  #       |> Repo.preload(ProductItem.Query.preloads(request.preloads))
  #       |> Translation.translate(request.locale)

  #     {:ok, %AccessResponse{ data: product_item }}
  #   else
  #     nil -> {:error, :not_found}
  #     changeset = %Changeset{} ->
  #       errors = Enum.into(changeset.errors, %{})
  #       {:error, %AccessResponse{ errors: errors }}
  #   end
  # end

  # def delete_product_item(request = %AccessRequest{ vas: vas }) do
  #   with {:ok, role} <- Identity.authorize(vas, "catalogue.delete_product_item") do
  #     do_delete_product_item(request)
  #   else
  #     {:error, reason} -> {:error, :access_denied}
  #   end
  # end
  # def do_delete_product_item(%AccessRequest{ vas: vas, params: %{ product_item_id: product_item_id } }) do
  #   product_item = ProductItem |> ProductItem.Query.for_account(vas[:account_id]) |> Repo.get(product_item_id)

  #   cond do
  #     !product_item ->
  #       {:error, :not_found}
  #     product_item && product_item.status == "disabled" ->
  #       Repo.delete!(product_item)
  #       {:ok, %AccessResponse{}}
  #     product_item ->
  #       errors = %{id: {"Only Disabled Product Item can be deleted.", [validation: :only_disabled_can_be_deleted]}}
  #       {:error, %AccessResponse{ errors: errors }}
  #   end
  # end

  #####
  # Price
  #####
  def create_price(request = %{ vas: vas }) do
    defaults = %{ preloads: [], fields: %{} }
    request = Map.merge(defaults, request)

    fields = Map.merge(request.fields, %{ "account_id" => vas[:account_id] })
    changeset = Price.changeset(%Price{}, fields)

    with {:ok, price} <- Repo.insert(changeset) do
      price = Repo.preload(price, request.preloads)
      {:ok, price}
    else
      other -> other
    end
  end

  def get_price!(request = %{ vas: vas, price_id: price_id }) do
    defaults = %{ locale: "en", preloads: [] }
    request = Map.merge(defaults, request)

    price =
      Price
      |> Repo.get_by!(account_id: vas[:account_id], id: price_id)
      |> Repo.preload(request.preloads)
      |> Translation.translate(request.locale)

    price
  end

  def list_prices(request = %{ vas: vas }) do
    defaults = %{ search_keyword: "", filter: %{}, page_size: 25, page_number: 1, locale: "en", preloads: [] }
    request = Map.merge(defaults, request)
    account_id = vas[:account_id]

    query =
      Price
      |> search([:name, :id], request.search_keyword, request.locale)
      |> filter_by(product_item_id: request.filter[:product_item_id], product_id: request.filter[:product_id], label: request.filter[:label])
      |> where([s], s.account_id == ^account_id)
    result_count = Repo.aggregate(query, :count, :id)

    total_query = Price |> where([s], s.account_id == ^account_id)
    total_count = Repo.aggregate(total_query, :count, :id)

    query = paginate(query, size: request.page_size, number: request.page_number)

    prices =
      Repo.all(query)
      |> Repo.preload(request.preloads)
      |> Translation.translate(request.locale)

    %{
      total_count: total_count,
      result_count: result_count,
      prices: prices
    }
  end

  def update_price(request = %{ vas: vas, price_id: price_id }) do
    defaults = %{ preloads: [], fields: %{}, locale: "en" }
    request = Map.merge(defaults, request)

    price = Repo.get_by!(Price, account_id: vas[:account_id], id: price_id) |> Repo.preload(:parent)

    with changeset = %{ valid?: true } <- Price.changeset(price, request.fields, request.locale) do
      {:ok, price} = Repo.transaction(fn ->
        price = Repo.update!(changeset)
        if price.parent do
          Price.balance!(price.parent)
        end

        price
      end)

      price =
        price
        |> Repo.preload(request.preloads)
        |> Translation.translate(request.locale)

      {:ok, price}
    else
      other -> {:error, other}
    end
  end

  def delete_price!(%{ vas: vas, price_id: price_id }) do
    price = Repo.get_by!(Price, account_id: vas[:account_id], id: price_id)

    case price.status do
      "disabled" ->
        Repo.delete!(price)
        {:ok, :deleted}
      _ ->
        errors = [id: {"Only Disabled Price can be deleted.", [validation: :only_disabled_can_be_deleted]}]
        {:error, errors}
    end
  end

end
