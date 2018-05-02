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
    with {:ok, authorize_args} <- Policy.authorize(request, "create_product_collection") do
      do_create_product_collection(authorize_args)
    else
      other -> other
    end
  end

  def do_create_product_collection(args) do
    with {:ok, product_collection} <- Service.create_product_collection(args[:fields], args[:opts]) do
      product_collection = Translation.translate(product_collection, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: product_collection }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_product_collection(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "get_product_collection") do
      do_get_product_collection(authorize_args)
    else
      other -> other
    end
  end

  def do_get_product_collection(args) do
    product_collection =
      Service.get_product_collection(args[:identifiers], args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    if product_collection do
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: product_collection }}
    else
      {:error, :not_found}
    end
  end

  def update_product_collection(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "update_product_collection") do
      do_update_product_collection(authorize_args)
    else
      other -> other
    end
  end

  def do_update_product_collection(args) do
    with {:ok, product_collection} <- Service.update_product_collection(args[:id], args[:fields], args[:opts]) do
      product_collection = Translation.translate(product_collection, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: product_collection }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_product_collection(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "delete_product_collection") do
      do_delete_product_collection(authorize_args)
    else
      other -> other
    end
  end

  def do_delete_product_collection(args) do
    with {:ok, _} <- Service.delete_product_collection(args[:id], args[:opts]) do
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
  def list_product_collection_membership(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "list_product_collection_membership") do
      do_list_product_collection_membership(authorize_args)
    else
      other -> other
    end
  end

  def do_list_product_collection_membership(args) do
    total_count =
      %{ filter: args[:filter] }
      |> Service.count_product_collection_membership(args[:opts])

    all_count =
      %{ filter: args[:all_count_filter] }
      |> Service.count_product_collection_membership(args[:opts])

    pcms =
      %{ filter: args[:filter] }
      |> Service.list_product_collection_membership(args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    response = %AccessResponse{
      meta: %{
        locale: args[:locale],
        all_count: all_count,
        total_count: total_count
      },
      data: pcms
    }

    {:ok, response}
  end

  def create_product_collection_membership(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "create_product_collection_membership") do
      do_create_product_collection_membership(authorize_args)
    else
      other -> other
    end
  end

  def do_create_product_collection_membership(args) do
    with {:ok, pcm} <- Service.create_product_collection_membership(args[:fields], args[:opts]) do
      pcm = Translation.translate(pcm, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: pcm }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_product_collection_membership(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "delete_product_collection_membership") do
      do_delete_product_collection_membership(authorize_args)
    else
      other -> other
    end
  end

  def do_delete_product_collection_membership(args) do
    with {:ok, _} <- Service.delete_product_collection_membership(args[:id], args[:opts]) do
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
  def list_price(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "list_price") do
      do_list_price(authorize_args)
    else
      other -> other
    end
  end

  def do_list_price(args) do
    total_count =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.count_price(args[:opts])

    all_count =
      %{ filter: args[:all_count_filter] }
      |> Service.count_price(args[:opts])

    prices =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.list_price(args[:opts])
      |> Translation.translate(args[:opts], args[:default_locale])

    response = %AccessResponse{
      meta: %{
        locale: args[:locale],
        all_count: all_count,
        total_count: total_count
      },
      data: prices
    }

    {:ok, response}
  end

  def create_price(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "create_price") do
      do_create_price(authorize_args)
    else
      other -> other
    end
  end

  def do_create_price(args) do
    with {:ok, price} <- Service.create_price(args[:fields], args[:opts]) do
      price = Translation.translate(price, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: price }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_price(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "get_price") do
      do_get_price(authorize_args)
    else
      other -> other
    end
  end

  def do_get_price(args) do
    price =
      Service.get_price(args[:identifiers], args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    if price do
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: price }}
    else
      {:error, :not_found}
    end
  end

  def update_price(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "update_price") do
      do_update_price(authorize_args)
    else
      other -> other
    end
  end

  def do_update_price(args) do
    with {:ok, price} <- Service.update_price(args[:id], args[:fields], args[:opts]) do
      price = Translation.translate(price, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: price }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_price(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "delete_price") do
      do_delete_price(authorize_args)
    else
      other -> other
    end
  end

  def do_delete_price(args) do
    with {:ok, _} <- Service.delete_price(args[:id], args[:opts]) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end
end
