defmodule BlueJet.Utils do
  def intersect_list(list1, list2) do
    list1 -- (list1 -- list2)
  end

  def sum(structs, field) do
    Enum.reduce(Enum.map(structs, fn(struct) -> struct[field] end), 0, &+/2)
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