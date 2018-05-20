defmodule BlueJet.Query.Helper do
  import Ecto.Query

  def filter_by(query, filter, filterable_fields) do
    filter = Map.take(filter, filterable_fields)

    Enum.reduce(filter, query, fn({k, v}, acc_query) ->
      cond do
        is_list(v) ->
          from q in acc_query, where: field(q, ^k) in ^v

        is_nil(v) ->
          from q in acc_query, where: is_nil(field(q, ^k))

        true ->
          from q in acc_query, where: field(q, ^k) == ^v
      end
    end)
  end

  def get_preload_filter(opts, key) do
    filters = opts[:filters] || %{}
    filters[key] || %{}
  end
end