defmodule BlueJet.UserTest do
  use BlueJet.ModelCase

  alias BlueJet.User
  alias BlueJet.Registration

  describe "User.changeset/1" do
    test "with valid attributes" do
      attrs = %{ email: "test1@example.com", password: "test1234", first_name: "Roy", last_name: "Bao" }
      changeset = User.changeset(%User{}, attrs)

      assert changeset.changes.encrypted_password
      assert changeset.valid?
      assert Comeonin.Bcrypt.checkpw("test1234", changeset.changes.encrypted_password)
    end

    test "with invalid email" do
      attrs = %{ email: "test1@sdf", password: "test1234", first_name: "Roy", last_name: "Bao" }

      changeset = User.changeset(%User{}, attrs)
      refute changeset.valid?
    end

    test "with loaded user and only email" do
      {:ok, user} = Registration.sign_up(%{
        first_name: Faker.Name.first_name,
        last_name: Faker.Name.last_name,
        password: "test1234",
        email: "test1@example.com",
        account_name: "Outersky"
      })

      changeset = User.changeset(user, %{ email: "test2@example.com" })

      assert changeset.valid?
      assert changeset.changes.email
    end
  end
end
