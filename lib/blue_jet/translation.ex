defmodule BlueJet.Translation do

  def put_change(changeset, _, _, "en"), do: changeset
  def put_change(changeset, translatable_fields, old_translations, locale) do
    t_fields = Enum.map_every(translatable_fields, 1, fn(item) -> Atom.to_string(item) end)
    nl_translations = old_translations
                    |> Map.get(locale, %{})
                    |> Map.merge(Map.take(changeset.changes, t_fields))

    new_translations = Map.merge(old_translations, %{ locale => nl_translations })

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