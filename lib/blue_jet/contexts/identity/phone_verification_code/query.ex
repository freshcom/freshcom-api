defmodule BlueJet.Identity.PhoneVerificationCode.Query do
  use BlueJet, :query

  use BlueJet.Query.Filter,
    for: [
      :phone_number,
      :value
    ]

  alias BlueJet.Identity.PhoneVerificationCode

  def default() do
    from(pvc in PhoneVerificationCode)
  end
end
