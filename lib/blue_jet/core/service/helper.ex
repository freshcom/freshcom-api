defmodule BlueJet.Service.Helper do
  def extract_filter(fields) do
    fields[:filter] || %{}
  end

  def extract_nil_filter(map) do
    Enum.reduce(map, %{}, fn({k, v}, acc) ->
      if is_nil(v) do
        Map.put(acc, k, v)
      else
        acc
      end
    end)
  end

  def extract_clauses(map) do
    Enum.reduce(map, %{}, fn({k, v}, acc) ->
      if is_nil(v) do
        acc
      else
        Map.put(acc, k, v)
      end
    end)
  end
end