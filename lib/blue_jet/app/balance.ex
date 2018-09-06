defmodule BlueJet.Balance do
  use BlueJet, :context
  use BlueJet.EventEmitter, namespace: :balance

  alias BlueJet.Balance.{Policy, Service}

  def get_settings(request) do
    with {:ok, args} <- Policy.authorize(request, "get_settings"),
         settings = %{} <- Service.get_settings(args[:opts])
    do
      {:ok, %ContextResponse{ meta: %{ locale: args[:locale] }, data: settings }}
    else
      nil -> {:error, :not_found}

      other -> other
    end
  end

  def update_settings(request) do
    with {:ok, args} <- Policy.authorize(request, "update_settings"),
         {:ok, settings} <- Service.update_settings(args[:fields], args[:opts])
    do
      {:ok, %ContextResponse{ meta: %{ locale: args[:locale] }, data: settings }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %ContextResponse{ errors: errors }}

      other -> other
    end
  end

  def list_card(req), do: list("card", req, __MODULE__)
  def update_card(req), do: update("card", req, __MODULE__)
  def delete_card(req), do: delete("card", req, __MODULE__)

  def list_payment(req), do: list("payment", req, __MODULE__)
  def create_payment(req), do: create("payment", req, __MODULE__)
  def get_payment(req), do: get("payment", req, __MODULE__)
  def update_payment(req), do: update("payment", req, __MODULE__)
  def delete_payment(req), do: delete("payment", req, __MODULE__)

  def create_refund(req), do: create("refund", req, __MODULE__)
end
