defmodule BlueJet.Balance.StripeClient do
  @stripe_client Application.get_env(:blue_jet, :balance)[:stripe_client]

  @callback get(String.t, list) :: {:ok | :error, map}
  @callback post(String.t, map, list) :: {:ok | :error, map}
  @callback delete(String.t, list) :: {:ok | :error, map}

  defdelegate get(path, opts), to: @stripe_client
  defdelegate post(path, fields, opts), to: @stripe_client
  defdelegate delete(path, opts), to: @stripe_client
end