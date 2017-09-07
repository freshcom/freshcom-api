defmodule BlueJet.Storefront do
  use BlueJet, :context

  alias BlueJet.Storefront.Product
  alias BlueJet.Storefront.ProductItem
  alias BlueJet.Storefront.Price
  alias BlueJet.Storefront.Order
  alias BlueJet.Storefront.OrderLineItem
  alias BlueJet.Storefront.OrderCharge

  alias BlueJet.FileStorage.ExternalFile

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
      |> Product.preload(request.preloads)
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
        |> Product.preload(request.preloads)
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
      |> Product.preload(request.preloads)
      |> Translation.translate(request.locale)

    %{
      total_count: total_count,
      result_count: result_count,
      products: products
    }
  end

  def delete_product!(%{ vas: vas, product_id: product_id }) do
    product = Repo.get_by!(Product, account_id: vas[:account_id], id: product_id)

    Repo.transaction(fn ->
      if product.avatar_id do
        ef = Repo.get!(ExternalFile, product.avatar_id)
        ExternalFile.delete_object(ef)
        Repo.delete!(ef)
      end

      Repo.delete!(product)
    end)
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

    with changeset = %{ valid?: true } <- ProductItem.changeset(product_item, request.fields, request.locale) do
      {:ok, product_item} = Repo.transaction(fn ->
        if Ecto.Changeset.get_change(changeset, :primary) do
          product_id = product_item.product_id
          from(pi in ProductItem, where: pi.product_id == ^product_id)
          |> Repo.update_all(set: [primary: false])
        end

        Repo.update!(changeset)
      end)

      product_item =
        product_item
        |> Repo.preload(request.preloads)
        |> Translation.translate(request.locale)

      {:ok, product_item}
    else
      other -> {:error, other}
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

    case product_item.status do
      "disabled" ->
        Repo.delete!(product_item)
        {:ok, :deleted}
      _ ->
        errors = [id: {"Only Disabled Product Item can be deleted.", [validation: :only_disabled_can_be_deleted]}]
        {:error, errors}
    end
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
      |> filter_by(product_item_id: request.filter[:product_item_id], label: request.filter[:label])
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

    price = Repo.get_by!(Price, account_id: vas[:account_id], id: price_id)
    changeset = Price.changeset(price, request.fields, request.locale)

    with {:ok, price} <- Repo.update(changeset) do
      price =
        price
        |> Repo.preload(request.preloads)
        |> Translation.translate(request.locale)

      {:ok, price}
    else
      other -> other
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

  ####
  # Order
  ####
  def create_order(request = %{ vas: vas }) do
    defaults = %{ preloads: [], fields: %{} }
    request = Map.merge(defaults, request)

    fields = Map.merge(request.fields, %{ "account_id" => vas[:account_id], "customer_id" => vas[:customer_id] || request.fields["customer_id"] })
    changeset = Order.changeset(%Order{}, fields)

    with {:ok, order} <- Repo.insert(changeset) do
      order = Repo.preload(order, request.preloads)
      {:ok, order}
    else
      other -> other
    end
  end

  def get_order!(request = %{ vas: vas, order_id: order_id }) do
    defaults = %{ locale: "en", preloads: [] }
    request = Map.merge(defaults, request)

    order_scope =
      case vas[:customer_id] do
        nil -> Order
        customer_id -> from(o in Order, where: o.customer_id == ^customer_id)
      end

    order =
      order_scope
      |> Repo.get_by!(account_id: vas[:account_id], id: order_id)
      |> Repo.preload(request.preloads)
      |> Translation.translate(request.locale)

    order
  end

  def update_order(request = %{ vas: vas, order_id: order_id }) do
    defaults = %{ preloads: [], fields: %{}, locale: "en" }
    request = Map.merge(defaults, request)

    order_scope =
      case vas[:customer_id] do
        nil -> Order
        customer_id -> from(o in Order, where: o.customer_id == ^customer_id)
      end

    order = order_scope |> Repo.get_by!(account_id: vas[:account_id], id: order_id)

    changeset = Order.changeset(order, request.fields, request.locale)

    with {:ok, order} <- Repo.update(changeset) do
      order =
        order
        |> Repo.preload(request.preloads)
        |> Translation.translate(request.locale)

      {:ok, order}
    else
      other -> other
    end
  end

  def list_orders(request = %{ vas: vas }) do
    defaults = %{ search_keyword: "", filter: %{ status: "opened" }, page_size: 25, page_number: 1, locale: "en", preloads: [] }
    request = Map.merge(defaults, request, fn(k, v1, v2) ->
      case k do
        :filter -> if (map_size(v2) == 0), do: v1, else: v2
        _ -> v2
      end
    end)
    account_id = vas[:account_id]

    query =
      Order
      |> search([:first_name, :last_name, :code, :email, :phone_number, :id], request.search_keyword, request.locale)
      |> filter_by(
        status: request.filter[:status],
        label: request.filter[:label],
        delivery_address_province: request.filter[:delivery_address_province],
        delivery_address_city: request.filter[:delivery_address_city],
        payment_status: request.filter[:payment_status],
        payment_gateway: request.filter[:payment_gateway],
        payment_processor: request.filter[:payment_processor],
        payment_method: request.filter[:payment_method],
        fulfillment_method: request.filter[:fulfillment_method]
      )
      |> where([s], s.account_id == ^account_id)
    result_count = Repo.aggregate(query, :count, :id)

    total_query = Order |> where([s], s.account_id == ^account_id)
    total_count = Repo.aggregate(total_query, :count, :id)

    query = paginate(query, size: request.page_size, number: request.page_number)

    orders =
      Repo.all(query)
      |> Repo.preload(request.preloads)
      |> Translation.translate(request.locale)

    %{
      total_count: total_count,
      result_count: result_count,
      orders: orders
    }
  end

  def delete_order!(%{ vas: vas, order_id: order_id }) do
    order = Repo.get_by!(Order, account_id: vas[:account_id], id: order_id)
    Repo.delete!(order)
  end

  ####
  # Order Line Item
  ####
  def create_order_line_item(request = %{ vas: vas }) do
    defaults = %{ preloads: [], fields: %{} }
    request = Map.merge(defaults, request)

    fields = Map.merge(request.fields, %{ "account_id" => vas[:account_id] })

    with changeset = %{valid?: true} <- OrderLineItem.changeset(%OrderLineItem{}, fields) do
      order = Repo.get!(Order, Ecto.Changeset.get_field(changeset, :order_id))
      Repo.transaction(fn ->
        order_line_item = Repo.insert!(changeset)
        OrderLineItem.balance!(order_line_item)
        Order.balance!(order)
      end)
    end
  end

  ####
  # Order Charge
  ####
  def create_order_charge(request = %{ vas: vas }) do
    defaults = %{ preloads: [], fields: %{} }
    request = Map.merge(defaults, request)

    fields = Map.merge(request.fields, %{ "account_id" => vas[:account_id] })
    changeset = OrderCharge.changeset(%OrderCharge{}, fields)

    # We create the charge first so that stripe_charge can have a reference to the charge,
    # since stripe_charge can't be rolled back this avoid an orphan stripe_charge
    # so we need to make sure what the stripe_charge is for and refund manually if needed
    with {:ok, order_charge} <- Repo.insert(changeset),
         {:ok, order_charge} <- process_order_charge(order_charge, request.fields["payment_source"]) do

      {:ok, order_charge}
    else
      {:error, errors} -> errors
      other -> other
    end

    # create stripe customer if there is not already one
    # if request[:save_payment_source] then save the card
    # acquire lock
    # enforce inventory (before_charge)
    # check shipping date deadline not passed (before_charge)
    # charge through stripe
    # create the charge object
    # update order status and payment status (after_charge)
    # release lock
    with {:ok, order} <- Repo.insert(changeset) do
      order = Repo.preload(order, request.preloads)
      {:ok, order}
    else
      other -> other
    end
  end

  # Save the payment_source to the stripe_customer
  defp keep_payment_source(token_or_card_id, customer_id) do
  end

  # Process the order_charge through stripe
  defp process_order_charge(order_charge, payment_source) do
    order = Repo.get!(Order, order_charge.order_id)

    Repo.transaction(fn ->
      Order.enforce_inventory!(order_charge.order_id) # acquires lock until end of transaction
      Order.enforce_shipping_date_deadline!(order_charge.order_id)

      with {:ok, stripe_info} = keep_payment_source(payment_source, order_charge.customer_id),
           {:ok, stripe_charge} <- Stripe.Charges.create(order.grand_total_cents, source: stripe_info[:payment_source], customer: stripe_info[:stripe_customer_id], capture: order.is_estimate, metadata: %{ order_charge_id: order_charge.id })
      do
        charge_changeset = Ecto.Changeset.change(order_charge, status: "captured", stripe_charge_id: stripe_charge.id)
        Repo.update!(charge_changeset)

        order_changeset = Ecto.Changeset.change(order, status: "opened", payment_status: "paid", payment_gateway: "storefront", payment_processor: "stripe")
        order_charge = Repo.update!(order_changeset)

        {:ok, order_charge}
      else
        {:error, response} -> {:error, response}
      end
    end)
  end
end
