defmodule BlueJet.Catalogue do
  use BlueJet, :context

  alias BlueJet.Catalogue.{Policy, Service}

  #
  # MARK: Product
  #
  def list_product(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "list_product") do
      do_list_product(authorize_args)
    else
      other -> other
    end
  end

  def do_list_product(args) do
    total_count =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.count_product(args[:opts])

    all_count =
      %{ filter: args[:all_count_filter] }
      |> Service.count_product(args[:opts])

    products =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.list_product(args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    response = %AccessResponse{
      meta: %{
        locale: args[:locale],
        all_count: all_count,
        total_count: total_count
      },
      data: products
    }

    {:ok, response}
  end

  def create_product(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "create_product") do
      do_create_product(authorize_args)
    else
      other -> other
    end
  end

  def do_create_product(args) do
    with {:ok, product} <- Service.create_product(args[:fields], args[:opts]) do
      product = Translation.translate(product, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: product }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_product(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "get_product") do
      do_get_product(authorize_args)
    else
      other -> other
    end
  end

  def do_get_product(args) do
    product =
      Service.get_product(args[:identifiers], args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    if product do
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: product }}
    else
      {:error, :not_found}
    end
  end

  def update_product(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "update_product") do
      do_update_product(authorize_args)
    else
      other -> other
    end
  end

  def do_update_product(args) do
    with {:ok, product} <- Service.update_product(args[:id], args[:fields], args[:opts]) do
      product = Translation.translate(product, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: product }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_product(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "delete_product") do
      do_delete_product(authorize_args)
    else
      other -> other
    end
  end

  def do_delete_product(args) do
    with {:ok, _} <- Service.delete_product(args[:id], args[:opts]) do
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
  defp filter_product_collection_by_role(request = %{ role: role, filter: filter }) when role in ["guest", "customer"] do
    filter = Map.put(filter, :status, "active")
    all_count_filter = Map.take(filter, [:status])
    preload_filters = %{
      memberships: %{ product_status: "active" }
    }

    %{ request | filter: filter, count_filter: %{ all: all_count_filter }, preload_filters: preload_filters }
  end

  defp filter_product_collection_by_role(request), do: request

  def list_product_collection(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "list_product_collection") do
      do_list_product_collection(authorize_args)
    else
      other -> other
    end
  end

  def do_list_product_collection(args) do
    total_count =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.count_product_collection(args[:opts])

    all_count =
      %{ filter: args[:all_count_filter] }
      |> Service.count_product_collection(args[:opts])

    product_collections =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.list_product_collection(args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    response = %AccessResponse{
      meta: %{
        locale: args[:locale],
        all_count: all_count,
        total_count: total_count
      },
      data: product_collections
    }

    {:ok, response}
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
    with {:ok, product_collection} <- Service.create_product_collection(request.fields, get_sopts(request)) do
      product_collection = Translation.translate(product_collection, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: product_collection }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_product_collection(request) do
    with {:ok, request} <- preprocess_request(request, "catalogue.get_product_collection") do
      request
      |> filter_product_collection_by_role()
      |> do_get_product_collection()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_product_collection(request = %{ account: account, params: params }) do
    product_collection =
      atom_map(params)
      |> Service.get_product_collection(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    if product_collection do
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: product_collection }}
    else
      {:error, :not_found}
    end
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
    with {:ok, product_collection} <- Service.update_product_collection(id, request.fields, get_sopts(request)) do
      product_collection = Translation.translate(product_collection, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: product_collection }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_product_collection(request) do
    with {:ok, request} <- preprocess_request(request, "catalogue.delete_product_collection") do
      request
      |> do_delete_product_collection()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_delete_product_collection(%{ account: account, params: %{ "id" => id } }) do
    with {:ok, _} <- Service.delete_product_collection(id, %{ account: account }) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  #
  # MARK: Product Collection Membership
  #
  defp filter_membership_by_role(request = %{ role: role }) when role in ["guest", "customer"] do
    request = %{ request | filter: Map.put(request.filter, :product_status, "active") }
    %{ request | count_filter: %{ all: Map.take(request.filter, [:product_status]) } }
  end

  defp filter_membership_by_role(request), do: request

  def list_product_collection_membership(request) do
    with {:ok, request} <- preprocess_request(request, "catalogue.list_product_collection_membership") do
      request
      |> filter_membership_by_role()
      |> do_list_product_collection_membership
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_product_collection_membership(request = %{ account: account, filter: filter, params: %{ "collection_id" => collection_id } }) do
    filter = Map.put(filter, :collection_id, collection_id)

    total_count =
      %{ filter: filter }
      |> Service.count_product_collection_membership(%{ account: account })

    all_count =
      %{ filter: request.count_filter[:all] }
      |> Service.count_product_collection_membership(%{ account: account })

    pcms =
      %{ filter: filter }
      |> Service.list_product_collection_membership(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: all_count,
        total_count: total_count
      },
      data: pcms
    }

    {:ok, response}
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

    with {:ok, pcm} <- Service.create_product_collection_membership(fields, get_sopts(request)) do
      pcm = Translation.translate(pcm, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: pcm }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def do_get_product_collection_membership(request = %{ account: account, params: params }) do
    pcm =
      atom_map(params)
      |> Service.get_product_collection_membership(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    if pcm do
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: pcm }}
    else
      {:error, :not_found}
    end
  end

  def delete_product_collection_membership(request) do
    with {:ok, request} <- preprocess_request(request, "catalogue.delete_product_collection_membership") do
      request
      |> do_delete_product_collection_membership()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_delete_product_collection_membership(%{ account: account, params: %{ "id" => id } }) do
    with {:ok, _} <- Service.delete_product_collection_membership(id, %{ account: account }) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  #
  # MARK: Price
  #
  defp filter_price_by_role(request = %{ role: role }) when role in ["guest", "customer"] do
    request = %{ request | filter: Map.put(request.filter, :status, "active") }
    %{ request | count_filter: %{ all: Map.take(request.filter, [:status, :product_id]) } }
  end

  defp filter_price_by_role(request), do: request

  def list_price(request) do
    with {:ok, request} <- preprocess_request(request, "catalogue.list_price") do
      request
      |> filter_price_by_role()
      |> do_list_price()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_price(request = %{ account: account, params: %{ "product_id" => product_id }, filter: filter }) do
    filter = Map.put(filter, :product_id, product_id)
    all_count_filter = Map.put(request.count_filter[:all], :product_id, product_id)

    total_count =
      %{ filter: filter, search: request.search }
      |> Service.count_price(%{ account: account })

    all_count =
      %{ filter: all_count_filter }
      |> Service.count_price(%{ account: account })

    prices =
      %{ filter: filter, search: request.search }
      |> Service.list_price(get_sopts(request))
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

    with {:ok, price} <- Service.create_price(fields, get_sopts(request)) do
      price = Translation.translate(price, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: price }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_price(request) do
    with {:ok, request} <- preprocess_request(request, "catalogue.get_price") do
      request
      |> filter_price_by_role()
      |> do_get_price()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_price(request = %{ account: account, params: params }) do
    price =
      atom_map(params)
      |> Service.get_price(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    if price do
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: price }}
    else
      {:error, :not_found}
    end
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
    with {:ok, price} <- Service.update_price(id, request.fields, get_sopts(request)) do
      price = Translation.translate(price, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: price }}
    else
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
    with {:ok, _} <- Service.delete_price(id, %{ account: account }) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

end
