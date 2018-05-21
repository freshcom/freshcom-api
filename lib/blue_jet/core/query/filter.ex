defmodule BlueJet.Query.Filter do
  def filter(filterable_fields) do
    quote do
      def filter_by(query, filter) do
        BlueJet.Query.filter_by(query, filter, unquote(filterable_fields))
      end
    end
  end

  defmacro __using__(opts) do
    filter(opts[:for])
  end
end