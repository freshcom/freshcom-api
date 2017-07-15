defmodule BlueJet.ExternalFileTest do
  use BlueJet.ModelCase, async: true

  alias BlueJet.ExternalFile

  @valid_params %{
    account_id: Ecto.UUID.generate(),
    user_id: Ecto.UUID.generate(),
    name: Faker.Lorem.word(),
    status: "pending",
    content_type: "image/png",
    size_bytes: 42
  }
  @invalid_params %{}

  describe "changeset/1" do
    test "with valid attributes" do
      changeset = ExternalFile.changeset(%ExternalFile{}, @valid_params)
      assert changeset.valid?
    end

    test "with invalid attributes" do
      changeset = ExternalFile.changeset(%ExternalFile{}, @invalid_params)
      refute changeset.valid?
    end
  end
end
