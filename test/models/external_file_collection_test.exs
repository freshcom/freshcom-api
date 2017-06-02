defmodule BlueJet.ExternalFileCollectionTest do
  use BlueJet.ModelCase

  alias BlueJet.ExternalFileCollection

  @valid_attrs %{ label: Faker.Lorem.word(), name: Faker.Lorem.word(), account_id: Ecto.UUID.generate() }
  @invalid_attrs %{}

  describe "changeset/1" do
    test "with valid attributes" do
      changeset = ExternalFileCollection.changeset(%ExternalFileCollection{}, @valid_attrs)
      assert changeset.valid?
    end

    test "with invalid attributes" do
      changeset = ExternalFileCollection.changeset(%ExternalFileCollection{}, @invalid_attrs)
      refute changeset.valid?
    end
  end
end
