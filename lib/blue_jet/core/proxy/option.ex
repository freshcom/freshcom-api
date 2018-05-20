defmodule BlueJet.Proxy.Option do
  def get_sopts(%{ account_id: account_id, account: nil }) do
    %{ account_id: account_id }
  end

  def get_sopts(%{ account: account }) do
    %{ account: account }
  end
end