defmodule BlueJet.Identity.Password.Query do
  import Ecto.Query

  alias BlueJet.Identity.{Password}

  def default() do
    from(p in Password)
  end

  def standard(query) do
    from(p in query, where: is_nil(p.account_id))
  end

  def with_valid_reset_token(query) do
    now = Timex.now()
    from(p in query, where: p.reset_token_expires_at > ^now)
  end
end
