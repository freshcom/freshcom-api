defmodule BlueJet.CRM.Customer.Query do
  @behaviour BlueJet.Query

  use BlueJet, :query

  alias BlueJet.CRM.{Customer, PointAccount}

  def identifiable_fields, do: [:id, :code, :email, :status, :user_id]
  def filterable_fields, do: [:id, :status, :label]
  def searchable_fields, do: [:id, :code, :name, :email, :phone_number]

  def default(), do: from(c in Customer)
  def get_by(q, i), do: filter_by(q, i, identifiable_fields())
  def filter_by(q, f), do: filter_by(q, f, filterable_fields())
  def search(q, k, l, d),
    do: search(q, k, l, d, searchable_fields(), Customer.translatable_fields())

  def preloads({:point_account, point_account_preloads}, options) do
    [
      point_account:
        {PointAccount.Query.default(),
         PointAccount.Query.preloads(point_account_preloads, options)}
    ]
  end

  def preloads(_, _) do
    []
  end

  def with_id_or_code(query, id_or_code) do
    case Ecto.UUID.dump(id_or_code) do
      :error -> from(c in query, where: c.code == ^id_or_code)
      _ -> from(c in query, where: c.id == ^id_or_code or c.code == ^id_or_code)
    end
  end
end
