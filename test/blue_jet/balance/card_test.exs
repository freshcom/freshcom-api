defmodule BlueJet.Balance.CardTest do
  use BlueJet.DataCase

  import Mox

  alias BlueJet.Identity.Account
  alias BlueJet.Balance.Card
  alias BlueJet.Balance.{StripeClientMock, IdentityServiceMock}

  setup :verify_on_exit!

  test "writable_fields/0" do
    assert match(Card.writable_fields(), [
      :label,
      :exp_month,
      :exp_year,
      :primary,
      :owner_id,
      :owner_type,
      :custom_data,
      :source,
      :translations
    ])
  end

  describe "validate/1" do
    test "when missing required fields" do
      changeset =
        %Card{}
        |> change(%{})
        |> Map.put(:action, :insert)
        |> Card.validate()

      refute changeset.valid?
      assert match_keys(changeset.errors, [
        :owner_id,
        :owner_type,
        :source
      ])
    end
  end

  describe "changeset/3" do
    test "when there is no primary card saved by owner" do
      changeset = Card.changeset(%Card{}, :insert, %{
        owner_id: Ecto.UUID.generate(),
        owner_type: "Customer"
      })

      assert changeset.changes[:primary] == true
    end

    test "when source provided is stripe card ID" do
      stripe_card = %{
        "last4" => "1231",
        "exp_month" => 10,
        "exp_year" => 2025,
        "fingerprint" => Faker.String.base64(12),
        "name" => Faker.String.base64(5),
        "brand" => "visa",
        "country" => "Canada",
        "id" => "card_" <> Faker.String.base64(12)
      }

      StripeClientMock
      |> expect(:get, fn(_, _) -> {:ok, stripe_card} end)

      account = %Account{}
      fields = %{
        owner_id: Ecto.UUID.generate(),
        owner_type: "Customer",
        source: stripe_card["id"]
      }
      changeset = Card.changeset(%Card{account: account}, :insert, fields)

      assert changeset.changes[:stripe_card_id] == fields[:source]
    end

    test "when source provided is a stripe token" do
      stripe_card = %{
        "last4" => "1231",
        "exp_month" => 10,
        "exp_year" => 2025,
        "fingerprint" => Faker.String.base64(12),
        "name" => Faker.String.base64(5),
        "brand" => "visa",
        "country" => "Canada",
        "id" => Faker.String.base64(12)
      }
      stripe_token = %{
        "id" => Faker.String.base64(12),
        "card" => stripe_card
      }

      StripeClientMock
      |> expect(:get, fn(_, _) -> {:ok, stripe_token} end)

      account = %Account{}
      fields = %{
        owner_id: Ecto.UUID.generate(),
        owner_type: "Customer",
        source: "tok_" <> Faker.String.base64(12)
      }

      changeset = Card.changeset(%Card{account: account}, :insert, fields)

      assert changeset.changes[:stripe_card_id] == stripe_card["id"]
    end
  end

  # describe "keep_stripe_source/3" do
  #   test "when given source is a card" do
  #     {:ok, source} = Card.keep_stripe_source(%{
  #       source: "card_" <> Faker.String.base64(12),
  #       customer_id: Faker.String.base64(12)
  #     }, %{}, %{})

  #     assert source
  #   end

  #   test "when given source is a token and no card exist yet" do
  #     token_object = %{
  #       "id" => Faker.String.base64(12),
  #       "card" => %{
  #         "fingerprint" => Faker.String.base64(12)
  #       }
  #     }
  #     stripe_card_id = Faker.String.base64(12)
  #     stripe_card = %{
  #       "last4" => "1231",
  #       "exp_month" => 10,
  #       "exp_year" => 2025,
  #       "fingerprint" => Faker.String.base64(12),
  #       "name" => Faker.String.base64(5),
  #       "brand" => "visa",
  #       "country" => "Canada",
  #       "id" => stripe_card_id
  #     }
  #     StripeClientMock
  #     |> expect(:get, fn(_, _) -> {:ok, token_object} end)
  #     |> expect(:post, fn(_, _, _) -> {:ok, stripe_card} end)

  #     account = Repo.insert!(%Account{})
  #     IdentityServiceMock
  #     |> expect(:get_account, fn(_) -> account end)

  #     owner_id = Ecto.UUID.generate()
  #     {:ok, source} = Card.keep_stripe_source(%{
  #       source: "tok_" <> Faker.String.base64(12),
  #       customer_id: Faker.String.base64(12)
  #     }, %{
  #       status: "saved_by_owner",
  #       owner_id: owner_id,
  #       owner_type: "Customer"
  #     }, %{
  #       account_id: account.id
  #     })

  #     card = Repo.get_by(Card, owner_id: owner_id, owner_type: "Customer")

  #     assert source == stripe_card_id
  #     assert card
  #     assert card.primary == true
  #   end

  #   test "when given source is a token and card already exist" do
  #     card_fingerprint = Faker.String.base64(12)
  #     token_object = %{
  #       "card" => %{
  #         "fingerprint" => card_fingerprint
  #       }
  #     }
  #     stripe_card_id = Faker.String.base64(12)
  #     stripe_card = %{}
  #     StripeClientMock
  #     |> expect(:get, fn(_, _) -> {:ok, token_object} end)
  #     |> expect(:post, fn(_, _, _) -> {:ok, stripe_card} end)

  #     account = Repo.insert!(%Account{})
  #     IdentityServiceMock
  #     |> expect(:get_account, fn(_) -> account end)

  #     owner_id = Ecto.UUID.generate()
  #     existing_card = Repo.insert!(%Card{
  #       account_id: account.id,
  #       status: "kept_by_system",
  #       owner_id: owner_id,
  #       owner_type: "Customer",
  #       fingerprint: card_fingerprint,
  #       stripe_card_id: stripe_card_id
  #     })

  #     {:ok, source} = Card.keep_stripe_source(%{
  #       source: "tok_" <> Faker.String.base64(12),
  #       customer_id: Faker.String.base64(12)
  #     }, %{
  #       status: "saved_by_owner",
  #       owner_id: owner_id,
  #       owner_type: "Customer"
  #     }, %{
  #       account_id: account.id
  #     })

  #     card = Repo.get(Card, existing_card.id)

  #     assert source == stripe_card_id
  #     assert card.status == "saved_by_owner"
  #   end
  # end
end
