defmodule BlueJet.ExternalFileCollectionTest do
  use BlueJet.ModelCase

  alias BlueJet.ExternalFileCollection

  @valid_attrs %{label: "some content", name: "some content", translations: %{}}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = ExternalFileCollection.changeset(%ExternalFileCollection{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = ExternalFileCollection.changeset(%ExternalFileCollection{}, @invalid_attrs)
    refute changeset.valid?
  end
end
