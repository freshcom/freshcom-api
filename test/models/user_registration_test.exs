defmodule BlueJet.UserRegistrationTest do
  use BlueJet.ModelCase

  alias BlueJet.UserRegistration

  @valid_attrs %{
    first_name: Faker.Name.first_name(),
    last_name: Faker.Name.last_name(),
    password: "test1234",
    email: Faker.Internet.safe_email(),
    account_name: Faker.Company.name()
  }
  describe "sign_up/1" do
    test "with valid params" do
      {:ok, user} = UserRegistration.sign_up(@valid_attrs)

      assert user.first_name == @valid_attrs.first_name
      assert user.last_name == @valid_attrs.last_name
      assert user.email == @valid_attrs.email
    end

    test "with invalid attrs" do
      {:error, changeset} = UserRegistration.sign_up(%{})

      refute changeset.valid?
    end

    test "with duplicate email" do
      {:ok, _} = UserRegistration.sign_up(@valid_attrs)
      {:error, _} = UserRegistration.sign_up(@valid_attrs)
    end
  end
end
