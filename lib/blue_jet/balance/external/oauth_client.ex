defmodule BlueJet.Balance.OauthClient do
  @oauth_client Application.get_env(:blue_jet, :balance)[:oauth_client]

  @callback get(String.t) :: {:ok | :error, map}
  @callback post(String.t, map) :: {:ok | :error, map}

  defdelegate get(path), to: @oauth_client
  defdelegate post(path, fields), to: @oauth_client
end