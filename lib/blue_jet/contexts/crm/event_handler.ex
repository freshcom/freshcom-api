defmodule BlueJet.Crm.EventHandler do
  alias BlueJet.Repo
  alias BlueJet.Crm.Customer
  alias BlueJet.Crm.Service

  @behaviour BlueJet.EventHandler

  def handle_event("identity.account.reset.success", %{account: account = %{mode: "test"}}) do
    Task.start(fn -> Service.delete_all_customer(%{account: account}) end)

    {:ok, nil}
  end

  def handle_event("identity.user.update.success", %{
        user: user,
        changeset: changeset,
        account: account
      }) do
    customer = Repo.get_by(Customer, user_id: user.id)

    if customer do
      fields = Map.take(changeset.changes, [:email, :phone_number, :name, :first_name, :last_name])
      Service.update_customer(customer, fields, %{account: account})
    else
      {:ok, nil}
    end
  end

  def handle_event(_, _) do
    {:ok, nil}
  end
end
