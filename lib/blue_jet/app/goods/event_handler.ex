defmodule BlueJet.Goods.EventHandler do
  @behaviour BlueJet.EventHandler

  alias BlueJet.Goods.Service

  def handle_event("identity:account.reset.success", %{account: account = %{mode: "test"}}) do
    Task.start(fn ->
      Service.delete_all_stockable(%{account: account})
      Service.delete_all_unlockable(%{account: account})
      Service.delete_all_depositable(%{account: account})
    end)

    {:ok, nil}
  end

  def handle_event(_, _) do
    {:ok, nil}
  end
end