defmodule BlueJet.Balance.Payment.Query do
  use BlueJet, :query

  alias BlueJet.Balance.{Payment, Refund}

  @searchable_fields [
    :code
  ]

  @filterable_fields [
    :id,
    :target_type,
    :target_id,
    :owner_id,
    :owner_type,
    :status,
    :gateway,
    :method,
    :label
  ]

  def default() do
    from p in Payment
  end

  def search(query, keyword, locale, default_locale) do
    search(query, @searchable_fields, keyword, locale, default_locale, Payment.translatable_fields())
  end

  def filter_by(query, filter) do
    filter_by(query, filter, @filterable_fields)
  end

  def for_target(query, target_type, target_id) do
    from p in query,
      where: p.target_type == ^target_type,
      where: p.target_id == ^target_id
  end

  def preloads({:refunds, refund_preloads}, options) do
    [refunds: {Refund.Query.default(), Refund.Query.preloads(refund_preloads, options)}]
  end
end