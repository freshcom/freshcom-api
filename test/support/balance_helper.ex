defmodule BlueJet.Balance.TestHelper do
  import Ecto.Changeset, only: [change: 2]
  alias Ecto.UUID
  alias BlueJet.Repo
  alias BlueJet.Balance.Service
  alias BlueJet.Balance.{Card, Payment}

  def payment_fixture(account, fields \\ %{}) do
    default_fields = %{
      account_id: account.id,
      status: "paid",
      gateway: "freshcom",
      amount_cents: System.unique_integer([:positive])
    }

    fields = Map.merge(default_fields, fields)

    %Payment{}
    |> change(fields)
    |> Repo.insert!()
  end

  def card_fixture(account, fields \\ %{}) do
    default_fields = %{
      account_id: account.id,
      status: "saved_by_owner",
      owner_id: UUID.generate(),
      owner_type: "Customer",
      exp_month: 12,
      exp_year: 2022,
      fingerprint: Faker.String.base64(12),
      stripe_customer_id: Faker.String.base64(12),
      stripe_card_id: "card_" <> Faker.String.base64(12)
    }
    fields = Map.merge(default_fields, fields)

    %Card{}
    |> change(fields)
    |> Repo.insert!()
  end

  def settings_fixture(account) do
    {:ok, settings} = Service.create_settings(%{account: account})

    settings
  end
end
