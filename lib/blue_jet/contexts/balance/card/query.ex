defmodule BlueJet.Balance.Card.Query do
  use BlueJet, :query

  alias BlueJet.Balance.Card

  @searchable_fields []

  @filterable_fields [
    :id,
    :name,
    :status,
    :label,
    :last_four_digit,
    :owner_id,
    :owner_type
  ]

  def default() do
    from c in Card
  end

  def search(query, keyword, locale, default_locale) do
    search(query, @searchable_fields, keyword, locale, default_locale, Card.translatable_fields())
  end

  def filter_by(query, filter) do
    filter_by(query, filter, @filterable_fields)
  end

  def not_primary(query) do
    from c in query, where: c.primary != true
  end

  def not_id(query, id) do
    from c in query, where: c.id != ^id
  end

  def with_owner(query, owner_type, owner_id) do
    from c in query,
      where: c.owner_type == ^owner_type,
      where: c.owner_id == ^owner_id
  end

  def with_status(query, status) do
    from c in query, where: c.status == ^status
  end
end