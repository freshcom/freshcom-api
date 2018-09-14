defmodule BlueJet.Identity.AuthenticationTest do
  use BlueJet.DataCase

  alias BlueJet.Identity.Authentication.Service

  describe "deserialize_scope/1" do
    test "with valid scope using abbreviation" do
      scope = Service.deserialize_scope("aid:test-test-test", %{ aid: :account_id })

      assert scope.account_id == "test-test-test"
    end

    test "with valid scope using full name" do
      scope = Service.deserialize_scope("account_id:test-test-test", %{ aid: :account_id })

      assert scope.account_id == "test-test-test"
    end

    test "with partially valid scope" do
      scope = Service.deserialize_scope("aid:test-test-test,ddd", %{ aid: :account_id })

      assert scope.account_id == "test-test-test"
    end
  end
end
