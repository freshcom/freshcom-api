defmodule BlueJet.CustomerTest do
  use BlueJet.DataCase, async: true

  alias Ecto.Changeset
  alias BlueJet.Repo
  alias BlueJet.Identity.Account
  alias BlueJet.Identity.Customer

  setup do
    account1 = Repo.insert!(%Account{})

    %{ account1_id: account1.id }
  end

  describe "validate/1" do
    test "with data: %{ status: \"anonymous\" }, changes: %{}", %{ account1_id: account1_id } do
      customer = %Customer{ account_id: account1_id, status: "anonymous" }
      changeset =
        %Changeset{ types: Customer.__changeset__, data: customer, changes: %{}, valid?: true }
        |> Customer.validate()

      assert changeset.valid?
    end

    test "with data: %{ status: \"anonymous\" }, changes: %{ status: \"registered\" }", %{ account1_id: account1_id } do
      customer = %Customer{ account_id: account1_id, status: "anonymous" }
      changeset =
        %Changeset{ types: Customer.__changeset__, data: customer, changes: %{ status: "registered" }, valid?: true }
        |> Customer.validate()

      refute changeset.valid?
      assert length(changeset.errors) == 4
    end

    test "with data: %{ status: \"registered\" }, changes: %{}", %{ account1_id: account1_id } do
      customer = %Customer{ account_id: account1_id, status: "registered" }
      changeset =
        %Changeset{ types: Customer.__changeset__, data: customer, changes: %{}, valid?: true }
        |> Customer.validate()

      refute changeset.valid?
      assert length(changeset.errors) == 4
    end
  end
end
