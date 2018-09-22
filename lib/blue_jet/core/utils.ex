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

  def stringify_keys(m) do
    Enum.reduce(m, %{}, fn({k, v}, acc) ->
      Map.put(acc, Atom.to_string(k), v)
    end)
  end
end