defmodule BlueJet.Notification.SmsTemplate.Query do
  use BlueJet, :query
  use BlueJet.Query.Search, for: [
    :name,
    :to
  ]
  use BlueJet.Query.Filter, for: [
    :id
  ]

  alias BlueJet.Notification.SmsTemplate

  def default() do
    from st in SmsTemplate
  end

  def preloads(_, _) do
    []
  end
end