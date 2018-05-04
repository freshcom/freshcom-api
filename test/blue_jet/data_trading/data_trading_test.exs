defmodule BlueJet.DataTradingTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.{Account, User}
  alias BlueJet.DataTrading
  alias BlueJet.DataTrading.ServiceMock
  alias BlueJet.DataTrading.DataImport

  describe "create_data_import/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = DataTrading.create_data_import(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        user: %User{},
        role: "administrator",
        fields: %{ "data_url" => Faker.Internet.url() }
      }

      ServiceMock
      |> expect(:create_data_import, fn(fields, opts) ->
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, %DataImport{}}
         end)

      {:ok, _} = DataTrading.create_data_import(request)
    end
  end
end
