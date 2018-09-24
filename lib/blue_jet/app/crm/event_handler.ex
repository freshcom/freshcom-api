defmodule BlueJet.CRM.EventHandler do
  @moduledoc false

  @behaviour BlueJet.EventHandler

  alias BlueJet.CRM.Service

  @account_reset "identity:account.reset.success"
  @user_updated "identity:user.update.success"

  def handle_event(@account_reset, %{account: account = %{mode: "test"}}) do
    Task.start(fn -> Service.delete_all_customer(%{account: account}) end)

    {:ok, nil}
  end

  def handle_event(@user_updated, %{changeset: changeset, account: account}) do
    identifires = %{user_id: changeset.data.id}
    fields = Map.take(changeset.changes, [:email, :phone_number, :name, :first_name, :last_name])
    opts = %{account: account}

    case Service.update_customer(identifires, fields, opts) do
      {:error, :not_found} ->
        {:ok, nil}

      {:ok, customer} ->
        {:ok, customer}
    end
  end

  def handle_event(_, _) do
    {:ok, nil}
  end
end
