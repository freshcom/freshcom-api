defmodule BlueJet.Identity.RefreshToken.Query do
  use BlueJet, :query

  alias BlueJet.Identity.RefreshToken

  def default() do
    from(rt in RefreshToken)
  end

  def for_user(user_id) do
    from(rt in RefreshToken, where: rt.user_id == ^user_id)
  end

  def publishable() do
    from(rt in RefreshToken, where: is_nil(rt.user_id))
  end
end