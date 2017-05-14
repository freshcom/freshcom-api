defmodule BlueJet.ExternalFileTest do
  use BlueJet.ModelCase

  alias BlueJet.ExternalFile

  @valid_attrs %{
    name: Faker.Lorem.word(),
    status: "pending",
    content_type: "image/png",
    size_bytes: 42
  }
  @invalid_attrs %{}

  describe "changeset/1" do
    test "with valid attributes" do
      changeset = ExternalFile.changeset(%ExternalFile{}, @valid_attrs)
      assert changeset.valid?
    end

    test "with invalid attributes" do
      changeset = ExternalFile.changeset(%ExternalFile{}, @invalid_attrs)
      refute changeset.valid?
    end
  end

end
