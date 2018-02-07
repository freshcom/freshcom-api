defmodule BlueJet.Catalogue do
  use BlueJet, :context

  alias BlueJet.Catalogue.Service
  alias BlueJet.Catalogue.{Product, ProductCollection, ProductCollectionMembership, Price}

  defp filter_by_role(request = %{ role: role }) when role in ["guest", "customer"] do
    request = %{ request | filter: Map.put(request.filter, :status, "active") }
    %{ request | count_filter: %{ all: Map.take(request.filter, [:status, :collection_id, :parent_id]) } }
  end

  defp filter_by_role(request), do: request

  #
  # MARK: Product
  #
  def list_product(request) do
    with {:ok, request} <- preprocess_request(request, "catalogue.list_product") do
      request
      |> filter_by_role()
      |> do_list_product
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_product(request = %{ account: account, filter: filter }) do
    total_count =
      %{ filter: filter, search: request.search }
      |> Service.count_product(%{ account: account })

    all_count =
      %{ filter: request.count_filter[:all] }
      |> Service.count_product(%{ account: account })

    products =
      %{ filter: filter, search: request.search }
      |> Service.list_product(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: all_count,
        total_count: total_count
      },
      data: products
    }

    {:ok, response}
  end

  def create_product(request) do
    with {:ok, request} <- preprocess_request(request, "catalogue.create_product") do
      request
      |> do_create_product()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_product(request = %{ account: account }) do
    with {:ok, product} <- Service.create_product(request.fields, get_sopts(request)) do
      product = Translation.translate(product, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: product }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_product(request) do
    with {:ok, request} <- preprocess_request(request, "catalogue.get_product") do
      request
      |> filter_by_role()
      |> do_get_product()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_product(request = %{ account: account, params: params }) do
    product =
      atom_map(params)
      |> Service.get_product(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    if product do
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: product }}
    else
      {:error, :not_found}
    end
  end

  def update_product(request) do
    with {:ok, request} <- preprocess_request(request, "catalogue.update_product") do
      request
      |> do_update_product()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_update_product(request = %{ account: account, params: %{ "id" => id }}) do
    with {:ok, product} <- Service.update_product(id, request.fields, get_sopts(request)) do
      product = Translation.translate(product, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: product }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_product(request) do
    with {:ok, request} <- preprocess_request(request, "catalogue.delete_product") do
      request
      |> do_delete_product()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_delete_product(%{ account: account, params: %{ "id" => id } }) do
    with {:ok, _} <- Service.delete_product(id, %{ account: account }) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  #
  # MARK: Product Collection
  #
  def list_product_collection(request) do
    with {:ok, request} <- preprocess_request(request, "catalogue.list_product_collection") do
      request
      |> AccessRequest.transform_by_role()
      |> do_list_product_collection
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_product_collection(request = %AccessRequest{ account: account, filter: filter, counts: counts, pagination: pagination }) do
    data_query =
      ProductCollection.Query.default()
      |> search([:name], request.search, request.locale, account.id)
      |> filter_by(status: filter[:status], label: filter[:label])
      |> ProductCollection.Query.for_account(account.id)

    total_count = Repo.aggregate(data_query, :count, :id)
    all_count =
      ProductCollection.Query.default()
      |> filter_by(status: counts[:all][:status])
      |> ProductCollection.Query.for_account(account.id)
      |> Repo.aggregate(:count, :id)

    preloads = ProductCollection.Query.preloads(request.preloads, role: request.role)
    product_collections =
      data_query
      |> paginate(size: pagination[:size], number: pagination[:number])
      |> Repo.all()
      |> Repo.preload(preloads)
      |> Product.put_external_resources(request.preloads, %{ account: account, role: request.role, locale: request.locale })
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: all_count,
        total_count: total_count
      },
      data: product_collections
    }

    {:ok, response}
  end

  defp product_collection_response(nil, _), do: {:error, :not_found}

  defp product_collection_response(product_collection, request = %{ account: account }) do
    preloads = ProductCollection.Query.preloads(request.preloads, role: request.role)

    product_collection =
      product_collection
      |> Repo.preload(preloads)
      |> ProductCollection.put_external_resources(request.preloads, %{ account: account, role: request.role, locale: request.locale })
      |> Translation.translate(request.locale, account.default_locale)

    {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: product_collection }}
  end

  def create_product_collection(request) do
    with {:ok, request} <- preprocess_request(request, "catalogue.create_product_collection") do
      request
      |> do_create_product_collection
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_product_collection(request = %{ account: account }) do
    with {:ok, product_collection} <- Service.create_product_collection(request.fields, %{ account: account }) do
      product_collection_response(product_collection, request)
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  def get_product_collection(request) do
    with {:ok, request} <- preprocess_request(request, "catalogue.get_product_collection") do
      request
      |> do_get_product_collection()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_product_collection(request = %{ account: account, params: %{ "id" => id } }) do
    product_collection =
      ProductCollection.Query.default()
      |> ProductCollection.Query.for_account(account.id)
      |> Repo.get(id)

    product_collection_response(product_collection, request)
  end
  def do_get_product_collection(request = %AccessRequest{ account: account, params: %{ "code" => code } }) do
    product_collection =
      ProductCollection.Query.default()
      |> ProductCollection.Query.for_account(account.id)
      |> Repo.get_by(code: code)

    product_collection_response(product_collection, request)
  end

  def update_product_collection(request) do
    with {:ok, request} <- preprocess_request(request, "catalogue.update_product_collection") do
      request
      |> do_update_product_collection()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_update_product_collection(request = %{ account: account, params: %{ "id" => id }}) do
    with {:ok, product_collection} <- Service.update_product_collection(id, request.fields, %{ account: account }) do
      product_collection_response(product_collection, request)
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  #
  # ProductCollectionMembership
  #
  def list_product_collection_membership(request) do
    with {:ok, request} <- preprocess_request(request, "catalogue.list_product_collection_membership") do
      request
      |> AccessRequest.transform_by_role()
      |> do_list_product_collection_membership
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_product_collection_membership(request = %{
    role: role,
    account: account,
    params: %{ "collection_id" => collection_id },
    pagination: pagination
  }) when role in ["guest", "customer"] do
    data_query =
      ProductCollectionMembership.Query.default()
      |> ProductCollectionMembership.Query.with_active_product()
      |> ProductCollectionMembership.Query.for_collection(collection_id)
      |> ProductCollectionMembership.Query.for_account(account.id)

    total_count = Repo.aggregate(data_query, :count, :id)

    preloads = ProductCollectionMembership.Query.preloads(request.preloads, role: request.role)
    pcms =
      data_query
      |> paginate(size: pagination[:size], number: pagination[:number])
      |> Repo.all()
      |> Repo.preload(preloads)
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: total_count,
        total_count: total_count
      },
      data: pcms
    }

    {:ok, response}
  end

  def do_list_product_collection_membership(request = %{
    account: account,
    params: %{ "collection_id" => collection_id },
    pagination: pagination
  }) do
    data_query =
      ProductCollectionMembership.Query.default()
      |> ProductCollectionMembership.Query.for_collection(collection_id)
      |> ProductCollectionMembership.Query.for_account(account.id)

    total_count = Repo.aggregate(data_query, :count, :id)

    preloads = ProductCollectionMembership.Query.preloads(request.preloads, role: request.role)
    pcms =
      data_query
      |> paginate(size: pagination[:size], number: pagination[:number])
      |> Repo.all()
      |> Repo.preload(preloads)
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: total_count,
        total_count: total_count
      },
      data: pcms
    }

    {:ok, response}
  end

  defp product_collection_membership_response(nil, _), do: {:error, :not_found}

  defp product_collection_membership_response(product_collection_membership, request = %{ account: account }) do
    preloads = ProductCollectionMembership.Query.preloads(request.preloads, role: request.role)

    product_collection_membership =
      product_collection_membership
      |> Repo.preload(preloads)
      |> ProductCollectionMembership.put_external_resources(request.preloads, %{ account: account, role: request.role, locale: request.locale })

    {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: product_collection_membership }}
  end

  def create_product_collection_membership(request) do
    with {:ok, request} <- preprocess_request(request, "catalogue.create_product_collection_membership") do
      request
      |> do_create_product_collection_membership()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_product_collection_membership(request = %{ account: account, params: %{ "collection_id" => collection_id } }) do
    fields = Map.merge(request.fields, %{ "collection_id" => collection_id })

    with {:ok, pcm} <- Service.create_product_collection_membership(fields, %{ account: account }) do
      product_collection_membership_response(pcm, request)
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def do_get_product_collection_membership(%{ params: %{ "collection_id" => nil } }), do: {:error, :not_found}
  def do_get_product_collection_membership(%{ params: %{ "product_id" => nil } }), do: {:error, :not_found}
  def do_get_product_collection_membership(request = %{ account: account, params: %{ "collection_id" => collection_id, "product_id" => product_id } }) do
    membership =
      ProductCollectionMembership |> ProductCollectionMembership.Query.for_account(account.id)
      |> Repo.get_by(collection_id: collection_id, product_id: product_id)

    if membership do
      membership =
        membership
        |> Repo.preload(ProductCollectionMembership.Query.preloads(request.preloads))
        |> Translation.translate(request.locale, account.default_locale)

      {:ok, %AccessResponse{ data: membership }}
    else
      {:error, :not_found}
    end
  end
  def do_get_product_collection_membership(_), do: {:error, :not_found}

  def delete_product_collection_membership(request) do
    with {:ok, request} <- preprocess_request(request, "catalogue.delete_product_collection_membership") do
      request
      |> do_delete_product_collection_membership()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_delete_product_collection_membership(%{ account: account, params: %{ "id" => id } }) do
    pcm =
      ProductCollectionMembership.Query.default()
      |> ProductCollectionMembership.Query.for_account(account.id)
      |> Repo.get(id)

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
  def list_price(request) do
    with {:ok, request} <- preprocess_request(request, "catalogue.list_price") do
      request
      |> AccessRequest.transform_by_role()
      |> do_list_price()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_price(request = %{ account: account, params: %{ "product_id" => product_id }, filter: filter, counts: counts, pagination: pagination }) do
    data_query =
      Price.Query.default()
      |> search([:name, :id], request.search, request.locale, account.default_locale)
      |> filter_by(product_id: product_id, status: filter[:status], label: filter[:label])
      |> Price.Query.for_account(account.id)

    total_count = Repo.aggregate(data_query, :count, :id)
    all_count =
      Price.Query.default()
      |> filter_by(status: counts[:all][:status])
      |> Price.Query.for_account(account.id)
      |> Repo.aggregate(:count, :id)

    prices =
      data_query
      |> paginate(size: pagination[:size], number: pagination[:number])
      |> Repo.all()
      |> Repo.preload(Price.Query.preloads(request.preloads))
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: all_count,
        total_count: total_count
      },
      data: prices
    }

    {:ok, response}
  end

  defp price_response(nil, _), do: {:error, :not_found}

  defp price_response(price, request = %{ account: account }) do
    preloads = Price.Query.preloads(request.preloads, role: request.role)

    price =
      price
      |> Repo.preload(preloads)
      |> Translation.translate(request.locale, account.default_locale)

    {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: price }}
  end

  def create_price(request) do
    with {:ok, request} <- preprocess_request(request, "catalogue.create_price") do
      request
      |> do_create_price()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_price(request = %{ account: account, params: %{ "product_id" => product_id } }) do
    fields = Map.merge(request.fields, %{ "product_id" => product_id })

    with {:ok, price} <- Service.create_price(fields, %{ account: account }) do
      price_response(price, request)
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  def get_price(request) do
    with {:ok, request} <- preprocess_request(request, "catalogue.get_price") do
      request
      |> do_get_price()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_price(request = %{ role: role, account: account, params: %{ "id" => id } }) when role in ["guest", "customer"] do
    price =
      Price.Query.default()
      |> Price.Query.active()
      |> Price.Query.for_account(account.id)
      |> Repo.get(id)

    price_response(price, request)
  end

  def do_get_price(request = %{ account: account, params: %{ "id" => id } }) do
    price =
      Price.Query.default()
      |> Price.Query.for_account(account.id)
      |> Repo.get(id)

    price_response(price, request)
  end

  def do_get_price(request = %{ account: account, params: %{ "code" => code } }) do
    price =
      Price.Query.default()
      |> Price.Query.for_account(account.id)
      |> Repo.get_by(code: code)

    price_response(price, request)
  end

  def update_price(request) do
    with {:ok, request} <- preprocess_request(request, "catalogue.update_price") do
      request
      |> do_update_price()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_update_price(request = %{ account: account, params: %{ "id" => id }}) do
    with {:ok, price} <- Service.update_price(id, request.fields, %{ account: account, locale: request.locale }) do
      price_response(price, request)
    else
      nil ->
        {:error, :not_found}

      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_price(request) do
    with {:ok, request} <- preprocess_request(request, "catalogue.delete_price") do
      request
      |> do_delete_price()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_delete_price(%AccessRequest{ account: account, params: %{ "id" => id } }) do
    price =
      Price
      |> Price.Query.for_account(account.id)
      |> Repo.get(id)

    cond do
      !price ->
        {:error, :not_found}

      price.status == "disabled" ->
        Repo.delete!(price)
        {:ok, %AccessResponse{}}

      true ->
        errors = %{ id: {"Only Disabled Price can be deleted.", [validation: :only_disabled_can_be_deleted]} }
        {:error, %AccessResponse{ errors: errors }}
    end
  end

end
