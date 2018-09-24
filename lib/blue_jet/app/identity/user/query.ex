defmodule BlueJet.Identity.User.Query do
  import Ecto.Query
  import BlueJet.Query

  alias BlueJet.Identity.{User, AccountMembership}

  def identifiable_fields, do: [:id, :username, :password_reset_token, :email_verification_token]

  def default() do
    from(u in User)
  end

  def get_by(q, i), do: filter_by(q, i, identifiable_fields())

  def filter_by(q, f), do: filter_by(q, f, [:id, :code, :email])

  def standard(query) do
    from(u in query, where: is_nil(u.account_id))
  end

  def member_of_account(query, account_id) do
    from(
      u in query,
      join: ac in AccountMembership,
      on: ac.user_id == u.id,
      where: ac.account_id == ^account_id
    )
  end
end
