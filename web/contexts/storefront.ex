defmodule BlueJet.Storefront do
  use BlueJet.Web, :context

  alias BlueJet.Product
  alias BlueJet.ProductItem
  alias BlueJet.Price

  ######
  # Product
  ######
  def create_product(request = %{ vas: vas }) do
    defaults = %{ preloads: [], fields: %{} }
    request = Map.merge(defaults, request)

    fields = Map.merge(request.fields, %{ "account_id" => vas[:account_id] })
    changeset = Product.changeset(%Product{}, fields)

    with {:ok, product} <- Repo.insert(changeset) do
      product = Repo.preload(product, request.preloads)
      {:ok, product}
    else
      other -> other
    end
  end

  def get_product!(request = %{ vas: vas, product_id: product_id }) do
    defaults = %{ locale: "en", preloads: [] }
    request = Map.merge(defaults, request)

    product =
      Product
      |> Repo.get_by!(account_id: vas[:account_id], id: product_id)
      |> Repo.preload(request.preloads)
      |> Translation.translate(request.locale)

    product
  end

  def update_product(request = %{ vas: vas, product_id: product_id }) do
    defaults = %{ preloads: [], fields: %{}, locale: "en" }
    request = Map.merge(defaults, request)

    product = Repo.get_by!(Product, account_id: vas[:account_id], id: product_id)
    changeset = Product.changeset(product, request.fields, request.locale)

    with {:ok, product} <- Repo.update(changeset) do
      product =
        product
        |> Repo.preload(request.preloads)
        |> Translation.translate(request.locale)

      {:ok, product}
    else
      other -> other
    end
  end

  def list_products(request = %{ vas: vas }) do
    defaults = %{ search_keyword: "", filter: %{}, page_size: 25, page_number: 1, locale: "en", preloads: [] }
    request = Map.merge(defaults, request)
    account_id = vas[:account_id]

    query =
      Product
      |> search([:name], request.search_keyword, request.locale)
      |> filter_by(status: request.filter[:status], item_mode: request.filter[:item_mode])
      |> where([s], s.account_id == ^account_id)
    result_count = Repo.aggregate(query, :count, :id)

    total_query = Product |> where([s], s.account_id == ^account_id)
    total_count = Repo.aggregate(total_query, :count, :id)

    query = paginate(query, size: request.page_size, number: request.page_number)

    products =
      Repo.all(query)
      |> Repo.preload(request.preloads)
      |> Translation.translate(request.locale)

    %{
      total_count: total_count,
      result_count: result_count,
      products: products
    }
  end

  def delete_product!(%{ vas: vas, product_id: product_id }) do
    product = Repo.get_by!(Product, account_id: vas[:account_id], id: product_id)
    Repo.delete!(product)
  end

  #####
  # ProductItem
  #####
  def create_product_item(request = %{ vas: vas }) do
    defaults = %{ preloads: [], fields: %{} }
    request = Map.merge(defaults, request)

    fields = Map.merge(request.fields, %{ "account_id" => vas[:account_id] })
    changeset = ProductItem.changeset(%ProductItem{}, fields)

    with {:ok, product_item} <- Repo.insert(changeset) do
      product_item = Repo.preload(product_item, request.preloads)
      {:ok, product_item}
    else
      other -> other
    end
  end

  def get_product_item!(request = %{ vas: vas, product_item_id: product_item_id }) do
    defaults = %{ locale: "en", preloads: [] }
    request = Map.merge(defaults, request)

    product_item =
      ProductItem
      |> Repo.get_by!(account_id: vas[:account_id], id: product_item_id)
      |> Repo.preload(request.preloads)
      |> Translation.translate(request.locale)

    product_item
  end

  def update_product_item(request = %{ vas: vas, product_item_id: product_item_id }) do
    defaults = %{ preloads: [], fields: %{}, locale: "en" }
    request = Map.merge(defaults, request)

    product_item = Repo.get_by!(ProductItem, account_id: vas[:account_id], id: product_item_id)
    changeset = ProductItem.changeset(product_item, request.fields, request.locale)

    with {:ok, product_item} <- Repo.update(changeset) do
      product_item =
        product_item
        |> Repo.preload(request.preloads)
        |> Translation.translate(request.locale)

      {:ok, product_item}
    else
      other -> other
    end
  end

  def list_product_items(request = %{ vas: vas }) do
    defaults = %{ search_keyword: "", filter: %{}, page_size: 25, page_number: 1, locale: "en", preloads: [] }
    request = Map.merge(defaults, request)
    account_id = vas[:account_id]

    query =
      ProductItem
      |> search([:short_name, :code, :id], request.search_keyword, request.locale)
      |> filter_by(sku_id: request.filter[:sku_id], unlockable_id: request.filter[:unlockable_id], product_id: request.filter[:product_id])
      |> where([s], s.account_id == ^account_id)
    result_count = Repo.aggregate(query, :count, :id)

    total_query = ProductItem |> where([s], s.account_id == ^account_id)
    total_count = Repo.aggregate(total_query, :count, :id)

    query = paginate(query, size: request.page_size, number: request.page_number)

    product_items =
      Repo.all(query)
      |> Repo.preload(request.preloads)
      |> Translation.translate(request.locale)

    %{
      total_count: total_count,
      result_count: result_count,
      product_items: product_items
    }
  end

  def delete_product_item!(%{ vas: vas, product_item_id: product_item_id }) do
    product_item = Repo.get_by!(ProductItem, account_id: vas[:account_id], id: product_item_id)
    Repo.delete!(product_item)
  end

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
end
