defmodule BlueJet.AccountMembershipTest do
  use BlueJet.ModelCase

  alias BlueJet.AccountMembership

  @valid_attrs %{ role: "admin", user_id: Ecto.UUID.generate(), account_id: Ecto.UUID.generate() }
  @invalid_attrs %{}

  describe "changeset/2" do
    test "when struct state is :built with valid attributes" do
      changeset = AccountMembership.changeset(%AccountMembership{}, @valid_attrs)

      assert changeset.valid?
      assert changeset.changes.role
      assert changeset.changes.user_id
      assert changeset.changes.account_id
    end

    test "when struct state is :loaded with valid attributes" do
      struct = Ecto.put_meta(%AccountMembership{}, state: :loaded)
      changeset = AccountMembership.changeset(struct, @valid_attrs)

      assert changeset.valid?
      assert changeset.changes.role
      refute Map.get(changeset.changes, :user_id)
      refute Map.get(changeset.changes, :account_id)
    end

    test "with invalid attributes" do
      changeset = AccountMembership.changeset(%AccountMembership{}, @invalid_attrs)
      refute changeset.valid?
    end
  end
end
