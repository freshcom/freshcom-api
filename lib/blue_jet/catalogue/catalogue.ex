defmodule BlueJet.Catalogue do
  use BlueJet, :context

  alias Ecto.Changeset
  alias BlueJet.Identity
  alias BlueJet.FileStorage

  alias BlueJet.Catalogue.Product
  alias BlueJet.Catalogue.ProductCollection
  alias BlueJet.Catalogue.ProductCollectionMembership
  alias BlueJet.Catalogue.Price

  ######
  # Product
  ######
  def list_product(request) do
    with {:ok, request} <- authorize_request(request, "catalogue.list_product") do
      request
      |> transform_request()
      |> do_list_product
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  defp transform_request(request = %{ role: role }) when role == "guest" or role == "customer" do
    filter = Map.put(request.filter, :status, "active")
    counts = Map.put(request.counts, :all, %{ status: "active" })
    %{ request | filter: filter, counts: counts }
  end

  defp transform_request(request), do: request

  def do_list_product(request = %{ account: account, filter: filter, counts: counts, pagination: pagination }) do
    data_query =
      Product.Query.default()
      |> search([:name], request.search, request.locale, account.default_locale, Product.translatable_fields)
      |> filter_by(status: filter[:status], kind: filter[:kind], parent_id: filter[:parent_id])
      |> root_only_if_no_parent_id(filter[:parent_id])
      |> Product.Query.for_account(account.id)

    total_count = Repo.aggregate(data_query, :count, :id)

    all_query =
      Product.Query.default()
      |> filter_by(parent_id: filter[:parent_id], status: counts[:all][:status])
      |> Product.Query.for_account(account.id)
      |> root_only_if_no_parent_id(filter[:parent_id])

    all_count = Repo.aggregate(all_query, :count, :id)

    products =
      data_query
      |> paginate(size: pagination[:size], number: pagination[:number])
      |> Repo.all()
      |> Repo.preload(Product.Query.preloads(request.preloads))
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        all_count: all_count,
        total_count: total_count
      },
      data: products
    }

    {:ok, response}
  end

  defp root_only_if_no_parent_id(query, nil), do: Product.Query.root(query)
  defp root_only_if_no_parent_id(query, _), do: query

  def create_product(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "catalogue.create_product") do
      do_create_product(%{ request | role: role })
    else
      {:error, _} -> {:error, :access_denied}
    end
  end
  def do_create_product(request = %{ vas: vas }) do
    fields = Map.merge(request.fields, %{ "account_id" => vas.account_id })
    changeset = Product.changeset(%Product{}, fields)

    with {:ok, product} <- Repo.insert(changeset) do
      product = Repo.preload(product, Product.Query.preloads(request.preloads))
      {:ok, %AccessResponse{ data: product }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  def get_product(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "catalogue.get_product") do
      do_get_product(%{ request | role: role })
    else
      {:error, _} -> {:error, :access_denied}
    end
  end
  def do_get_product(request = %AccessRequest{ vas: vas, params: %{ "id" => id } }) do
    product = Product |> Product.Query.for_account(vas.account_id) |> Repo.get(id)
    do_get_product_response(product, request)
  end
  def do_get_product(request = %AccessRequest{ vas: vas, params: %{ "code" => code } }) do
    product = Product |> Product.Query.for_account(vas.account_id) |> Repo.get_by(code: code)
    do_get_product_response(product, request)
  end
  defp do_get_product_response(nil, _), do: {:error, :not_found}
  defp do_get_product_response(product, request) do
    product =
      product
      |> Repo.preload(Product.Query.preloads(request.preloads))
      |> Translation.translate(request.locale)

    {:ok, %AccessResponse{ data: product }}
  end

  def update_product(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "catalogue.update_product") do
      do_update_product(%{ request | role: role })
    else
      {:error, _} -> {:error, :access_denied}
    end
  end
  def do_update_product(request = %AccessRequest{ vas: vas, params: %{ "id" => id }}) do
    product = Product |> Product.Query.for_account(vas.account_id) |> Repo.get(id)

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
      %{ errors: errors } ->
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  def delete_product(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "catalogue.delete_product") do
      do_delete_product(%{ request | role: role })
    else
      {:error, _} -> {:error, :access_denied}
    end
  end
  def do_delete_product(%AccessRequest{ vas: vas, params: %{ product_id: product_id } }) do
    product = Product |> Product.Query.for_account(vas.account_id) |> Repo.get(product_id)

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


  ######
  # ProductCollection
  ######
  def list_product_collection(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "catalogue.list_product_collection") do
      do_list_product_collection(%{ request | role: role })
    else
      {:error, _} -> {:error, :access_denied}
    end
  end
  def do_list_product_collection(request = %AccessRequest{ vas: %{ account_id: account_id }, filter: filter, pagination: pagination }) do
    query =
      ProductCollection.Query.default()
      |> search([:name], request.search, request.locale, account_id)
      |> filter_by(status: filter[:status], label: filter[:label])
      |> ProductCollection.Query.for_account(account_id)
    result_count = Repo.aggregate(query, :count, :id)

    all_query = ProductCollection |> ProductCollection.Query.for_account(account_id)
    all_count = Repo.aggregate(all_query, :count, :id)

    query = paginate(query, size: pagination[:size], number: pagination[:number])

    product_collections =
      Repo.all(query)
      |> Repo.preload(ProductCollection.Query.preloads(request.preloads))
      |> Translation.translate(request.locale)

    response = %AccessResponse{
      meta: %{
        all_count: all_count,
        result_count: result_count,
      },
      data: product_collections
    }

    {:ok, response}
  end

  def create_product_collection(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "catalogue.create_product_collection") do
      do_create_product_collection(%{ request | role: role })
    else
      {:error, _} -> {:error, :access_denied}
    end
  end
  def do_create_product_collection(request = %{ vas: vas }) do
    fields = Map.merge(request.fields, %{ "account_id" => vas.account_id })
    changeset = ProductCollection.changeset(%ProductCollection{}, fields)

    with {:ok, product_collection} <- Repo.insert(changeset) do
      product_collection = Repo.preload(product_collection, ProductCollection.Query.preloads(request.preloads))
      {:ok, %AccessResponse{ data: product_collection }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  def get_product_collection(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "catalogue.get_product_collection") do
      do_get_product_collection(%{ request | role: role })
    else
      {:error, _} -> {:error, :access_denied}
    end
  end
  def do_get_product_collection(request = %AccessRequest{ vas: vas, params: %{ "id" => id } }) do
    product_collection = ProductCollection |> ProductCollection.Query.for_account(vas.account_id) |> Repo.get(id)
    do_get_product_collection_response(product_collection, request)
  end
  def do_get_product_collection(request = %AccessRequest{ vas: vas, params: %{ "code" => code } }) do
    product_collection = ProductCollection |> ProductCollection.Query.for_account(vas.account_id) |> Repo.get_by(code: code)
    do_get_product_collection_response(product_collection, request)
  end

  defp do_get_product_collection_response(nil, _), do: {:error, :not_found}
  defp do_get_product_collection_response(product_collection, request) do
    product_collection =
      product_collection
      |> Repo.preload(ProductCollection.Query.preloads(request.preloads))
      |> Translation.translate(request.locale)

    {:ok, %AccessResponse{ data: product_collection }}
  end

  def update_product_collection(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "catalogue.update_product_collection") do
      do_update_product_collection(%{ request | role: role })
    else
      {:error, _} -> {:error, :access_denied}
    end
  end
  def do_update_product_collection(request = %{ vas: vas, params: %{ id: id }}) do
    product_collection = ProductCollection |> ProductCollection.Query.for_account(vas.account_id) |> Repo.get(id)

    with %ProductCollection{} <- product_collection,
         changeset <- ProductCollection.changeset(product_collection, request.fields, request.locale),
        {:ok, product_collection} <- Repo.update(changeset)
    do
      product_collection =
        product_collection
        |> Repo.preload(ProductCollection.Query.preloads(request.preloads))
        |> Translation.translate(request.locale)

      {:ok, %AccessResponse{ data: product_collection }}
    else
      nil -> {:error, :not_found}
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  #
  # ProductCollectionMembership
  #
  def create_product_collection_membership(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "catalogue.create_product_collection_membership") do
      do_create_product_collection_membership(%{ request | role: role })
    else
      {:error, _} -> {:error, :access_denied}
    end
  end
  def do_create_product_collection_membership(request = %{ vas: vas }) do
    fields = Map.merge(request.fields, %{ "account_id" => vas.account_id })
    changeset = ProductCollectionMembership.changeset(%ProductCollectionMembership{}, fields)

    with {:ok, product_collection_membership} <- Repo.insert(changeset) do
      product_collection_membership = Repo.preload(product_collection_membership, ProductCollection.Query.preloads(request.preloads))
      {:ok, %AccessResponse{ data: product_collection_membership }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  def do_get_product_collection_membership(%{ params: %{ "collection_id" => nil } }), do: {:error, :not_found}
  def do_get_product_collection_membership(%{ params: %{ "product_id" => nil } }), do: {:error, :not_found}
  def do_get_product_collection_membership(request = %{ vas: vas, params: %{ "collection_id" => collection_id, "product_id" => product_id } }) do
    membership =
      ProductCollectionMembership |> ProductCollectionMembership.Query.for_account(vas.account_id)
      |> Repo.get_by(collection_id: collection_id, product_id: product_id)

    if membership do
      membership =
        membership
        |> Repo.preload(ProductCollectionMembership.Query.preloads(request.preloads))
        |> Translation.translate(request.locale)

      {:ok, %AccessResponse{ data: membership }}
    else
      {:error, :not_found}
    end
  end
  def do_get_product_collection_membership(_), do: {:error, :not_found}

  def delete_product_collection_membership(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "catalogue.delete_product_collection_membership") do
      do_delete_product_collection_membership(%{ request | role: role })
    else
      {:error, _} -> {:error, :access_denied}
    end
  end
  def do_delete_product_collection_membership(%AccessRequest{ vas: vas, params: %{ id: id } }) do
    pcm = ProductCollectionMembership |> ProductCollectionMembership.Query.for_account(vas.account_id) |> Repo.get(id)

    if pcm do
      Repo.delete!(pcm)
      {:ok, %AccessRequest{}}
    else
      {:error, :not_found}
    end
  end

  #####
  # Price
  #####
  def list_price(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "catalogue.list_price") do
      do_list_price(%{ request | role: role })
    else
      {:error, _} -> {:error, :access_denied}
    end
  end
  def do_list_price(request = %AccessRequest{ vas: %{ account_id: account_id }, filter: filter, pagination: pagination }) do
    query =
      Price.Query.default()
      |> search([:name, :id], request.search, request.locale, account_id)
      |> filter_by(product_id: filter[:product_id], label: filter[:label])
      |> Price.Query.for_account(account_id)
    result_count = Repo.aggregate(query, :count, :id)

    all_query = Price |> Price.Query.for_account(account_id)
    all_count = Repo.aggregate(all_query, :count, :id)

    query = paginate(query, size: pagination[:size], number: pagination[:number])

    prices =
      Repo.all(query)
      |> Repo.preload(Price.Query.preloads(request.preloads))
      |> Translation.translate(request.locale)

    response = %AccessResponse{
      meta: %{
        all_count: all_count,
        result_count: result_count,
      },
      data: prices
    }

    {:ok, response}
  end

  def create_price(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "catalogue.create_price") do
      do_create_price(%{ request | role: role })
    else
      {:error, _} -> {:error, :access_denied}
    end
  end
  def do_create_price(request = %AccessRequest{ vas: vas }) do
    fields = Map.merge(request.fields, %{ "account_id" => vas.account_id })
    changeset = Price.changeset(%Price{}, fields)

    with {:ok, price} <- Repo.insert(changeset) do
      price = Repo.preload(price, Price.Query.preloads(request.preloads))
      {:ok, %AccessResponse{ data: price }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  def get_price(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "catalogue.get_price") do
      do_get_price(%{ request | role: role })
    else
      {:error, _} -> {:error, :access_denied}
    end
  end
  def do_get_price(request = %AccessRequest{ vas: vas, params: %{ "id" => id } }) do
    price = Price |> Price.Query.for_account(vas.account_id) |> Repo.get(id)
    do_get_price_response(price, request)
  end
  def do_get_price(request = %AccessRequest{ vas: vas, params: %{ "code" => code } }) do
    price = Price |> Price.Query.for_account(vas.account_id) |> Repo.get_by(code: code)
    do_get_price_response(price, request)
  end
  def do_get_price_response(nil, _), do: {:error, :not_found}
  def do_get_price_response(price, request) do
    price =
      price
      |> Repo.preload(Price.Query.preloads(request.preloads))
      |> Translation.translate(request.locale)

    {:ok, %AccessResponse{ data: price }}
  end

  def update_price(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "catalogue.update_price") do
      do_update_price(%{ request | role: role })
    else
      {:error, _} -> {:error, :access_denied}
    end
  end
  def do_update_price(request = %AccessRequest{ vas: vas, params: %{ "id" => id }}) do
    price = Price |> Price.Query.for_account(vas.account_id) |> Repo.get(id) |> Repo.preload(:parent)

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
      %{ errors: errors } ->
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  def delete_price(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "catalogue.delete_price") do
      do_delete_price(%{ request | role: role })
    else
      {:error, _} -> {:error, :access_denied}
    end
  end
  def do_delete_price(%AccessRequest{ vas: vas, params: %{ "id" => id } }) do
    price = Price |> Price.Query.for_account(vas.account_id) |> Repo.get(id)

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
