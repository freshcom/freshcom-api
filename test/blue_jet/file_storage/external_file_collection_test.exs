defmodule BlueJet.ExternalFileCollectionTest do
  use BlueJet.DataCase

  alias BlueJet.FileStorage.ExternalFileCollection

  @valid_params %{
    label: Faker.Lorem.word(),
    name: Faker.Lorem.word(),
    account_id: Ecto.UUID.generate()
  }
  @invalid_params %{}

  describe "changeset/1" do
    test "with valid attributes" do
      changeset = ExternalFileCollection.changeset(%ExternalFileCollection{}, @valid_params)
      assert changeset.valid?
    end

    test "with invalid attributes" do
      changeset = ExternalFileCollection.changeset(%ExternalFileCollection{}, @invalid_params)
      refute changeset.valid?
    end
  end
end
