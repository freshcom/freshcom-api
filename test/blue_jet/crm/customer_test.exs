defmodule BlueJet.Crm.CustomerTest do
  use BlueJet.DataCase

  import Mox

  alias BlueJet.Identity.Account
  alias BlueJet.Crm.Customer
  alias BlueJet.Crm.IdentityServiceMock

  describe "schema" do
    test "when account is deleted customer is automatically deleted" do
      account = Repo.insert!(%Account{})
      customer = Repo.insert!(%Customer{
        account_id: account.id
      })
      Repo.delete!(account)

      refute Repo.get(Customer, customer.id)
    end

    test "defaults" do
      customer = %Customer{}

      assert customer.status == "guest"
    end
  end

  test "writable_fields/0" do
    assert Customer.writable_fields() == [
      :status,
      :code,
      :name,
      :label,
      :first_name,
      :last_name,
      :email,
      :phone_number,
      :caption,
      :description,
      :custom_data,
      :translations,
      :stripe_customer_id,
      :user_id,
      :enroller_id,
      :sponsor_id
    ]
  end

  test "changeset/3" do
    fields = %{
      "first_name" => Faker.Name.first_name(),
      "last_name" => Faker.Name.last_name(),
      "email" => " tEst@examp le.com "
    }

    changeset = Customer.changeset(%Customer{}, :insert, fields)

    assert changeset.action == :insert
    assert changeset.changes.name == fields["first_name"] <> " " <> fields["last_name"]
    assert changeset.changes.email == "test@example.com"
  end

  test "changeset/5" do
    fields = %{
      "first_name" => Faker.Name.first_name(),
      "last_name" => Faker.Name.last_name(),
      "email" => " tEst@examp le.com "
    }

    changeset = Customer.changeset(%Customer{ account: %Account{} }, :update, fields)

    assert changeset.action == :update
    assert changeset.changes.name == fields["first_name"] <> " " <> fields["last_name"]
    assert changeset.changes.email == "test@example.com"
  end

  test "changeset/2" do
    changeset = Customer.changeset(%Customer{}, :delete)

    assert changeset.action == :delete
  end

  describe "validate/1" do
    test "when status is guest" do
      changeset =
        change(%Customer{}, %{})
        |> Customer.validate()

      assert changeset.valid? == true
    end

    test "when status is registered" do
      changeset =
        change(%Customer{ status: "registered" }, %{})
        |> Customer.validate()

      assert changeset.valid? == false
      assert Keyword.keys(changeset.errors) == [:name, :email]
    end
  end

  describe "put_user_id/1" do
    test "when status is changed to registered" do
      user_id = Ecto.UUID.generate()

      IdentityServiceMock
      |> expect(:create_user, fn(fields, _) ->
          assert fields[:role] == "customer"

          {:ok, %{ id: user_id }}
         end)

      {:ok, changeset} =
        change(%Customer{ account: %Account{} }, %{ status: "registered" })
        |> Customer.put_user_id()

      assert changeset.changes.user_id == user_id
    end

    test "when status did not change to registered" do
      {:ok, changeset} =
        change(%Customer{ account: %Account{} }, %{})
        |> Customer.put_user_id()

      assert changeset.changes[:user_id] == nil
    end
  end
end
