defmodule BlueJet.Query do
  import Ecto.Query

  def for_account(query, nil) do
    from q in query, where: is_nil(q.account_id)
  end

  def for_account(query, account_id) do
    from q in query, where: q.account_id == ^account_id
  end

  def sort_by(query, sort) do
    from q in query, order_by: ^sort
  end

  def paginate(query, size: size, number: number) do
    limit = size
    offset = size * (number - 1)

    query
    |> limit(^limit)
    |> offset(^offset)
  end

  def id_only(query) do
    from r in query, select: r.id
  end
end