defmodule BlueJet.Identity.JwtTest do
  use BlueJet.DataCase

  alias BlueJet.Identity.Jwt

  test "sign_token/1" do
    assert Jwt.sign_token(%{"data" => "value"})
  end

  describe "verify_token/1" do
    test "when given invalid token" do
      {valid, _} = Jwt.verify_token("test")

      refute valid
    end

    test "when given valid token" do
      signed = Jwt.sign_token(%{"data" => "value"})
      {valid, claims} = Jwt.verify_token(signed)

      assert valid
      assert claims["data"] == "value"
    end
  end
end
