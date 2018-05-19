defmodule BlueJet.Balance.SettingsTest do
  use BlueJet.DataCase

  import Mox

  alias BlueJet.Identity.Account
  alias BlueJet.Balance.Settings
  alias BlueJet.Balance.OauthClientMock

  test "writable_fields/0" do
    assert Settings.writable_fields() == [
      :stripe_user_id,
      :country,
      :default_currency,
      :stripe_auth_code
    ]
  end

  describe "changeset/3" do
    test "when valid stripe_auth_code provided" do
      auth_code = "code"
      stripe_response = %{
        "stripe_user_id" => Faker.Lorem.word(),
        "stripe_livemode" => false,
        "stripe_access_token" => Faker.Lorem.word(),
        "stripe_refresh_token" => Faker.Lorem.word(),
        "stripe_publishable_key" => Faker.Lorem.word(),
        "stripe_scope" => Faker.Lorem.word()
      }

      OauthClientMock
      |> expect(:post, fn(_, body) ->
        assert body[:code] == auth_code
        {:ok, stripe_response}
      end)

      changeset =
        %Settings{ account: %Account{} }
        |> Settings.changeset(:update, %{ stripe_auth_code: auth_code })

      assert changeset.changes.stripe_user_id == stripe_response["stripe_user_id"]
      assert changeset.changes.stripe_livemode == stripe_response["stripe_livemode"]
      assert changeset.changes.stripe_access_token == stripe_response["stripe_access_token"]
      assert changeset.changes.stripe_refresh_token == stripe_response["stripe_refresh_token"]
      assert changeset.changes.stripe_publishable_key == stripe_response["stripe_publishable_key"]
      assert changeset.changes.stripe_scope == stripe_response["stripe_scope"]
    end

    test "when changing stripe_user_id" do
      settings = %Settings{
        stripe_user_id: Faker.Lorem.word(),
        stripe_livemode: false,
        stripe_access_token: Faker.Lorem.word(),
        stripe_refresh_token: Faker.Lorem.word(),
        stripe_publishable_key: Faker.Lorem.word(),
        stripe_scope: Faker.Lorem.word()
      }

      changeset =
        settings
        |> Settings.changeset(:update, %{ "stripe_user_id" => nil })

      assert changeset.changes.stripe_user_id == nil
      assert changeset.changes.stripe_livemode == nil
      assert changeset.changes.stripe_access_token == nil
      assert changeset.changes.stripe_refresh_token == nil
      assert changeset.changes.stripe_publishable_key == nil
      assert changeset.changes.stripe_scope == nil
    end
  end
end
