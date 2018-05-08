defmodule BlueJet.Catalogue.EventHandler do
  alias BlueJet.Catalogue.Service

  @behaviour BlueJet.EventHandler

  def handle_event("identity.account.reset.success", %{ account: account = %{ mode: "test" } }) do
    Task.start(fn ->
      Service.delete_all_product_collection(%{ account: account })
      Service.delete_all_product(%{ account: account })
    end)

    {:ok, nil}
  end

  def handle_event(_, _) do
    {:ok, nil}
  end
end