defmodule BlueJet.FulfillmentTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.{Account, User}

  alias BlueJet.Fulfillment
  alias BlueJet.Fulfillment.{ServiceMock, FulfillmentPackage}

  describe "get_fulfillment_package/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "guest"
      }

      {:error, error} = Fulfillment.get_fulfillment_package(request)
      assert error == :access_denied
    end

    test "when request is valid" do
      fulfillment_package = %FulfillmentPackage{ id: Ecto.UUID.generate() }

      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "administrator",
        params: %{ "id" => fulfillment_package.id }
      }

      ServiceMock
      |> expect(:get_fulfillment_package, fn(identifiers, _) ->
          assert identifiers[:id] == fulfillment_package.id

          {:ok, %FulfillmentPackage{}}
         end)

      {:ok, _} = Fulfillment.get_fulfillment_package(request)
    end
  end
end
