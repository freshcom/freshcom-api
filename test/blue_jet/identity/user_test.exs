defmodule BlueJet.UserTest do
  use BlueJet.DataCase, async: true

  alias BlueJet.Identity.User

  @valid_params %{
    email: Faker.Internet.safe_email(),
    password: "test1234",
    first_name: Faker.Name.first_name(),
    last_name: Faker.Name.last_name(),
    default_account_id: Ecto.UUID.generate()
  }

  describe "changeset/1" do
    test "with valid params" do
      changeset = User.changeset(%User{}, @valid_params)

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
      struct =
        %User{}
        |> Ecto.put_meta(state: :loaded)
        |> Map.merge(@valid_params)

      changeset = User.changeset(struct, %{ email: "test1234@example.com" })

      assert changeset.valid?
      assert changeset.changes.email
    end
  end
end
