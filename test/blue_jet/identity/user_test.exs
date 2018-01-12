defmodule BlueJet.UserTest do
  use BlueJet.DataCase

  alias BlueJet.Identity.Account
  alias BlueJet.Identity.User

  @valid_params %{
    email: Faker.Internet.safe_email(),
    password: "test1234",
    first_name: Faker.Name.first_name(),
    last_name: Faker.Name.last_name(),
    default_account_id: Ecto.UUID.generate()
  }

  test "writable_fields/0" do
    assert User.writable_fields == [
      :status,
      :username,
      :email,
      :name,
      :first_name,
      :last_name,
      :password,
      :current_password
    ]
  end

  describe "validate/1" do
    test "when missing required fields" do
      changeset =
        change(%User{}, %{})
        |> User.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:username, :password]
    end

    test "when given username less than 5 characters" do
      changeset =
        change(%User{}, %{ username: "abcd", password: "test1234" })
        |> User.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:username]
    end

    test "when given global username already exist" do
      account = Repo.insert!(%Account{ name: Faker.Company.name() })
      user = Repo.insert!(%User{
        username: "username",
        password: "test1234",
        default_account_id: account.id
      })
      {:error, changeset} =
        change(%User{}, %{
          username: user.username,
          password: "test1234",
          default_account_id: account.id
        })
        |> User.validate()
        |> Repo.insert()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:username]
    end

    # test "when given account username already exist" do
    #   account = Repo.insert!(%Account{ name: Faker.Company.name() })
    #   user = Repo.insert!(%User{
    #     username: "username",
    #     password: "test1234",
    #     default_account_id: account.id
    #   })
    #   {:error, changeset} =
    #     change(%User{}, %{
    #       username: user.username,
    #       password: "test1234",
    #       default_account_id: account.id
    #     })
    #     |> User.validate()
    #     |> Repo.insert()

    #   refute changeset.valid?
    #   assert Keyword.keys(changeset.errors) == [:username]
    # end


    test "when given password less than 8 characters" do
      changeset =
        change(%User{}, %{ username: "username", password: "abc" })
        |> User.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:password]
    end

    test "when given invalid email" do
      changeset =
        change(%User{}, %{ username: "username", email: "invalid", password: "test1234" })
        |> User.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:email]
    end

    test "when updating user password but did not provide current password" do
      user = %User{ username: "username" }

      changeset =
        user
        |> Ecto.put_meta(state: :loaded)
        |> change(%{ password: "newpassword" })
        |> User.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:current_password]
    end

    test "when updating user password but provided wrong current password" do
      user = %User{ username: "username" }

      changeset =
        user
        |> Ecto.put_meta(state: :loaded)
        |> change(%{ password: "newpassword", current_password: "wrongpassword" })
        |> User.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:current_password]
    end

    test "when user is alreay persisted and updating" do
      user = %User{ username: "username" }

      changeset =
        user
        |> Ecto.put_meta(state: :loaded)
        |> change(%{})
        |> User.validate()

      assert changeset.valid?
    end
  end

  # describe "changeset/1" do
  #   test "with valid params" do
  #     changeset = User.changeset(%User{}, @valid_params)

  #     assert changeset.valid?
  #     assert changeset.changes.encrypted_password
  #     assert Comeonin.Bcrypt.checkpw("test1234", changeset.changes.encrypted_password)
  #   end

  #   test "with invalid email" do
  #     attrs = %{ email: "test1@sdf", password: "test1234", first_name: Faker.Name.first_name(), last_name: Faker.Name.last_name() }

  #     changeset = User.changeset(%User{}, attrs)
  #     refute changeset.valid?
  #   end

  #   test "with loaded user and only email" do
  #     struct =
  #       %User{}
  #       |> Ecto.put_meta(state: :loaded)
  #       |> Map.merge(@valid_params)

  #     changeset = User.changeset(struct, %{ email: "test1234@example.com" })

  #     assert changeset.valid?
  #     assert changeset.changes.email
  #   end
  # end
end
