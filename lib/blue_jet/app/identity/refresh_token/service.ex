defmodule BlueJet.Identity.RefreshToken.Service do
  use BlueJet, :service

  alias BlueJet.Identity.RefreshToken

  @spec create_refresh_token!(map, map) :: RefreshToken.t()
  def create_refresh_token!(fields \\ %{}, opts) do
    account = extract_account(opts)

    Repo.insert!(%RefreshToken{
      account_id: account.id,
      user_id: fields["user_id"] || fields[:user_id]
    })
  end

  @spec get_refresh_token(map) :: RefreshToken.t() | nil
  def get_refresh_token(opts) do
    account = extract_account(opts)

    RefreshToken.Query.publishable()
    |> Repo.get_by!(account_id: account.id)
    |> RefreshToken.put_prefixed_id()
  end
end