defmodule BlueJet.Balance do
  use BlueJet, :context
  use BlueJet.EventEmitter, namespace: :balance

  alias BlueJet.Balance.{Policy, Service}

  def get_settings(request) do
    with {:ok, args} <- Policy.authorize(request, "get_settings"),
         settings = %{} <- Service.get_settings(args[:opts])
    do
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: settings }}
    else
      nil -> {:error, :not_found}

      other -> other
    end
  end

  def update_settings(request) do
    with {:ok, args} <- Policy.authorize(request, "update_settings"),
         {:ok, settings} <- Service.update_settings(args[:fields], args[:opts])
    do
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: settings }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def list_card(req), do: list("card", req)
  def update_card(req), do: update("card", req)
  def delete_card(req), do: delete("card", req)

  def list_payment(req), do: list("payment", req)
  def create_payment(req), do: create("payment", req)
  def get_payment(req), do: get("payment", req)
  def update_payment(req), do: update("payment", req)
  def delete_payment(req), do: delete("payment", req)

  def create_refund(req), do: create("refund", req)
end
