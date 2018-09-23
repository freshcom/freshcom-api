defmodule BlueJet.Crm.CustomerTest do
  use BlueJet.DataCase

  import BlueJet.Crm.TestHelper

  alias BlueJet.Identity.Account
  alias BlueJet.Crm.Customer

  describe "schema" do
    test "when account is deleted customer is automatically deleted" do
      account = account_fixture()
      customer = customer_fixture(account)

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
      :sponsor_id,
      :username,
      :password
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
    account = %Account{id: UUID.generate()}
    fields = %{
      "first_name" => Faker.Name.first_name(),
      "last_name" => Faker.Name.last_name(),
      "email" => " tEst@examp le.com "
    }

    changeset = Customer.changeset(%Customer{account: account}, :update, fields)

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
        %Customer{}
        |> change(%{})
        |> Customer.validate()

      assert changeset.valid? == true
    end

    test "when status is registered" do
      changeset =
        %Customer{status: "registered"}
        |> change(%{})
        |> Customer.validate()

      assert changeset.valid? == false
      assert match_keys(changeset.errors, [:name, :email])
    end
  end
end
