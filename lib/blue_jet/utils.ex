defmodule BlueJet.Utils do
  def intersect_list(list1, list2) do
    list1 -- (list1 -- list2)
  end
end