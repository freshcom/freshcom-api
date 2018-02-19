defmodule BlueJet.Translation do
  @moduledoc """
  This is the Translation module.
  """

  alias Ecto.Changeset

  @spec put_change(Changeset.t, list, String.t, String.t) :: Changeset.t
  def put_change(changeset, translatable_fields, locale \\ nil, default_locale \\ nil)
  def put_change(changeset, _, nil, nil), do: changeset
  def put_change(changeset, _, _, nil), do: changeset
  def put_change(changeset, _, locale, default_locale) when locale == default_locale, do: changeset
  def put_change(changeset, translatable_fields, locale, _) do
    put_translations(changeset, translatable_fields, locale)
  end

  defp put_translations(changeset, translatable_fields, locale) do
    translations = Changeset.get_field(changeset, :translations)

    locale_struct = Map.get(translations, locale, %{})
    new_locale_struct =
      changeset.changes
      |> Map.take(translatable_fields)
      |> Map.new(fn({k, v}) -> { Atom.to_string(k), v } end)

    merged_locale_struct = Map.merge(locale_struct, new_locale_struct)
    new_translations = Map.merge(translations, %{ locale => merged_locale_struct })

    changeset = Enum.reduce(translatable_fields, changeset, fn(field_name, acc) -> Changeset.delete_change(acc, field_name) end)
    Changeset.put_change(changeset, :translations, new_translations)
  end

  @spec translate(any, String.t, String.t) :: map | list
  def translate(value, locale, default_locale \\ nil)
  def translate(nil, _, _), do: nil
  def translate([], _, _), do: []
  def translate(value, _, nil), do: value
  def translate(value, locale, default_locale) when locale == default_locale, do: value
  def translate(value, locale, default_locale) do
    translate_fields(value, locale, default_locale)
  end

  defp translate_fields(struct = %{ translations: %{} }, locale, default_locale) do
    # Translate each field recursively
    fnames = Map.keys(struct) -- [:__meta__, :__struct__]
    struct = Enum.reduce(fnames, struct, fn(field_name, acc) ->
      value = Map.get(struct, field_name)
      Map.put(acc, field_name, translate(value, locale, default_locale))
    end)

    # Translate each attributes
    case Map.get(struct, :translations) do
      nil ->
        struct

      translations ->
        t_attributes = Map.new(Map.get(translations, locale, %{}), fn({k, v}) -> { String.to_atom(k), v } end)
        Map.merge(struct, t_attributes)
    end
  end

  defp translate_fields(list, locale, default_locale) when is_list(list) do
    Enum.map(list, fn(item) -> translate(item, locale, default_locale) end)
  end

  defp translate_fields(value, _, _), do: value

  @spec merge_translations(map, map, list, String.t) :: map
  def merge_translations(dst_translations, src_translations, fields, prefix \\ "") do
    Enum.reduce(src_translations, dst_translations, fn({locale, src_locale_struct}, acc) ->
      dst_locale_struct = Map.get(acc, locale, %{})
      dst_locale_struct = merge_locale_struct(dst_locale_struct, src_locale_struct, fields, prefix)

      Map.put(acc, locale, dst_locale_struct)
    end)
  end

  defp merge_locale_struct(dst_struct, src_struct, fields, prefix) do
    Enum.reduce(fields, dst_struct, fn(field, acc) ->
      if Map.has_key?(src_struct, field) do
        Map.put(acc, "#{prefix}#{field}", src_struct[field])
      else
        acc
      end
    end)
  end
end