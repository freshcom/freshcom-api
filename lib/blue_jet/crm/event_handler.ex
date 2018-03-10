defmodule BlueJet.Crm.EventHandler do
  alias BlueJet.Repo
  alias BlueJet.Crm.Customer
  alias BlueJet.Crm.Service

  @behaviour BlueJet.EventHandler

  def handle_event("identity.account.reset.success", %{ account: account = %{ mode: "test" } }) do
    Task.start(fn -> Service.delete_all_customer(%{ account: account }) end)

    {:ok, nil}
  end

  def handle_event("balance.payment.create.before", %{ fields: fields = %{ "owner_type" => "Customer", "owner_id" => customer_id } }) do
    customer = Repo.get!(Customer, customer_id)
    customer = Customer.ensure_stripe_customer(customer, payment_processor: "stripe")
    fields = Map.put(fields, "stripe_customer_id", customer.stripe_customer_id)

    {:ok, fields}
  end

  def handle_event("balance.payment.create.before", %{ fields: fields }), do: {:ok, fields}

  def handle_event(_, _) do
    {:ok, nil}
  end
end