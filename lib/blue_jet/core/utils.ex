defmodule BlueJet.Utils do
  alias Ecto.Changeset

  def parameterize(s) do
    s
    |> String.downcase()
    |> String.replace(" ", "")
  end

  def put_parameterized(changeset, attribute_list) when is_list(attribute_list) do
    Enum.reduce(attribute_list, changeset, fn(attribute, changeset) ->
      put_parameterized(changeset, attribute)
    end)
  end

  def put_parameterized(changeset, attribute) do
    value = Changeset.get_change(changeset, attribute)

    if value do
      Changeset.put_change(changeset, attribute, parameterize(value))
    else
      changeset
    end
  end

  def downcase(nil), do: nil
  def downcase(value), do: String.downcase(value)

  def digit_only(nil), do: nil
  def digit_only(value), do: String.replace(value, ~r/[^0-9]/, "")

  def remove_space(nil), do: nil
  def remove_space(value), do: String.replace(value, " ", "")

  @spec stringify_keys(map | nil) :: map
  def stringify_keys(nil), do: %{}

  def stringify_keys(input_map) do
    Enum.reduce(input_map, %{}, fn({k, v}, acc) ->
      Map.put(acc, Atom.to_string(k), v)
    end)
  end

  @spec atomize_keys(map | nil) :: map
  def atomize_keys(nil), do: %{}

  def atomize_keys(input_map) do
    Enum.reduce(input_map, %{}, fn({k, v}, acc) ->
      Map.put(acc, String.to_existing_atom(k), v)
    end)
  end

  @spec atomize_keys(map | nil, map) :: map
  def atomize_keys(nil, _), do: %{}
  def atomize_keys(input_map, _) when map_size(input_map) == 0, do: input_map

  def atomize_keys(input_map, permitted) do
    {k, _} = Enum.random(input_map)
    atomize_keys(input_map, permitted, is_atom(k))
  end

  defp atomize_keys(input_map, permitted, true) do
    Map.take(input_map, permitted)
  end

  defp atomize_keys(input_map, permitted, false) do
    permitted = Enum.map(permitted, &Atom.to_string(&1))

    input_map
    |> Map.take(permitted)
    |> atomize_keys()
  end

  @spec take_nil_values(map) :: map
  def take_nil_values(input_map) do
    Enum.reduce(input_map, %{}, fn({k, v}, acc) ->
      put_nil_value(acc, k, v)
    end)
  end

  defp put_nil_value(input_map, key, nil), do: Map.put(input_map, key, nil)
  defp put_nil_value(input_map, _, _), do: input_map

  @spec drop_nil_values(map) :: map
  def drop_nil_values(input_map) do
    Enum.reduce(input_map, %{}, fn({k, v}, acc) ->
      put_non_nil_value(acc, k, v)
    end)
  end

  defp put_non_nil_value(input_map, _, nil), do: input_map
  defp put_non_nil_value(input_map, key, value), do: Map.put(input_map, key, value)
end