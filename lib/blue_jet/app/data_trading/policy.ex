defmodule BlueJet.DataTrading.Policy do
  use BlueJet, :policy

  def authorize(%{vas: vas, _role_: nil} = req, endpoint) do
    identity_service =
      Atom.to_string(__MODULE__)
      |> String.split(".")
      |> Enum.drop(-1)
      |> Enum.join(".")
      |> Module.concat(IdentityService)

    vad = identity_service.get_vad(vas)
    role = identity_service.get_role(vad)
    default_locale = if vad[:account], do: vad[:account].default_locale, else: nil

    req
    |> Map.put(:_vad_, vad)
    |> Map.put(:_role_, role)
    |> Map.put(:_default_locale_, default_locale)
    |> authorize(endpoint)
  end

  def authorize(%{_role_: role} = req, :create_data_import)
      when role in ["developer", "administrator"] do
    {:ok, req}
  end

  def authorize(_, _) do
    {:error, :access_denied}
  end
end
