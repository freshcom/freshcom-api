defmodule BlueJet.CustomerTest do
  use BlueJet.ModelCase, async: true

  alias Ecto.Changeset
  alias BlueJet.Repo
  alias BlueJet.Account
  alias BlueJet.Customer

  setup do
    account1 = Repo.insert!(%Account{})

    %{ account1_id: account1.id }
  end

  describe "validate/1" do
    test "with data: %{ status: \"guest\" }, changes: %{}", %{ account1_id: account1_id } do
      customer = %Customer{ account_id: account1_id, status: "guest" }
      changeset =
        %Changeset{ types: Customer.__changeset__, data: customer, changes: %{}, valid?: true }
        |> Customer.validate()

      assert changeset.valid?
    end

    test "with data: %{ status: \"guest\" }, changes: %{ status: \"member\" }", %{ account1_id: account1_id } do
      customer = %Customer{ account_id: account1_id, status: "guest" }
      changeset =
        %Changeset{ types: Customer.__changeset__, data: customer, changes: %{ status: "member" }, valid?: true }
        |> Customer.validate()

      refute changeset.valid?
      assert length(changeset.errors) == 4
    end

    test "with data: %{ status: \"member\" }, changes: %{}", %{ account1_id: account1_id } do
      customer = %Customer{ account_id: account1_id, status: "member" }
      changeset =
        %Changeset{ types: Customer.__changeset__, data: customer, changes: %{}, valid?: true }
        |> Customer.validate()

      refute changeset.valid?
      assert length(changeset.errors) == 4
    end
  end
end
