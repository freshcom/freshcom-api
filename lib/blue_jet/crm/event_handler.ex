defmodule BlueJet.Crm.EventHandler do
  alias BlueJet.Repo
  alias BlueJet.Crm.Customer
  alias BlueJet.Crm.Service

  @behaviour BlueJet.EventHandler

  def handle_event("identity.account.reset.success", %{ account: account = %{ mode: "test" } }) do
    Task.start(fn -> Service.delete_all_customer(%{ account: account }) end)

    {:ok, nil}
  end

  def handle_event("identity.user.update.success", %{ user: user, changeset: changeset, account: account }) do
    customer = Repo.get_by(Customer, user_id: user.id)
    fields = Map.take(changeset.changes, [:email, :phone_number, :name, :first_name, :last_name])

    {:ok, customer} = Service.update_customer(customer, fields, %{ account: account })
    {:ok, customer}
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