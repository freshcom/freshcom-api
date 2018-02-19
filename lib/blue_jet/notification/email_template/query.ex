defmodule BlueJet.Notification.EmailTemplate.Query do
  use BlueJet, :query

  alias BlueJet.Notification.EmailTemplate

  def default() do
    from et in EmailTemplate, order_by: [desc: :updated_at]
  end

  def for_account(query, account_id) do
    from et in query, where: et.account_id == ^account_id
  end

  def preloads(_, _) do
    []
  end
end