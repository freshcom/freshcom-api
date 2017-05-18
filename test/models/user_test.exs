defmodule BlueJet.UserTest do
  use BlueJet.ModelCase

  alias BlueJet.User
  alias BlueJet.UserRegistration

  describe "User.changeset/1" do
    test "with valid attributes" do
      attrs = %{
        email: Faker.Internet.safe_email(),
        password: "test1234",
        first_name: Faker.Name.first_name(),
        last_name: Faker.Name.last_name(),
        default_account_id: Ecto.UUID.generate()
      }
      changeset = User.changeset(%User{}, attrs)

      assert changeset.valid?
      assert changeset.changes.encrypted_password
      assert Comeonin.Bcrypt.checkpw("test1234", changeset.changes.encrypted_password)
    end

    test "with invalid email" do
      attrs = %{ email: "test1@sdf", password: "test1234", first_name: Faker.Name.first_name(), last_name: Faker.Name.last_name() }

      changeset = User.changeset(%User{}, attrs)
      refute changeset.valid?
    end

    test "with loaded user and only email" do
      {:ok, user} = UserRegistration.sign_up(%{
        first_name: Faker.Name.first_name(),
        last_name: Faker.Name.last_name(),
        password: "test1234",
        email: Faker.Internet.safe_email(),
        account_name: Faker.Company.name()
      })

      changeset = User.changeset(user, %{ email: "test1234@example.com" })

      assert changeset.valid?
      assert changeset.changes.email
    end
  end
end
