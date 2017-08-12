defmodule BlueJet.TranslationTest do
  use BlueJet.DataCase, async: true

  alias Ecto.Changeset
  alias BlueJet.Translation
  alias BlueJet.Inventory.Sku
  alias BlueJet.FileStorage.ExternalFileCollection

  describe "put_change/4" do
    test "with en locale" do
      original_changeset = %Changeset{}
      new_changeset = Translation.put_change(original_changeset, %{}, "en")

      assert new_changeset == original_changeset
    end

    test "with zh-CN locale" do
      data = %{}
      types = %{ name: :string, caption: :string, translations: :map }

      params = %{ name: "苹果", caption: "好苹果", translations: %{ "zh-CN" => %{ "name" => "橙子", "caption" => "好橙子", "random" => "hi" } } }
      original_changeset = Changeset.cast({data, types}, params, Map.keys(types))
      translatable_fields = [:name, :caption]

      new_changeset = Translation.put_change(original_changeset, translatable_fields, "zh-CN")

      assert new_changeset != original_changeset
      assert new_changeset.changes.translations["zh-CN"]["name"] == params[:name]
      assert new_changeset.changes.translations["zh-CN"]["caption"] == params[:caption]
      assert new_changeset.changes.translations["zh-CN"]["random"] == "hi"
      refute Map.get(new_changeset.changes, :name)
      refute Map.get(new_changeset.changes, :caption)
    end
  end

  describe "translate/2" do
    test "when locale is en" do
      struct = %{}
      translated = Translation.translate(struct, "en")

      assert struct == translated
    end

    test "when locale is not en" do
      sku = %Sku{
        name: "Apple",
        caption: "Good Apple",
        translations: %{ "zh-CN" => %{ "name" => "苹果", "caption" => "好苹果" } },
        external_file_collections: [%ExternalFileCollection{ name: "Primary Images", translations: %{ "zh-CN" => %{ "name" => "主要图片" } } }]
      }
      translated = Translation.translate(sku, "zh-CN")

      assert translated != sku
      assert translated.name == "苹果"
      assert translated.caption == "好苹果"
      assert Enum.at(translated.external_file_collections, 0).name == "主要图片"
    end
  end
end
