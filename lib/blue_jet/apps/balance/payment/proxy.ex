defmodule BlueJet.Balance.Payment.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Balance.{IdentityService, CrmService}

  def get_account(payment) do
    Map.get(payment, :account) || IdentityService.get_account(payment)
  end

  def put_account(payment) do
    %{ payment | account: get_account(payment) }
  end

  def get_owner(payment = %{ owner_type: "Customer" }) do
    account = get_account(payment)
    Map.get(payment, :owner) || CrmService.get_customer(%{ id: payment.owner_id }, %{ account: account })
  end

  def update_owner(payment = %{ owner_type: "Customer" }, fields) do
    customer = get_owner(payment)
    account = get_account(payment)

    CrmService.update_customer(customer, fields, %{ account: account })
  end

  def put(payment, _, _), do: payment
end