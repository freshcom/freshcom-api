defmodule BlueJet.Utils do
  def intersect_list(list1, list2) do
    list1 -- (list1 -- list2)
  end

  def sum(structs, field) do
    Enum.reduce(Enum.map(structs, fn(struct) -> struct[field] end), 0, &+/2)
  end

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
    value = Ecto.Changeset.get_change(changeset, attribute)

    if value do
      Ecto.Changeset.put_change(changeset, attribute, parameterize(value))
    else
      changeset
    end
  end

  def clean_email(nil), do: nil

  def clean_email(email) do
    email
    |> String.downcase()
    |> String.replace(" ", "")
  end

  def put_clean_email(changeset = %{ changes: %{ email: email } }) do
    Ecto.Changeset.put_change(changeset, :email, clean_email(email))
  end

  def put_clean_email(changeset), do: changeset
end