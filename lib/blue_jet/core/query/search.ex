defmodule BlueJet.Query.Search do
  def search(searchable_fields, translatable_fields) do
    quote do
      def search(query, keyword, locale, default_locale) do
        BlueJet.Query.search(query, unquote(searchable_fields), keyword, locale, default_locale, unquote(translatable_fields))
      end
    end
  end

  defmacro __using__(opts) do
    search(opts[:searchable_fields], opts[:translatable_fields])
  end
end