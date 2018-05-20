defmodule BlueJet.Crm.PointTransaction.Query do
  use BlueJet, :query

  alias BlueJet.Crm.{PointTransaction, PointAccount}

  @filterable_fields [
    :status,
    :label,
    :point_account_id,
    :reason_label,
  ]

  @searchable_fields [
    :name,
    :caption
  ]

  def default() do
    from(pt in PointTransaction, order_by: [desc: pt.inserted_at])
  end

  def filter_by(query, filter) do
    filter_by(query, filter, @filterable_fields)
  end

  def search(query, keyword, locale, default_locale) do
    search(query, @searchable_fields, keyword, locale, default_locale, PointTransaction.translatable_fields())
  end

  def committed(query) do
    from pt in query, where: pt.status == "committed"
  end

  def only(query, limit) do
    from pt in query, limit: ^limit
  end

  def for_point_account(query, point_account_id) do
    from(pt in query, where: pt.point_account_id == ^point_account_id)
  end

  def preloads({:point_account, point_account_preloads}, options) do
    [point_account: {PointAccount.Query.default(), PointAccount.Query.preloads(point_account_preloads, options)}]
  end

  def preloads(_, _) do
    []
  end
end