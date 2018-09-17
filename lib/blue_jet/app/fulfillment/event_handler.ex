defmodule BlueJet.Fulfillment.EventHandler do
  alias BlueJet.Fulfillment.Service

  @behaviour BlueJet.EventHandler

  def handle_event("identity:account.reset.success", %{account: account = %{mode: "test"}}) do
    Task.start(fn ->
      Service.delete_all_fulfillment_package(%{account: account})
      Service.delete_all_return_package(%{account: account})
    end)

    {:ok, nil}
  end

  def handle_event(_, _), do: {:ok, nil}
end
