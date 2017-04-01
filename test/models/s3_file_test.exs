defmodule BlueJet.S3FileTest do
  use BlueJet.ModelCase

  alias BlueJet.S3File

  @valid_attrs %{content_type: "some content", name: "some content", original_id: "7488a646-e31f-11e4-aace-600308960662", public_readable: true, size_bytes: 42, status: "some content", system_tag: "some content", version_name: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = S3File.changeset(%S3File{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = S3File.changeset(%S3File{}, @invalid_attrs)
    refute changeset.valid?
  end
end
