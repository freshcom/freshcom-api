defmodule BlueJet.S3FileSetTest do
  use BlueJet.ModelCase

  alias BlueJet.S3FileSet

  @valid_attrs %{label: "some content", name: "some content", translations: %{}}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = S3FileSet.changeset(%S3FileSet{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = S3FileSet.changeset(%S3FileSet{}, @invalid_attrs)
    refute changeset.valid?
  end
end
