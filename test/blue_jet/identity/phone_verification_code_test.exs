defmodule BlueJet.Identity.PhoneVerificationCodeTest do
  use BlueJet.DataCase

  alias BlueJet.Identity.{Account, PhoneVerificationCode}

  describe "schema" do
    test "when account is deleted phone verification code should be automatically deleted" do
      account = Repo.insert!(%Account{
        name: Faker.Company.name()
      })

      pvc = Repo.insert!(%PhoneVerificationCode{
        account_id: account.id,
        phone_number: Faker.Phone.EnUs.phone(),
        value: "123456",
        expires_at: Timex.now()
      })

      Repo.delete!(account)
      refute Repo.get(PhoneVerificationCode, pvc.id)
    end
  end

  describe "validate/1" do
    test "when missing required fields" do
      changeset =
        %PhoneVerificationCode{}
        |> change()
        |> PhoneVerificationCode.validate()

      assert changeset.valid? == false
      assert changeset.errors[:phone_number]
    end

    test "when phone number is no long enough" do
      changeset =
        %PhoneVerificationCode{}
        |> change(%{phone_number: "123"})
        |> PhoneVerificationCode.validate()

      assert changeset.valid? == false
      assert changeset.errors[:phone_number]
    end

    test "when phone number format is invalid" do
      changeset =
        %PhoneVerificationCode{}
        |> change(%{phone_number: "123ab123123"})
        |> PhoneVerificationCode.validate()

      assert changeset.valid? == false
      assert changeset.errors[:phone_number]
    end
  end

  describe "changeset/3" do
    test "value and expires_at should be automatically generated" do
      account = Repo.insert!(%Account{})
      params = %{
        phone_number: "+11234567890"
      }

      changeset =
        %PhoneVerificationCode{account_id: account.id, account: account}
        |> PhoneVerificationCode.changeset(:insert, params)

      assert changeset.valid?
      assert changeset.changes[:value]
      assert changeset.changes[:expires_at]
    end
  end
end
