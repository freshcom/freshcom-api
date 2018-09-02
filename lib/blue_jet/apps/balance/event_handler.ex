defmodule BlueJet.Balance.EventHandler do
  alias BlueJet.Balance.Service

  @behaviour BlueJet.EventHandler

  def handle_event("identity.account.reset.success", %{account: account = %{mode: "test"}}) do
    Task.start(fn ->
      Service.delete_all_card(%{account: account})
      Service.delete_all_payment(%{account: account})
    end)

    Task.start(fn ->
      Service.delete_settings(%{account: account})
      Service.create_settings(%{account: account})
    end)

    {:ok, nil}
  end

  def handle_event("identity.account.create.success", %{
        account: account,
        test_account: test_account
      }) do
    {:ok, _} = Service.create_settings(%{account: account})
    {:ok, _} = Service.create_settings(%{account: test_account})

    {:ok, nil}
  end

  def handle_event(_, _), do: {:ok, nil}
end
