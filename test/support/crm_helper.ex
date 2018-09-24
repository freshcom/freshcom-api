defmodule BlueJet.CRM.TestHelper do
  alias BlueJet.CRM.Service
  import BlueJet.Utils, only: [stringify_keys: 1]

  def customer_fixture(account, fields \\ %{}) do
    default_fields = %{
      name: Faker.Name.name(),
      email: Faker.Internet.safe_email(),
      password: "test1234"
    }
    fields =
      default_fields
      |> Map.merge(fields)
      |> stringify_keys()

    {:ok, customer} = Service.create_customer(fields, %{account: account, skip_dispatch: true})

    customer
  end

  def point_transaction_fixture(account, point_account, fields \\ %{}) do
    default_fields = %{
      amount: System.unique_integer([:positive]),
      point_account_id: point_account.id
    }
    fields =
      default_fields
      |> Map.merge(fields)
      |> stringify_keys()

    {:ok, transaction} = Service.create_point_transaction(fields, %{account: account})

    transaction
  end
end
