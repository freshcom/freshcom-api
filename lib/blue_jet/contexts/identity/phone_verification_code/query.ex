defmodule BlueJet.Identity.PhoneVerificationCode.Query do
  use BlueJet, :query

  alias BlueJet.Identity.PhoneVerificationCode

  @filterable_fields [
    :phone_number,
    :value
  ]

  def default() do
    from pvc in PhoneVerificationCode
  end

  def filter_by(query, filter) do
    filter_by(query, filter, @filterable_fields)
  end
end