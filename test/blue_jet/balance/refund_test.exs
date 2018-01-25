defmodule BlueJet.Balance.RefundTest do
  use BlueJet.DataCase

  import Mox

  alias BlueJet.Identity.Account
  alias BlueJet.Balance.{Refund, Payment}
  alias BlueJet.Balance.{StripeClientMock, IdentityServiceMock}

  test "writable_fields/0" do
    assert Refund.writable_fields() == [
      :status,
      :code,
      :label,
      :gateway,
      :processor,
      :method,
      :amount_cents,
      :caption,
      :description,
      :custom_data,
      :translations,
      :owner_id,
      :owner_type,
      :target_id,
      :target_type,
      :payment_id
    ]
  end

  describe "validate/1" do
    test "when missing required fields" do
      changeset =
        change(%Refund{}, %{})
        |> Refund.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [
        :amount_cents,
        :payment_id,
        :gateway
      ]
    end

    test "when amount greater than payment amount" do
      account = Repo.insert!(%Account{})
      payment = Repo.insert!(%Payment{
        account_id: account.id,
        amount_cents: 5000,
        gateway: "online"
      })
      changeset =
        change(%Refund{ account_id: account.id }, %{
          payment_id: payment.id,
          gateway: "online",
          processor: "stripe",
          amount_cents: 6000
        })
        |> Refund.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [
        :amount_cents
      ]
    end
  end

  describe "process/1" do
    test "when refund use online gateway" do
      account = Repo.insert!(%Account{})
      IdentityServiceMock
      |> expect(:get_account, fn(_) -> account end)

      stripe_refund_id = Faker.String.base64(12)
      stripe_refund = %{
        "id" => stripe_refund_id,
        "balance_transaction" => %{
          "fee" => -500
        }
      }
      stripe_transfer_reversal_id = Faker.String.base64(12)
      stripe_transfer_reversal = %{
        "id" => stripe_transfer_reversal_id,
        "amount" => 4200
      }
      StripeClientMock
      |> expect(:post, fn(_, _, _) -> {:ok, stripe_refund} end)
      |> expect(:post, fn(_, _, _) -> {:ok, stripe_transfer_reversal} end)

      payment = Repo.insert!(%Payment{
        account_id: account.id,
        gateway: "online",
        amount_cents: 5000,
        freshcom_fee_cents: 300
      })
      refund = Repo.insert!(%Refund{
        account_id: account.id,
        payment_id: payment.id,
        amount_cents: 5000,
        gateway: "online"
      })

      changeset = change(%Refund{}, %{ amount_cents: 500 })
      Refund.process(refund, changeset)

      refund = Repo.get(Refund, refund.id)
      verify!()
      assert refund.stripe_refund_id == stripe_refund_id
      assert refund.stripe_transfer_reversal_id == stripe_transfer_reversal_id
      assert refund.processor_fee_cents == 500
      assert refund.freshcom_fee_cents == 300
    end
  end
end
