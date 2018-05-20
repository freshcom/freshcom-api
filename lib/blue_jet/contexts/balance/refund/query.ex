defmodule BlueJet.Balance.Refund.Query do
  use BlueJet, :query

  alias BlueJet.Balance.Refund

  @searchable_fields [
    :code
  ]

  @filterable_fields [
    :status,
    :gateway,
    :processor,
    :method,
    :label,
    :owner_id,
    :owner_type,
    :target_id,
    :target_type
  ]

  def default() do
    from r in Refund
  end

  def search(query, keyword, locale, default_locale) do
    search(query, @searchable_fields, keyword, locale, default_locale, Refund.translatable_fields())
  end

  def filter_by(query, filter) do
    filter_by(query, filter, @filterable_fields)
  end
end