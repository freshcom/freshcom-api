defmodule BlueJet.DataTrading.Policy do
  use BlueJet, :policy

  def authorize(request = %{role: role}, "create_data_import")
      when role in ["developer", "administrator"] do
    {:ok, from_access_request(request, :create)}
  end

  def authorize(_, _) do
    {:error, :access_denied}
  end
end
