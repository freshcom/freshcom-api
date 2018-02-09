defmodule BlueJet.Crm.EventHandler do
  @behaviour BlueJet.EventHandler

  alias BlueJet.Repo
  alias BlueJet.Crm.Customer

  def handle_event("balance.payment.before_create", %{ fields: fields = %{ "owner_type" => "Customer", "owner_id" => customer_id } }) do
    customer = Repo.get!(Customer, customer_id)
    customer = Customer.ensure_stripe_customer(customer, payment_processor: "stripe")
    fields = Map.put(fields, "stripe_customer_id", customer.stripe_customer_id)

    {:ok, fields}
  end

  def handle_event("balance.payment.before_create", %{ fields: fields }), do: {:ok, fields}

  def handle_event(_, _) do
    {:ok, nil}
  end
end