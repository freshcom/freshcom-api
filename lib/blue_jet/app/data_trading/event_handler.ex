defmodule BlueJet.DataTrading.EventHandler do
  alias BlueJet.DataTrading.Service

  @behaviour BlueJet.EventHandler

  def handle_event("identity:account.reset.success", %{account: account = %{mode: "test"}}) do
    Task.start(fn ->
      Service.delete_all_data_import(%{account: account})
    end)

    {:ok, nil}
  end

  def handle_event(_, _), do: {:ok, nil}
end
