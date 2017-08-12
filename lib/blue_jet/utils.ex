defmodule BlueJet.Utils do
  def intersect_list(list1, list2) do
    list1 -- (list1 -- list2)
  end

  def sum(structs, field) do
    Enum.reduce(Enum.map(structs, fn(struct) -> struct[field] end), 0, &+/2)
  end
end