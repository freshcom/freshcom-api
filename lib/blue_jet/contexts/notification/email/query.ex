defmodule BlueJet.Notification.Email.Query do
  use BlueJet, :query

  use BlueJet.Query.Search,
    for: [
      :to,
      :from,
      :subject,
      :reply_to
    ]

  use BlueJet.Query.Filter,
    for: [
      :id,
      :status
    ]

  alias BlueJet.Notification.Email

  def default() do
    from(e in Email)
  end

  def preloads(_, _) do
    []
  end
end
