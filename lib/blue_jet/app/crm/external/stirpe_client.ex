defmodule BlueJet.CRM.StripeClient do
  @moduledoc false

  @stripe_client Application.get_env(:blue_jet, :crm)[:stripe_client]

  @callback post(String.t(), map, list) :: {:ok | :error, map}

  defdelegate post(path, fields, opts), to: @stripe_client
end
