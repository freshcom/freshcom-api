defmodule BlueJet.Translation do
  @moduledoc """
  This is the Translation module.
  """

  def put_change(changeset, _, _, "en"), do: changeset
  def put_change(changeset, translatable_fields, old_translations, locale) do
    old_locale_translations = old_translations |> Map.get(locale, %{})
    new_locale_translations =
      changeset.changes
      |> Map.take(translatable_fields)
      |> Map.new(fn({k, v}) -> { Atom.to_string(k), v } end)

    merged_new = Map.merge(old_locale_translations, new_locale_translations)
    new_translations = Map.merge(old_translations, %{ locale => merged_new })

    changeset = Enum.reduce(translatable_fields, changeset, fn(field_name, acc) -> Ecto.Changeset.delete_change(acc, field_name) end)
    Ecto.Changeset.put_change(changeset, :translations, new_translations)
  end

  def translate(target, "en"), do: target
  def translate(struct = %{ translations: _ }, locale) when is_map(struct) do
    # Translate each loaded association (recursively)
    assoc_fnames = struct.__struct__.__schema__(:associations)
    struct = Enum.reduce(assoc_fnames, struct, fn(field_name, acc) ->
      assoc = Map.get(struct, field_name)
      case assoc do
        %Ecto.Association.NotLoaded{} -> acc
        nil -> acc
        _ -> Map.put(acc, field_name, translate(assoc, locale))
      end
    end)

    # Translate each attributes
    t_attributes = Map.new(Map.get(struct.translations, locale, %{}), fn({k, v}) -> { String.to_atom(k), v } end)
    Map.merge(struct, t_attributes)
  end
  def translate(struct, locale) when is_map(struct) do
    struct
  end
  def translate(list, locale) when is_list(list) do
    Enum.map(list, fn(item) -> translate(item, locale) end)
  end

  # Backward compatability
  def translate_collection(collection, locale) do
    translate(collection, locale)
  end
end