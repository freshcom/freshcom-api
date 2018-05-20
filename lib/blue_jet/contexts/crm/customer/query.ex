defmodule BlueJet.Crm.Customer.Query do
  use BlueJet, :query

  alias BlueJet.Crm.{Customer, PointAccount}

  @searchable_fields [
    :code,
    :name,
    :email,
    :phone_number,
    :id
  ]

  @filterable_fields [
    :id,
    :status,
    :label
  ]

  def default() do
    from c in Customer
  end

  def search(query, keyword, locale, default_locale) do
    search(query, @searchable_fields, keyword, locale, default_locale, Customer.translatable_fields())
  end

  def filter_by(query, filter) do
    filter_by(query, filter, @filterable_fields)
  end

  def with_id_or_code(query, id_or_code) do
    case Ecto.UUID.dump(id_or_code) do
      :error -> from(c in query, where: c.code == ^id_or_code)
      _ -> from(c in query, where: (c.id == ^id_or_code) or (c.code == ^id_or_code))
    end
  end

  def preloads({:point_account, point_account_preloads}, options) do
    [point_account: {PointAccount.Query.default(), PointAccount.Query.preloads(point_account_preloads, options)}]
  end

  def preloads(_, _) do
    []
  end
end