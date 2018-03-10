defmodule BlueJet.Balance.Service do
  @service Application.get_env(:blue_jet, :balance)[:service]

  @callback get_settings(map) :: Settings.t | nil
  @callback update_settings(Settings.t, map, map) :: {:ok, Settings.t} | {:error, any}
  @callback update_settings(map, map) :: {:ok, Settings.t} | {:error, any}

  @callback list_card(map, map) :: [Card.t]
  @callback count_card(map, map) :: integer
  @callback update_card(String.t | Card.t, map, map) :: {:ok, Card.t} | {:error, any}
  @callback delete_card(String.t | Card.t, map) :: {:ok, Card.t} | {:error, any}

  @callback list_payment(map, map) :: [Payment.t]
  @callback count_payment(map, map) :: integer
  @callback create_payment(map, map) :: {:ok, Payment.t} | {:error, any}
  @callback get_payment(map, map) :: Payment.t | nil
  @callback update_payment(String.t | Payment.t, map, map) :: {:ok, Payment.t} | {:error, any}
  @callback delete_payment(String.t | Payment.t, map) :: {:ok, Payment.t} | {:error, any}

  @callback create_refund(map, map) :: {:ok, Refund.t} | {:error, any}

  defdelegate get_settings(opts), to: @service
  defdelegate update_settings(settings, fields, opts), to: @service
  defdelegate update_settings(fields, opts), to: @service

  defdelegate list_card(params, opts), to: @service
  defdelegate count_card(params, opts), to: @service
  defdelegate update_card(id_or_card, fields, opts), to: @service
  defdelegate delete_card(id_or_card, opts), to: @service

  defdelegate list_payment(params, opts), to: @service
  defdelegate count_payment(params \\ %{}, opts), to: @service
  defdelegate create_payment(fields, opts), to: @service
  defdelegate get_payment(identifiers, opts), to: @service
  defdelegate update_payment(id_or_payment, fields, opts), to: @service
  defdelegate delete_payment(id_or_payment, opts), to: @service

  defdelegate create_refund(fields, opts), to: @service
end