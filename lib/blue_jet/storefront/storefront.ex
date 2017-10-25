defmodule BlueJet.Storefront do
  use BlueJet, :context

  alias Ecto.Changeset
  alias BlueJet.Identity.Customer
  alias BlueJet.Storefront.Product
  alias BlueJet.Storefront.ProductItem
  alias BlueJet.Storefront.Price
  alias BlueJet.Storefront.Order
  alias BlueJet.Storefront.OrderLineItem
  alias BlueJet.Storefront.Payment
  alias BlueJet.Storefront.StripePaymentError
  alias BlueJet.Storefront.Unlock
  alias BlueJet.Storefront.Refund

  alias BlueJet.Inventory.Unlockable
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
      product_item = ProductItem.preload(product_item, request.preloads)
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
      |> ProductItem.preload(request.preloads)
      |> Translation.translate(request.locale)

    product_item
  end

  def update_product_item(request = %{ vas: vas, product_item_id: product_item_id }) do
    defaults = %{ preloads: [], fields: %{}, locale: "en" }
    request = Map.merge(defaults, request)

    product_item = Repo.get_by!(ProductItem, account_id: vas[:account_id], id: product_item_id)

    with changeset = %{ valid?: true } <- ProductItem.changeset(product_item, request.fields, request.locale) do
      {:ok, product_item} = Repo.transaction(fn ->
        if Changeset.get_change(changeset, :primary) do
          product_id = product_item.product_id
          from(pi in ProductItem, where: pi.product_id == ^product_id)
          |> Repo.update_all(set: [primary: false])
        end

        Repo.update!(changeset)
      end)

      product_item =
        product_item
        |> ProductItem.preload(request.preloads)
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
      |> filter_by(sku_id: request.filter[:sku_id], unlockable_id: request.filter[:unlockable_id], product_id: request.filter[:product_id], status: request.filter[:status])
      |> where([s], s.account_id == ^account_id)
    result_count = Repo.aggregate(query, :count, :id)

    total_query = ProductItem |> where([s], s.account_id == ^account_id)
    total_count = Repo.aggregate(total_query, :count, :id)

    query = paginate(query, size: request.page_size, number: request.page_number)

    product_items =
      Repo.all(query)
      |> ProductItem.preload(request.preloads)
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
      |> Order.preload(request.preloads)
      |> Translation.translate(request.locale)

    order
  end

  def update_order(request = %{ vas: vas, order_id: order_id }) do
    defaults = %{ preloads: [], fields: %{}, locale: "en" }
    request = Map.merge(defaults, request)

    # If Customer trying to update, scope to order that belongs to that specific
    # Customer
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
      order = Repo.get!(Order, Changeset.get_field(changeset, :order_id))
      Repo.transaction(fn ->
        order_line_item = Repo.insert!(changeset)
        OrderLineItem.balance!(order_line_item)
        Order.balance!(order)
        order_line_item
      end)
    else
      other -> {:error, other}
    end
  end

  def update_order_line_item(request = %{ vas: vas, order_line_item_id: order_line_item_id }) do
    defaults = %{ preloads: [], fields: %{} }
    request = Map.merge(defaults, request)

    order_line_item = Repo.get_by!(OrderLineItem, account_id: vas[:account_id], id: order_line_item_id) |> Repo.preload(:order)

    with changeset = %{valid?: true} <- OrderLineItem.changeset(order_line_item, request.fields) do
      Repo.transaction(fn ->
        order_line_item = Repo.update!(changeset)
        OrderLineItem.balance!(order_line_item)
        Order.balance!(order_line_item.order)
        order_line_item
      end)
    else
      other -> {:error, other}
    end
  end

  def delete_order_line_item!(request = %{ vas: vas, order_line_item_id: order_line_item_id }) do
    defaults = %{ preloads: [], fields: %{} }
    request = Map.merge(defaults, request)

    order_line_item = Repo.get_by!(OrderLineItem, account_id: vas[:account_id], id: order_line_item_id)
    order = Repo.get_by!(Order, account_id: vas[:account_id], id: order_line_item.order_id)

    Repo.transaction(fn ->
      Repo.delete!(order_line_item)
      Order.balance!(order)
    end)
  end

  ####
  # Payment
  ####

  def get_payment!(request = %{ vas: vas, payment_id: payment_id }) do
    defaults = %{ locale: "en", preloads: [] }
    request = Map.merge(defaults, request)

    payment =
      Payment
      |> Repo.get_by!(account_id: vas[:account_id], id: payment_id)
      |> Payment.preload(request.preloads)
      |> Translation.translate(request.locale)

    payment
  end

  def create_payment(request = %{ vas: vas }) do
    defaults = %{ preloads: [], fields: %{} }
    request = Map.merge(defaults, request)
    fields = Map.merge(request.fields, %{ "account_id" => vas[:account_id] })
    changeset = Payment.changeset(%Payment{}, fields)

    order =
      Order
      |> Repo.get_by!(account_id: vas[:account_id], id: request.fields["order_id"])
      |> Repo.preload(:customer)

    Customer.preprocess(order.customer, request.fields)

    # TODO: handle stock and shipping errors
    create_payment(changeset, fields)
  end
  def create_payment(changeset = %Changeset{ valid?: true }, options) do
    # We create the charge first so that stripe_charge can have a reference to the charge,
    # since stripe_charge can't be rolled back this avoid an orphan stripe_charge
    # so we need to make sure what the stripe_charge is for and refund manually if needed
    Repo.transaction(fn ->
      payment = Repo.insert!(changeset) |> Repo.preload(:order)

      order_changeset = Changeset.change(payment.order, status: "opened")
      order = Repo.update!(order_changeset)

      with {:ok, _} <- Order.lock_stock(payment.order_id),
           {:ok, _} <- Order.lock_shipping_date(payment.order_id),
           {:ok, payment} <- Payment.process(payment, changeset, options),
           {:ok, order} <- Order.process(order, order_changeset)
      do
        payment
      else
        {:error, errors} -> Repo.rollback(errors)
      end
    end)
  end
  def create_payment(changeset, _) do
    {:error, changeset.errors}
  end

  def update_payment(request = %{ vas: vas, payment_id: payment_id }) do
    defaults = %{ preloads: [], fields: %{} }
    request = Map.merge(defaults, request)
    payment = Repo.get_by!(Payment, account_id: vas[:account_id], id: payment_id)
    update_payment(Payment.changeset(payment, request.fields), request.fields)
  end
  def update_payment(changeset = %Changeset{ valid?: true }, options) do
    Repo.transaction(fn ->
      payment = Repo.update!(changeset)
      with {:ok, payment} <- Payment.process(payment, changeset, options) do
        payment
      else
        {:error, errors} -> Repo.rollback(errors)
      end
    end)
  end
  def update_payment(changeset, _) do
    {:error, changeset.errors}
  end

  defp process_order(order) do
    order_changeset = Changeset.change(order, status: "opened", is_payment_balanced: true)
    order = Repo.update!(order_changeset)

    leaf_line_items = Order.leaf_line_items(order)
    Enum.each(leaf_line_items, fn(line_item) ->
      line_item
      |> Repo.preload([:sku, :unlockable])
      |> OrderLineItem.source()
      |> process_source(order)
    end)

    {:ok, order}
  end

  defp process_source(unlockable = %Unlockable{}, order) do
    # TODO: check if already unlocked, add the contraint to database
    changeset = Unlock.changeset(%Unlock{}, %{ account_id: unlockable.account_id, unlockable_id: unlockable.id, customer_id: order.customer_id })
    Repo.insert!(changeset)
  end
  defp process_source(source, order), do: source

  defp format_stripe_errors(stripe_errors) do
    [source: { stripe_errors["error"]["message"], [code: stripe_errors["error"]["code"], full_error_message: true] }]
  end

  def delete_payment!(request = %{ vas: vas, payment_id: payment_id }) do
    payment = Repo.get_by!(Payment, account_id: vas[:account_id], id: payment_id)
    Repo.delete!(payment)
  end

  ######
  # Refund
  ######
  def create_refund(request = %{ vas: vas }) do
    defaults = %{ preloads: [], fields: %{} }
    request = Map.merge(defaults, request)
    fields = Map.merge(request.fields, %{ "account_id" => vas[:account_id] })

    with changeset = %Changeset{ valid?: true } <- Refund.changeset(%Refund{}, fields),
      {:ok, refund} <- Repo.transaction(fn ->

        refund = Repo.insert!(changeset) |> Repo.preload(:payment)
        new_refunded_amount_cents = refund.payment.refunded_amount_cents + refund.amount_cents
        new_payment_status = if new_refunded_amount_cents >= refund.payment.paid_amount_cents do
          "refunded"
        else
          "partially_refunded"
        end

        payment_changeset = Changeset.change(refund.payment, %{ refunded_amount_cents: new_refunded_amount_cents, status: new_payment_status })
        payment = Repo.update!(payment_changeset)

        with {:ok, refund} <- process_refund(refund, payment) do
          refund
        else
          {:error, errors} -> Repo.rollback(errors)
        end

      end)
    do
      {:ok, refund}
    else
      {:error, changeset = %Changeset{}} -> {:error, changeset.errors}
      changeset = %Changeset{} -> {:error, changeset.errors}
      other -> other
    end
  end

  defp process_refund(refund, payment = %Payment{ gateway: "online", processor: "stripe" }) do
    with {:ok, stripe_refund} <- create_stripe_refund(refund, payment) do
      {:ok, refund}
    else
      {:error, stripe_errors} -> {:error, format_stripe_errors(stripe_errors)}
    end
  end
  defp process_refund(refund, _), do: {:ok, refund}

  defp create_stripe_refund(refund, payment) do
    StripeClient.post("/refunds", %{ charge: payment.stripe_charge_id, amount: refund.amount_cents, metadata: %{ fc_refund_id: refund.id }  })
  end
end
