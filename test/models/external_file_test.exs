defmodule BlueJet.ExternalFileTest do
  use BlueJet.ModelCase

  alias BlueJet.ExternalFile

  @valid_attrs %{content_type: "some content", name: "some content", original_id: "7488a646-e31f-11e4-aace-600308960662", public_readable: true, size_bytes: 42, status: "some content", system_tag: "some content", version_name: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = ExternalFile.changeset(%ExternalFile{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = ExternalFile.changeset(%ExternalFile{}, @invalid_attrs)
    refute changeset.valid?
  end
end
