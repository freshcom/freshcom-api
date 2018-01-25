defmodule BlueJet.Catalogue do
  use BlueJet, :context

  alias Ecto.Changeset
  alias BlueJet.Catalogue.{FileStorageService}

  alias BlueJet.Catalogue.{Product, ProductCollection, ProductCollectionMembership, Price}

  defmodule Service do
    alias Ecto.Multi

    def get_product(id) do
      Repo.get(Product, id)
    end

    def get_product(id, opts) do
      account_id = opts[:account_id] || opts[:account].id
      Repo.get_by(Product, id: id, account_id: account_id)
    end

    def get_product_by_code(code, opts) do
      account_id = opts[:account_id] || opts[:account].id
      Repo.get_by(Product, code: code, account_id: account_id)
    end

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
            parent_id = product.parent_id
            from(pi in Product, where: pi.parent_id == ^parent_id)
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

    def get_price(%{ product_id: product_id, status: status, order_quantity: order_quantity }) do
      Price.Query.for_product(product_id)
      |> Price.Query.with_status(status)
      |> Price.Query.with_order_quantity(order_quantity)
      |> first()
      |> Repo.one()
    end

    def get_price(id) do
      Repo.get(Price, id)
    end

    def get_price(id, opts) do
      account_id = opts[:account_id] || opts[:account].id
      Repo.get_by(Price, id: id, account_id: account_id)
    end

    def get_price_by_code(code, opts) do
      account_id = opts[:account_id] || opts[:account].id
      Repo.get_by(Price, code: code, account_id: account_id)
    end

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

    def get_product_collection_membership(%{ collection_id: collection_id, product_id: product_id }) do
      ProductCollectionMembership
      |> Repo.get_by(collection_id: collection_id, product_id: product_id)
    end

    def create_product_collection_membership(fields, opts) do
      account_id = opts[:account_id] || opts[:account].id
      %ProductCollectionMembership{ account_id: account_id, account: opts[:account] }
      |> ProductCollectionMembership.changeset(fields)
      |> Repo.insert()
    end
  end

  #
  # MARK: Product
  #
  def list_product(request) do
    with {:ok, request} <- preprocess_request(request, "catalogue.list_product") do
      request
      |> AccessRequest.transform_by_role()
      |> do_list_product
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_product(request = %{ account: account, filter: filter, counts: counts, pagination: pagination }) do
    data_query =
      Product.Query.default()
      |> search([:name, :code, :id], request.search, request.locale, account.default_locale, Product.translatable_fields())
      |> filter_by(status: filter[:status], kind: underscore(filter[:kind]), parent_id: filter[:parent_id])
      |> Product.Query.in_collection(filter[:collection_id])
      |> root_only_if_no_parent_id(filter[:parent_id])
      |> Product.Query.for_account(account.id)
      |> default_order_if_no_collection_id(filter[:collection_id])

    total_count = Repo.aggregate(data_query, :count, :id)
    all_count =
      Product.Query.default()
      |> filter_by(parent_id: filter[:parent_id], status: counts[:all][:status])
      |> Product.Query.in_collection(filter[:collection_id])
      |> Product.Query.for_account(account.id)
      |> root_only_if_no_parent_id(filter[:parent_id])
      |> Repo.aggregate(:count, :id)

    preloads = Product.Query.preloads(request.preloads, role: request.role)
    products =
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
      data: products
    }

    {:ok, response}
  end

  defp root_only_if_no_parent_id(query, nil), do: Product.Query.root(query)
  defp root_only_if_no_parent_id(query, _), do: query

  defp default_order_if_no_collection_id(query, nil), do: Product.Query.default_order(query)
  defp default_order_if_no_collection_id(query, _), do: query

  defp product_response(nil, _), do: {:error, :not_found}

  defp product_response(product, request = %{ account: account }) do
    preloads = Product.Query.preloads(request.preloads, role: request.role)

    product =
      product
      |> Repo.preload(preloads)
      |> Product.put_external_resources(request.preloads, %{ account: account, role: request.role, locale: request.locale })
      |> Translation.translate(request.locale, account.default_locale)

    {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: product }}
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
    with {:ok, product} <- Service.create_product(request.fields, %{ account: account }) do
      product_response(product, request)
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  def get_product(request) do
    with {:ok, request} <- preprocess_request(request, "catalogue.get_product") do
      request
      |> do_get_product()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_product(request = %{ role: role, account: account, params: %{ "id" => id } }) when role in ["guest", "customer"] do
    product =
      Product.Query.default()
      |> Product.Query.active()
      |> Product.Query.for_account(account.id)
      |> Repo.get(id)

    product_response(product, request)
  end

  def do_get_product(request = %{ account: account, params: %{ "id" => id } }) do
    product =
      Product.Query.default()
      |> Product.Query.for_account(account.id)
      |> Repo.get(id)

    product_response(product, request)
  end

  def do_get_product(request = %{ role: role, account: account, params: %{ "code" => code } }) when role in ["guest", "customer"] do
    product =
      Product.Query.default()
      |> Product.Query.active()
      |> Product.Query.for_account(account.id)
      |> Repo.get_by(code: code)

    product_response(product, request)
  end

  def do_get_product(request = %{ account: account, params: %{ "code" => code } }) do
    product =
      Product.Query.default()
      |> Product.Query.for_account(account.id)
      |> Repo.get_by(code: code)

    product_response(product, request)
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
    with {:ok, product} <- Service.update_product(id, request.fields, %{ account: account }) do
      product_response(product, request)
    else
      %{ errors: errors } ->
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
    product =
      Product.Query.default()
      |> Product.Query.for_account(account.id)
      |> Repo.get(id)

    cond do
      product && product.avatar_id ->
        {:ok, _} = Repo.transaction(fn ->
          FileStorageService.delete_external_file(product.avatar_id)
          Repo.delete!(product)
        end)
        {:ok, %AccessResponse{}}

      product ->
        Repo.delete!(product)
        {:ok, %AccessResponse{}}

      !product ->
        {:error, :not_found}
    end
  end


  ######
  # ProductCollection
  ######
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
