defmodule BlueJet.Goods do
  use BlueJet, :context

  def list_stockable(req), do: list("stockable", req)
  def create_stockable(req), do: create("stockable", req)
  def get_stockable(req), do: get("stockable", req)
  def update_stockable(req), do: update("stockable", req)
  def delete_stockable(req), do: delete("stockable", req)

  def list_unlockable(req), do: list("unlockable", req)
  def create_unlockable(req), do: create("unlockable", req)
  def get_unlockable(req), do: get("unlockable", req)
  def update_unlockable(req), do: update("unlockable", req)
  def delete_unlockable(req), do: delete("unlockable", req)

  def list_depositable(req), do: list("depositable", req)
  def create_depositable(req), do: create("depositable", req)
  def get_depositable(req), do: get("depositable", req)
  def update_depositable(req), do: update("depositable", req)
  def delete_depositable(req), do: delete("depositable", req)
end
