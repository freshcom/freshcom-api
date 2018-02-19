defmodule BlueJet.Balance.EventHandler do
  alias BlueJet.Repo
  alias BlueJet.Balance.Settings

  @behaviour BlueJet.EventHandler

  def handle_event("identity.account.create.success", %{ account: account, test_account: test_account }) do
    %Settings{ account_id: account.id }
    |> Repo.insert!()

    %Settings{ account_id: test_account.id }
    |> Repo.insert!()

    {:ok, nil}
  end

  def handle_event(_, _), do: {:ok, nil}
end
