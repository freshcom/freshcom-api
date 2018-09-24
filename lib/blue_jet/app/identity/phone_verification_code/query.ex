defmodule BlueJet.Identity.PhoneVerificationCode.Query do
  import Ecto.Query
  import BlueJet.Query

  alias BlueJet.Identity.PhoneVerificationCode

  def default() do
    from(pvc in PhoneVerificationCode)
  end

  def filter_by(q, f), do: filter_by(q, f, [:phone_number, :value])
end
