defmodule BlueJet.FileStorage.FileTest do
  use BlueJet.DataCase

  alias BlueJet.FileStorage.File

  test "writable_fields/0" do
    assert File.writable_fields() == [
      :status,
      :code,
      :name,
      :label,
      :content_type,
      :size_bytes,
      :public_readable,
      :version_name,
      :version_label,
      :caption,
      :description,
      :custom_data
    ]
  end

  describe "validate/1" do
    test "when missing required fields" do
      changeset =
        change(%File{}, %{})
        |> File.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:name, :content_type, :size_bytes]
    end
  end
end
