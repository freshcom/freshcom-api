defmodule BlueJet.Query.Search do
  def search(searchable_fields) do
    quote do
      def search(query, keyword) do
        BlueJet.Query.search(query, unquote(searchable_fields), keyword)
      end

      def search(query, keyword, locale, default_locale) do
        translatable_fields =
          Atom.to_string(__MODULE__)
          |> String.split(".")
          |> Enum.drop(-1)
          |> Enum.join(".")
          |> String.to_existing_atom()
          |> apply(:translatable_fields, [])

        if translatable_fields do
          BlueJet.Query.search(query, unquote(searchable_fields), keyword, locale, default_locale, translatable_fields)
        else
          BlueJet.Query.search(query, unquote(searchable_fields), keyword)
        end
      end
    end
  end

  defmacro __using__(opts) do
    search(opts[:for])
  end
end