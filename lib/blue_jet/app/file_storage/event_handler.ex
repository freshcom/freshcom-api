defmodule BlueJet.FileStorage.EventHandler do
  alias BlueJet.FileStorage.Service

  @behaviour BlueJet.EventHandler

  def handle_event("identity:account.reset.success", %{account: account = %{mode: "test"}}) do
    Task.start(fn ->
      Service.delete_all_file_collection(%{account: account})
      Service.delete_all_file(%{account: account})
    end)

    {:ok, nil}
  end

  def handle_event(_, _), do: {:ok, nil}
end
