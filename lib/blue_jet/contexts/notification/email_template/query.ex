defmodule BlueJet.Notification.EmailTemplate.Query do
  use BlueJet, :query
  use BlueJet.Query.Search, for: [
    :name,
    :subject,
    :to,
    :reply_to
  ]
  use BlueJet.Query.Filter, for: [
    :id,
    :from
  ]

  alias BlueJet.Notification.EmailTemplate

  def default() do
    from et in EmailTemplate
  end

  def preloads(_, _) do
    []
  end
end