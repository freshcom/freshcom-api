defmodule BlueJet.Policy.Common do
  def common do
    quote do
      def authorize(request = %{ role: nil }, endpoint) do
        identity_service =
          Atom.to_string(__MODULE__)
          |> String.split(".")
          |> Enum.drop(-1)
          |> Enum.join(".")
          |> Module.concat(IdentityService)

        request
        |> identity_service.put_vas_data()
        |> authorize(endpoint)
      end
    end
  end

  defmacro __using__(_) do
    common()
  end
end