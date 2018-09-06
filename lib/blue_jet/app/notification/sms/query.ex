defmodule BlueJet.Notification.Sms.Query do
  use BlueJet, :query

  use BlueJet.Query.Search,
    for: [
      :to,
      :body
    ]

  use BlueJet.Query.Filter,
    for: [
      :id,
      :status,
      :to
    ]

  alias BlueJet.Notification.Sms

  def default() do
    from(s in Sms)
  end

  def preloads(_, _) do
    []
  end
end
