defmodule BlueJet.TranslationTest do
  use BlueJet.ModelCase, async: true

  alias Ecto.Changeset
  alias BlueJet.Translation

  describe "put_change/4" do
    test "with en locale" do
      original_changeset = %Changeset{}
      new_changeset = Translation.put_change(original_changeset, %{}, %{}, "en")

      assert new_changeset == original_changeset
    end

    test "with zh-CN locale" do
      data = %{}
      types = %{ name: :string, caption: :string }

      params = %{ name: "苹果", caption: "好苹果" }
      original_changeset = Changeset.cast({data, types}, params, Map.keys(types))
      translatable_fields = [:name, :caption]
      original_translations = %{ "zh-CN" => %{ "name" => "橙子", "caption" => "好橙子" } }

      new_changeset = Translation.put_change(original_changeset, translatable_fields, original_translations, "zh-CN")

      assert new_changeset != original_changeset
      assert new_changeset.changes.translations["zh-CN"]["name"] == params[:name]
      assert new_changeset.changes.translations["zh-CN"]["caption"] == params[:caption]
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
      struct = %{ name: "Apple", caption: "Good Apple", nt: "ok", translations: %{ "zh-CN" => %{ "name" => "苹果", "caption" => "好苹果" } } }
      translated = Translation.translate(struct, "zh-CN")

      assert translated != struct
      assert translated.name == "苹果"
      assert translated.caption == "好苹果"
      assert translated.nt == "ok"
    end
  end
end
