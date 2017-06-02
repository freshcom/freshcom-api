defmodule BlueJet.RefreshTokenTest do
  use BlueJet.ModelCase, async: true

  alias BlueJet.RefreshToken

  @valid_params %{
    user_id: Ecto.UUID.generate(),
    account_id: Ecto.UUID.generate()
  }
  @invalid_params %{}

  describe "changeset/2" do
    test "with valid attrs" do
      changeset = RefreshToken.changeset(%RefreshToken{}, @valid_params)

      assert changeset.valid?
    end

    test "with invalid attrs" do
      changeset = RefreshToken.changeset(%RefreshToken{}, @invalid_params)

      refute changeset.valid?
    end
  end

  describe "sign_token/1" do
    test "with valid claims" do
      signed_token = RefreshToken.sign_token(%{ })

      assert signed_token
    end
  end

  describe "verify_token/1" do
    test "with valid signed token" do
      signed_token = RefreshToken.sign_token(%{ })
      verified_token = RefreshToken.verify_token(signed_token)

      assert verified_token
    end
  end
end
