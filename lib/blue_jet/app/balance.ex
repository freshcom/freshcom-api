defmodule BlueJet.Balance do
  use BlueJet, :context
  import BlueJet.ControlFlow
  alias BlueJet.Balance.{Policy, Service}

  def get_settings(req) do
    Policy.authorize(req, :get_settings)
    ~>> do_get_settings()
  end

  def do_get_settings(req) do
    case Service.get_settings(%{account: req._vad_.account}) do
      nil -> {:error, :not_found}
      settings -> {:ok, %ContextResponse{meta: %{locale: req.locale}, data: settings}}
    end
  end

  def update_settings(req) do
    Policy.authorize(req, :update_settings)
    ~>> do_get_settings()
  end

  def do_update_settings(req) do
    case Service.update_settings(req.fields, %{account: req._vad_.account}) do
      {:error, %{errors: errors}} -> {:error, %ContextResponse{errors: errors}}
      {:ok, settings} -> {:ok, %ContextResponse{meta: %{locale: req.locale}, data: settings}}
    end
  end

  def list_card(req), do: default(req, :list, :card, Policy, Service)
  def create_card(req), do: default(req, :create, :card, Policy, Service)
  def get_card(req), do: default(req, :get, :card, Policy, Service)
  def update_card(req), do: default(req, :update, :card, Policy, Service)
  def delete_card(req), do: default(req, :delete, :card, Policy, Service)

  def list_payment(req), do: default(req, :list, :payment, Policy, Service)
  def create_payment(req), do: default(req, :create, :payment, Policy, Service)
  def get_payment(req), do: default(req, :get, :payment, Policy, Service)
  def update_payment(req), do: default(req, :update, :payment, Policy, Service)
  def delete_payment(req), do: default(req, :delete, :payment, Policy, Service)

  def create_refund(req), do: create("refund", req, __MODULE__)
end
