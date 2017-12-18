defmodule BlueJet.Translation do
  @moduledoc """
  This is the Translation module.
  """

  alias Ecto.Changeset

  alias BlueJet.AccessRequest
  alias BlueJet.Identity

  def default_locale(%{ default_locale: default_locale }), do: default_locale
  def default_locale(%{ account_id: account_id }) when not is_nil(account_id) do
    {:ok, %{ data: account }} = Identity.do_get_account(%AccessRequest{ vas: %{ account_id: account_id } })
    account.default_locale
  end
  def default_locale(structs) when length(structs) > 0 do
    default_locale(Enum.at(structs, 0))
  end
  def default_locale(_), do: nil

  def put_change(changeset = %{ data: struct }, translatable_fields, locale) do
    default_locale = default_locale(struct)

    cond do
      is_nil(default_locale) || locale == default_locale -> changeset
      true -> put_translations(changeset, translatable_fields, locale)
    end
  end

  def put_translations(changeset, translatable_fields, locale) do
    translations = Changeset.get_field(changeset, :translations)

    locale_struct = translations |> Map.get(locale, %{})
    new_locale_struct =
      changeset.changes
      |> Map.take(translatable_fields)
      |> Map.new(fn({k, v}) -> { Atom.to_string(k), v } end)

    merged_locale_struct = Map.merge(locale_struct, new_locale_struct)
    new_translations = Map.merge(translations, %{ locale => merged_locale_struct })

    changeset = Enum.reduce(translatable_fields, changeset, fn(field_name, acc) -> Changeset.delete_change(acc, field_name) end)
    Changeset.put_change(changeset, :translations, new_translations)
  end

  # TODO: remove this
  # def translate(struct_or_structs, locale) do
  #   default_locale = default_locale(struct_or_structs)

  #   cond do
  #     is_nil(default_locale) || locale == default_locale -> struct_or_structs
  #     true -> translate_fields(struct_or_structs, locale)
  #   end
  # end

  # TODO: remove this
  def translate(struct_or_structs, _) do
    struct_or_structs
  end

  def translate(struct_or_structs, locale, default_locale) do
    cond do
      is_nil(default_locale) || locale == default_locale -> struct_or_structs
      true -> translate_fields(struct_or_structs, locale, default_locale)
    end
  end

  defp translate_fields(struct, locale, default_locale) when is_map(struct) do
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
    case Map.get(struct, :translations) do
      nil -> struct
      translations ->
        t_attributes = Map.new(Map.get(translations, locale, %{}), fn({k, v}) -> { String.to_atom(k), v } end)
        Map.merge(struct, t_attributes)
    end
  end

  defp translate_fields(list, locale, default_locale) when is_list(list) do
    Enum.map(list, fn(item) -> translate(item, locale) end)
  end

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