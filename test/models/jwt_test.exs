defmodule BlueJet.JwtTest do
  use BlueJet.ModelCase

  alias BlueJet.Jwt

  @valid_attrs %{ name: "Default",  system_tag: "default", user_id: Ecto.UUID.generate(), account_id: Ecto.UUID.generate() }
  @invalid_attrs %{}

  describe "changeset/2" do
    test "with valid attrs" do
      changeset = Jwt.changeset(%Jwt{}, @valid_attrs)

      assert changeset.valid?
      assert changeset.changes.value
      assert changeset.changes.name
      assert changeset.changes.system_tag
    end

    test "with invalid attrs" do
      changeset = Jwt.changeset(%Jwt{}, @invalid_attrs)

      refute changeset.valid?
    end
  end

  describe "sign_token/1" do
    test "with valid claims" do
      signed_token = Jwt.sign_token(%{ jti: Ecto.UUID.generate() })

      assert signed_token
    end
  end

  describe "verify_token/1" do
    test "with valid signed token" do
      signed_token = Jwt.sign_token(%{ jti: Ecto.UUID.generate() })
      verified_token = Jwt.verify_token(signed_token)

      assert verified_token
    end
  end
end
