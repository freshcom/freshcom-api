defmodule BlueJet.AccountMembershipTest do
  use BlueJet.DataCase

  alias BlueJet.Identity.AccountMembership

  @valid_params %{
    role: "admin",
    user_id: Ecto.UUID.generate(),
    account_id: Ecto.UUID.generate()
  }
  @invalid_params %{}

  describe "changeset/4" do
    test "with struct in :built state with valid attributes" do
      changeset = AccountMembership.changeset(%AccountMembership{}, @valid_params)

      assert changeset.valid?
      assert changeset.changes.role
      assert changeset.changes.user_id
      assert changeset.changes.account_id
    end

    test "with struct in :loaded state with valid attributes" do
      struct = Ecto.put_meta(%AccountMembership{ user_id: Ecto.UUID.generate(), account_id: Ecto.UUID.generate() }, state: :loaded)
      changeset = AccountMembership.changeset(struct, @valid_params)

      assert changeset.valid?
      assert changeset.changes.role
      refute Map.get(changeset.changes, :user_id)
      refute Map.get(changeset.changes, :account_id)
    end

    test "with invalid attributes" do
      changeset = AccountMembership.changeset(%AccountMembership{}, @invalid_params)
      refute changeset.valid?
    end
  end
end
