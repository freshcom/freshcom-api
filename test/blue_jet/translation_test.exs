defmodule BlueJet.TranslationTest do
  use BlueJet.DataCase

  alias Ecto.Changeset
  alias BlueJet.Translation
  alias BlueJet.Goods.Stockable

  describe "put_change/4" do
    test "when both locale and default locale not provided" do
      original_changeset = %Changeset{}
      new_changeset = Translation.put_change(original_changeset, %{})

      assert new_changeset == original_changeset
    end

    test "with locale and default locale is different" do
      data = %{}
      types = %{ name: :string, caption: :string, translations: :map }

      params = %{ name: "苹果", caption: "好苹果", translations: %{ "zh-CN" => %{ "name" => "橙子", "caption" => "好橙子", "random" => "hi" } } }
      original_changeset = Changeset.cast({data, types}, params, Map.keys(types))
      translatable_fields = [:name, :caption]

      new_changeset = Translation.put_change(original_changeset, translatable_fields, "zh-CN", "en")

      assert new_changeset != original_changeset
      assert new_changeset.changes.translations["zh-CN"]["name"] == params[:name]
      assert new_changeset.changes.translations["zh-CN"]["caption"] == params[:caption]
      assert new_changeset.changes.translations["zh-CN"]["random"] == "hi"
      refute Map.get(new_changeset.changes, :name)
      refute Map.get(new_changeset.changes, :caption)
    end
  end

  describe "translate/3" do
    test "when locale and defaut locale is the same" do
      struct = %{}
      translated = Translation.translate(struct, "en", "en")

      assert struct == translated
    end

    test "when locale and default locale is different" do
      stockable = %Stockable{
        name: "Apple",
        caption: "Good Apple",
        translations: %{ "zh-CN" => %{ "name" => "苹果", "caption" => "好苹果" } }
      }
      translated = Translation.translate(stockable, "zh-CN", "en")

      assert translated != stockable
      assert translated.name == "苹果"
      assert translated.caption == "好苹果"
    end
  end
end
