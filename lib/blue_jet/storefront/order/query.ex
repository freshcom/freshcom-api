  defmodule BlueJet.Storefront.Order.Query do
    use BlueJet, :query

    alias BlueJet.Storefront.Order
    alias BlueJet.Storefront.OrderLineItem

    @searchable_fields [
      :name,
      :email,
      :phone_number,
      :code,
      :id
    ]

    @filterable_fields [
      :status,
      :customer_id
    ]

    def default() do
      from(o in Order, order_by: [desc: o.opened_at, desc: o.inserted_at])
    end

    def search(query, keyword, locale, default_locale) do
      search(query, @searchable_fields, keyword, locale, default_locale, Order.translatable_fields())
    end

    def filter_by(query, filter) do
      filter_by(query, filter, @filterable_fields)
    end

    def for_account(query, account_id) do
      from(o in query, where: o.account_id == ^account_id)
    end

    def opened(query) do
      from o in query, where: o.status == "opened"
    end

    def not_cart(query) do
      from(o in query, where: o.status != "cart")
    end

    def preloads({:root_line_items, root_line_item_preloads}, options) do
      [root_line_items: {OrderLineItem.Query.root(), OrderLineItem.Query.preloads(root_line_item_preloads, options)}]
    end

    def preloads(_, _) do
      []
    end
  end