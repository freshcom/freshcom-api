defmodule BlueJet.Translation do

  def put_change(changeset, _, _, "en"), do: changeset
  def put_change(changeset, translatable_fields, old_translations, locale) do
    old_locale_translations = old_translations |> Map.get(locale, %{})
    new_locale_translations =
      changeset.changes
      |> Map.take(translatable_fields)
      |> Map.new(fn({k, v}) -> { Atom.to_string(k), v } end)

    new_translations = Map.merge(old_translations, %{ locale => new_locale_translations })

    changeset = Enum.reduce(translatable_fields, changeset, fn(field_name, acc) -> Ecto.Changeset.delete_change(acc, field_name) end)
    Ecto.Changeset.put_change(changeset, :translations, new_translations)
  end

  def translate(struct, "en"), do: struct
  def translate(struct, locale) do
    t_attributes = Map.new(Map.get(struct.translations, locale, %{}), fn({k, v}) -> { String.to_atom(k), v } end)
    Map.merge(struct, t_attributes)
  end

  def translate_collection(collection, "en"), do: collection
  def translate_collection(collection, locale) do
    Enum.map(collection, fn(item) -> translate(item, locale) end)
  end

end