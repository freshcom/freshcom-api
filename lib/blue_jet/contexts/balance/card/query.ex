defmodule BlueJet.Balance.Card.Query do
  use BlueJet, :query
  use BlueJet.Query.Search, for: [
  ]
  use BlueJet.Query.Filter, for: [
    :id,
    :name,
    :status,
    :label,
    :last_four_digit,
    :owner_id,
    :owner_type,
    :primary
  ]

  alias BlueJet.Balance.Card

  def default() do
    from c in Card
  end

  def not_primary(query) do
    from c in query, where: c.primary != true
  end

  def except_id(query, id) do
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